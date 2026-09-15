#Requires AutoHotkey v2.0
#SingleInstance Force
#Include util.ahk

; 独立的 Raw Input 录制器。
; F1：进入待录制状态 / 停止并保存录制。
; F2：松开时开始 / 停止回放。
; 所有公开状态与函数均使用 Rec_ 前缀，便于后续 #Include 到 run.ahk。

global Rec_State := "idle"                 ; idle | armed | recording | save_pending | replaying
global Rec_Events := []
global Rec_DownKeys := Map()
global Rec_MouseDowns := Map()
global Rec_InputGui := ""
global Rec_StatusGui := ""
global Rec_StatusText := ""
global Rec_StatusX := 0
global Rec_StatusY := 0
global Rec_QpcFrequency := 0
global Rec_RecordStartQpc := 0
global Rec_DragWidth := 0
global Rec_DragHeight := 0
global Rec_RawInputErrorCount := 0
global Rec_OutputFile := A_ScriptDir "\recording.tsv"
global Rec_TempFile := A_ScriptDir "\recording.tmp"
global Rec_ReplayStopRequested := false
global Rec_ReplayDownKeys := Map()
global Rec_ReplayMouseDowns := Map()

Rec_EnableDpiAwareness()
Rec_InitializeQpc()
Rec_CreateInputReceiver()
Log("Recorder | Raw Input 接收器已初始化")
OnExit(Rec_OnExit)

$F1::Rec_Toggle()
*$F2 Up::Rec_ToggleReplay()

Rec_EnableDpiAwareness()
{
    ; 必须在创建接收窗口前设置，确保坐标使用物理像素。
    try
    {
        if DllCall("User32\SetProcessDpiAwarenessContext", "Ptr", -4, "Int")
            return
    }

    try
    {
        if (DllCall("Shcore\SetProcessDpiAwareness", "Int", 2, "Int") = 0)
            return
    }

    try DllCall("User32\SetProcessDPIAware")
}

Rec_InitializeQpc()
{
    global Rec_QpcFrequency, Rec_DragWidth, Rec_DragHeight

    frequencyBuffer := Buffer(8, 0)
    if !DllCall("Kernel32\QueryPerformanceFrequency", "Ptr", frequencyBuffer)
        throw Error("无法初始化 QueryPerformanceCounter。")

    Rec_QpcFrequency := NumGet(frequencyBuffer, 0, "Int64")
    Rec_DragWidth := DllCall("User32\GetSystemMetrics", "Int", 68, "Int")
    Rec_DragHeight := DllCall("User32\GetSystemMetrics", "Int", 69, "Int")
}

Rec_CreateInputReceiver()
{
    global Rec_InputGui

    ; 该窗口只负责接收 WM_INPUT，不显示任何界面。
    Rec_InputGui := Gui("+ToolWindow -Caption", "RecInputReceiver")
    Rec_InputGui.Show("Hide")

    Rec_RegisterRawInput(Rec_InputGui.Hwnd)
    OnMessage(0x00FF, Rec_OnWmInput)  ; WM_INPUT
}

Rec_ShowStatus(message, durationMs := 0, reposition := false)
{
    global Rec_StatusGui, Rec_StatusText, Rec_StatusX, Rec_StatusY

    SetTimer(Rec_HideStatus, 0)
    if !IsObject(Rec_StatusGui)
    {
        ; 不激活、置顶、工具窗口；分层窗口配合透明样式实现点击穿透。
        Rec_StatusGui := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08080020", "录制状态")
        Rec_StatusGui.BackColor := "202020"
        Rec_StatusGui.MarginX := 12
        Rec_StatusGui.MarginY := 10
        Rec_StatusGui.SetFont("s10 cFFFFFF", "Microsoft YaHei UI")
        Rec_StatusText := Rec_StatusGui.AddText("w280 h24 +0x200", "")
        WinSetTransparent(235, Rec_StatusGui.Hwnd)
    }

    if reposition
    {
        monitor := MonitorGetPrimary()
        if Rec_GetCursorPosition(&x, &y)
        {
            Loop MonitorGetCount()
            {
                MonitorGet(A_Index, &left, &top, &right, &bottom)
                if (x >= left && x < right && y >= top && y < bottom)
                {
                    monitor := A_Index
                    break
                }
            }
        }
        MonitorGetWorkArea(monitor, &left, &top, &right, &bottom)
        Rec_StatusX := Max(left, right - 304 - 16)
        Rec_StatusY := top + 16
    }

    Rec_StatusText.Text := message
    Rec_StatusGui.Show("NA x" Rec_StatusX " y" Rec_StatusY " w304 h44")
    if (durationMs > 0)
        SetTimer(Rec_HideStatus, -durationMs)
}

Rec_HideStatus()
{
    global Rec_StatusGui

    SetTimer(Rec_HideStatus, 0)
    if IsObject(Rec_StatusGui)
        Rec_StatusGui.Hide()
}

