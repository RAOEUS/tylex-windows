#Requires AutoHotkey v2.0

; --- Configuration ---
configFile := A_ScriptDir "\config.ini"
if not FileExist(configFile)
    configFile := A_AppData "\Tylex\config.ini"

; Read hotkeys from the config file ONCE at startup.
expandHotkey := IniRead(configFile, "Hotkeys", "Expand", "#z")
addHotkey := IniRead(configFile, "Hotkeys", "Add", "#+z")


; --- Hotkey Actions ---
ExpandAction(*) {
    Run("Expand-Text.exe")
}
AddAction(*) {
    Run("Add-Text.exe")
}


; --- Create Hotkeys Statically ---
Hotkey(expandHotkey, ExpandAction)
Hotkey(addHotkey, AddAction)