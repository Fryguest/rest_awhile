#Requires AutoHotkey v2.0

; 比较几种等待策略命中绝对目标时刻的误差。结果写入 sleep-test-result.txt。

global FreqBuf := Buffer(8, 0), CtrBuf := Buffer(8, 0), QpcFreq := 0, TimerHandle := 0

DllCall("Kernel32\QueryPerformanceFrequency", "Ptr", FreqBuf)
QpcFreq := NumGet(FreqBuf, 0, "Int64")

out := "时钟分辨率：" Resolution() "`n"
TimerHandle := CreateHighResTimer()
out .= "高精度 waitable timer 句柄=" TimerHandle "（0 表示创建失败）`n`n"

for eventHz in [60, 6]
{
    out .= "== 目标间隔 1/" eventHz " 秒，每种策略 150 次 ==`n"
    ; for name in ["timer", "timer+spin1000", "timer-segment+spin1000"]
    for name in ["timer-segment20", "timer+spin10000"]
    {
        if (TimerHandle = 0 && InStr(name, "timer"))
        {
            out .= Format("  {:-10s} 跳过（无高精度定时器）`n", name)
            continue
        }
        s := MeasureStrategy(name, 1000 / eventHz, 150, eventHz)
        out .= Format("  {}：CPU {:.1f} ms，单核占用 {:.1f}%`n", name, s.cpuMs, s.cpuPercent)
        out .= Format("  {:-10s} 迟到 ms：最小 {:.3f}  中位 {:.3f}  p90 {:.3f}  最大 {:.3f}  标准差 {:.3f}`n"
            , name, s.min, s.median, s.p90, s.max, s.sd)
    }
    out .= "`n"
}

out .= "`n== 按住 100ms 的时长误差（每种 40 次）==`n"
; for name in ["timer", "timer+spin1000", "timer-segment+spin1000"]
for name in ["timer-segment20", "timer+spin10000"]
{
    if (TimerHandle = 0 && InStr(name, "timer"))
        continue
    s := MeasureHold(name, 100, 40)
    out .= Format("  {}：CPU {:.1f} ms，单核占用 {:.1f}%`n", name, s.cpuMs, s.cpuPercent)
    out .= Format("  {:-10s} 时长误差 ms：最小 {:.3f}  中位 {:.3f}  最大 {:.3f}  标准差 {:.3f}`n"
        , name, s.min, s.median, s.max, s.sd)
}

FileAppend(out, A_ScriptDir "\sleep-test-result-" FormatTime(, "yyyyMMdd-HHmmss") ".txt", "UTF-8")
ExitApp()

Qpc()
{
    global CtrBuf
    DllCall("Kernel32\QueryPerformanceCounter", "Ptr", CtrBuf)
    return NumGet(CtrBuf, 0, "Int64")
}

Resolution()
{
    mn := 0, mx := 0, cur := 0
    st := DllCall("ntdll\NtQueryTimerResolution", "UInt*", &mn, "UInt*", &mx, "UInt*", &cur)
    if (st != 0)
        return "查询失败 status=" st
    return Format("当前 {:.4f} ms，最小 {:.4f} ms，最大 {:.4f} ms", cur / 10000, mn / 10000, mx / 10000)
}

CreateHighResTimer()
{
    ; CREATE_WAITABLE_TIMER_HIGH_RESOLUTION = 0x2，TIMER_ALL_ACCESS = 0x1F0003
    return DllCall("CreateWaitableTimerExW", "Ptr", 0, "Ptr", 0, "UInt", 0x2, "UInt", 0x1F0003, "Ptr")
}

WaitTimer(targetQpc)
{
    global QpcFreq, TimerHandle
    remainingUs := (targetQpc - Qpc()) * 1000000 / QpcFreq
    if (remainingUs <= 0)
        return
    due := Buffer(8, 0)
    NumPut("Int64", -Round(remainingUs * 10), due)   ; 负数表示相对时间，单位 100ns
    DllCall("SetWaitableTimer", "Ptr", TimerHandle, "Ptr", due, "Int", 0, "Ptr", 0, "Ptr", 0, "Int", 0)
    DllCall("WaitForSingleObject", "Ptr", TimerHandle, "UInt", 0xFFFFFFFF)
}

WaitTimerSegment(targetQpc)
{
    global QpcFreq, TimerHandle
    due := Buffer(8, 0)
    Loop
    {
        remainingUs := (targetQpc - Qpc()) * 1000000 / QpcFreq
        if (remainingUs <= 0)
            return

        waitUs := Min(20000, remainingUs)
        NumPut("Int64", -Max(1, Round(waitUs * 10)), due)
        if !DllCall("SetWaitableTimer", "Ptr", TimerHandle, "Ptr", due, "Int", 0, "Ptr", 0, "Ptr", 0, "Int", 0)
            throw OSError()
        result := DllCall("WaitForSingleObject", "Ptr", TimerHandle, "UInt", 0xFFFFFFFF, "UInt")
        if (result = 0xFFFFFFFF)
            throw OSError()
        if (result != 0)
            throw Error("等待定时器返回异常：" result)
    }
}

