import psycopg2
import pandas as pd
import os

class QueryExecutor:
    def __init__(self):
        # Use existing config if possible or env vars
        self.host = os.getenv('POSTGRES_HOST', 'localhost')
        self.port = os.getenv('POSTGRES_PORT', '5432')
        self.database = os.getenv('POSTGRES_DB', 'warehouse')
        self.user = os.getenv('POSTGRES_USER', 'warehouse_user')
        self.password = os.getenv('POSTGRES_PASSWORD', 'warehouse_pass')

    def execute(self, sql):
        """
        Executes the SQL query and returns a Pandas DataFrame.
        """
        try:
            conn = psycopg2.connect(
                host=self.host,
                port=self.port,
                database=self.database,
                user=self.user,
                password=self.password
            )
            
            # Use pandas to read sql
            df = pd.read_sql_query(sql, conn)
            conn.close()
            return df, None
        except Exception as e:
            return None, str(e)
