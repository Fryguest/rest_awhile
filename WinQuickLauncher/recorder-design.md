# 键鼠录制回放功能 设计文档

本文档记录 WinQuickLauncher 项目中"键鼠操作录制与回放"功能的调研结论、技术分析与设计决策。

---

## 1. 需求与范围

### 1.1 原始需求

按某个键开始录制后续所有操作（鼠标 + 键盘），按某个键停止录制，之后可以播放该录制以重放操作。

### 1.2 第一阶段范围

包含：

- 热键触发的开始 / 停止录制（切换式）
- 热键触发的播放 / 停止播放
- 录制内容：键盘按下与抬起、鼠标移动轨迹、左 / 右 / 中键、滚轮
- 时序还原（记录真实间隔并在回放时还原）
- 录制数据持久化到文件，脚本重启后仍可播放
- 紧急停止机制
- 热键可在设置界面中配置

明确排除（第一阶段不做）：

- 多份录制的管理、命名、列表选择
- 播放倍速、循环次数
- 图像识别定位（SikuliX 式）
- UI 元素定位（Power Automate 式）
- 录制内容的可视化编辑
- 与 Launcher 列表的集成（如"点击条目即播放宏"）

### 1.3 关键约束

功能集成进现有的 run.ahk，运行时为同一进程、同一托盘图标、同一套热键体系。

---

## 2. 选型结论

### 2.1 市面同类产品

以下数据为调研时刻通过 GitHub API 与官方文档联网核实。

开源 / 免费：

| 产品 | 技术栈 | 状态 | 特点 | 短板 |
| --- | --- | --- | --- | --- |
| Pulover's Macro Creator | AHK v1 | 2.0k star，最后 push 2022-07，基本停更 | 录制键鼠、可视化编辑每条事件、导出 AHK 脚本、图像查找、循环与条件 | 仅 AHK v1；已停更 |
| TinyTask | C / 汇编 | 闭源免费，约 35KB | 极简录放，可编译成 exe，免安装无注册表 | 无编辑、无坐标校正 |
| Mini Mouse Macro | .NET | 免费社区版 | 录制 + 列表编辑 + 图像识别（付费） | 部分功能收费 |
| raeleus/AHK-Macro-Recorder | AHK v2 | 108 star，2025-07 更新 | 单文件脚本，基于论坛 feiyue 的经典实现 | 文档仅视频，功能基础 |
| Sz-KLevy/AHK_AutoHotKey_Macro_Recorder | AHK v2 | 2026-06 更新，标注 alpha | GUI 面板、保存加载、可配置热键、坐标模式可选 | star 极少，质量待验证 |
| NoOne20104/ahk-macro-recorder | AHK v2 | 2025-12 更新 | F9 录 / F10 放、拟人化回放、紧急停止、GUI | 极小项目 |
| SikuliX (oculix-org/SikuliX1) | Java + OpenCV | 3.2k star，2026-07 更新，活跃 | 图像识别定位，抗界面位移 | 非录制而是编写脚本；依赖 JVM |
| OpenAdapt | Python | 1.7k star，v1.16.0 (2026-08)，活跃 | 录制人类演示后由 LLM 泛化成程序 | 方向新、体量重、需模型 |

Python 生态：

| 库 | 状态 | 用途 |
| --- | --- | --- |
| pynput | 2.1k star，2026-05 更新，活跃 | 全局键鼠监听 + 模拟，录放最常用 |
| pyautogui | 12.7k star，最后 push 2024-08 | 仅模拟与截图，无全局监听，做不了录制 |
| boppreh/keyboard | 4k star，release 停在 2020 | 自带 record/play，仅键盘 |
| boppreh/mouse | 已归档停更 | 鼠标录放 |

商业 / 官方：

| 产品 | 说明 |
| --- | --- |
| Power Automate Desktop | 微软官方，Win10/11 免费自带。录制的是 UI 元素选择器而非纯坐标，稳但重，学习曲线陡 |
| Macro Recorder (Bartels Media) | 商业约 40 美元，录制 + 编辑 + 图像识别 |
| JitBit Macro Recorder | 商业老牌，同上 |
| Windows 步骤记录器 psr.exe | 系统自带，只截图记录步骤，不能回放，常被误认为录制工具 |

### 2.2 选型结论

自行实现，技术栈 AutoHotkey v2。

理由：

1. 机器上已运行 run.ahk，AutoHotkey v2 已安装，新增功能的边际成本为零，比安装 TinyTask 更"无感"。
2. 与现有项目技术栈一致，可复用托盘、配置文件、设置界面等基础设施。
3. 与 Launcher 集成的能力是现成产品无法提供的，是本项目的差异化价值点。

同时需认识到：纯坐标回放这条路，所有免费产品的脆弱性是一致的（分辨率、DPI、窗口位置变化即失效）。商业产品与 SikuliX 的差异化全部建立在图像识别或 UI 元素定位之上。

