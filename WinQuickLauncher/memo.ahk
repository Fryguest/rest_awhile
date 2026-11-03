#Requires AutoHotkey v2.0
#Include memo-core.ahk

; 只在原启动列表左侧的空白区域增加控件，不调整原窗口或启动图标。
global Memo_File := A_ScriptDir "\memo-data.tsv"
global Memo_JournalFile := A_ScriptDir "\logs\memo-journal.log"
global Memo_JournalCount := 0
global Memo_Tasks := []
global Memo_LoadError := "", Memo_SaveError := "", Memo_Busy := false
global Memo_PanelGui := "", Memo_DialogGui := ""
global Memo_Editor := "", Memo_Ctrl := {}
global Memo_Rendering := false
global Memo_PendingCheck := ""
global Memo_Page := 1
global Memo_GroupStates := Map(1, "all", 7, "all", 0, "all")
; 固定布局，基准为 3840×2160、Windows 缩放 150%。
global Memo_Layout := {X: 30, Y: 100, Width: 720, Height: 2000, CardTop: 0, PageSize: 13, GroupTitleHeight: 60, GroupTitleGap: 12, AddSize: 60, DialogCenterX: 1920, DialogCenterY: 1080}
global Memo_CardStyle := {OpenColor: "FFFF99", DoneColor: "B5E61D", TextColor: "000000", Height: 90, Gap: 36, Radius: 36, Padding: 36, FontSize: 16}

Memo_Init()
{
    global Memo_Tasks, Memo_LoadError, Memo_File
    global Memo_JournalFile, Memo_JournalCount
    try Memo_Tasks := MemoCore_Load(Memo_File)
    catch Error as err
    {
        Memo_LoadError := err.Message
        Log("Memo | 读取失败，原文件已保留：" err.Message)
    }
    try Memo_JournalCount := MemoCore_JournalCount(Memo_JournalFile)
    Memo_RefreshNow()
}

Memo_RefreshNow()
{
    global Memo_Tasks, Memo_File, Memo_Busy, Memo_LoadError, Memo_SaveError
    if (Memo_Busy || Memo_LoadError != "")
        return false
    Memo_Busy := true
    changed := false, oldError := Memo_SaveError
    try
    {
        candidate := MemoCore_CopyTasks(Memo_Tasks)
        changed := MemoCore_RefreshAll(candidate, A_Now)
        if changed
        {
            MemoCore_Save(Memo_File, candidate)
            Memo_Tasks := candidate
        }
        Memo_SaveError := ""
    }
    catch Error as err
    {
        changed := false
        Memo_SaveError := err.Message
    }
    finally Memo_Busy := false
    if (changed || oldError != Memo_SaveError)
        Memo_UpdateView()
    return changed
}

; 保存成功后才发布内存快照；周期检查与修改在同一笔事务中完成。
Memo_Transact(change, action := "")
{
    global Memo_Tasks, Memo_File, Memo_Busy, Memo_LoadError, Memo_SaveError
    global Memo_JournalFile, Memo_JournalCount
    if (Memo_LoadError != "")
    {
        Memo_Message(Memo_File "`n`n" Memo_LoadError "`n`n原数据未覆盖。请检查数据文件或访问权限后重新启动。")
        return false
    }
    if Memo_Busy
        return false
    Memo_Busy := true, success := false
    try
    {
        now := A_Now
        candidate := MemoCore_CopyTasks(Memo_Tasks)
        MemoCore_RefreshAll(candidate, now)
        id := change.Call(candidate, now)
        MemoCore_Save(Memo_File, candidate)
        if (action != "")
            try Memo_JournalCount := MemoCore_AppendJournal(Memo_JournalFile, Memo_JournalCount, candidate, id, action)
        Memo_Tasks := candidate
        Memo_SaveError := ""
        success := true
    }
    catch Error as err
        Memo_Message("本次修改没有保存。`n`n" err.Message)
    finally Memo_Busy := false
    if success
    {
        Memo_UpdateView()
    }
    return success
}

