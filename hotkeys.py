# hotkeys.py
from pynput import keyboard

def start_listener(expand_callback, settings_callback):
    """
    Registers global hotkeys using pynput:
      - Ctrl+Alt+P → expand_callback
      - Ctrl+Alt+Shift+P → settings_callback
    Ensures Ctrl+Alt+Shift+P doesn't also trigger expand.
    """
    expand_combo   = '<ctrl>+<alt>+p'
    settings_combo = '<ctrl>+<alt>+<shift>+p'

    # track shift state
    shift_pressed = False

    def on_press(key):
        nonlocal shift_pressed
        if key in (keyboard.Key.shift, keyboard.Key.shift_r, keyboard.Key.shift_l):
            shift_pressed = True

    def on_release(key):
        nonlocal shift_pressed
        if key in (keyboard.Key.shift, keyboard.Key.shift_r, keyboard.Key.shift_l):
            shift_pressed = False

    def on_activate_expand():
        # ignore if shift is down
        if shift_pressed:
            return
        print(f"Hotkey '{expand_combo}' activated!")
        expand_callback()

    def on_activate_settings():
        print(f"Hotkey '{settings_combo}' activated!")
        settings_callback()

    # GlobalHotKeys for the two combos
    hotkey_map = {
            expand_combo: on_activate_expand,
            settings_combo: on_activate_settings,
            }
    listener = keyboard.GlobalHotKeys(hotkey_map)

    # separate listener just to keep shift_pressed accurate
    state_listener = keyboard.Listener(on_press=on_press, on_release=on_release)
    state_listener.daemon = True
    state_listener.start()

    print("Starting hotkey listener...")
    print(f"- Expand:  Ctrl + Alt + P")
    print(f"- Settings: Ctrl + Alt + Shift + P")

    listener.start()
    return listener

