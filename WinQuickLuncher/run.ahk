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

; 右键菜单的安装/卸载统一由 setup.ahk 管理。
; 这里不要自动写注册表，否则卸载后只要运行一次 run.ahk 又会被重新装回去。


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
        and WinExist("ahk_id " LauncherGui.Hwnd)
    {
        HideLauncher()
        return
    }

    ShowLauncher()
}


; ============================================================
; 创建并显示 Launcher
; ============================================================

ShowLauncher()
{
    global LauncherGui, Items

    if IsObject(LauncherGui)
    {
        LauncherGui.Destroy()
        LauncherGui := ""
    }

    Items := []
    LoadItems()

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