Memo_Build(host)
{
    global Memo_PanelGui, Memo_Ctrl, Memo_Layout
    Memo_DestroyView()
    layout := Memo_Layout
    w := layout.Width, h := layout.Height
    Memo_PanelGui := Gui("-Caption -DPIScale +Parent" host.Hwnd)
    g := Memo_PanelGui
    g.BackColor := "1A1A1A"
    g.MarginX := 0, g.MarginY := 0

    Memo_Ctrl.Cards := [], Memo_Ctrl.GroupHeaders := []
    Memo_Ctrl.Previous := Memo_Button(g, 0, h - 42, 96, 42, "上一页", Memo_ChangePage.Bind(-1))
    Memo_Ctrl.PageLabel := Memo_Label(g, 108, h - 36, w - 216, 33, "")
    Memo_Ctrl.Next := Memo_Button(g, w - 96, h - 42, 96, 42, "下一页", Memo_ChangePage.Bind(1))
    Memo_UpdateView()
    g.Show("NA x" layout.X " y" layout.Y " w" w " h" h)
}

Memo_DestroyView()
{
    global Memo_PanelGui, Memo_Ctrl, Memo_PendingCheck, Memo_Rendering
    Memo_DestroyDialog(false)
    SetTimer(Memo_ApplyQueuedCheck, 0)
    SetTimer(Memo_UpdateView, 0)
    Memo_PendingCheck := "", Memo_Rendering := true
    try
    {
        Memo_DestroyCards()
        if IsObject(Memo_PanelGui)
            Memo_PanelGui.Destroy()
    }
    finally
    {
        Memo_PanelGui := "", Memo_Ctrl := {}
        Memo_Rendering := false
    }
}

Memo_UpdateView()
{
    global Memo_PanelGui, Memo_Tasks, Memo_Ctrl
    global Memo_Rendering, Memo_Page, Memo_CardStyle, Memo_Layout
    global Memo_GroupStates, Memo_LoadError
    if (!IsObject(Memo_PanelGui) || Memo_Rendering || !Memo_Ctrl.HasOwnProp("Cards"))
        return
    ordered := []
    for task in MemoCore_OrderTasks(Memo_Tasks)
    {
        state := Memo_GroupStates[task.IntervalDays]
        if (state = "hidden" || (state = "open" && task.Done))
            continue
        ordered.Push(task)
    }
    style := Memo_CardStyle
    pageSize := Memo_Layout.PageSize
    pageCount := Max(1, Ceil(ordered.Length / pageSize))
    Memo_Page := Min(Max(1, Memo_Page), pageCount)
    Memo_Rendering := true
    try
    {
        Memo_DestroyCards()
        start := (Memo_Page - 1) * pageSize + 1
        count := Min(pageSize, ordered.Length - start + 1)
        groupNames := Map(1, "每天", 7, "每周", 0, "单次")
        y := Memo_Layout.CardTop
        for group in [1, 7, 0]
        {
            header := Gui("-Caption -DPIScale +Parent" Memo_PanelGui.Hwnd)
            Memo_Ctrl.GroupHeaders.Push(header)
            header.BackColor := Memo_PanelGui.BackColor
            header.MarginX := 0, header.MarginY := 0
            iconSize := Memo_Layout.AddSize
            iconX := Memo_Layout.Width - style.Padding - iconSize
            addX := style.Padding
            titleX := addX + iconSize + 12
            Memo_Font(header, 14, "AAAAAA")
            header.AddText(Memo_Pos(titleX, 0, iconX - titleX - 12, Memo_Layout.GroupTitleHeight) " BackgroundTrans +0x200", groupNames[group])
            addButton := header.AddPicture(Memo_Pos(addX, 0, iconSize, iconSize), A_ScriptDir "\ico\add-icon-ring.ico")
            addButton.Enabled := Memo_LoadError = ""
            period := group = 1 ? 2 : group = 7 ? 3 : 1
            addButton.OnEvent("Click", Memo_OpenEditor.Bind("", period))
            icon := A_ScriptDir "\ico\memo-group-list-" Memo_GroupStates[group] ".ico"
            button := header.AddPicture(Memo_Pos(iconX, 0, iconSize, iconSize), icon)
            button.OnEvent("Click", Memo_CycleGroupState.Bind(group))
            header.Show("NA x0 y" y " w" Memo_Layout.Width " h" Memo_Layout.GroupTitleHeight)
            y += Memo_Layout.GroupTitleHeight + Memo_Layout.GroupTitleGap
            Loop count
            {
                task := ordered[start + A_Index - 1]
                if (task.IntervalDays != group)
                    continue
                Memo_CreateCard(task, y)
                y += style.Height + style.Gap
            }
        }
        multiple := pageCount > 1
        Memo_Ctrl.Previous.Visible := multiple
        Memo_Ctrl.PageLabel.Visible := multiple
        Memo_Ctrl.Next.Visible := multiple
        Memo_Ctrl.Previous.Enabled := Memo_Page > 1
        Memo_Ctrl.Next.Enabled := Memo_Page < pageCount
        Memo_Ctrl.PageLabel.Text := Memo_Page " / " pageCount
    }
    finally
        Memo_Rendering := false
}