WaitTimerSpin(targetQpc, spinUs)
{
    global QpcFreq, TimerHandle
    remainingUs := (targetQpc - Qpc()) * 1000000 / QpcFreq
    if (remainingUs > spinUs)
    {
        due := Buffer(8, 0)
        NumPut("Int64", -Round((remainingUs - spinUs) * 10), due)
        DllCall("SetWaitableTimer", "Ptr", TimerHandle, "Ptr", due, "Int", 0, "Ptr", 0, "Ptr", 0, "Int", 0)
        DllCall("WaitForSingleObject", "Ptr", TimerHandle, "UInt", 0xFFFFFFFF)
    }
    while (Qpc() < targetQpc)
    {
    }
}

WaitTimerSegmentSpin(targetQpc)
{
    global QpcFreq, TimerHandle
    due := Buffer(8, 0)
    Loop
    {
        remainingUs := (targetQpc - Qpc()) * 1000000 / QpcFreq
        if (remainingUs <= 1000)
            break

        waitUs := Min(5000, remainingUs - 1000)
        NumPut("Int64", -Max(1, Round(waitUs * 10)), due)
        if !DllCall("SetWaitableTimer", "Ptr", TimerHandle, "Ptr", due, "Int", 0, "Ptr", 0, "Ptr", 0, "Int", 0)
            throw OSError()
        result := DllCall("WaitForSingleObject", "Ptr", TimerHandle, "UInt", 0xFFFFFFFF, "UInt")
        if (result = 0xFFFFFFFF)
            throw OSError()
        if (result != 0)
            throw Error("等待定时器返回异常：" result)
    }
    while (Qpc() < targetQpc)
    {
    }
}

MeasureStrategy(name, intervalMs, samples, eventHz := 0)
{
    global QpcFreq
    lates := []
    cpuStart := ProcessCpuMs()
    start := Qpc()
    Loop samples
    {
        target := start + (eventHz > 0 ? Round(A_Index * QpcFreq / eventHz) : Round(A_Index * intervalMs * QpcFreq / 1000))
        WaitByName(name, target)
        lates.Push((Qpc() - target) * 1000 / QpcFreq)
    }
    return StatsWithCpu(lates, cpuStart, start)
}

MeasureHold(name, holdMs, samples)
{
    global QpcFreq
    errors := []
    cpuStart := ProcessCpuMs()
    wallStart := Qpc()
    Loop samples
    {
        start := Qpc()
        ; 第一个目标放在未来 50ms，使 KD 也经历一次完整等待，与回放路径一致。
        WaitByName(name, start + Round(50 * QpcFreq / 1000))
        t0 := Qpc()
        WaitByName(name, start + Round((50 + holdMs) * QpcFreq / 1000))
        errors.Push((Qpc() - t0) * 1000 / QpcFreq - holdMs)
    }
    return StatsWithCpu(errors, cpuStart, wallStart)
}

WaitByName(name, target)
{
    switch name
    {
        case "timer": WaitTimer(target)
        case "timer-segment20": WaitTimerSegment(target)
        case "timer+spin1000": WaitTimerSpin(target, 1000)
        case "timer+spin10000": WaitTimerSpin(target, 10000)
        case "timer-segment+spin1000": WaitTimerSegmentSpin(target)
    }
}

ProcessCpuMs()
{
    times := Buffer(32, 0)
    process := DllCall("Kernel32\GetCurrentProcess", "Ptr")
    if !DllCall("Kernel32\GetProcessTimes", "Ptr", process, "Ptr", times.Ptr, "Ptr", times.Ptr + 8, "Ptr", times.Ptr + 16, "Ptr", times.Ptr + 24, "Int")
        throw OSError()
    return (NumGet(times, 16, "Int64") + NumGet(times, 24, "Int64")) / 10000
}

StatsWithCpu(values, cpuStart, wallStart)
{
    global QpcFreq
    elapsedMs := (Qpc() - wallStart) * 1000 / QpcFreq
    cpuMs := ProcessCpuMs() - cpuStart
    result := Stats(values)
    result.cpuMs := cpuMs
    result.cpuPercent := elapsedMs > 0 ? cpuMs / elapsedMs * 100 : 0
    return result
}

Stats(values)
{
    SortNums(values)
    n := values.Length
    sum := 0.0
    for v in values
        sum += v
    avg := sum / n
    var := 0.0
    for v in values
        var += (v - avg) ** 2
    return {
        min: values[1],
        median: values[Floor(n / 2) + 1],
        p90: values[Ceil(n * 0.9)],
        max: values[n],
        sd: Sqrt(var / n)
    }
}

SortNums(arr)
{
    Loop arr.Length - 1
    {
        i := A_Index + 1
        v := arr[i]
        j := i - 1
        while (j >= 1 && arr[j] > v)
        {
            arr[j + 1] := arr[j]
            j -= 1
        }
        arr[j + 1] := v
    }
}
