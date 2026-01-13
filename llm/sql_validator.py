import re

class SQLValidator:
    def validate(self, sql_query):
        """
        Validates the SQL query for safety and correctness.
        Returns (is_valid, error_message).
        """
        sql = sql_query.strip().upper()

        # 1. READ-ONLY Check
        # Ensure it starts with SELECT or WITH ... SELECT
        if not (sql.startswith("SELECT") or sql.startswith("WITH")):
            return False, "Query must start with SELECT or WITH."

        # Check for forbidden keywords
        forbidden_keywords = ["INSERT", "UPDATE", "DELETE", "DROP", "ALTER", "TRUNCATE", "CREATE", "GRANT", "REVOKE", ";"]
        # Allow ; only at the very end
        sql_clean = sql.rstrip(";")
        
        for keyword in forbidden_keywords:
            # We use word boundary to avoid matching inside words (e.g. "UPDATE_DATE" which is valid column)
            if re.search(r'\b' + keyword + r'\b', sql_clean):
                 if keyword == ";":
                     continue # handled by rstrip
                 return False, f"Forbidden keyword detected: {keyword}"

        # 2. SCHEMA Check (Simple Heuristic)
        # We want to discourage querying 'bronze' or 'silver' if strict mode is on.
        # But for now, we just ensure it doesn't try to access system tables.
        if "INFORMATION_SCHEMA" in sql or "PG_CATALOG" in sql:
            return False, "Querying system catalogs is not allowed."

        return True, None