Memo_CycleGroupState(group, *)
{
    global Memo_GroupStates, Memo_Page, Memo_Rendering
    if Memo_Rendering
        return
    state := Memo_GroupStates[group]
    Memo_GroupStates[group] := state = "all" ? "open" : state = "open" ? "hidden" : "all"
    Memo_Page := 1
    SetTimer(Memo_UpdateView, -1)
}

Memo_DestroyCards()
{
    global Memo_Ctrl
    if !Memo_Ctrl.HasOwnProp("Cards")
        return
    for card in Memo_Ctrl.Cards
        card.Destroy()
    for header in Memo_Ctrl.GroupHeaders
        header.Destroy()
    Memo_Ctrl.Cards := [], Memo_Ctrl.GroupHeaders := []
}

Memo_CreateCard(task, y)
{
    global Memo_PanelGui, Memo_Ctrl, Memo_CardStyle, Memo_Layout
    style := Memo_CardStyle
    w := Memo_Layout.Width, height := style.Height
    g := Gui("-Caption -DPIScale +Parent" Memo_PanelGui.Hwnd)
    Memo_Ctrl.Cards.Push(g)
    g.BackColor := task.Done ? style.DoneColor : style.OpenColor
    g.MarginX := 0, g.MarginY := 0
    Memo_Font(g, style.FontSize, style.TextColor)
    title := g.AddText(Memo_Pos(style.Padding, 18, w - style.Padding - 78, height - 36) " BackgroundTrans +0x100 +0x200", task.Title)
    title.OnEvent("Click", Memo_OnTitleClick.Bind(task.Id))
    icon := A_ScriptDir (task.Done ? "\ico\memo-check-bold-done.ico" : "\ico\memo-check-bold-open.ico")
    check := g.AddPicture(Memo_Pos(w - 60, (height - 36) / 2, 36, 36), icon)
    check.OnEvent("Click", Memo_OnItemCheck.Bind(task.Id))
    diameter := style.Radius * 2
    WinSetRegion("0-0 W" w " H" height " R" diameter "-" diameter, "ahk_id " g.Hwnd)
    g.Show("NA x0 y" y " w" w " h" height)
}

Memo_ChangePage(direction, *)
{
    global Memo_Page
    Memo_Page += direction
    Memo_UpdateView()
}

Memo_OnItemCheck(id, *)
{
    global Memo_Tasks, Memo_Rendering, Memo_PendingCheck, Memo_DialogGui
    if Memo_Rendering
        return
    task := MemoCore_FindTask(Memo_Tasks, id)
    if !IsObject(task)
        return
    if (IsObject(Memo_PendingCheck) || IsObject(Memo_DialogGui))
        return
    ; 图片保持已保存的状态，事务成功后随卡片重建切换。
    Memo_PendingCheck := {Id: task.Id, Cycle: task.CycleStart, Checked: !task.Done}
    ; 控件回调结束后再保存和重建卡片。
    SetTimer(Memo_ApplyQueuedCheck, -1)
}

