#Requires AutoHotkey v2.0
#SingleInstance Force
TraySetIcon(A_ScriptDir "\ico.ico")

; ============================================================
; My Launcher
;
; Ctrl + 1       显示 / 隐藏 Launcher
; 右键文件       添加到 My Launcher
; 点击项目       打开文件
; Esc            隐藏 Launcher
; ============================================================

global BgGui := ""         ; 背景层，全屏半透明，不销毁
global ContentGui := ""    ; 内容层，切换视图时销毁重建
global LauncherLV := ""
global CtxGui := ""
global Items := []
global ConfigFile := A_ScriptDir "\items.txt"
global CfgFile := A_ScriptDir "\config.txt"
global ViewMode := "list"  ; "list" | "settings"
global ScreenX := 0, ScreenY := 0, ScreenW := 0, ScreenH := 0

; 图标大小配置映射: 选项 -> [图标尺寸, 字体大小]
global SizeMap := Map("S", [64, 16], "M", [96, 20], "L", [128, 26])
global SizeLabels := ["S", "M", "L"]
global SizeDisplayNames := Map("S", "小", "M", "中", "L", "大")

; 对比测试用的全部尺寸
global TestSizes := [[32, 10], [48, 14], [64, 16], [96, 20], [128, 26], [256, 30]]

; ============================================================
; 快捷键
; ============================================================

global ScriptModTime := FileGetTime(A_ScriptFullPath, "M")

^1::ToggleLauncher()

#HotIf IsLauncherActive()
Escape::
{
    global ViewMode
    if (ViewMode = "settings")
    {
        ViewMode := "list"
        RebuildContent()
    }
    else
    {
        HideLauncher()
    }
}
#HotIf


; ============================================================
; 配置读写
; ============================================================

global CfgIconSize := "L"
global CfgOpacity := 230

LoadItems()
LoadConfig()

LoadConfig()
{
    global CfgFile, CfgIconSize, CfgOpacity, SizeMap
    if !FileExist(CfgFile)
    {
        Log("LoadConfig: file not found, using defaults IconSize=" CfgIconSize " Opacity=" CfgOpacity)
        return
    }
    content := FileRead(CfgFile, "UTF-8")
    Log("LoadConfig: raw content=[" content "]")
    Loop Parse, content, "`n", "`r"
    {
        line := Trim(A_LoopField)
        if line = ""
            continue
        parts := StrSplit(line, "=", , 2)
        if parts.Length < 2
            continue
        key := Trim(parts[1])
        val := Trim(parts[2])
        Log("LoadConfig: key=[" key "] val=[" val "]")
        if (key = "IconSize") and SizeMap.Has(val)
            CfgIconSize := val
        else if (key = "Opacity")
        {
            CfgOpacity := Integer(val)
            if (CfgOpacity < 100)
                CfgOpacity := 100
            if (CfgOpacity > 255)
                CfgOpacity := 255
        }
    }
    ; Log("LoadConfig: final IconSize=" CfgIconSize " Opacity=" CfgOpacity)
}

SaveConfig(iconSize, opacity)
{
    global CfgFile
    if FileExist(CfgFile)
        FileDelete(CfgFile)
    FileAppend("IconSize=" iconSize "`nOpacity=" opacity "`n", CfgFile, "UTF-8")
}

; ============================================================
; Toggle Launcher
; ============================================================

ToggleLauncher()
{
    global BgGui, ScriptModTime, ViewMode
    currentTime := FileGetTime(A_ScriptFullPath, "M")
    if (currentTime != ScriptModTime)
    {
        Reload()
        return
    }
    if IsObject(BgGui) and WinExist("ahk_id " BgGui.Hwnd)
    {
        HideLauncher()
        return
    }
    ViewMode := "list"
    ShowLauncher()
}

; ============================================================
; 创建并显示 Launcher
; ============================================================