---

## 3. 业界实现的时序策略

调研了三个实际实现的源码，结论是主流实现并不追求时间精度，而是降低时序的重要性。

### 3.1 boppreh/keyboard

```python
if speed_factor > 0 and last_time is not None:
    _time.sleep((event.time - last_time) / speed_factor)
last_time = event.time
```

逐条累加 sleep 差值，不修正累积漂移，提供 speed_factor 倍速参数。

### 3.2 raeleus/AHK-Macro-Recorder

```ahk
if (Delay > 200)
    LogArr.Push((RecordSleep == "false" ? ";" : "") "Sleep(" (Delay // 2) ")")
```

策略：

- 间隔小于 200ms 直接丢弃，不生成任何等待
- 保留下来的延迟还要除以 2
- RecordSleep 默认为 false，即把所有 Sleep 语句注释掉
- 由脚本头部的 `SendMode("Event")` 与 `SetKeyDelay(30)` 提供固定 30ms 兜底间隔

其设计意图是：小于 200ms 的间隔是人的手速抖动，无信息量；大于 200ms 的间隔通常对应思考或等待程序响应，需要保留。除以 2 是在赌回放时程序比录制时快。

### 3.3 Pulover's Macro Creator

采集方式与其他实现不同：使用 `SetTimer, MouseRecord` 轮询鼠标位置，键盘用 AHK 的 Hotkey 与 Input，完全不使用低级钩子。

时序处理：

```ahk
If (Interval := TimeRecord())
{
    If (Interval > TDelay)
    GoSub, SleepInput
}
```

```ahk
SleepInput:
LV_Add("Check", ListCount%A_List%+1, "[Pause]", "", 1, Interval, cType5)
return
```

时序记录是可选功能（Timed Intervals），开启后把间隔存成显式的 `[Pause]` 指令行，阈值 TDelay 默认 10ms；关闭时使用固定延迟 DelayG / DelayM。

### 3.4 两个值得借鉴的设计

把延迟建模成显式指令，而不是隐含时间戳：

- 录制文件可读、可手工编辑（例如删掉某个无意义的 5 秒等待）
- 倍速、压缩、阈值过滤都退化成对数据的简单变换，回放逻辑不需要改动
- 回放逻辑简化为"顺序执行指令"
- 代价是文件行数增多

采集方式存在三种而非两种选择：轮询、低级钩子、Raw Input。

### 3.5 结论

| 场景 | 业界做法 |
| --- | --- |
| UI 自动化（主流） | 时序不还原或压缩，追求快速重复 |
| 游戏宏 / 音游 | 才使用高精度计时与忙等 |

没有任何调研到的实现使用 QueryPerformanceCounter 或忙等。真正提高回放成功率的手段是等待条件（SikuliX 一派），而非提高时间精度。

---

## 4. 技术机制备忘

### 4.1 低级钩子的超时与静默摘除

MSDN `LowLevelMouseProc` / `LowLevelKeyboardProc` 原文：

> The hook procedure should process a message in less time than the data entry specified in the LowLevelHooksTimeout value in the following registry key: HKEY_CURRENT_USER\Control Panel\Desktop. The value is in milliseconds. If the hook procedure times out, the system passes the message to the next hook. **However, on Windows 7 and later, the hook is silently removed without being called. There is no way for the application to know whether the hook is removed.**

> Windows 10 version 1709 and later: The maximum timeout value the system allows is 1000 milliseconds (1 second). The system will default to using a 1000 millisecond timeout if the LowLevelHooksTimeout value is set to a value larger than 1000.

关键后果：超时不是"卡顿后恢复"，而是钩子被系统静默摘除且程序无法感知。对录制器而言意味着录制会在毫无提示的情况下停止采集，得到一份静默残缺的数据。

注册表默认值 MSDN 未公开（该键通常不存在），社区普遍报告为 300ms 量级。查询方式：

`reg query "HKCU\Control Panel\Desktop" /v LowLevelHooksTimeout`

MSDN 同时给出的建议（在 AHK 中无法采纳，见 4.5）：

> If the application must use low level hooks, it should run the hooks on a dedicated thread that passes the work off to a worker thread and then immediately returns.

### 4.2 timeBeginPeriod 的限制

MSDN `timeBeginPeriod` 原文：

> Prior to Windows 10, version 2004, this function affects a global Windows setting. For all processes Windows uses the lowest value (that is, highest resolution) requested by any process. **Starting with Windows 10, version 2004, this function no longer affects global timer resolution.** For processes which call this function, Windows uses the lowest value requested by any process.

> **Starting with Windows 11, if a window-owning process becomes fully occluded, minimized, or otherwise invisible or inaudible to the end user, Windows does not guarantee a higher resolution than the default system resolution.**

第二条对本场景构成真实风险：AHK 脚本运行时只有隐藏的主窗口，在 Windows 11 上可能被判定为 invisible，导致 `timeBeginPeriod(1)` 静默失效，定时器精度退回约 15.6ms。

