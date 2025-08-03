; Super/Windows key is "#"
; z is the trigger key
; Shift is "+"

; Super + z to run the expander script
#z::
{
    ; Run the compiled script hidden, capture its process object
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec("Expand-Text.exe")

    ; Read the standard output from the script after it finishes
    result := exec.StdOut.ReadAll()

    ; Use AHK's more reliable SendInput to type the result
    SendInput(result)
}

; Super + Shift + z to run the add script
#+z::
{
    ; Run the "Add" script, which has its own GUI
    Run("Add-Text.exe")
}
