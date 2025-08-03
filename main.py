import webview
import time
import database
import hotkeys
from pynput.keyboard import Controller, Key
import threading
import logging
import os
from pathlib import Path # Import Path for proper URL formatting

# Get the absolute path to the directory this script is in
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(threadName)s - %(message)s')

search_window = None
settings_window = None
api_instance = None

def on_settings_closed():
    global settings_window
    logging.info("Settings window closed by user.")
    settings_window = None

def on_search_closed():
    global search_window
    logging.info("Search window closed by user.")
    search_window = None

class Api:
    def search_snippets(self, text): return database.search_snippets(text)
    def get_all_snippets(self): return database.search_snippets()
    def paste_text(self, abbv, delay_ms=20):
        global search_window
        if search_window:
            search_window.hide()
        text = database.get_and_increment_snippet(abbv)
        if not text:
            return
        kb = Controller()
        # map symbols that require shift → key
        SHIFT_CHARS = {
            '~':'`','!':'1','@':'2','#':'3','$':'4','%':'5',
            '^':'6','&':'7','*':'8','(':'9',')':'0','_':'-',
            '+':'=','{':'[','}':']','|':'\\',':':';','"':"'",'<':',',
            '>':'.','?':'/'
        }
        for ch in text:
            if ch.isupper():
                kb.press(Key.shift)
                kb.press(ch.lower())
                kb.release(ch.lower())
                kb.release(Key.shift)
            elif ch in SHIFT_CHARS:
                kb.press(Key.shift)
                kb.press(SHIFT_CHARS[ch])
                kb.release(SHIFT_CHARS[ch])
                kb.release(Key.shift)
            else:
                kb.press(ch)
                kb.release(ch)
            # pause between characters
            time.sleep(delay_ms / 1000.0)
    def add_or_update_snippet(self, data):
        abbv = data.get("abbv"); value = data.get("value")
        if abbv and value: return database.add_or_update_snippet(abbv, value)
        return {"status": "error", "message": "Missing abbreviation or value."}
    def delete_snippet(self, abbv): return database.delete_snippet(abbv)
    def get_translations(self): return database.get_translations("en")
    def close_search_window(self):
        if search_window:
            search_window.destroy()
    def reset_counts(self):
        """Reset all snippets’ usage counts to zero."""
        return database.reset_usage_counts()


# ✅ MODIFIED: The functions to open windows are now in the Api class
# to ensure they are independent and correctly managed.
    def show_search_window(self):
        global search_window
        logging.info("show_search_window called.")
        
        if search_window is None:
            logging.info("Creating new search window.")
            # Format the path as a file URL
            search_html_path = Path(os.path.join(BASE_DIR, 'frontend', 'index.html')).as_uri()
            search_window = webview.create_window(
                "Tylex Expander", search_html_path, js_api=self,
                width=1000, height=800, on_top=True
            )
            search_window.events.closed += on_search_closed
        else:
            logging.info("Showing existing search window.")
            search_window.show()

    def open_settings_window(self):
        global settings_window
        logging.info("open_settings_window called.")
        if settings_window is None:
            logging.info("Creating new settings window.")
            # Format the path as a file URL
            settings_html_path = Path(os.path.join(BASE_DIR, 'frontend', 'settings.html')).as_uri()
            settings_window = webview.create_window(
                "Tylex Settings", settings_html_path, js_api=self,
                width=1000, height=800, frameless=True, on_top=True
            )
            settings_window.events.closed += on_settings_closed
        else:
            logging.info("Showing existing settings window.")
            settings_window.show()

def start_app():
    global api_instance
    logging.info("Starting Tylex application...")
    database.run_migrations()
    api_instance = Api()

    # Pass the API methods directly to the listener
    listener_thread = threading.Thread(
        target=hotkeys.start_listener,
        args=(api_instance.show_search_window, api_instance.open_settings_window),
        daemon=True
    )
    listener_thread.start()
    
    main_window = webview.create_window("Tylex Backend", hidden=True)
    webview.start()
    
    logging.info("Tylex stopped.")

if __name__ == "__main__":
    start_app()