ShowLauncher()
{
    global BgGui, ContentGui, Items, ViewMode
    global ScreenX, ScreenY, ScreenW, ScreenH, CfgOpacity

    ; 清理旧窗口
    DestroyContent()
    if IsObject(BgGui)
    {
        BgGui.Destroy()
        BgGui := ""
    }

    Items := []
    LoadItems()

    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    monIdx := GetMonitorAt(mx, my)
    MonitorGet(monIdx, &monL, &monT, &monR, &monB)
    ScreenX := monL
    ScreenY := monT
    ScreenW := monR - monL
    ScreenH := monB - monT
    Log("ShowLauncher: mouse=(" mx "," my ") monitor=" monIdx " area=(" ScreenX "," ScreenY "," ScreenW "x" ScreenH ")")

    ; 背景层：全屏深色半透明，始终存在
    ; -DPIScale: 禁用 AHK 自动 DPI 缩放，避免高 DPI 下窗口尺寸被放大导致溢出到其他显示器
    BgGui := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale", "My Launcher BG")
    BgGui.BackColor := "1A1A1A"
    BgGui.OnEvent("Close", HideLauncher)
    BgGui.Show("x" ScreenX " y" ScreenY " w" ScreenW " h" ScreenH)
    WinSetTransparent(CfgOpacity, "ahk_id " BgGui.Hwnd)

    ; 内容层
    BuildContent()
}

; ============================================================
; 构建内容层
; ============================================================

BuildContent()
{
    global BgGui, ContentGui, ViewMode
    global ScreenX, ScreenY, ScreenW, ScreenH

    ContentGui := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale +Owner" BgGui.Hwnd, "My Launcher Content")
    ContentGui.BackColor := "1A1A1A"

    if (ViewMode = "settings")
        CreateSettingsView()
    else
        CreateListView()

    ContentGui.Show("x" ScreenX " y" ScreenY " w" ScreenW " h" ScreenH)
    WinSetTransparent(CfgOpacity, "ahk_id " ContentGui.Hwnd)
}

; ============================================================
; 销毁内容层
; ============================================================

DestroyContent()
{
    global ContentGui
    if IsObject(ContentGui)
    {
        ContentGui.Destroy()
        ContentGui := ""
    }
}

; ============================================================
; 重建内容层 (切换视图，背景层不动)
; ============================================================

RebuildContent()
{
    DestroyContent()
    BuildContent()
}

; ============================================================
; 创建项目列表视图
; ============================================================

CreateListView()
{
    global ContentGui, LauncherLV, Items
    global ScreenW, ScreenH, CfgIconSize, SizeMap
    Log("LoadConfig: final IconSize=" CfgIconSize " Opacity=" CfgOpacity)

    sizes := SizeMap[CfgIconSize]
    iconPx := sizes[1]
    fontSize := sizes[2]

    ; 右上角齿轮按钮
    ContentGui.SetFont("s24 norm cAAAAAA", "Segoe MDL2 Assets")
    gearBtn := ContentGui.AddText("x" (ScreenW - 70) " y20 w50 h50 Center 0x200 BackgroundTrans", Chr(0xE713))
    gearBtn.OnEvent("Click", OnGearClick)

    ; 项目列表字体
    ContentGui.SetFont("s" fontSize " norm cWhite", "Segoe UI")

    lvW := 700
    lvH := ScreenH - 160
    lvX := (ScreenW - lvW) // 2
    lvY := 100

    ; 创建自定义尺寸的 ImageList (ILC_COLOR32=0x20, ILC_MASK=0x1)
    IL := DllCall("Comctl32\ImageList_Create", "Int", iconPx, "Int", iconPx, "UInt", 0x21, "Int", Items.Length, "Int", 1, "Ptr")
    for index, path in Items
    {
        hIcon := ExtractFileIcon(path, iconPx)
        if hIcon
        {
            DllCall("Comctl32\ImageList_ReplaceIcon", "Ptr", IL, "Int", -1, "Ptr", hIcon)
            DllCall("DestroyIcon", "Ptr", hIcon)
        }
        else
        {
            hFallback := DllCall("Shell32\ExtractIconW", "Ptr", 0, "Str", "shell32.dll", "Int", 2, "Ptr")
            if hFallback
            {
                DllCall("Comctl32\ImageList_ReplaceIcon", "Ptr", IL, "Int", -1, "Ptr", hFallback)
                DllCall("DestroyIcon", "Ptr", hFallback)
            }
        }
    }

    ; 创建 ListView (Icon 模式)
    LauncherLV := ContentGui.AddListView("x" lvX " y" lvY " w" lvW " h" lvH " Icon -E0x200", ["Name"])

    ; 设置 ImageList: LVSIL_NORMAL=0
    SendMessage(0x1003, 0, IL, LauncherLV)  ; LVM_SETIMAGELIST

    ; 设置图标间距: LVM_SETICONSPACING=0x1035
    spacingW := iconPx + 80
    spacingH := iconPx + 50
    SendMessage(0x1035, 0, (spacingH << 16) | spacingW, LauncherLV)

    ; ListView 深色主题
    SendMessage(0x1001, 0, 0x1A1A1A, LauncherLV)  ; LVM_SETBKCOLOR
    SendMessage(0x1026, 0, 0x1A1A1A, LauncherLV)  ; LVM_SETTEXTBKCOLOR
    SendMessage(0x1024, 0, 0xFFFFFF, LauncherLV)   ; LVM_SETTEXTCOLOR

    for index, path in Items
    {
        name := GetDisplayName(path)
        LauncherLV.Add("Icon" index, name)
    }

    LauncherLV.OnEvent("DoubleClick", OnListViewDoubleClick)
    LauncherLV.OnEvent("ContextMenu", OnListViewRightClick)
}

