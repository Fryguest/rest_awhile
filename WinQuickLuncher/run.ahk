#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; My Launcher
;
; Ctrl + 1       显示 / 隐藏 Launcher
; 右键文件       添加到 My Launcher
; 点击项目       打开文件
; Esc            隐藏 Launcher
; ============================================================

global LauncherGui := ""
global Items := []
global ConfigFile := A_ScriptDir "\items.txt"


; ============================================================
; 启动
; ============================================================

LoadItems()
RegisterContextMenu()


; ============================================================
; 处理右键菜单传入的文件
;
; 如果脚本是通过右键菜单启动的：
;
; MyLauncher.ahk "C:\xxx\test.exe"
;
; 那么 A_Args[1] 就是文件路径
; ============================================================

if A_Args.Length > 0
{
    path := A_Args[1]

    if FileExist(path)
    {
        AddItem(path)
    }

    ExitApp
}


; ============================================================
; Ctrl + 1
; ============================================================

^1::
{
    ToggleLauncher()
}


; ============================================================
; Esc
; ============================================================

#HotIf IsLauncherActive()

Escape::
{
    HideLauncher()
}

#HotIf


; ============================================================
; Toggle Launcher
; ============================================================

ToggleLauncher()
{
    global LauncherGui

    if IsObject(LauncherGui)
    {
        if WinActive("ahk_id " LauncherGui.Hwnd)
        {
            HideLauncher()
            return
        }

        LauncherGui.Show()
        return
    }

    ShowLauncher()
}


; ============================================================
; 创建并显示 Launcher
; ============================================================

ShowLauncher()
{
    global LauncherGui

    LauncherGui := Gui(
        "-Caption +AlwaysOnTop +Border",
        "My Launcher"
    )

    LauncherGui.BackColor := "F5F5F5"

    ; 标题
    LauncherGui.SetFont(
        "s12 bold",
        "Segoe UI"
    )

    LauncherGui.AddText(
        "x20 y15 w660 h30",
        "My Launcher"
    )

    ; 项目按钮
    CreateButtons()

    ; 关闭窗口
    LauncherGui.OnEvent(
        "Close",
        HideLauncher
    )

    ; 显示
    LauncherGui.Show(
        "w700 h500 Center"
    )
}


; ============================================================
; 创建项目按钮
; ============================================================

CreateButtons()
{
    global LauncherGui, Items

    x := 20
    y := 60

    buttonWidth := 210
    buttonHeight := 50
    gap := 10

    for index, path in Items
    {
        name := GetDisplayName(path)

        button := LauncherGui.AddButton(
            Format(
                "x{} y{} w{} h{}",
                x,
                y,
                buttonWidth,
                buttonHeight
            ),
            name
        )

        ; Bind 当前项目的 index
        button.OnEvent(
            "Click",
            LaunchItem.Bind(index)
        )

        x += buttonWidth + gap

        ; 每 3 个换一行
        if Mod(index, 3) = 0
        {
            x := 20
            y += buttonHeight + gap
        }
    }
}


; ============================================================
; 打开项目
; ============================================================

LaunchItem(index, *)
{
    global Items

    if index > Items.Length
        return

    path := Items[index]

    if !FileExist(path)
    {
        MsgBox(
            "文件不存在：`n`n" path,
            "My Launcher",
            "Icon!"
        )

        return
    }

    ; 使用 Windows 默认方式打开
    Run(path)

    HideLauncher()
}


; ============================================================
; 隐藏 Launcher
; ============================================================

HideLauncher(*)
{
    global LauncherGui

    if IsObject(LauncherGui)
    {
        LauncherGui.Hide()
    }
}


; ============================================================
; 判断 Launcher 是否处于激活状态
; ============================================================

IsLauncherActive()
{
    global LauncherGui

    if !IsObject(LauncherGui)
        return false

    return WinActive(
        "ahk_id " LauncherGui.Hwnd
    )
}


; ============================================================
; 注册 Windows 右键菜单
;
; 使用：
;
; HKEY_CURRENT_USER\Software\Classes
;
; 所以不需要管理员权限。
;
; 最终效果：
;
; 右键文件
;     ↓
; 添加到 My Launcher
; ============================================================

RegisterContextMenu()
{
    menuKey :=
        "HKEY_CURRENT_USER\Software\Classes\*\shell\MyLauncher"

    commandKey :=
        menuKey "\command"


    ; 菜单文字
    RegWrite(
        "添加到 My Launcher",
        "REG_SZ",
        menuKey
    )


    ; 菜单图标
    RegWrite(
        A_AhkPath,
        "REG_SZ",
        menuKey,
        "Icon"
    )


    ; 执行命令
    ;
    ; A_AhkPath      = AutoHotkey.exe
    ; A_ScriptFullPath = 当前脚本
    ; %1             = Windows 传入的文件路径
    ;
    command := Format('"{}" "{}" "%1"', A_AhkPath, A_ScriptFullPath)

    RegWrite(
        command,
        "REG_SZ",
        commandKey
    )
}


; ============================================================
; 添加项目
; ============================================================

AddItem(path)
{
    global Items, ConfigFile

    path := Trim(path)

    if path = ""
        return


    ; 避免重复添加
    for existingPath in Items
    {
        if StrCompare(
            existingPath,
            path,
            true
        ) = 0
        {
            return
        }
    }


    ; 添加到内存
    Items.Push(path)


    ; 写入配置文件
    FileAppend(
        path "`n",
        ConfigFile,
        "UTF-8"
    )
}


; ============================================================
; 读取配置
; ============================================================

LoadItems()
{
    global Items, ConfigFile

    if !FileExist(ConfigFile)
        return

    content := FileRead(
        ConfigFile,
        "UTF-8"
    )

    Loop Parse, content, "`n", "`r"
    {
        path := Trim(A_LoopField)

        if path = ""
            continue

        ; 只加载仍然存在的文件
        if FileExist(path)
        {
            Items.Push(path)
        }
    }
}


; ============================================================
; 获取显示名称
;
; C:\Tools\abc.exe
;       ↓
; abc.exe
; ============================================================

GetDisplayName(path)
{
    SplitPath(
        path,
        &name
    )

    return name
}