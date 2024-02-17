;#IfWinActive,ahk_class D3 Main Window Class

;按F2启动或暂停宏
;按住鼠标右键扫射，并自动按烟雾弹
;松开鼠标右键自动打追踪箭，并补充复仇，战宠，蓄势待发


SetKeyDelay,20
SetMouseDelay,20

v_Enable=0 ;宏开关变量
v_Tab=0 ;按Tab查看小地图暂停宏变量
v_RightDown=0

$F2:: ;开关键，鼠标有侧键的玩家，可以将F2换成鼠标侧键对应的代码XButton1、XButton2
{
    v_Enable:=!v_Enable
    If (v_Enable=0)
    {
        v_RightDown=0
        Send {w up}
        SetTimer, Label1, off ;关闭技能1连点计时器
        SetTimer, Label2, off ;关闭技能2连点计时器
        SetTimer, Label3, off ;关闭技能3连点计时器
        SetTimer, Label4, off ;关闭技能4连点计时器
        SetTimer, Label5, off ;药水
        SetTimer, MouseLButton, off ;关闭左键连点计时器
        Click, Up, Right
    }
    Else
    {
        v_RightDown=0
        Send {w down}
        SetTimer, Label1, 1000 ;动作条技能1键600毫秒连点，600可改动
        SetTimer, Label2, 1000 ;动作条技能2键600毫秒连点，600可改动
        SetTimer, Label3, 1000 ;动作条技能3键600毫秒连点，600可改动
        SetTimer, Label4, off ;动作条技能4键600毫秒连点，600可改动
        SetTimer, Label5, 1000 ;药水
        SetTimer, MouseLButton, 150 ;鼠标左键150毫秒连点，150可改动
        Click, Up, Right
    }
}
Return

$F3:: ;开关键，鼠标有侧键的玩家，可以将F2换成鼠标侧键对应的代码XButton1、XButton2
{
    If (v_Enable)
    {
        v_RightDown:=!v_RightDown
        if (v_RightDown=0)
        {
            Send {w down}
            SetTimer, Label4, off
            SetTimer, MouseLButton, 150
            Click, Up, Right
        }
        Else
        {
            Send {w up}
            SetTimer, Label4, 100
            SetTimer, MouseLButton, off
            Click, Down, Right
        }
    }
}
Return

;~*RButton:: ;按住右键暂停123和左键连点，保持强制移动
;If (v_Enable)
;{
;    Send {w up}
;    SetTimer, Label1, off
;    SetTimer, Label2, off
;    SetTimer, Label3, off
;    SetTimer, Label4, 100
;    SetTimer, MouseLButton, off
;    Send {x down}
;}
;Return
;
;*RButton Up:: ;松开右键恢复123和左键连点，开启强制攻击
;If (v_Enable)
;{
;    Send {w down}
;    SetTimer, Label1, 600
;    SetTimer, Label2, 600
;    SetTimer, Label3, 600
;    SetTimer, Label4, off
;    SetTimer, MouseLButton, 150
;    Send {x up}
;}
;Return

Label1:
{
    Send {1} ;动作条技能1键对应按键
    Return
}

Label2:
{
    Send {2} ;动作条技能2键对应按键
    Return
}

Label3:
{
    Send {3} ;动作条技能3键对应按键
    Return
}

Label4:
{
    Send {4} ;动作条技能4键对应按键
    Return
}

Label5:
{
    Send {q} ;药水
    Return
}

MouseLButton:
{
    Click ;点击鼠标左键，对应主要技能
}
Return