### 4.3 Windows 热键机制

Windows 上实现全局热键有两套机制。

RegisterHotKey（系统级注册，独占）：

- 向系统登记某个组合归本进程所有。按下时系统投递 `WM_HOTKEY` 到注册线程的消息队列，按键被系统消费，不传给前台窗口
- MSDN 原文：`RegisterHotKey` typically fails if the keystrokes specified for the hot key have already been registered for another hot key（`GetLastError` 返回 `ERROR_HOTKEY_ALREADY_REGISTERED`，值 1409）
- 优点：冲突可检测、零性能开销、不干扰其他按键
- 限制：Win 键组合被系统保留；`Ctrl+Alt+Del`、`Win+L` 等不可覆盖
- 修饰符标志：`MOD_ALT` 0x1、`MOD_CONTROL` 0x2、`MOD_SHIFT` 0x4、`MOD_WIN` 0x8、`MOD_NOREPEAT` 0x4000

WH_KEYBOARD_LL 低级钩子（拦截式，非独占）：

- 拦截全部按键自行判断，可选择吞掉（不调用 `CallNextHookEx` 并返回非零）
- 多个程序可同时挂载，后安装的先被调用；谁先吞掉谁生效，没有"冲突"概念，也无法检测冲突
- 用于实现 RegisterHotKey 做不到的场景：条件热键、通配符、自定义组合等

Raw Input 是第三种输入获取途径，但只读、不能拦截，无法实现热键语义。

AHK 的实际行为，官方文档 `#UseHook`：

> If this directive is unspecified in the script, it will behave as though set to False, meaning the windows API function **RegisterHotkey() is used to implement a keyboard hotkey whenever possible**.

官方文档 `InstallKeybdHook`：

> The keyboard hook monitors keystrokes for the purpose of activating hotstrings and any keyboard hotkeys not supported by RegisterHotkey. AutoHotkey does not install the keyboard and mouse hooks unconditionally because together they consume at least 500 KB of memory. Therefore, the keyboard hook is normally installed only when the script contains one of the following: 1) hotstrings; 2) one or more hotkeys that require the keyboard hook (most do not); 3) SetCaps/Scroll/NumLock AlwaysOn/AlwaysOff; 4) active Input hooks.

因此 `^2::` 这类普通组合热键走 RegisterHotKey 路径，冲突原则上可以检测到。

存疑点（需实测验证）：AHK 在 `RegisterHotKey` 调用失败时是否会静默回退到键盘钩子。若会回退，则 `Hotkey()` 不会抛出异常，冲突仍然无法在保存时检测。验证方法：让某个程序先占用目标组合键，再运行一个仅含该热键的最小脚本，观察是否报错以及按下时哪个程序响应。

### 4.4 AHK #Include 语义

AHK v2 支持 `#Include`，但它是加载期的文本插入，不是模块导入。

```ahk
#Include Lib\Recorder.ahk           ; 相对于当前脚本所在目录
#Include %A_ScriptDir%\Lib\Hook.ahk ; 显式路径
#Include *i Lib\Optional.ahk        ; 文件不存在也不报错
#IncludeAgain Lib\Util.ahk          ; 允许重复插入
```

与 Python import 的差异：

| 特性 | AHK #Include | Python import |
| --- | --- | --- |
| 机制 | 把文件内容原样插入该行位置 | 独立模块对象 |
| 命名空间 | 无，全部展开到同一全局空间 | 有模块命名空间 |
| 命名冲突 | 同名函数或类导致加载失败 | 各自隔离 |
| 全局变量 | 直接共享 | 需显式引用 |
| 重复包含 | 默认自动去重 | 有模块缓存 |
| 执行时机 | 加载时插入，运行时无开销 | 运行时执行模块顶层代码 |

需要注意的坑：

1. 自动执行段从第一行执行到第一个 return、热键或函数定义为止。若 `#Include` 放在文件顶部，被包含文件中的顶层可执行语句会跟着运行。惯例是把 `#Include` 放在文件末尾，或确保被包含文件只含函数、类、热键定义。
2. 被包含文件中的热键定义会立即生效。
3. `#Include` 路径不支持变量表达式，只支持字面量与少数内置变量（`%A_ScriptDir%`、`%A_LineFile%` 等）。在库文件中引用同目录兄弟文件时用 `%A_LineFile%` 更稳。
4. 没有 export 概念，一切公开。私有化只能靠命名前缀约定或用 class 作命名空间。
5. 编译成 exe 时被包含内容会一并打包，发布仍是单文件。

### 4.5 AHK 无法使用独立线程运行钩子

MSDN 建议钩子跑在专用线程，但在 AHK 中不可行：

