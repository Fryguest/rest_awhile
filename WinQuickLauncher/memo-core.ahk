#Requires AutoHotkey v2.0

; 备忘录数据模型：无 GUI、定时器或全局状态。
; 时间戳是本地日历时间 yyyyMMddHHmmss。

MemoCore_NewTask(id, title, kind, intervalDays, nextRefresh, now)
{
    task := {Id: id, Title: Trim(title), Kind: kind,
        IntervalDays: kind = "recurring" ? intervalDays : 0,
        NextRefresh: kind = "recurring" ? nextRefresh : "", CycleStart: now,
        Done: 0, CreatedAt: now}
    MemoCore_ValidateTask(task)
    return task
}

MemoCore_NewId(tasks, now := "")
{
    if (now = "")
        now := A_Now
    Loop
    {
        id := now "-" Random(100000, 999999)
        if !IsObject(MemoCore_FindTask(tasks, id))
            return id
    }
}

MemoCore_FindTask(tasks, id)
{
    for task in tasks
        if (task.Id == id)
            return task
    return ""
}

MemoCore_RequireTask(tasks, id)
{
    task := MemoCore_FindTask(tasks, id)
    if !IsObject(task)
        throw Error("这个事项已不存在，请重新打开清单。")
    return task
}

MemoCore_CopyTasks(tasks)
{
    copy := []
    for task in tasks
        copy.Push(task.Clone())
    return copy
}

; 从原来的刷新锚点推进，而不是从本次启动时间重新计时。
; 未完成也推进轮次；离线漏过很多轮时，一次算出新的边界。
MemoCore_RefreshTask(task, now)
{
    if (task.Kind != "recurring" || StrCompare(now, task.NextRefresh) < 0)
        return false

    elapsedDays := DateDiff(now, task.NextRefresh, "Days")
    periods := Floor(elapsedDays / task.IntervalDays) + 1
    lastBoundary := DateAdd(task.NextRefresh, (periods - 1) * task.IntervalDays, "Days")
    nextBoundary := DateAdd(task.NextRefresh, periods * task.IntervalDays, "Days")
    task.CycleStart := lastBoundary
    task.NextRefresh := nextBoundary
    task.Done := 0
    return true
}

MemoCore_RefreshAll(tasks, now)
{
    changed := false
    for task in tasks
        if MemoCore_RefreshTask(task, now)
            changed := true
    return changed
}

MemoCore_DefaultRefresh(days, now := "", weekday := 1)
{
    if !IsInteger(days) || (days != 1 && days != 7)
        throw Error("重复周期只支持每天或每周。")
    if (now = "")
        now := A_Now
    midnight := SubStr(now, 1, 8) "000000"
    if (days = 7)
    {
        if !IsInteger(weekday) || weekday < 1 || weekday > 7
            throw Error("请选择周一至周日。")
        today := Mod(Integer(FormatTime(now, "WDay")) + 5, 7) + 1
        untilRefresh := Mod(weekday - today + 7, 7)
        return DateAdd(midnight, untilRefresh = 0 ? 7 : untilRefresh, "Days")
    }
    return DateAdd(midnight, 1, "Days")
}

MemoCore_OrderTasks(tasks)
{
    result := []
    ; 每天、每周、单次；同组未完成优先，其余保持原顺序。
    for days in [1, 7, 0]
    {
        for done in [0, 1]
        {
            for task in tasks
            {
                if (task.IntervalDays = days && task.Done = done)
                    result.Push(task)
            }
        }
    }
    return result
}

MemoCore_IsStamp(value)
{
    if !RegExMatch(value, "^\d{14}$")
        return false
    if (Integer(SubStr(value, 1, 4)) < 1900)
        return false
    try
        return DateAdd(value, 0, "Seconds") == value
    catch Error
        return false
}

MemoCore_ValidateTask(task)
{
    if !RegExMatch(task.Id, "^[A-Za-z0-9_-]{1,64}$")
        throw Error("事项编号无效。")
    if (Trim(task.Title) = "" || StrLen(task.Title) > 120 || RegExMatch(task.Title, "[\t\r\n]"))
        throw Error("事项标题须为 1～120 个字，不能包含换行或制表符。")
    if (task.Kind != "recurring" && task.Kind != "once")
        throw Error("事项类型无效。")
    if !MemoCore_IsStamp(task.CreatedAt) || !MemoCore_IsStamp(task.CycleStart)
        throw Error("事项的创建时间或轮次时间无效。")
    if (task.Kind = "recurring")
    {
        if !IsInteger(task.IntervalDays) || (task.IntervalDays != 1 && task.IntervalDays != 7)
            throw Error("重复周期只支持每天或每周。")
        if !MemoCore_IsStamp(task.NextRefresh) || StrCompare(task.NextRefresh, task.CycleStart) <= 0
            throw Error("下次刷新时间必须晚于本轮起点。")
    }
    else if (task.IntervalDays != 0 || task.NextRefresh != "")
        throw Error("单次事项不应包含刷新设置。")

    if (task.Done != 0 && task.Done != 1)
        throw Error("完成状态无效。")
}