Rec_DestroyStatus()
{
    global Rec_StatusGui, Rec_StatusText

    SetTimer(Rec_HideStatus, 0)
    if IsObject(Rec_StatusGui)
        Rec_StatusGui.Destroy()
    Rec_StatusGui := ""
    Rec_StatusText := ""
}

Rec_RegisterRawInput(hwnd)
{
    ridSize := 8 + A_PtrSize
    rawDevices := Buffer(ridSize * 2, 0)

    ; Generic Desktop / Mouse
    NumPut("UShort", 0x01, rawDevices, 0)
    NumPut("UShort", 0x02, rawDevices, 2)
    NumPut("UInt", 0x00000100, rawDevices, 4)  ; RIDEV_INPUTSINK
    NumPut("Ptr", hwnd, rawDevices, 8)

    ; Generic Desktop / Keyboard
    keyboardOffset := ridSize
    NumPut("UShort", 0x01, rawDevices, keyboardOffset)
    NumPut("UShort", 0x06, rawDevices, keyboardOffset + 2)
    NumPut("UInt", 0x00000100, rawDevices, keyboardOffset + 4)
    NumPut("Ptr", hwnd, rawDevices, keyboardOffset + 8)

    if !DllCall("User32\RegisterRawInputDevices", "Ptr", rawDevices, "UInt", 2, "UInt", ridSize)
        throw OSError()
}

Rec_Toggle()
{
    global Rec_State

    if (Rec_State = "replaying")
    {
        Log("Replay | 忽略 F1：回放流程尚未结束")
        return
    }

    if (Rec_State = "idle")
        Rec_Arm()
    else
        Rec_Stop()
}

Rec_Arm()
{
    global Rec_State, Rec_Events, Rec_DownKeys, Rec_MouseDowns, Rec_RawInputErrorCount

    Rec_Events := []
    Rec_DownKeys := Map()
    Rec_MouseDowns := Map()
    Rec_RawInputErrorCount := 0
    Rec_State := "armed"
    Rec_ShowStatus("待录制 · F1 取消", 0, true)
    Log("Recorder | 进入待录制状态")
}

Rec_Stop()
{
    global Rec_State, Rec_Events, Rec_DownKeys, Rec_MouseDowns, Rec_RawInputErrorCount

    if (Rec_State = "armed")
    {
        Rec_State := "idle"
        Log("Recorder | 待录制状态已取消：没有有效事件")
        Rec_ShowStatus("已取消录制", 2000)
        return
    }

    if (Rec_State != "recording" && Rec_State != "save_pending")
        return

    if (Rec_State = "recording")
    {
        Rec_State := "save_pending"
        Log("Recorder | 停止录制：事件数=" Rec_Events.Length)
        Rec_AppendPendingReleases()
        if (Rec_RawInputErrorCount > 0)
            Log("Recorder | Raw Input 读取失败次数=" Rec_RawInputErrorCount)
    }

    try
        Rec_SaveRecording()
    catch Error as err
    {
        Log("Recorder | 保存失败：" err.Message)
        Rec_ShowStatus("保存失败 · F1 重试")
        MsgBox("录制保存失败，数据仍保留在内存中。`n"
            "关闭提示后可按 F1 重试；退出或重载脚本会丢失这些数据。`n`n"
            err.Message, "键鼠录制", "Icon!")
        return
    }

    Rec_State := "idle"
    Rec_Events := []
    Rec_DownKeys := Map()
    Rec_MouseDowns := Map()
    Rec_ShowStatus("录制已保存", 2000)
}

Rec_OnWmInput(wParam, lParam, msg, hwnd)
{
    static RID_INPUT := 0x10000003
    global Rec_State, Rec_RawInputErrorCount

    ; 校验、回放、清理及等待保存期间均不采集输入。
    if (Rec_State = "replaying" || Rec_State = "save_pending")
        return

    ; RAWINPUTHEADER: UInt + UInt + HANDLE + WPARAM
    ; x86 为 16 字节，x64 为 24 字节。
    headerSize := 8 + (2 * A_PtrSize)
    dataSize := 0

    queryResult := DllCall("User32\GetRawInputData", "Ptr", lParam, "UInt", RID_INPUT, "Ptr", 0, "UIntP", &dataSize, "UInt", headerSize)

    if (queryResult = 0xFFFFFFFF)
    {
        if (Rec_State != "idle")
            Rec_RawInputErrorCount += 1
        return
    }

    if (dataSize = 0)
        return

    rawData := Buffer(dataSize, 0)
    copiedSize := DllCall("User32\GetRawInputData", "Ptr", lParam, "UInt", RID_INPUT, "Ptr", rawData, "UIntP", &dataSize, "UInt", headerSize)

    if (copiedSize = 0xFFFFFFFF)
    {
        if (Rec_State != "idle")
            Rec_RawInputErrorCount += 1
        return
    }

    inputType := NumGet(rawData, 0, "UInt")
    if (inputType = 0)
    {
        ; RAWMOUSE 固定部分为 24 字节。
        if (copiedSize < headerSize + 24)
        {
            if (Rec_State != "idle")
                Rec_RawInputErrorCount += 1
            return
        }
        Rec_HandleRawMouse(rawData, headerSize)
    }
    else if (inputType = 1)
    {
        ; RAWKEYBOARD 固定部分为 16 字节。
        if (copiedSize < headerSize + 16)
        {
            if (Rec_State != "idle")
                Rec_RawInputErrorCount += 1
            return
        }
        Rec_HandleRawKeyboard(rawData, headerSize)
    }
}