| 手段 | 可行性 | 说明 |
| --- | --- | --- |
| AHK 的 thread | 不可行 | AHK 的"线程"是伪线程，同一 OS 线程上的中断式调度，不解决阻塞 |
| DllCall CreateThread + CallbackCreate | 不可行 | AHK 解释器非线程安全，在非主线程执行 AHK 代码为未定义行为 |
| CreateThread + 纯机器码回调 | 理论可行 | 回调不碰 AHK，只写共享内存，主线程定时取。需手写 shellcode，维护成本极高 |
| AutoHotkey_H / AhkThread | 可行但有代价 | 第三方 DLL，同进程内跑第二个解释器实例。引入外部依赖，违背"无感"前提 |
| 独立进程 + WM_COPYDATA | 可行，AHK 的正解 | 真隔离，主进程 GUI 阻塞不影响钩子。代价是 IPC、双进程生命周期管理、崩溃恢复，代码量翻倍 |

结论：第一阶段全部否决，不引入多线程或多进程。

---

## 5. 时间精度分析

### 5.1 录制侧

事件完整性：

| 采集方式 | 是否漏事件 |
| --- | --- |
| 低级钩子 / Raw Input | 事件驱动，不漏 |
| SetTimer 轮询 | 按周期采样，会漏；两次采样之间的快速点击、短按会丢失 |

时间戳精度：

| 时间源 | 抖动 | 副作用 |
| --- | --- | --- |
| A_TickCount | 约 15.6ms | 真实间隔 5ms 与 12ms 被量化成同一值，回放时鼠标轨迹忽快忽慢 |
| 钩子结构体的 time 字段 | 约 15.6ms | 语义更准（事件真实产生时刻，不含传递延迟），但分辨率同样受限于 GetTickCount |
| QueryPerformanceCounter | 小于 1 微秒 | 含钩子传递延迟（正常几十至几百微秒，主线程繁忙时放大） |

由于回放关心的是相对间隔而非绝对时刻，而传递延迟在正常情况下是稳定常量、会在相减时抵消，QPC 给出的相对时序更细。

关键点：鼠标按 10ms 节流采样，而 A_TickCount 分辨率为 15.6ms，时钟比采样还粗，间隔信息基本被抹平。QPC 只需一次 DllCall，开销约 20 至 50 纳秒。

第三个误差源是钩子回调延迟。缓解方式：回调第一行就取时间戳，回调内禁止任何 IO。

录制侧误差不累积，因为所有时间戳基于同一时钟。

### 5.2 播放侧

播放侧是主要误差来源。

| 等待方式 | 实际精度 | CPU 占用 | 能否响应停止热键 |
| --- | --- | --- | --- |
| AHK Sleep(n) | 约 ±15.6ms，系统性偏长 | 0 | 能，AHK Sleep 会泵消息 |
| DllCall("Sleep") | 约 ±15.6ms，偏长 | 0 | 不能，不泵消息 |
| timeBeginPeriod(1) + Sleep | ±1 至 2ms | 0 | 能。但受 4.2 的限制 |
| QPC 纯忙等 | 小于 0.05ms | 单核 100% | 需主动轮询按键 |
| 混合：剩余大于 2ms 用 Sleep，最后 2ms 忙等 | 小于 0.3ms | 接近 0 | 能 |

Sleep 的偏差是单向的，只会睡过头，永远不会睡不够，因此纯 Sleep 方案下回放必然比录制慢。

忙等期间不泵消息会导致 AHK 热键无法触发。三种解法中，在忙等循环内用 `GetKeyState(key, "P")` 直接查询物理按键状态是唯一既保精度又保响应的做法（不依赖消息循环，每次轮询几十纳秒）。

### 5.3 累积漂移

这是唯一会造成秒级偏差的因素。

错误写法是逐条 `Sleep(本条与上条的间隔)`：每次 Sleep 平均偏长 5 至 8ms，1000 条事件后回放比录制慢 5 至 8 秒，事件越密集漂移越严重。

正确写法是以播放起点为基准对齐绝对时刻：

```
t0 := 播放开始时刻
对每条事件：等到 (t0 + 事件的相对偏移) 这个绝对时刻
```

每条独立对齐绝对时刻，误差不累积。单条仍有抖动，但不会滚雪球。改动成本为零，只是写法不同。

### 5.4 落后与追赶

对齐绝对时刻的算法必然遇到"已经落后于计划时刻"的情况：

```
target = t0 + 事件.偏移
now < target   → 等待
now >= target  → 已落后，立即执行
```

三种处理策略：

| 策略 | 行为 | 后果 |
| --- | --- | --- |
| A 无限追赶 | 落后就持续全速发送直到追上 | 总时长准确。若落后 500ms，会有几十条事件在几毫秒内爆发 |
| B 不追赶（顺延） | 每条都保证间隔，落后则整体后移 | 节奏完美保持，但累积漂移重现，出现秒级偏差 |
| C 限幅追赶 | 落后小于阈值就追；超过阈值判定为系统异常，重置 t0 基准 | 不爆发，漂移有上限。但静默丢弃时间债，第一版无法观测异常 |

