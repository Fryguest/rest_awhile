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
global LauncherLV := ""
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

    ; 项目列表
    LauncherGui.SetFont(
        "s10 norm",
        "Segoe UI"
    )

    CreateListView()

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
; 创建项目列表
; ============================================================

CreateListView()
{
    global LauncherGui, LauncherLV, Items

    ; 创建 ImageList (大图标 32x32)
    IL := IL_Create(Items.Length, 1, true)

    for index, path in Items
    {
        hIcon := ExtractFileIcon(path)

        if hIcon
        {
            IL_Add(IL, "HICON:" hIcon)
            DllCall("DestroyIcon", "Ptr", hIcon)
        }
        else
        {
            IL_Add(IL, "shell32.dll", 3)
        }
    }

    ; 创建 ListView (Icon 模式，自带滚动条)
    LauncherLV := LauncherGui.AddListView(
        "x20 y55 w660 h420 Icon",
        ["Name"]
    )

    LauncherLV.SetImageList(IL)

    for index, path in Items
    {
        name := GetDisplayName(path)
        LauncherLV.Add("Icon" index, name)
    }

    LauncherLV.OnEvent(
        "DoubleClick",
        OnListViewDoubleClick
    )
}


; ============================================================
; 从文件提取图标
; ============================================================

ExtractFileIcon(path)
{
    ; SHGFI_ICON (0x100) | SHGFI_LARGEICON (0x0)
    cbFileInfo := A_PtrSize + 4 + 4 + 520 + 160
    fileInfo := Buffer(cbFileInfo, 0)

    result := DllCall(
        "Shell32\SHGetFileInfoW",
        "Str", path,
        "UInt", 0,
        "Ptr", fileInfo,
        "UInt", cbFileInfo,
        "UInt", 0x100,
        "Ptr"
    )

    if result
        return NumGet(fileInfo, 0, "Ptr")

    return 0
}


; ============================================================
; 双击列表项打开文件
; ============================================================

OnListViewDoubleClick(LV, rowNumber)
{
    if rowNumber < 1
        return

    LaunchItem(rowNumber)
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