Rec_HandleRawKeyboard(rawData, dataOffset)
{
    global Rec_State, Rec_DownKeys

    ; RAWKEYBOARD:
    ; MakeCode(0), Flags(2), Reserved(4), VKey(6), Message(8), Extra(12)
    makeCode := NumGet(rawData, dataOffset, "UShort")
    flags := NumGet(rawData, dataOffset + 2, "UShort")
    virtualKey := NumGet(rawData, dataOffset + 6, "UShort")
    isKeyUp := (flags & 0x01) != 0       ; RI_KEY_BREAK
    isExtended := (flags & 0x02) != 0    ; RI_KEY_E0

    ; F1、F2 仅用于控制录制和回放，永不写入事件。
    if (virtualKey = 0x70 || virtualKey = 0x71 || virtualKey = 0 || virtualKey = 0xFF)
        return

    if (Rec_State = "armed" && isKeyUp)
        return

    if (Rec_State = "idle")
        return

    qpc := Rec_GetQpc()
    if (Rec_State = "armed")
        Rec_Begin(qpc)

    keyId := virtualKey ":" makeCode ":" isExtended
    if isKeyUp
    {
        ; 忽略在录制开始前已经按下的键的抬起事件。
        if !Rec_DownKeys.Has(keyId)
            return

        Rec_AppendEvent(qpc, "KU", virtualKey, makeCode, isExtended)
        Rec_DownKeys.Delete(keyId)
    }
    else
    {
        ; 自动重复的 key-down 仍按原样记录。
        Rec_AppendEvent(qpc, "KD", virtualKey, makeCode, isExtended)
        Rec_DownKeys[keyId] := [virtualKey, makeCode, isExtended]
    }
}

Rec_HandleRawMouse(rawData, dataOffset)
{
    ; RAWMOUSE 的 buttonFlags 位于偏移 4，buttonData 位于偏移 6。
    buttonFlags := NumGet(rawData, dataOffset + 4, "UShort")
    buttonData := NumGet(rawData, dataOffset + 6, "Short")

    relevantFlags := 0x0001 | 0x0002 | 0x0004 | 0x0008 | 0x0010 | 0x0020 | 0x0400 | 0x0800
    if !(buttonFlags & relevantFlags)
        return

    if !Rec_GetCursorPosition(&x, &y)
        return

    qpc := Rec_GetQpc()
    Rec_HandleMouseButton(buttonFlags, 0x0001, 0x0002, "L", qpc, x, y)
    Rec_HandleMouseButton(buttonFlags, 0x0004, 0x0008, "R", qpc, x, y)
    Rec_HandleMouseButton(buttonFlags, 0x0010, 0x0020, "M", qpc, x, y)

    if (buttonFlags & 0x0400)  ; RI_MOUSE_WHEEL
        Rec_RecordWheel("W", buttonData, qpc, x, y)
    if (buttonFlags & 0x0800)  ; RI_MOUSE_HWHEEL
        Rec_RecordWheel("HW", buttonData, qpc, x, y)
}

Rec_HandleMouseButton(flags, downFlag, upFlag, button, qpc, x, y)
{
    global Rec_State, Rec_MouseDowns, Rec_DragWidth, Rec_DragHeight

    if (flags & downFlag)
    {
        if (Rec_State = "idle")
            return
        if (Rec_State = "armed")
            Rec_Begin(qpc)

        Rec_AppendEvent(qpc, "MD", button, x, y)
        Rec_MouseDowns[button] := [x, y]
    }

    if !(flags & upFlag)
        return

    ; 抬起事件不能作为录制的首个有效操作。
    if (Rec_State != "recording" || !Rec_MouseDowns.Has(button))
        return

    startPoint := Rec_MouseDowns[button]
    isDrag := Abs(x - startPoint[1]) >= Rec_DragWidth || Abs(y - startPoint[2]) >= Rec_DragHeight

    Rec_AppendEvent(qpc, "MU", button, x, y, isDrag ? 1 : 0)
    Rec_MouseDowns.Delete(button)
}