Memo_ApplyQueuedCheck()
{
    global Memo_PendingCheck
    request := Memo_PendingCheck
    Memo_PendingCheck := ""
    if !IsObject(request)
        return
    Memo_RefreshNow()
    Memo_Transact(Memo_ChangeDone.Bind(request.Id, request.Cycle, request.Checked))
}

Memo_OnTitleClick(id, *)
{
    global Memo_DialogGui, Memo_PendingCheck
    if (!IsObject(Memo_DialogGui) && !IsObject(Memo_PendingCheck))
        Memo_OpenEditor(id)
}

Memo_OpenEditor(id := "", defaultPeriod := 1, *)
{
    global Memo_Tasks, Memo_Editor, Memo_LoadError
    if (Memo_LoadError != "")
        return
    Memo_RefreshNow()
    task := id = "" ? "" : MemoCore_FindTask(Memo_Tasks, id)
    if (id != "" && !IsObject(task))
        return
    g := Memo_CreateDialog(id = "" ? "添加事项" : "编辑事项")
    days := IsObject(task) && task.Kind = "recurring" ? task.IntervalDays : 1
    selected := IsObject(task) ? (task.Kind = "recurring" ? (days = 7 ? 3 : 2) : 1) : defaultPeriod
    Memo_Editor := {Id: id, Period: selected}
    Memo_Label(g, 24, 27, 102, 33, "事项")
    Memo_Font(g, 10, "000000")
    Memo_Editor.Title := g.AddEdit(Memo_Pos(138, 21, 522, 42) " Limit120", IsObject(task) ? task.Title : "")
    Memo_Label(g, 24, 93, 102, 33, "周期")
    Memo_Label(g, 138, 93, 522, 33, ["单次", "每天", "每周"][selected])
    Memo_Editor.WeekdayLabel := Memo_Label(g, 24, 159, 108, 33, "刷新日")
    Memo_Font(g, 10, "000000")
    weekday := IsObject(task) && task.Kind = "recurring" && task.IntervalDays = 7 ? Mod(Integer(FormatTime(task.NextRefresh, "WDay")) + 5, 7) + 1 : 1
    Memo_Editor.Weekday := g.AddDropDownList(Memo_Pos(138, 150, 264, 240), ["周一", "周二", "周三", "周四", "周五", "周六", "周日"])
    Memo_Editor.Weekday.Choose(weekday)
    Memo_Editor.Cancel := Memo_Button(g, 408, 285, 114, 42, "取消", Memo_CloseDialog)
    Memo_Editor.Save := Memo_Button(g, 546, 285, 114, 42, "保存", Memo_SaveEditor, "Default")
    weekly := selected = 3
    Memo_Editor.WeekdayLabel.Visible := weekly
    Memo_Editor.Weekday.Visible := weekly
    buttonY := selected = 1 ? 159 : weekly ? 285 : 222
    Memo_Editor.Cancel.Move(, buttonY)
    Memo_Editor.Save.Move(, buttonY)
    Memo_ShowDialog(690, buttonY + 69)
    Memo_Editor.Title.Focus()
}

Memo_SaveEditor(*)
{
    global Memo_Editor, Memo_Page
    try
    {
        kind := Memo_Editor.Period = 1 ? "once" : "recurring"
        days := kind = "recurring" ? (Memo_Editor.Period = 2 ? 1 : 7) : 0
        fields := {Title: Trim(Memo_Editor.Title.Value), Kind: kind, Days: days, Weekday: Memo_Editor.Weekday.Value}
        isNew := Memo_Editor.Id = ""
        if Memo_Transact(Memo_ChangeEdit.Bind(Memo_Editor.Id, fields), isNew ? "add" : "edit")
        {
            Memo_CloseDialog()
            if isNew
            {
                Memo_Page := 1
                Memo_UpdateView()
            }
        }
    }
    catch Error as err
        Memo_Message(err.Message)
}