; ============================================================
; 创建设置视图
; ============================================================

CreateSettingsView()
{
    global ContentGui, ScreenW, ScreenH, CfgIconSize, CfgOpacity

    panelW := 400
    panelX := (ScreenW - panelW) // 2
    panelY := ScreenH // 2 - 150

    ; 右上角返回按钮
    ContentGui.SetFont("s24 norm cAAAAAA", "Segoe MDL2 Assets")
    backBtn := ContentGui.AddText("x" (ScreenW - 70) " y20 w50 h50 Center 0x200 BackgroundTrans", Chr(0xE72B))
    backBtn.OnEvent("Click", OnBackClick)

    ; 标题
    ContentGui.SetFont("s20 bold cWhite", "Segoe UI")
    ContentGui.AddText("x" panelX " y" panelY " w" panelW " h40 Center", "设置")

    ; 图标大小
    ContentGui.SetFont("s14 norm cWhite", "Segoe UI")
    ContentGui.AddText("x" panelX " y" (panelY + 70) " w120 h36 0x200", "图标大小")
    ContentGui.SetFont("s14 norm c000000", "Segoe UI")
    global ddlSize := ContentGui.AddDropDownList("x" (panelX + 140) " y" (panelY + 70) " w200 h400 Choose" GetSizeIndex(CfgIconSize), ["小", "中", "大"])

    ; 透明度
    ContentGui.SetFont("s14 norm cWhite", "Segoe UI")
    ContentGui.AddText("x" panelX " y" (panelY + 130) " w120 h36 0x200", "透明度")
    global sliderOpacity := ContentGui.AddSlider("x" (panelX + 140) " y" (panelY + 130) " w180 h36 Range100-255 ToolTip", CfgOpacity)
    global lblOpacity := ContentGui.AddText("x" (panelX + 330) " y" (panelY + 130) " w60 h36 0x200", CfgOpacity)
    sliderOpacity.OnEvent("Change", OnOpacityChange)

    ; 保存按钮
    ContentGui.SetFont("s14 norm", "Segoe UI")
    saveBtn := ContentGui.AddButton("x" (panelX + 130) " y" (panelY + 210) " w140 h42", "保存")
    saveBtn.OnEvent("Click", OnSaveClick)
}

GetSizeIndex(name)
{
    if (name = "S")
        return 1
    if (name = "L")
        return 3
    return 2
}

; ============================================================
; 设置页事件
; ============================================================

OnGearClick(*)
{
    global ViewMode
    Log("OnGearClick: switching to settings")
    ViewMode := "settings"
    RebuildContent()
}

OnBackClick(*)
{
    global ViewMode
    Log("OnBackClick: switching to list")
    ViewMode := "list"
    RebuildContent()
}

OnOpacityChange(ctrl, *)
{
    global lblOpacity
    Log("OnOpacityChange: " ctrl.Value)
    lblOpacity.Value := ctrl.Value
}

OnSaveClick(*)
{
    global ddlSize, sliderOpacity, CfgIconSize, CfgOpacity, ViewMode, BgGui
    CfgIconSize := SizeLabels[ddlSize.Value]
    CfgOpacity := sliderOpacity.Value
    Log("OnSaveClick: iconSize=" CfgIconSize " opacity=" CfgOpacity)
    SaveConfig(CfgIconSize, CfgOpacity)
    ; 更新背景层透明度
    WinSetTransparent(CfgOpacity, "ahk_id " BgGui.Hwnd)
    ; 返回主页
    ViewMode := "list"
    RebuildContent()
}

; ============================================================
; 从文件提取图标 (指定尺寸)
; ============================================================