Rec_RecordWheel(type, delta, qpc, x, y)
{
    global Rec_State

    if (Rec_State = "idle")
        return
    if (Rec_State = "armed")
        Rec_Begin(qpc)

    Rec_AppendEvent(qpc, type, delta, x, y)
}

Rec_Begin(qpc)
{
    global Rec_State, Rec_RecordStartQpc

    Rec_RecordStartQpc := qpc
    Rec_State := "recording"
    Rec_ShowStatus("脚本录制中 · F1 停止")
    Log("Recorder | 录制开始")
}

Rec_GetQpc()
{
    qpcBuffer := Buffer(8, 0)
    DllCall("Kernel32\QueryPerformanceCounter", "Ptr", qpcBuffer)
    return NumGet(qpcBuffer, 0, "Int64")
}

Rec_AppendEvent(qpc, type, args*)
{
    global Rec_Events, Rec_RecordStartQpc, Rec_QpcFrequency

    offsetUs := Round((qpc - Rec_RecordStartQpc) * 1000000 / Rec_QpcFrequency)
    event := [offsetUs, type]
    for arg in args
        event.Push(arg)
    Rec_Events.Push(event)
}

Rec_AppendPendingReleases()
{
    global Rec_DownKeys, Rec_MouseDowns, Rec_DragWidth, Rec_DragHeight

    qpc := Rec_GetQpc()
    for keyId, keyData in Rec_DownKeys
        Rec_AppendEvent(qpc, "KU", keyData[1], keyData[2], keyData[3])

    if !Rec_GetCursorPosition(&x, &y)
        return

    for button, startPoint in Rec_MouseDowns
    {
        isDrag := Abs(x - startPoint[1]) >= Rec_DragWidth || Abs(y - startPoint[2]) >= Rec_DragHeight
        Rec_AppendEvent(qpc, "MU", button, x, y, isDrag ? 1 : 0)
    }
}

Rec_GetCursorPosition(&x, &y)
{
    point := Buffer(8, 0)
    if !DllCall("User32\GetCursorPos", "Ptr", point)
        return false

    x := NumGet(point, 0, "Int")
    y := NumGet(point, 4, "Int")
    return true
}

Rec_SaveRecording()
{
    global Rec_Events, Rec_OutputFile, Rec_TempFile

    virtualLeft := DllCall("User32\GetSystemMetrics", "Int", 76, "Int")
    virtualTop := DllCall("User32\GetSystemMetrics", "Int", 77, "Int")
    virtualWidth := DllCall("User32\GetSystemMetrics", "Int", 78, "Int")
    virtualHeight := DllCall("User32\GetSystemMetrics", "Int", 79, "Int")

    output := "WQLREC`t1`n"
    output .= "VSCREEN`t" virtualLeft "`t" virtualTop "`t" virtualWidth "`t" virtualHeight "`n"

    monitorCount := MonitorGetCount()
    Loop monitorCount
    {
        MonitorGet(A_Index, &left, &top, &right, &bottom)
        output .= "MONITOR`t" A_Index "`t" left "`t" top "`t" right "`t" bottom "`n"
    }

    for event in Rec_Events
    {
        output .= "EVENT"
        for field in event
            output .= "`t" field
        output .= "`n"
    }

    if FileExist(Rec_TempFile)
        FileDelete(Rec_TempFile)
    FileAppend(output, Rec_TempFile, "UTF-8-RAW")

    ; MOVEFILE_REPLACE_EXISTING：临时文件完整写入后才替换旧录制。
    if !DllCall("Kernel32\MoveFileExW", "Str", Rec_TempFile, "Str", Rec_OutputFile, "UInt", 0x00000001)
        throw OSError()

    Log("Recorder | 录制已保存：事件数=" Rec_Events.Length " 文件=" Rec_OutputFile)
}

Rec_OnExit(exitReason, exitCode)
{
    global Rec_State

    Log("Recorder | 脚本退出：reason=" exitReason " code=" exitCode)
    if (Rec_State = "recording")
        Rec_AppendPendingReleases()

    ; 进程退出会自动注销；这里显式注销避免作为库使用时遗留注册。
    try Rec_UnregisterRawInput()
    try Rec_DestroyStatus()
}

Rec_UnregisterRawInput()
{
    ridSize := 8 + A_PtrSize
    rawDevices := Buffer(ridSize * 2, 0)

    NumPut("UShort", 0x01, rawDevices, 0)
    NumPut("UShort", 0x02, rawDevices, 2)
    NumPut("UInt", 0x00000001, rawDevices, 4)  ; RIDEV_REMOVE

    keyboardOffset := ridSize
    NumPut("UShort", 0x01, rawDevices, keyboardOffset)
    NumPut("UShort", 0x06, rawDevices, keyboardOffset + 2)
    NumPut("UInt", 0x00000001, rawDevices, keyboardOffset + 4)

    DllCall("User32\RegisterRawInputDevices", "Ptr", rawDevices, "UInt", 2, "UInt", ridSize)
}