是否会持续落后取决于占用率：SendInput 单次约 0.05 至 0.3ms，键盘自动重复 33ms 间隔对应占用率小于 1%，鼠标 10ms 节流对应约 3%。正常情况下不会持续落后，只有系统被其他进程抢占时才会短暂落后。

爆发对语义的影响（已知并接受）：

| 被压缩的间隔 | 后果 |
| --- | --- |
| 鼠标 down 到 up | 间隔压到接近 0，部分程序识别不到点击 |
| 两次点击之间 | 压到低于双击阈值，两个单击变成一次双击 |
| 按键 down 到 up | 长按被压成短按 |

第一阶段的要求是保证事件顺序正确即可，不要求时间约束。事件顺序在追赶模式下永远正确，因为按数组顺序逐条调用 SendInput，系统输入队列是 FIFO。

### 5.5 键盘自动重复与回放精度

按住一个键不放，系统持续产生 keydown，最快约 33ms 一个（`KeyboardSpeed` 默认 31 档）。Sleep 抖动 ±15.6ms 对应相对误差接近 ±50%，但实际影响很小，因为两类消费者都不看节奏：

| 消费方 | 实际关心的 | 节奏抖动的影响 |
| --- | --- | --- |
| 文本输入（编辑器、输入框） | keydown 数量 | 无。发 20 个就是 20 个字符 |
| 游戏 | 每帧查 GetAsyncKeyState，只看 down 到 up 的时间跨度 | 无。重复 down 本身被忽略 |

加上绝对时刻对齐保证总时长正确，结果是内部节奏不均、首尾对齐、数量准确。

如需彻底消除该抖动，可把连续的自动重复识别成一段，回放时用 SendInput 批量数组一次性提交（SendInput 支持一次传入多个 INPUT 结构，由系统连续注入，不经过 Sleep），代价是该段真实节奏被压成瞬时。

### 5.6 坐标精度

归一化误差：SendInput 绝对坐标是 0 至 65535 归一化。以 3840 宽度计算约 17 个归一化单位对应 1 像素，分辨率足够，但正反变换各有一次舍入，残留 ±1 像素误差是常态。对按钮、菜单项无影响，对 1 像素边框拖拽有影响。

DPI（唯一会造成灾难性偏差的点）：

- 钩子给出的 `MSLLHOOKSTRUCT.pt` 是物理像素坐标，不受 DPI 虚拟化影响
- SendInput 绝对坐标也是相对物理虚拟屏幕
- 两端自洽，但归一化的分母必须同样是物理尺寸

若分母用 AHK 的 MonitorGet 或 SysGet 取得（在 DPI unaware 进程中返回虚拟化后的逻辑尺寸），分母就是错的，坐标会整体按缩放比例偏移。200% 缩放下点击 (3000, 1000) 会打到 (1500, 500)。

必须使用 `GetSystemMetrics` 的 `SM_XVIRTUALSCREEN` (76)、`SM_YVIRTUALSCREEN` (77)、`SM_CXVIRTUALSCREEN` (78)、`SM_CYVIRTUALSCREEN` (79)，并确保进程 DPI 感知。

多显示器负坐标：副屏位于主屏左侧时坐标为负，归一化必须先减去 `SM_XVIRTUALSCREEN`。

### 5.7 按键还原精度

| 项 | 还原度 | 说明 |
| --- | --- | --- |
| 普通按键 | 高 | 用 scancode 配合 `KEYEVENTF_SCANCODE` 比用 vk 更贴近真实硬件输入，被程序过滤的概率更低 |
| 扩展键（右 Ctrl / Alt、方向键、Home / End、小键盘） | 高，前提是记录并回放 E0 标志 | 漏掉 `KEYEVENTF_EXTENDEDKEY` 会导致右 Alt 变左 Alt、方向键变小键盘数字 |
| 修饰键组合 | 高 | 前提是 down / up 成对记录，停止录制时补齐悬挂的 keyup |
| 输入法 IME | 不还原 | 录制时用中文输入法打的字，回放只重放物理按键。若回放时 IME 状态不同或候选词顺序变化，输出完全不同 |
| Unicode 字符 | 不还原 | 除非改用 `KEYEVENTF_UNICODE` 走文本注入，但那已不属于按键回放 |
| 游戏 DirectInput / Raw Input 独占 | 可能无效 | 部分游戏只读 Raw Input，SendInput 注入的事件带 INJECTED 标志可能被过滤 |

### 5.8 按住类操作

能够录制，前提是 down 与 up 记成两条独立事件，按住时长由两者的时间差自然表达。

对比：生成 `Send "{Blind}a"` 这类合并写法无法表达长按，这也是 raeleus 实现中额外引入 Duration 变量补救的原因。

