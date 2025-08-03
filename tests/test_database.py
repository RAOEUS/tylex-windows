import unittest
import sqlite3
import database

class TestDatabase(unittest.TestCase):

    def setUp(self):
        self.conn = sqlite3.connect(":memory:")
        self.conn.row_factory = sqlite3.Row
        database.run_migrations(conn=self.conn)
        self.conn.executemany(
            "INSERT INTO snippets (abbv, value, usage_count) VALUES (?, ?, ?)",
            [
                ('eml', 'user@example.com', 10),
                ('sig', '- My Signature', 5),
                ('py', 'print("Hello, Python!")', 20)
            ]
        )
        self.conn.commit()

    def tearDown(self):
        self.conn.close()

    def test_search_snippets_all(self):
        results = database.search_snippets("", conn=self.conn)
        self.assertEqual(len(results), 3)
        self.assertEqual(results[0]['abbv'], 'py')
        self.assertEqual(results[1]['abbv'], 'eml')

    def test_search_snippets_filtered(self):
        results = database.search_snippets("com", conn=self.conn)
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['abbv'], 'eml')

    def test_add_new_snippet(self):
        database.add_or_update_snippet('new', 'a new value', conn=self.conn)
        results = database.search_snippets('new', conn=self.conn)
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['value'], 'a new value')

    def test_update_existing_snippet(self):
        database.add_or_update_snippet('eml', 'new-email@example.com', conn=self.conn)
        row = self.conn.execute("SELECT value, usage_count FROM snippets WHERE abbv = 'eml'").fetchone()
        self.assertEqual(row['value'], 'new-email@example.com')
        self.assertEqual(row['usage_count'], 11)

    def test_get_and_increment_snippet(self):
        value = database.get_and_increment_snippet('sig', conn=self.conn)
        self.assertEqual(value, '- My Signature')
        new_count = self.conn.execute("SELECT usage_count FROM snippets WHERE abbv = 'sig'").fetchone()['usage_count']
        self.assertEqual(new_count, 6)

    def test_delete_snippet(self):
        database.delete_snippet('eml', conn=self.conn)
        results = database.search_snippets('eml', conn=self.conn)
        self.assertEqual(len(results), 0)

    def test_get_translations(self):
        translations = database.get_translations('en', conn=self.conn)
        self.assertIn('app_title', translations)
        self.assertEqual(translations['app_title'], 'Tylex Snippets')

if __name__ == '__main__':
    unittest.main()