Memo_ChangeEdit(id, fields, tasks, now)
{
    if (id = "")
    {
        nextRefresh := fields.Kind = "recurring" ? MemoCore_DefaultRefresh(fields.Days, now, fields.Weekday) : ""
        id := MemoCore_NewId(tasks, now)
        tasks.InsertAt(1, MemoCore_NewTask(id, fields.Title, fields.Kind, fields.Days, nextRefresh, now))
    }
    else
    {
        task := MemoCore_RequireTask(tasks, id)
        task.Title := fields.Title
        if (task.Kind = "recurring" && task.IntervalDays = 7)
        {
            weekday := Mod(Integer(FormatTime(task.NextRefresh, "WDay")) + 5, 7) + 1
            if (weekday != fields.Weekday)
                task.NextRefresh := MemoCore_DefaultRefresh(7, now, fields.Weekday)
        }
        MemoCore_ValidateTask(task)
    }
    return id
}

Memo_ChangeDone(id, cycle, done, tasks, now)
{
    task := MemoCore_RequireTask(tasks, id)
    if (task.CycleStart != cycle)
        throw Error("事项已经进入新周期，请重试。")
    task.Done := done
}

Memo_CreateDialog(title)
{
    global Memo_DialogGui, ContentGui
    Memo_DestroyDialog(false)
    Memo_DialogGui := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox -DPIScale +Owner" ContentGui.Hwnd, title)
    Memo_DialogGui.BackColor := "1A1A1A"
    Memo_DialogGui.MarginX := 0, Memo_DialogGui.MarginY := 0
    Memo_DialogGui.OnEvent("Close", Memo_CloseDialog)
    Memo_DialogGui.OnEvent("Escape", Memo_CloseDialog)
    ContentGui.Opt("+Disabled")
    return Memo_DialogGui
}

Memo_ShowDialog(width, height)
{
    global Memo_DialogGui, Memo_Layout, ScreenX, ScreenY
    x := ScreenX + Memo_Layout.DialogCenterX - width // 2
    y := ScreenY + Memo_Layout.DialogCenterY - height // 2
    Memo_DialogGui.Show("x" x " y" y " w" width " h" height)
}

Memo_CloseDialog(*)
{
    Memo_DestroyDialog(true)
}

Memo_DestroyDialog(activateOwner := true)
{
    global Memo_DialogGui, Memo_Editor, ContentGui
    hadDialog := IsObject(Memo_DialogGui)
    if hadDialog
        Memo_DialogGui.Destroy()
    Memo_DialogGui := "", Memo_Editor := ""
    if (hadDialog && IsSet(ContentGui) && IsObject(ContentGui))
    {
        ContentGui.Opt("-Disabled")
        if activateOwner
            WinActivate("ahk_id " ContentGui.Hwnd)
    }
}

Memo_IsDialogActive()
{
    global Memo_DialogGui
    return IsObject(Memo_DialogGui) && WinActive("ahk_id " Memo_DialogGui.Hwnd)
}

Memo_Message(message, options := "Icon!", title := "提示")
{
    global Memo_DialogGui, ContentGui
    if IsObject(Memo_DialogGui)
        Memo_DialogGui.Opt("+OwnDialogs")
    else if (IsSet(ContentGui) && IsObject(ContentGui))
        ContentGui.Opt("+OwnDialogs")
    return MsgBox(message, title, options)
}

Memo_Pos(x, y, width, height)
{
    return "x" x " y" y " w" width " h" height
}

Memo_Font(target, size := 10, color := "FFFFFF")
{
    target.SetFont("s" size " norm c" color, "Segoe UI")
}

Memo_Label(g, x, y, width, height, text, size := 10, color := "FFFFFF")
{
    Memo_Font(g, size, color)
    return g.AddText(Memo_Pos(x, y, width, height) " BackgroundTrans 0x4000", text)
}

Memo_Button(g, x, y, width, height, text, callback, options := "")
{
    Memo_Font(g, 10, "000000")
    ctrl := g.AddButton(Memo_Pos(x, y, width, height) " " options, text)
    ctrl.OnEvent("Click", callback)
    return ctrl
}