; 热键只切换状态，播放交给一次性定时器，避免占住 F2 热键线程。
Rec_ToggleReplay()
{
    global Rec_State, Rec_ReplayStopRequested, Rec_ReplayDownKeys, Rec_ReplayMouseDowns

    if (Rec_State = "replaying")
    {
        Rec_ReplayStopRequested := true
        Log("Replay | 收到 F2 停止请求")
        return
    }
    if (Rec_State != "idle")
    {
        Log("Replay | 忽略 F2：当前状态=" Rec_State)
        return
    }

    Rec_ReplayStopRequested := false
    Rec_ReplayDownKeys := Map()
    Rec_ReplayMouseDowns := Map()
    Rec_State := "replaying"
    Log("Replay | 收到回放请求，进入 replaying 状态")
    Rec_ShowStatus("脚本播放中 · F2 停止", 0, true)
    SetTimer(Rec_Replay, -1)
}

Rec_Replay()
{
    global Rec_State, Rec_OutputFile, Rec_QpcFrequency, Rec_ReplayStopRequested, Rec_ReplayDownKeys, Rec_ReplayMouseDowns
    failure := ""
    completed := 0
    total := 0
    lineNumber := 0

    try
    {
        ; 每次重新读取并校验，直接使用返回的数据，不二次读文件。
        Log("Replay | 调用格式校验：文件=" Rec_OutputFile)
        data := Rec_ValidateRecording(Rec_OutputFile)
        total := data.Events.Length
        Log("Replay | 格式校验通过：事件数=" total)

        if (total > 0 && !Rec_ReplayStopRequested)
        {
            startQpc := Rec_GetQpc()
            Log("Replay | 开始发送事件")
            for index, event in data.Events
            {
                lineNumber := data.EventLines[index]
                targetQpc := startQpc + Round(event[1] * Rec_QpcFrequency / 1000000)
                Log("Replay | 准备事件：序号=" index " 行号=" lineNumber " 类型=" event[2] " 计划偏移us=" event[1])
                if !Rec_ReplayWaitUntil(targetQpc)
                    break

                lateUs := Round((Rec_GetQpc() - targetQpc) * 1000000 / Rec_QpcFrequency)
                Log("Replay | 事件到期：行号=" lineNumber " 落后us=" lateUs)
                if !Rec_ReplayEvent(event)
                    break

                completed += 1
                Log("Replay | 事件发送完成：行号=" lineNumber " 已完成=" completed "/" total)
            }
        }
    }
    catch Error as err
    {
        failure := (lineNumber > 0 ? "第 " lineNumber " 行：" : "") err.Message
        Log("Replay | 回放失败：" failure)
    }
    finally
    {
        try
        {
            Log("Replay | 开始清理：未释放键数=" Rec_ReplayDownKeys.Count " 未释放鼠标按钮数=" Rec_ReplayMouseDowns.Count)
            releaseFailure := Rec_ReplayReleaseInputs()
            if (releaseFailure != "")
                failure .= (failure = "" ? "" : "`n") releaseFailure
            Log("Replay | 回放流程结束：已完成=" completed "/" total " 停止请求=" Rec_ReplayStopRequested " 存在错误=" (failure != ""))
        }
        finally
        {
            Rec_State := "idle"
        }
    }

    if (failure != "")
    {
        Rec_HideStatus()
        MsgBox("本次回放已停止。`n`n" failure, "键鼠回放", "Icon!")
        return
    }

    Rec_ShowStatus(Rec_ReplayStopRequested ? "已停止播放" : "脚本播放完成", 2000)
}

; 按绝对时刻等待；到期事件也处理一次消息，保证密集回放时能响应 F2。
Rec_ReplayWaitUntil(targetQpc)
{
    global Rec_ReplayStopRequested, Rec_QpcFrequency
    while !Rec_ReplayStopRequested
    {
        remainingMs := (targetQpc - Rec_GetQpc()) * 1000 / Rec_QpcFrequency
        if (remainingMs <= 0)
        {
            Sleep(-1)
            return !Rec_ReplayStopRequested
        }
        Sleep(Min(10, Max(1, Floor(remainingMs))))
    }
    return false
}

