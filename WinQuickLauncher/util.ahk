#Requires AutoHotkey v2.0

global debug := true

; 录制/回放期间共用的日志句柄。为 0 时 Log 逐条 FileAppend。
global LogSessionFile := 0

Log(message)
{
    global debug, LogSessionFile
    if !debug
        return
    message := StrReplace(StrReplace(message, "`r", "\r"), "`n", "\n")
    line := FormatTime(, "yyyy-MM-dd HH:mm:ss") " | " message "`n"
    if (LogSessionFile != 0)
        LogSessionFile.Write(line)
    else
        try FileAppend(line, A_ScriptDir "\launcher.log", "UTF-8")
}

; 打开日志会话：一场录制或一次回放内的全部日志共用同一个句柄。
LogSessionOpen()
{
    global debug, LogSessionFile
    if !debug || (LogSessionFile != 0)
        return
    LogSessionFile := FileOpen(A_ScriptDir "\launcher.log", "a", "UTF-8")
}

LogSessionClose()
{
    global LogSessionFile
    if (LogSessionFile = 0)
        return
    LogSessionFile.Close()
    LogSessionFile := 0
}
