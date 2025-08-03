import unittest
from unittest.mock import patch, MagicMock

# Import the class you want to test
from main import Api

class TestApi(unittest.TestCase):

    @patch('main.database')  # Mock the entire database module in main.py
    def test_add_or_update_snippet_api(self, mock_database):
        """
        Tests if the Api.add_or_update_snippet method calls the
        database function with the correct data.
        """
        # Arrange
        api = Api()
        snippet_data = {'abbv': 'test', 'value': 'this is a test'}
        
        # Act
        api.add_or_update_snippet(snippet_data)
        
        # Assert
        # Check that the database function was called exactly once with the expected arguments.
        mock_database.add_or_update_snippet.assert_called_once_with('test', 'this is a test')

    @patch('main.database')
    def test_add_snippet_api_handles_missing_data(self, mock_database):
        """Tests that the API handles bad data gracefully."""
        api = Api()
        bad_data = {'abbv': 'test'} # Missing 'value'
        
        result = api.add_or_update_snippet(bad_data)
        
        # Assert that the database function was NOT called
        mock_database.add_or_update_snippet.assert_not_called()
        self.assertEqual(result['status'], 'error')