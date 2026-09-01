#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; My Launcher - Setup
;
; 功能：
;   Install   安装右键菜单
;   Uninstall 卸载右键菜单
; ============================================================

AppName := "My Launcher"
LauncherScript := A_ScriptDir "\add.ahk"
RegistryMenuKey := "HKEY_CURRENT_USER\Software\Classes\*\shell\MyLauncher"
RegistryCommandKey := RegistryMenuKey "\command"

; ============================================================
; 检查 Launcher 是否存在
; ============================================================

if !FileExist(LauncherScript)
{
    MsgBox(
        "找不到 add.ahk：`n`n"
        LauncherScript
        "`n`n请确保 Setup.ahk 和 add.ahk 位于同一个目录。",
        AppName, "Iconx"
    )
    ExitApp
}

; ============================================================
; GUI
; ============================================================

myGui := Gui("", AppName " Setup")
myGui.SetFont("s10", "Segoe UI")
myGui.AddText("x20 y20 w360 h30", AppName)
myGui.AddText("x20 y55 w360 h40", "配置 Windows 文件右键菜单")

installButton := myGui.AddButton("x20 y110 w170 h40", "安装右键菜单")
uninstallButton := myGui.AddButton("x210 y110 w170 h40", "卸载右键菜单")

installButton.OnEvent("Click", InstallContextMenu)
uninstallButton.OnEvent("Click", UninstallContextMenu)
myGui.OnEvent("Close", (*) => ExitApp())
myGui.Show("w400 h180")

; ============================================================
; Install
; ============================================================

InstallContextMenu(*)
{
    global AppName, LauncherScript, RegistryMenuKey, RegistryCommandKey

    ; 创建菜单项
    RegWrite("添加到 " AppName, "REG_SZ", RegistryMenuKey, "MUIVerb")

    ; 设置图标
    RegWrite(A_ScriptDir "\ico.ico", "REG_SZ", RegistryMenuKey, "Icon")

    ; 设置执行命令（Windows 会把被右键的文件路径放在 %1）
    command := Format('"{}" "{}" "%1"', A_AhkPath, LauncherScript)
    RegWrite(command, "REG_SZ", RegistryCommandKey)

    MsgBox(
        "右键菜单安装成功！`n`n"
        "现在右键任意文件，应该可以看到：`n"
        "「添加到 " AppName "」",
        AppName, "Iconi"
    )
}

; ============================================================
; Uninstall
; ============================================================

UninstallContextMenu(*)
{
    global AppName, RegistryMenuKey

    if DeleteRegistryTree(RegistryMenuKey)
        MsgBox("右键菜单已经卸载。", AppName, "Iconi")
    else
        MsgBox("右键菜单不存在，或者删除失败。", AppName, "Icon!")
}

DeleteRegistryTree(key)
{
    try
    {
        RegDeleteKey(key)
        return true
    }
    catch
        return false
}