Rec_ReplayEvent(event)
{
    global Rec_ReplayStopRequested, Rec_ReplayDownKeys, Rec_ReplayMouseDowns
    static buttonFlags := Map("L", [0x0002, 0x0004], "R", [0x0008, 0x0010], "M", [0x0020, 0x0040])
    if Rec_ReplayStopRequested
        return false

    eventType := event[2]
    if (eventType == "KD" || eventType == "KU")
    {
        virtualKey := event[3]
        scanCode := event[4]
        extended := event[5]
        isUp := (eventType == "KU")
        keyId := (scanCode != 0 ? "SC:" scanCode : "VK:" virtualKey) ":" extended
        Rec_ReplaySendKeyboard(virtualKey, scanCode, extended, isUp)
        if isUp
        {
            if Rec_ReplayDownKeys.Has(keyId)
                Rec_ReplayDownKeys.Delete(keyId)
        }
        else
            Rec_ReplayDownKeys[keyId] := [virtualKey, scanCode, extended]
        Log("Replay | 键盘状态更新：未释放键数=" Rec_ReplayDownKeys.Count)
        return true
    }

    x := event[4]
    y := event[5]
    Log("Replay | 定位鼠标：x=" x " y=" y)
    if !DllCall("User32\SetCursorPos", "Int", x, "Int", y, "Int")
        throw OSError()
    Log("Replay | 鼠标定位成功")
    if Rec_ReplayStopRequested
        return false

    if (eventType == "MD" || eventType == "MU")
    {
        button := event[3]
        isUp := (eventType == "MU")
        Rec_ReplaySendMouse(buttonFlags[button][isUp ? 2 : 1])
        if isUp
        {
            if Rec_ReplayMouseDowns.Has(button)
                Rec_ReplayMouseDowns.Delete(button)
        }
        else
            Rec_ReplayMouseDowns[button] := true
        ; 忽略 MU 的拖拽标记，不生成移动轨迹。
        Log("Replay | 鼠标按钮状态更新：未释放按钮数=" Rec_ReplayMouseDowns.Count)
    }
    else
    {
        ; MOUSEEVENTF_WHEEL / MOUSEEVENTF_HWHEEL。
        flags := (eventType == "W") ? 0x0800 : 0x1000
        Rec_ReplaySendMouse(flags, event[3])
        Log("Replay | 滚轮发送完成：类型=" eventType " 增量=" event[3])
    }
    return true
}

Rec_ReplaySendKeyboard(virtualKey, scanCode, extended, isUp)
{
    inputSize := (A_PtrSize = 8) ? 40 : 28
    unionOffset := (A_PtrSize = 8) ? 8 : 4
    input := Buffer(inputSize, 0)
    ; INPUT_KEYBOARD；KEYEVENTF_KEYUP / EXTENDEDKEY / SCANCODE。
    flags := (isUp ? 0x0002 : 0) | (extended ? 0x0001 : 0)
    if (scanCode != 0)
    {
        flags |= 0x0008
        virtualKey := 0
    }
    NumPut("UInt", 1, input, 0)
    NumPut("UShort", virtualKey, input, unionOffset)
    NumPut("UShort", scanCode, input, unionOffset + 2)
    NumPut("UInt", flags, input, unionOffset + 4)
    Log("Replay | 构造键盘 INPUT：模式=" (scanCode != 0 ? "扫描码" : "虚拟键码") " 抬起=" isUp " 扩展=" extended)
    Rec_ReplaySendInput(input)
}

Rec_ReplaySendMouse(flags, mouseData := 0)
{
    inputSize := (A_PtrSize = 8) ? 40 : 28
    unionOffset := (A_PtrSize = 8) ? 8 : 4
    input := Buffer(inputSize, 0)
    ; INPUT_MOUSE；坐标由 SetCursorPos 设置，此处不发送移动事件。
    NumPut("UInt", 0, input, 0)
    NumPut("Int", mouseData, input, unionOffset + 8)
    NumPut("UInt", flags, input, unionOffset + 12)
    Log("Replay | 构造鼠标 INPUT：flags=" flags " mouseData=" mouseData)
    Rec_ReplaySendInput(input)
}

Rec_ReplaySendInput(input)
{
    sent := DllCall("User32\SendInput", "UInt", 1, "Ptr", input, "Int", input.Size, "UInt")
    lastError := A_LastError
    Log("Replay | SendInput 返回：预期=1 实际=" sent)
    if (sent != 1)
        throw Error("SendInput 发送失败，返回数量=" sent "，系统错误码=" lastError "。权限限制可能不会提供有效错误码。")
}

; 只释放本次回放仍按住的输入；单项失败不妨碍其他项清理。
; 不移动鼠标、不重试、不释放未被本次回放跟踪的键。
Rec_ReplayReleaseInputs()
{
    global Rec_ReplayDownKeys, Rec_ReplayMouseDowns
    static upFlags := Map("L", 0x0004, "R", 0x0010, "M", 0x0040)
    failures := ""

    for keyId, keyData in Rec_ReplayDownKeys
    {
        try
        {
            Log("Replay | 补发键盘释放")
            Rec_ReplaySendKeyboard(keyData[1], keyData[2], keyData[3], true)
            Log("Replay | 键盘释放成功")
        }
        catch Error as err
        {
            Log("Replay | 键盘释放失败：" err.Message)
            failures .= "键盘释放失败：" err.Message "`n"
        }
    }

    for button, unused in Rec_ReplayMouseDowns
    {
        try
        {
            Log("Replay | 补发鼠标释放：按钮=" button)
            Rec_ReplaySendMouse(upFlags[button])
            Log("Replay | 鼠标释放成功：按钮=" button)
        }
        catch Error as err
        {
            Log("Replay | 鼠标释放失败：按钮=" button " 原因=" err.Message)
            failures .= "鼠标按钮 " button " 释放失败：" err.Message "`n"
        }
    }

    Rec_ReplayDownKeys := Map()
    Rec_ReplayMouseDowns := Map()
    if (failures != "")
        failures .= "可能仍有按键或鼠标按钮未释放，请手动按下再松开。"
    return failures
}

