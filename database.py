import sqlite3
import os

DB_FILE = "tylex.db"

# --- Migrations ---
# (Migrations dictionary remains the same)
migrations = {
    1: """
    CREATE TABLE snippets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        abbv TEXT NOT NULL UNIQUE,
        value TEXT NOT NULL,
        usage_count INTEGER NOT NULL DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    """,
    2: """
    CREATE TABLE translations (
        key TEXT NOT NULL,
        lang TEXT NOT NULL,
        text TEXT NOT NULL,
        PRIMARY KEY (key, lang)
    );
    """,
    3: """
    INSERT INTO translations (key, lang, text) VALUES
        ('app_title', 'en', 'Tylex Snippets'),
        ('search_placeholder', 'en', 'Search snippets...'),
        ('settings_title', 'en', 'Tylex Settings & Snippets'),
        ('manage_snippets', 'en', 'Manage Snippets'),
        ('add_new_snippet', 'en', 'Add New Snippet'),
        ('abbreviation_label', 'en', 'Abbreviation:'),
        ('expansion_label', 'en', 'Expansion Text:'),
        ('save_button', 'en', 'Save Snippet'),
        ('delete_button', 'en', 'Delete');
    """,
}


def get_db_connection():
    """Establishes a new connection to the database file."""
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn


def run_migrations(conn=None):
    """Checks the current database version and applies all new migrations.
    If a connection is provided, it uses it; otherwise, it creates a new one.
    """
    close_conn = False
    if conn is None:
        conn = get_db_connection()
        close_conn = True

    cursor = conn.cursor()
    current_version = cursor.execute("PRAGMA user_version").fetchone()[0]
    latest_version = max(migrations.keys()) if migrations else 0

    if current_version < latest_version:
        print(f"Applying migrations to database version {current_version}...")
        for version in sorted(migrations.keys()):
            if version > current_version:
                with conn:
                    conn.executescript(migrations[version])
                    conn.execute(f"PRAGMA user_version = {version}")
        print("Database migrations complete.")

    if close_conn:
        conn.close()


# --- Refactored API Functions ---


def search_snippets(filter_text="", conn=None):
    close_conn = False
    if conn is None:
        conn = get_db_connection()
        close_conn = True

    query = """
    SELECT abbv, value, usage_count FROM snippets
    WHERE abbv LIKE ? OR value LIKE ?
    ORDER BY usage_count DESC, abbv ASC
    LIMIT 20;
    """
    results = conn.execute(query, (f"%{filter_text}%", f"%{filter_text}%")).fetchall()

    if close_conn:
        conn.close()

    return [dict(row) for row in results]


def get_and_increment_snippet(abbv, conn=None):
    close_conn = False
    if conn is None:
        conn = get_db_connection()
        close_conn = True

    value = None
    with conn:
        row = conn.execute(
            "SELECT value FROM snippets WHERE abbv = ?", (abbv,)
        ).fetchone()
        if row:
            value = row["value"]
            conn.execute(
                "UPDATE snippets SET usage_count = usage_count + 1 WHERE abbv = ?",
                (abbv,),
            )

    if close_conn:
        conn.close()

    return value


def add_or_update_snippet(abbv, value, conn=None):
    close_conn = False
    if conn is None:
        conn = get_db_connection()
        close_conn = True

    with conn:
        conn.execute(
            """
        INSERT INTO snippets (abbv, value) VALUES (?, ?)
        ON CONFLICT(abbv) DO UPDATE SET value = ?, usage_count = usage_count + 1;
        """,
            (abbv, value, value),
        )

    if close_conn:
        conn.close()

    print(f"Saved snippet: {abbv}")
    return {"status": "success", "abbv": abbv}


def delete_snippet(abbv, conn=None):
    close_conn = False
    if conn is None:
        conn = get_db_connection()
        close_conn = True

    with conn:
        conn.execute("DELETE FROM snippets WHERE abbv = ?", (abbv,))

    if close_conn:
        conn.close()

    print(f"Deleted snippet: {abbv}")
    return {"status": "success"}


def get_translations(lang="en", conn=None):
    close_conn = False
    if conn is None:
        conn = get_db_connection()
        close_conn = True

    rows = conn.execute(
        "SELECT key, text FROM translations WHERE lang = ?", (lang,)
    ).fetchall()

    if close_conn:
        conn.close()

    return {row["key"]: row["text"] for row in rows}

def reset_usage_counts(conn=None):
    close_conn = False
    if conn is None:
        conn = get_db_connection()
        close_conn = True
    with conn:
        conn.execute("UPDATE snippets SET usage_count = 0")
    if close_conn:
        conn.close()
    return {"status": "success"}
