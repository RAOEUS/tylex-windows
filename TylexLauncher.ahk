#Requires AutoHotkey v2.0

; --- Configuration ---
; Define global variables that will hold the hotkey strings
global expandHotkey := ""
global addHotkey := ""

; Define the path to the config file
global configFile := A_ScriptDir "\config.ini"

if not FileExist(configFile)
    configFile := A_AppData "\Tylex\config.ini"

; --- Hotkey Actions ---
; The functions that are called when a hotkey is pressed
ExpandAction(*) {
    Run("Expand-Text.exe")
}

AddAction(*) {
    Run("Add-Text.exe")
}

; --- Hotkey Reload Logic ---
; This function reads the config and applies the hotkeys.
ReloadHotkeys(*) {
    ; Deactivate the old hotkeys before reading new ones
    if (expandHotkey != "")
        Hotkey(expandHotkey, "Off")
    if (addHotkey != "")
        Hotkey(addHotkey, "Off")
        
    ; Re-read the values from the config file, with defaults
    expandHotkey := IniRead(configFile, "Hotkeys", "Expand", "#z")
    addHotkey := IniRead(configFile, "Hotkeys", "Add", "#+z")

    ; Activate the hotkeys with the new values
    Hotkey(expandHotkey, ExpandAction)
    Hotkey(addHotkey, AddAction)
}

; --- Initial Script Start ---
; 1. Run the reload function once on startup to set the initial hotkeys
ReloadHotkeys()

; 2. Create a monitor that will call ReloadHotkeys whenever config.ini is saved
monitor := FileChangeMonitor(configFile, ReloadHotkeys)
monitor.Start() 