#Requires AutoHotkey v2.0

; 测量 Sleep(-1) / Sleep(0) 的实际耗时。结果写入 yield-test-result-<时间>.txt。

global FreqBuf := Buffer(8, 0), CtrBuf := Buffer(8, 0), QpcFreq := 0
DllCall("Kernel32\QueryPerformanceFrequency", "Ptr", FreqBuf)
QpcFreq := NumGet(FreqBuf, 0, "Int64")

out := ""
for n in [-1, 0, 1]
{
    v := []
    Loop 200
    {
        t0 := Qpc()
        Sleep(n)
        v.Push((Qpc() - t0) * 1000 / QpcFreq)
    }
    SortNums(v)
    sum := 0.0
    for x in v
        sum += x
    out .= Format("Sleep({}) 平均 {:.3f} 最小 {:.3f} 中位 {:.3f} p90 {:.3f} 最大 {:.3f} ms`n"
        , n, sum / 200, v[1], v[100], v[180], v[200])
}

FileAppend(out, A_ScriptDir "\yield-test-result-" FormatTime(, "yyyyMMdd-HHmmss") ".txt", "UTF-8")
ExitApp()

Qpc()
{
    global CtrBuf
    DllCall("Kernel32\QueryPerformanceCounter", "Ptr", CtrBuf)
    return NumGet(CtrBuf, 0, "Int64")
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
