from llm.sql_validator import SQLValidator
from llm.prompt_templates import get_system_message

def test_sql_validator_valid():
    validator = SQLValidator()
    valid_query = "SELECT * FROM gold.orders LIMIT 10"
    is_valid, msg = validator.validate(valid_query)
    assert is_valid is True
    assert msg is None

def test_sql_validator_with_clause():
    validator = SQLValidator()
    valid_query = "WITH temp AS (SELECT * FROM gold.orders) SELECT * FROM temp"
    is_valid, msg = validator.validate(valid_query)
    assert is_valid is True

def test_sql_validator_invalid_drop():
    validator = SQLValidator()
    # Posing as a valid query that tries to inject a DROP
    invalid_query = "SELECT * FROM gold.orders; DROP TABLE gold.orders"
    is_valid, msg = validator.validate(invalid_query)
    assert is_valid is False
    assert "Forbidden keyword" in msg

def test_sql_validator_invalid_update():
    validator = SQLValidator()
    # Posing as a valid query that tries to inject an UPDATE
    invalid_query = "SELECT * FROM gold.orders; UPDATE gold.orders SET status = 'shipped'"
    is_valid, msg = validator.validate(invalid_query)
    assert is_valid is False
    assert "Forbidden keyword" in msg

def test_sql_validator_system_tables():
    validator = SQLValidator()
    invalid_query = "SELECT * FROM INFORMATION_SCHEMA.TABLES"
    is_valid, msg = validator.validate(invalid_query)
    assert is_valid is False
    assert "Querying system catalogs" in msg

def test_get_system_message_prompts():
    mock_schema = [
        {
            "schema": "gold",
            "table_name": "test_table",
            "description": "A test table",
            "columns": [
                {"name": "id", "type": "INTEGER", "description": "Primary Key"},
                {"name": "val", "type": "VARCHAR", "description": "A value"}
            ]
        }
    ]
    prompt = get_system_message(mock_schema)
    assert "Table: gold.test_table" in prompt
    assert "A test table" in prompt
    assert "- id (INTEGER): Primary Key" in prompt