MemoCore_Escape(value)
{
    return StrReplace(StrReplace(StrReplace(StrReplace(value, "\", "\\"), "`t", "\t"), "`r", "\r"), "`n", "\n")
}

MemoCore_Unescape(value)
{
    result := "", escaped := false
    escapes := Map("\", "\", "t", "`t", "r", "`r", "n", "`n")
    Loop Parse, value
    {
        ch := A_LoopField
        if escaped
        {
            if !escapes.Has(ch)
                throw Error("文本包含未知转义字符。")
            result .= escapes[ch]
            escaped := false
        }
        else if (ch = "\")
            escaped := true
        else
            result .= ch
    }
    if escaped
        throw Error("文本以不完整的转义字符结尾。")
    return result
}

MemoCore_ReadInteger(value, minimum, maximum)
{
    if !RegExMatch(value, "^\d+$")
        throw Error("需要一个非负整数。")
    parsedInteger := Integer(value)
    if (parsedInteger < minimum || parsedInteger > maximum)
        throw Error("整数超出允许范围。")
    return parsedInteger
}

MemoCore_Load(path)
{
    if !FileExist(path)
        return []
    content := LTrim(FileRead(path, "UTF-8"), Chr(0xFEFF))
    tasks := [], ids := Map(), headerSeen := false, version := 0
    Loop Parse, content, "`n", "`r"
    {
        lineNumber := A_Index
        line := A_LoopField
        if (line = "")
            continue
        try
        {
            fields := StrSplit(line, "`t")
            if !headerSeen
            {
                if (line != "WQLMEMO`t1" && line != "WQLMEMO`t2" && line != "WQLMEMO`t3")
                    throw Error("不是支持的备忘录数据文件（WQLMEMO 1/2/3）。")
                version := Integer(fields[2])
                headerSeen := true
            }
            else if (fields[1] == "TASK" && fields.Length = (version = 1 ? 11 : version = 2 ? 10 : 9))
            {
                id := fields[2]
                if ids.Has(id)
                    throw Error("事项编号重复。")
                offset := version = 1 ? 1 : 0
                task := {Id: id, Kind: fields[3], IntervalDays: MemoCore_ReadInteger(fields[4], 0, 7), NextRefresh: fields[5], CycleStart: fields[6], Done: MemoCore_ReadInteger(fields[7], 0, 1), CreatedAt: fields[8 + offset], Title: MemoCore_Unescape(fields[9 + offset])}
                tasks.Push(task)
                ids[id] := task
            }
            else if (version = 1 && fields[1] == "HISTORY" && fields.Length = 4)
                continue ; 旧格式兼容：不再导入历史完成记录。
            else
                throw Error("未知记录或字段数量不正确。")
        }
        catch Error as err
            throw Error("第 " lineNumber " 行：" err.Message)
    }
    if !headerSeen
        throw Error("数据文件为空或缺少文件头。")
    for task in tasks
    {
        try MemoCore_ValidateTask(task)
        catch Error as err
            throw Error("事项「" task.Title "」：" err.Message)
    }
    return tasks
}

MemoCore_TaskRow(task)
{
    return "TASK`t" task.Id "`t" task.Kind "`t" task.IntervalDays "`t" task.NextRefresh "`t" task.CycleStart "`t" task.Done "`t" task.CreatedAt "`t" MemoCore_Escape(task.Title) "`n"
}

; 临时文件完整落盘后替换正式文件。
; 调用方在成功后才替换内存快照，写入失败不会显示成“保存成功”。
MemoCore_Save(path, tasks)
{
    output := "WQLMEMO`t3`n", ids := Map()
    for task in tasks
    {
        MemoCore_ValidateTask(task)
        if ids.Has(task.Id)
            throw Error("事项编号重复，未写入文件。")
        ids[task.Id] := true
        output .= MemoCore_TaskRow(task)
    }

    tempPath := path ".tmp"
    writer := FileOpen(tempPath, "w", "UTF-8-RAW")
    if !IsObject(writer)
        throw Error("无法写入备忘录临时文件，系统错误码：" A_LastError)
    try
    {
        bytesWritten := writer.Write(output)
        if (bytesWritten != StrPut(output, "UTF-8") - 1)
            throw Error("备忘录未能完整写入，原文件没有被替换。")
        if !DllCall("Kernel32\FlushFileBuffers", "Ptr", writer.Handle, "Int")
            throw OSError()
    }
    finally
        writer.Close()
    ; REPLACE_EXISTING | WRITE_THROUGH，临时文件始终与目标文件位于同一目录。
    if !DllCall("Kernel32\MoveFileExW", "Str", tempPath, "Str", path, "UInt", 0x9, "Int")
        throw OSError()
}

MemoCore_JournalSnapshot(tasks, timestamp)
{
    output := "SNAPSHOT`t" timestamp "`nWQLMEMO`t3`n"
    for task in tasks
        output .= MemoCore_TaskRow(task)
    return output "END`tSNAPSHOT`n"
}

MemoCore_JournalCount(path)
{
    if !FileExist(path)
        return 0
    content := LTrim(FileRead(path, "UTF-8"), Chr(0xFEFF))
    count := 0, pending := ""
    Loop Parse, content, "`n", "`r"
    {
        line := A_LoopField
        if (line = "")
            continue
        fields := StrSplit(line, "`t")
        if (fields[1] = "SNAPSHOT" && fields.Length = 2)
            pending := "SNAPSHOT"
        else if (fields[1] = "DELTA" && fields.Length = 3)
            pending := "DELTA"
        else if (line = "END`tSNAPSHOT" && pending = "SNAPSHOT")
        {
            count := 0
            pending := ""
        }
        else if (line = "END`tDELTA" && pending = "DELTA")
        {
            count += 1
            pending := ""
        }
    }
    return count
}

MemoCore_AppendJournal(path, count, tasks, id, action)
{
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    output := "`n"
    output .= "DELTA`t" timestamp "`t" action "`n"
    output .= MemoCore_TaskRow(MemoCore_RequireTask(tasks, id))
    output .= "END`tDELTA`n"
    count += 1
    if (count >= 100)
    {
        output .= MemoCore_JournalSnapshot(tasks, timestamp)
        count := 0
    }
    FileAppend(output, path, "UTF-8")
    return count
}
