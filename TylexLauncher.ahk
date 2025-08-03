; Tylex.ahk
; Super/Windows key is "#"
; z is the trigger key
; Shift is "+"

; Super + z to run the expander script
#z::
{
    Run("Expand-Text.exe")
}

; Super + Shift + z to run the add script
#+z::
{
    Run("Add-Text.exe")
}