ExtractFileIcon(path, size := 32)
{
    ; SHGFI_ICON=0x100, SHGFI_LARGEICON=0x0, SHGFI_SMALLICON=0x1
    flags := 0x100
    if (size <= 16)
        flags |= 0x1

    cbFileInfo := A_PtrSize + 4 + 4 + 520 + 160
    fileInfo := Buffer(cbFileInfo, 0)
    result := DllCall("Shell32\SHGetFileInfoW", "Str", path, "UInt", 0, "Ptr", fileInfo, "UInt", cbFileInfo, "UInt", flags, "Ptr")
    if !result
        return 0

    hIconSmall := NumGet(fileInfo, 0, "Ptr")

    ; 如果需要更大的图标，用 SHGetImageList
    if (size > 32)
    {
        ; SHIL_EXTRALARGE=2 (48x48), SHIL_JUMBO=4 (256x256)
        shil := (size > 48) ? 4 : 2
        IID_IImageList := Buffer(16)
        NumPut("UInt", 0x46EB5926, IID_IImageList, 0)
        NumPut("UShort", 0x582E, IID_IImageList, 4)
        NumPut("UShort", 0x4017, IID_IImageList, 6)
        NumPut("UChar", 0x9F, IID_IImageList, 8)
        NumPut("UChar", 0xBF, IID_IImageList, 9)
        NumPut("UChar", 0x16, IID_IImageList, 10)
        NumPut("UChar", 0xD6, IID_IImageList, 11)
        NumPut("UChar", 0xE2, IID_IImageList, 12)
        NumPut("UChar", 0xF2, IID_IImageList, 13)
        NumPut("UChar", 0x14, IID_IImageList, 14)
        NumPut("UChar", 0x97, IID_IImageList, 15)

        pImageList := 0
        hr := DllCall("Shell32\SHGetImageList", "Int", shil, "Ptr", IID_IImageList, "PtrP", &pImageList, "Int")
        if (hr = 0 and pImageList)
        {
            fileInfo2 := Buffer(cbFileInfo, 0)
            DllCall("Shell32\SHGetFileInfoW", "Str", path, "UInt", 0, "Ptr", fileInfo2, "UInt", cbFileInfo, "UInt", 0x4000, "Ptr")  ; SHGFI_SYSICONINDEX
            iconIndex := NumGet(fileInfo2, A_PtrSize, "Int")

            ; IImageList::GetIcon (vtable index 10)
            hIconLarge := 0
            vTable := NumGet(pImageList + 0, 0, "Ptr")
            getIconFn := NumGet(vTable + 0, 10 * A_PtrSize, "Ptr")
            DllCall(getIconFn, "Ptr", pImageList, "Int", iconIndex, "UInt", 0x1, "PtrP", &hIconLarge)

            ; Release
            releaseFn := NumGet(vTable + 0, 2 * A_PtrSize, "Ptr")
            DllCall(releaseFn, "Ptr", pImageList)

            if hIconLarge
            {
                DllCall("DestroyIcon", "Ptr", hIconSmall)
                return hIconLarge
            }
        }
    }

    return hIconSmall
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
; 右键菜单
; ============================================================

OnListViewRightClick(LV, rowNumber, isRightClick, x, y)
{
    if rowNumber < 1
        return
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    ShowContextMenu(mx, my, rowNumber)
}

; ============================================================
; 自定义右键菜单 (GUI 模拟)
; ============================================================

ShowContextMenu(x, y, rowIndex)
{
    global CtxGui, BgGui, CfgIconSize, SizeMap
    CloseContextMenu()

    sizes := SizeMap[CfgIconSize]
    fontSize := sizes[2]
    menuW := fontSize * 12
    itemH := fontSize * 3
    sepH := 1
    menuItems := ["打开所在文件夹", "复制路径", "-", "删除"]

    menuH := 0
    for i, item in menuItems
        menuH += (item = "-") ? sepH : itemH

    monIdx := GetMonitorAt(x, y)
    MonitorGet(monIdx, &monL, &monT, &monR, &monB)
    if (x + menuW > monR)
        x := monR - menuW
    if (y + menuH > monB)
        y := monB - menuH

    CtxGui := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale +Owner" BgGui.Hwnd, "CtxMenu")
    CtxGui.BackColor := "2D2D2D"
    CtxGui.MarginX := 0
    CtxGui.MarginY := 0

    curY := 0
    for i, item in menuItems
    {
        if (item = "-")
        {
            CtxGui.AddProgress("x0 y" curY " w" menuW " h" sepH " Background444444 -E0x200", 0)
            curY += sepH
            continue
        }

        CtxGui.SetFont("s" fontSize " cWhite", "Segoe UI")
        btn := CtxGui.AddText("x0 y" curY " w" menuW " h" itemH " Center 0x200 BackgroundTrans", item)
        btn.OnEvent("Click", CtxMenuAction.Bind(item, rowIndex))
        curY += itemH
    }

    CtxGui.Show("x" x " y" y " w" menuW " h" menuH " NoActivate")
    SetTimer(CheckCtxFocus, 100)
}

; ============================================================
; 菜单项点击处理
; ============================================================

CtxMenuAction(action, rowIndex, *)
{
    global Items
    CloseContextMenu()
    if rowIndex > Items.Length
        return
    path := Items[rowIndex]

    if (action = "打开所在文件夹")
        Run('explorer /select,"' path '"')
    else if (action = "复制路径")
        A_Clipboard := path
    else if (action = "删除")
        DeleteItem(rowIndex)
}

; ============================================================
; 检测菜单外点击并关闭
; ============================================================

CheckCtxFocus()
{
    global CtxGui
    if !IsObject(CtxGui)
    {
        SetTimer(CheckCtxFocus, 0)
        return
    }
    if !WinExist("ahk_id " CtxGui.Hwnd)
    {
        CloseContextMenu()
        return
    }
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " CtxGui.Hwnd)
    if GetKeyState("LButton", "P")
    {
        if (mx < wx or mx > wx + ww or my < wy or my > wy + wh)
            CloseContextMenu()
    }
}

; ============================================================
; 关闭右键菜单
; ============================================================

CloseContextMenu()
{
    global CtxGui
    SetTimer(CheckCtxFocus, 0)
    if IsObject(CtxGui)
    {
        CtxGui.Destroy()
        CtxGui := ""
    }
}

; ============================================================
; 删除项目
; ============================================================

DeleteItem(index)
{
    global Items, ConfigFile, ViewMode
    if index > Items.Length
        return
    Items.RemoveAt(index)
    content := ""
    for i, path in Items
        content .= path "`n"
    FileDelete(ConfigFile)
    if content != ""
        FileAppend(content, ConfigFile, "UTF-8")
    ; 重建内容层刷新列表
    Items := []
    LoadItems()
    ViewMode := "list"
    RebuildContent()
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
        MsgBox("文件不存在：`n`n" path, "My Launcher", "Icon!")
        return
    }
    Run(path)
    HideLauncher()
}