鼠标拖拽依赖完整轨迹。拖拽等于 down 加移动序列加 up，若只记录点击点，拖拽会变成"按下、瞬移、抬起"，拖选、绘图、拖动窗口大多会失败。

### 5.9 精度之外的根本限制

时序精确不等于回放成功。纯坐标回放没有任何同步机制：录制时程序 200ms 响应完成，回放时冷启动需要 2 秒，则第 300ms 的那次点击会打在尚未出现的控件上，后续全部错位。

时间精度做到 0.1ms 也解决不了这个问题。真正的解法是等待条件（等窗口出现、等图像匹配），属于第一阶段范围之外。

---

## 6. 现有 run.ahk 分析

### 6.1 结构

文件 711 行，AHK v2，`#SingleInstance Force`，托盘图标 ico.ico。

关键全局状态：

- `BgGui` 背景层（全屏半透明，不销毁）
- `ContentGui` 内容层（切换视图时销毁重建）
- `Items` 条目数组，来源 items.txt
- `ViewMode` 取值 list 或 settings
- `CfgIconSize` / `CfgOpacity`，来源 config.txt

关键函数：

- `ToggleLauncher()` 显示隐藏切换，内含脚本修改时间检测与自动 Reload
- `ShowLauncher()` / `HideLauncher()` / `BuildContent()` / `RebuildContent()` / `DestroyContent()`
- `CreateListView()` 列表视图，含 ImageList 与图标提取
- `CreateSettingsView()` 设置视图，图标大小下拉框与透明度滑块
- `LoadConfig()` / `SaveConfig(iconSize, opacity)`
- `ExtractFileIcon(path, size)` 通过 SHGetFileInfoW 与 SHGetImageList 提取图标
- `Log(msg)` 每次调用执行一次 FileAppend

现有热键：

- `^1::ToggleLauncher()`
- `#HotIf IsLauncherActive()` 条件下的 `Escape::`

### 6.2 集成冲突项

| 项 | 说明 | 处理 |
| --- | --- | --- |
| 控制键自指 | 停止录制的热键必然出现在每份录制的末尾。不过滤则回放到最后会触发新一轮录制并覆盖数据；播放热键同理会导致回放中途自我重入 | 采集层必须过滤全部控制热键。热键可配置后，过滤名单由硬编码改为读取运行时变量 |
| 播放时自己录自己 | AHK 的 SendInput 只临时卸载 AHK 自己的钩子，无法卸载通过 DllCall 安装的低级钩子 | 播放期间不挂载录制钩子；所有钩子一律过滤 `LLKHF_INJECTED` 标志位 |
| Log 不能进钩子 | Log 每次执行一次 FileAppend，即打开、写入、关闭三次系统调用。鼠标移动 10ms 一次，钩子内写日志会拖垮系统 | 钩子回调内严禁任何 IO，只在开始录制、停止录制、播放结束三个时机记录日志 |
| Escape 热键复用 | 现有 Escape 在 `#HotIf IsLauncherActive()` 条件下，只在 Launcher 激活时生效 | 无冲突，不改动 |
| 自动重载逻辑 | `ToggleLauncher()` 检测 `A_ScriptFullPath` 修改时间自动 Reload。若功能拆到独立文件并 `#Include`，修改该文件不会触发重载 | 见待更新项 Q8 |
| DPI 感知 | run.ahk 目前靠 Gui 的 `-DPIScale` 处理界面缩放，未声明进程级 DPI 感知 | 录制与播放统一走物理虚拟屏幕坐标与 65535 归一化，不改动 run.ahk 现有 DPI 策略。详见 5.6 |
| 崩溃影响面 | 集成后录制模块出错会拖垮 Launcher | 钩子回调全程 try / catch 兜底，OnExit 中强制卸载钩子并释放悬挂按键 |

### 6.3 GUI 构建耗时估算

关注点在于：主线程被 GUI 操作阻塞期间，低级钩子回调无法执行，超过 LowLevelHooksTimeout 会被静默摘除。

当前实际配置：items.txt 共 8 个本地条目，config.txt 中 `IconSize=S`（64 像素，走 `SHIL_EXTRALARGE` 分支而非 256 像素的 JUMBO 分支）。

| 操作 | 热缓存估算 |
| --- | --- |
| ImageList_Create | 小于 1ms |
| SHGetFileInfoW 提取图标，8 次 | 每次 0.5 至 2ms，合计 4 至 16ms |
| SHGetImageList 与 GetIcon，8 次 | 每次小于 0.5ms，合计小于 4ms |
| ListView 创建与 8 次 Add | 3 至 8ms |
| 合计 | 约 10 至 30ms（热缓存），50 至 120ms（首次冷缓存） |

对照推测的 300ms 阈值，余量约 10 倍。日志旁证：launcher.log 中 `ShowLauncher` 与紧随其后的 `LoadConfig: final`（位于 `CreateListView()` 第一行）大多落在同一秒，连续开关间隔 1 至 2 秒。