; 校验并解析录制文件；失败时抛出异常，不修改文件或录制状态。
Rec_ValidateRecording(filePath)
{
    startedAt := A_TickCount
    Log("ValidateRecording | 开始校验：文件=" filePath)
    try
    {
        data := Rec_ParseRecordingFile(filePath)
        Log("ValidateRecording | 校验通过：文件=" filePath " 格式号=" data.Version " 显示器数=" data.Monitors.Length " 事件数=" data.Events.Length " 耗时ms=" (A_TickCount - startedAt))
        if (data.Events.Length = 0)
            Log("ValidateRecording | 文件格式合法，但没有可回放事件")
        return data
    }
    catch Error as err
    {
        Log("ValidateRecording | 校验失败：文件=" filePath " 耗时ms=" (A_TickCount - startedAt) " 原因=" err.Message)
        throw err
    }
}

Rec_ParseRecordingFile(filePath)
{
    Log("ValidateRecording | 读取文件：编码=UTF-8")
    try
        content := FileRead(filePath, "UTF-8")
    catch Error as err
        throw Error("无法读取录制文件：" filePath "`n" err.Message)

    Log("ValidateRecording | 读取完成：字符数=" StrLen(content))
    ; 接受文件末尾的换行；文件内部空行仍视为格式错误。
    originalLength := StrLen(content)
    content := RTrim(content, "`r`n")
    Log("ValidateRecording | 末尾换行处理：移除字符数=" (originalLength - StrLen(content)) " 剩余字符数=" StrLen(content))
    if (content = "")
        throw Error("录制文件为空：" filePath)

    data := {Version: 1, VirtualScreen: [], Monitors: [], Events: [], EventLines: []}
    lineCount := 0
    eventsStarted := false

    Log("ValidateRecording | 开始逐行解析")
    Loop Parse, content, "`n"
    {
        lineNumber := A_Index
        lineCount := lineNumber
        line := A_LoopField
        if (SubStr(line, -1) = "`r")
            line := SubStr(line, 1, StrLen(line) - 1)
        fields := StrSplit(line, "`t")

        Log("ValidateRecording | 第 " lineNumber " 行：字符数=" StrLen(line) " 字段数=" fields.Length)
        if (lineNumber = 1)
        {
            if (fields.Length != 2)
                Rec_RecordingFormatError(lineNumber, "文件头应为 WQLREC<TAB>1")
            if !(fields[1] == "WQLREC") || !(fields[2] == "1")
                Rec_RecordingFormatError(lineNumber, "文件标识或格式号不支持，应为 WQLREC<TAB>1")
            Log("ValidateRecording | 第 " lineNumber " 行：文件头通过，格式号=1")
            continue
        }

        if (lineNumber = 2)
        {
            if (fields.Length != 5)
                Rec_RecordingFormatError(lineNumber, "VSCREEN 应有 5 个字段")
            if !(fields[1] == "VSCREEN")
                Rec_RecordingFormatError(lineNumber, "文件头之后必须是 VSCREEN")
            Loop 4
                data.VirtualScreen.Push(Rec_ParseRecordingInteger(fields[A_Index + 1], lineNumber, "VSCREEN 数值"))
            Log("ValidateRecording | 第 " lineNumber " 行：VSCREEN 通过" " left=" data.VirtualScreen[1] " top=" data.VirtualScreen[2] " width=" data.VirtualScreen[3] " height=" data.VirtualScreen[4])
            continue
        }

        if (fields[1] == "MONITOR")
        {
            Log("ValidateRecording | 第 " lineNumber " 行：识别为 MONITOR")
            if eventsStarted
                Rec_RecordingFormatError(lineNumber, "MONITOR 必须位于所有 EVENT 之前")
            if (fields.Length != 6)
                Rec_RecordingFormatError(lineNumber, "MONITOR 应有 6 个字段")
            monitor := []
            Loop 5
                monitor.Push(Rec_ParseRecordingInteger(fields[A_Index + 1], lineNumber, "MONITOR 数值"))
            data.Monitors.Push(monitor)
            Log("ValidateRecording | 第 " lineNumber " 行：MONITOR 通过" " id=" monitor[1] " left=" monitor[2] " top=" monitor[3] " right=" monitor[4] " bottom=" monitor[5] " 累计显示器数=" data.Monitors.Length)
            continue
        }

        if !(fields[1] == "EVENT")
            Rec_RecordingFormatError(lineNumber, "应为 MONITOR 或 EVENT 记录")
        Log("ValidateRecording | 第 " lineNumber " 行：识别为 EVENT")
        if (data.Monitors.Length = 0)
            Rec_RecordingFormatError(lineNumber, "EVENT 之前缺少 MONITOR")
        if (fields.Length < 3)
            Rec_RecordingFormatError(lineNumber, "EVENT 缺少时间偏移或事件类型")

        if !eventsStarted
            Log("ValidateRecording | 第 " lineNumber " 行：进入事件区，已解析显示器数=" data.Monitors.Length)
        eventsStarted := true
        eventType := fields[3]
        if !(eventType == "KD" || eventType == "KU" || eventType == "MD" || eventType == "MU" || eventType == "W" || eventType == "HW")
            Rec_RecordingFormatError(lineNumber, "未知事件类型：" eventType)

        expectedFields := (eventType == "MU") ? 7 : 6
        Log("ValidateRecording | 第 " lineNumber " 行：事件类型=" eventType " 预期字段数=" expectedFields " 实际字段数=" fields.Length)
        if (fields.Length != expectedFields)
            Rec_RecordingFormatError(lineNumber, eventType " 应有 " expectedFields " 个字段")

        offsetUs := Rec_ParseRecordingInteger(fields[2], lineNumber, "时间偏移")
        event := [offsetUs, eventType]
        if (eventType == "KD" || eventType == "KU")
        {
            virtualKey := Rec_ParseRecordingInteger(fields[4], lineNumber, "虚拟键码")
            scanCode := Rec_ParseRecordingInteger(fields[5], lineNumber, "扫描码")
            if !(fields[6] == "0" || fields[6] == "1")
                Rec_RecordingFormatError(lineNumber, "键盘扩展标志必须为 0 或 1")
            Log("ValidateRecording | 第 " lineNumber " 行：键盘扩展标志通过")
            event.Push(virtualKey, scanCode, Integer(fields[6]))
        }
        else if (eventType == "MD" || eventType == "MU")
        {
            button := fields[4]
            if !(button == "L" || button == "R" || button == "M")
                Rec_RecordingFormatError(lineNumber, "鼠标按钮必须为 L、R 或 M")
            Log("ValidateRecording | 第 " lineNumber " 行：鼠标按钮枚举通过")
            x := Rec_ParseRecordingInteger(fields[5], lineNumber, "鼠标 X 坐标")
            y := Rec_ParseRecordingInteger(fields[6], lineNumber, "鼠标 Y 坐标")
            event.Push(button, x, y)
            if (eventType == "MU")
            {
                if !(fields[7] == "0" || fields[7] == "1")
                    Rec_RecordingFormatError(lineNumber, "拖拽标志必须为 0 或 1")
                Log("ValidateRecording | 第 " lineNumber " 行：拖拽标志通过")
                event.Push(Integer(fields[7]))
            }
        }
        else
        {
            delta := Rec_ParseRecordingInteger(fields[4], lineNumber, "滚轮增量")
            x := Rec_ParseRecordingInteger(fields[5], lineNumber, "滚轮 X 坐标")
            y := Rec_ParseRecordingInteger(fields[6], lineNumber, "滚轮 Y 坐标")
            event.Push(delta, x, y)
        }

        data.Events.Push(event)
        data.EventLines.Push(lineNumber)
        Log("ValidateRecording | 第 " lineNumber " 行：EVENT 通过" " 类型=" eventType " 时间偏移us=" offsetUs " 累计事件数=" data.Events.Length)
    }

    if (lineCount < 2)
        Rec_RecordingFormatError(2, "缺少 VSCREEN 记录")
    if (data.Monitors.Length = 0)
        Rec_RecordingFormatError(3, "缺少 MONITOR 记录")
    Log("ValidateRecording | 必要记录检查通过")
    return data
}

Rec_ParseRecordingInteger(value, lineNumber, fieldName)
{
    Log("ValidateRecording | 第 " lineNumber " 行：检查整数字段=" fieldName)
    if !RegExMatch(value, "^-?[0-9]+$")
        Rec_RecordingFormatError(lineNumber, fieldName " 必须为十进制整数")
    try
        parsed := Integer(value)
    catch Error
        Rec_RecordingFormatError(lineNumber, fieldName " 无法转换为整数")
    Log("ValidateRecording | 第 " lineNumber " 行：整数转换通过，字段=" fieldName)
    return parsed
}

Rec_RecordingFormatError(lineNumber, reason)
{
    Log("ValidateRecording | 格式检查失败：第 " lineNumber " 行，" reason)
    throw Error("录制文件格式错误：第 " lineNumber " 行，" reason)
}