; ============================================================
; 隐藏 Launcher
; ============================================================

HideLauncher(*)
{
    global BgGui
    DestroyContent()
    if IsObject(BgGui)
    {
        BgGui.Destroy()
        BgGui := ""
    }
}

; ============================================================
; 判断 Launcher 是否处于激活状态
; ============================================================

IsLauncherActive()
{
    global BgGui
    if !IsObject(BgGui)
        return false
    return WinActive("ahk_id " BgGui.Hwnd) or WinActive("My Launcher Content")
}

; ============================================================
; 读取配置
; ============================================================

LoadItems()
{
    global Items, ConfigFile
    if !FileExist(ConfigFile)
        return
    content := FileRead(ConfigFile, "UTF-8")
    Loop Parse, content, "`n", "`r"
    {
        path := Trim(A_LoopField)
        if path = ""
            continue
        if FileExist(path)
            Items.Push(path)
    }
}

; ============================================================
; 获取显示名称 (C:\Tools\abc.exe -> abc.exe)
; ============================================================

GetDisplayName(path)
{
    SplitPath(path, &name)
    return name
}

; ============================================================
; 获取坐标所在的显示器索引
; ============================================================

GetMonitorAt(x, y)
{
    count := MonitorGetCount()
    Log("GetMonitorAt: (" x "," y ") monitorCount=" count)
    Loop count
    {
        MonitorGet(A_Index, &l, &t, &r, &b)
        Log("  monitor " A_Index ": (" l "," t "," r "," b ")")
        if (x >= l and x < r and y >= t and y < b)
            return A_Index
    }
    return MonitorGetPrimary()
}

; ============================================================
; 日志
; ============================================================

Log(msg)
{
    FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " | " msg "`n", A_ScriptDir "\launcher.log")
}