另一项容易被忽略的开销：`Log()` 本身。一次 `ShowLauncher` 会写约 4 至 5 条日志（`GetMonitorAt` 对每个显示器各写一条，当前为双显示器），每条 0.5 至 3ms，合计 2 至 15ms，占本次 GUI 构建耗时的相当一部分。若杀毒软件对 .log 做实时扫描会显著放大。

会突破余量的情形：

| 触发条件 | 影响 |
| --- | --- |
| items.txt 条目增至 100 以上 | 线性放大 |
| IconSize 切换到 L（128 像素，走 JUMBO 256 分支） | 单个提取耗时上升 |
| 引入网络路径、U 盘或已断连的映射盘条目 | `FileExist` 与 `SHGetFileInfoW` 可能阻塞数秒，是唯一能轻易越过 1000ms 上限的情形 |

按当前用法（本地 exe、个位数条目），该风险不成立。

### 6.4 技术债务记录

launcher.log 已累积 44860 字节 / 788 行，无轮转机制。不影响单次写入耗时，但长期会持续增长。

---

## 7. 已定决策

| 项 | 结论 |
| --- | --- |
| 技术栈 | AutoHotkey v2，自行实现，不引入第三方软件或依赖 |
| 集成方式 | 集成进 run.ahk，同一进程、同一托盘、同一套热键 |
| 并发模型 | 单线程。多线程与多进程方案明确否决 |
| 录制时间源 | QueryPerformanceCounter，在钩子回调第一行取值 |
| 回放等待策略 | 对齐绝对时刻 `t0 + 偏移`，不逐条累加 Sleep |
| 落后处理 | 策略 A 无限追赶，保证事件顺序正确；播放循环内只做统计不做 IO，播放结束后一次性上报落后次数与最大落后量 |
| 精度目标 | 不出现秒级漂移即可。不使用忙等，不使用 timeBeginPeriod |
| 键盘自动重复 | 原样记录全部重复的 keydown |
| 悬挂按键 | 停止录制时扫描未配对的 down 并补写 up |
| 控制热键过滤 | 全部控制热键必须在采集层过滤 |
| Ctrl+1 冲突 | 不做防御。用户主动按下才触发且后果即时可见，不写保护逻辑。run.ahk 的 `^1::ToggleLauncher()` 不改动 |
| 录制期间 GUI 限制 | 不做限制。不禁止录制期间打开 Launcher |
| 钩子回调约束 | 全程 try / catch，回调内零 IO，OnExit 兜底清理 |
| 热键默认值 | Ctrl+2 开始 / 停止录制，Ctrl+3 播放 / 停止播放 |
| 热键配置 | 可配置，入口放在设置界面。支持组合键。冲突时提示并回滚 |

### 7.1 热键可配置带来的连带影响

该需求使 run.ahk 从"只追加代码"变为需要修改现有函数：

| 函数 | 需要的改动 |
| --- | --- |
| `LoadConfig()` | 新增热键相关键的解析 |
| `SaveConfig(iconSize, opacity)` | 函数签名与写入内容都要修改 |
| `CreateSettingsView()` | 新增输入控件，面板高度与 panelY 布局需要调整 |
| `OnSaveClick()` | 读取新控件、校验、调用 Hotkey() 重新注册 |

其他影响：

- 采集层的控制键过滤名单从硬编码变为读取运行时变量
- 热键变更后需要 `Hotkey(旧键, , "Off")` 再注册新键，或直接 `Reload()`
- 若代码分文件组织，设置界面在 run.ahk、热键逻辑在录制模块，两者需要约定接口函数

### 7.2 本轮确认的原待定项

以下为逐项确认的结论；相关早期分析与结构草案尚未全面同步。

| 项 | 已确认结论 |
| --- | --- |
| Q1 文件组织 | `run.ahk` 通过 `#Include recorder.ahk` 集成录制与回放，同一进程运行；`recorder.ahk` 保留独立启动能力；两者包含 `util.ahk`，共用日志和 `debug` 开关。 |
| Q10 采集方式 | 键盘、鼠标均使用 Raw Input，通过隐藏窗口接收 `WM_INPUT`；鼠标事件坐标通过 `GetCursorPos` 获取。不采用 InputHook、自建低级采集钩子或轮询采集；注册热键漏录问题暂缓处理。 |
| Q3 鼠标移动粒度 | 不记录或还原鼠标移动轨迹；只记录按下、抬起及滚轮事件发生时的坐标。回放时先定位再发送事件，不保证完整还原拖拽和悬停操作。 |
| Q4 文件及覆盖策略 | 固定保存到 `recording.tsv`；有效录制停止后直接覆盖，不弹确认、不自动编号。先完整写入 `recording.tmp`，再替换旧录制文件。 |
| Q5 起始与终止延迟 | 不保留首个有效操作之前、最后一个释放事件之后的空闲时间；操作之间的间隔和按住时长照常保留。每次回放先校验文件格式，校验耗时不计入回放时间轴；通过后按事件时间戳回放，不额外添加起始或终止等待。 |
| Q6 分辨率校验 | 文件中保留虚拟屏幕及显示器布局信息；回放前只校验文件格式，不比较当前分辨率或显示器布局，也不检查坐标范围。 |
| Q7 空录制保护 | 按 F1 进入待录制后，若没有有效操作，再按 F1 则取消；不生成新录制、不覆盖已有 `recording.tsv`，不显示状态提示。 |
| Q9 钩子心跳 | 当前使用 Raw Input，针对低级采集钩子的心跳检测不适用；不新增心跳定时器或报警逻辑。 |
| Q12 自动重复按键回放 | 原样记录重复 `keydown`，逐条按时间戳回放，不合并成批量输入，保留按住时长。 |

