#Requires AutoHotkey v2.0

global debug := true

Log(message)
{
    global debug
    if !debug
        return
    message := StrReplace(StrReplace(message, "`r", "\r"), "`n", "\n")
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " | " message "`n", A_ScriptDir "\launcher.log", "UTF-8")
}
