import pywebview
import threading
import keyboard
import time
import database
import hotkeys

# Global window objects remain the same
search_window = None
settings_window = None


class Api:
    """
    API class exposed to the JavaScript frontend. This is the bridge between
    Python and the UI.
    """
    # ... (all methods inside the Api class remain exactly the same) ...
    def search_snippets(self, text):
        return database.search_snippets(text)

    def get_all_snippets(self):
        return database.search_snippets()

    def paste_text(self, abbv):
        global search_window
        print(f"Pasting snippet for '{abbv}'")
        if search_window:
            search_window.hide()
        value_to_paste = database.get_and_increment_snippet(abbv)
        if value_to_paste:
            time.sleep(0.1)
            keyboard.write(value_to_paste)

    def add_or_update_snippet(self, data):
        abbv = data.get("abbv")
        value = data.get("value")
        if abbv and value:
            return database.add_or_update_snippet(abbv, value)
        return {"status": "error", "message": "Missing abbreviation or value."}

    def delete_snippet(self, abbv):
        return database.delete_snippet(abbv)

    def get_translations(self):
        return database.get_translations("en")

    def close_search_window(self):
        if search_window:
            search_window.hide()

    def open_settings(self):
        global settings_window
        if settings_window:
            settings_window.show()
        else:
            settings_window = pywebview.create_window(
                "Tylex Settings",
                "frontend/settings.html",
                js_api=self,
                width=800,
                height=600,
                resizable=True,
            )

def show_search_window():
    """Callback function for the expand hotkey."""
    if search_window:
        search_window.show()

# ✅ NEW: All startup logic is now wrapped in this function
def start_app():
    """Initializes and starts the Tylex application."""
    global search_window # Allow this function to assign to the global variable
    
    print("Starting Tylex...")
    database.run_migrations()
    api = Api()

    search_window = pywebview.create_window(
        "Tylex Expander",
        "frontend/index.html",
        js_api=api,
        width=600,
        height=400,
        resizable=False,
        frameless=True,
        on_top=True,
        hidden=True,
    )

    hotkey_thread = threading.Thread(
        target=hotkeys.start_listener,
        args=(show_search_window, api.open_settings),
        daemon=True,
    )
    hotkey_thread.start()

    pywebview.start(debug=True)
    print("Tylex stopped.")


# ✅ MODIFIED: This block now just calls the main startup function.
if __name__ == "__main__":
    start_app()