---

## 8. 待更新事项

**Q8 自动重载**

- 待办：移除 `run.ahk` 的自动重载逻辑，源码修改后统一手动重载。
- 已记入 [TODO.md](TODO.md)，尚未执行；当前代码仍保留原自动重载逻辑。

---

## 9. 待定问题

### 9.1 热键相关

**Q14a 输入方式**

| 选项 | 代价 |
| --- | --- |
| A 打字输入，用户在文本框内敲入字符 | 最简单；用户需了解语法；保存时用 try Hotkey() 校验 |
| B 按键录入，焦点在框内直接按下组合键 | 体验更好；需要 `msctls_hotkey32` 控件加 DllCall 收发 `HKM_GETHOTKEY` / `HKM_SETHOTKEY` 并转换为 AHK 语法，约 40 行 |

**Q14b 存储与显示格式**

| 选项 | 代价 |
| --- | --- |
| A 人类可读格式 `Ctrl+2` | 与现有 `IconSize=S` 风格一致；需要双向转换函数，约 20 行 |
| B AHK 原生格式 `^2` | 零转换成本；手工编辑 config.txt 时不直观 |

**Q14c 紧急停止热键** — 默认值待定（原提案 `Ctrl+Alt+Q`），是否同样做成可配置待定。

**Q15 冲突检测能力** — 见 4.3 的存疑点。语法非法与脚本内部重复可以检测；被其他程序全局占用的情况能否检测，取决于 AHK 在 RegisterHotKey 失败时是否静默回退到钩子，需实测确认。

---

## 10. 拟定的模块结构

以下为早期结构草案，尚未按已确认决策全面同步；Q1、Q10 的结论见 7.2。

```
配置区    热键定义、鼠标采样阈值、录制数据文件路径
状态区    运行状态（idle / rec / play）、事件数组、钩子句柄
热键      开始停止录制、播放、紧急停止
采集层    安装与卸载、键盘回调、鼠标回调
          键盘回调：过滤 INJECTED、过滤控制热键、记录 vk / sc / 扩展位 / down-up
          鼠标回调：移动按 10ms 与 3px 双阈值节流，按键与滚轮全量记录
录制层    开始录制（清空缓冲、记录基准时刻、记录屏幕元信息）
          停止录制（补齐悬挂 keyup、写入文件）
存储层    保存与加载，行式 TSV，坏行跳过并计数
回放层    播放（绝对时刻对齐、SendInput INPUT 结构、落后统计）
          中止（释放所有按下的键与鼠标按钮、卸载钩子）
工具      状态提示（ToolTip，短暂显示后消失）
清理      OnExit 兜底
```

### 10.1 数据格式草案

行式 TSV 文本。AHK 无内置 JSON，TSV 解析成本最低，且可肉眼查看与手工修改。

```
#V1  screen=3840x2160  vscreen=0,0,3840,2160  dpi=96
12     K  65   30  D              时间偏移(ms) 类型 vk sc down/up
35     M  1024 600                鼠标移动 绝对屏幕坐标
210    B  L    D   1024 600       鼠标按键 左键 down 坐标
980    W  120  1024 600           滚轮 delta 坐标
```

对外接口保持最小化，以便随时整块移除。

---

## 11. 已知限制

以下限制在第一阶段被接受，不做处理：

1. 分辨率或 DPI 变化后坐标会偏移，处理方式见 Q6。
2. 目标程序以管理员权限运行时，脚本必须同权限运行，否则输入被 UIPI 拦截。
3. 部分游戏使用 DirectInput 或 Raw Input 独占，SendInput 注入可能无效。
4. 输入法状态不还原，用中文输入法录制的内容回放结果不可预期。
5. 录制会记录明文按键，不应用于录制密码输入。
6. 纯坐标回放无同步机制，目标程序响应速度与录制时不同会导致后续操作错位。
7. 被其他程序全局占用的热键，冲突是否可检测存疑，见 4.3。
8. 低级钩子若被系统静默摘除，程序无法感知，缓解手段见 Q9。
