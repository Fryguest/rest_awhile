#Requires AutoHotkey v2.0

; ============================================================
; My Launcher - Add Item
;
; 由右键菜单调用：
;   AutoHotkey.exe add.ahk "C:\xxx\test.exe"
; ============================================================

ConfigFile := A_ScriptDir "\items.txt"

if A_Args.Length < 1
    ExitApp

path := Trim(A_Args[1])

if path = ""
    ExitApp

if !FileExist(path)
    ExitApp

; 检查是否已存在
if FileExist(ConfigFile)
{
    content := FileRead(ConfigFile, "UTF-8")

    Loop Parse, content, "`n", "`r"
    {
        if StrCompare(Trim(A_LoopField), path, false) = 0
            ExitApp
    }
}

; 追加到配置文件
FileAppend(path "`n", ConfigFile, "UTF-8")

ExitApp
