import keyboard
import threading

def start_listener(expand_callback, settings_callback):
    expand_hotkey = "win+z"
    settings_hotkey = "win+shift+z"

    keyboard.add_hotkey(expand_hotkey, expand_callback)
    keyboard.add_hotkey(settings_hotkey, settings_callback)
    
    print(f"Listening for hotkeys...")
    print(f"- Expand: {expand_hotkey}")
    print(f"- Settings: {settings_hotkey}")