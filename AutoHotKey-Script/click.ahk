F1::
{
    toggle := !toggle
    if (toggle)
        SetTimer ClickMouse, 10
    else
        SetTimer ClickMouse, Off
}
return

ClickMouse:
{
    Click 10
}
return
