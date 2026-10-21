#Persistent
CoordMode, Mouse, Screen

SetTimer, ShowPos, 100
return

ShowPos:
MouseGetPos, x, y
ToolTip, % "X: " x " Y: " y
return