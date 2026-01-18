import os
import sys
import json
import io
import csv
import psycopg2

# Add project root to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from data_utils.utils import MinioClient

# Configuration
POSTGRES_CONF = {
    "host": os.getenv('POSTGRES_HOST', 'localhost'),
    "port": "5432",
    "database": "warehouse",
    "user": "warehouse_user",
    "password": "warehouse_pass"
}

# Load Config
CONF_PATH = os.getenv('CONFIG_PATH', '/opt/airflow/config/project_config.json')
if not os.path.exists(CONF_PATH):
    # Fallback for local
    CONF_PATH = os.path.join(os.path.dirname(__file__), '../config/project_config.json')

with open(CONF_PATH, 'r') as f:
    config = json.load(f)

# Map bucket prefix (source name) -> table name
TABLE_MAPPING = { source["name"]: source["table"] for source in config["sources"] }

def get_db_connection():
    return psycopg2.connect(**POSTGRES_CONF)

def json_to_csv_io(json_data):
    """Convert list of dicts to CSV-like StringIO object."""
    if not json_data:
        return None
    
    headers = json_data[0].keys()
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=headers)
    writer.writeheader()
    writer.writerows(json_data)
    output.seek(0)
    return output

def load_bronze():
    minio = MinioClient()
    conn = get_db_connection()
    cur = conn.cursor()
    
    print("Starting Bronze Load...")
    
    try:
        # 0. Ensure Bronze Schema and Tables Exist
        print("Ensuring Bronze schema and tables exist...")
        
        # Determine scripts directory (handle Docker vs Local)
        base_dir = os.path.dirname(__file__)
        if os.path.exists('/opt/airflow/scripts'):
            scripts_dir = '/opt/airflow/scripts/bronze'
        else:
            scripts_dir = os.path.abspath(os.path.join(base_dir, '../scripts/bronze'))
            
        schema_sql = os.path.join(scripts_dir, '01_create_bronze_schema.sql')
        tables_sql = os.path.join(scripts_dir, '02_create_bronze_tables.sql')

        for sql_file in [schema_sql, tables_sql]:
            if os.path.exists(sql_file):
                print(f"Executing {sql_file}...")
                with open(sql_file, 'r') as f:
                    cur.execute(f.read())
                    conn.commit()
            else:
                print(f"Error: SQL file not found at {sql_file}")
                raise FileNotFoundError(f"Missing {sql_file}")

        # Iterate over mapped tables/buckets
        for bucket_prefix, table_name in TABLE_MAPPING.items():
            # Truncate table before loading to prevent duplicates on rerun
            print(f"Truncating {table_name}...")
            cur.execute(f"TRUNCATE TABLE {table_name} CASCADE")
            conn.commit()

            objects = minio.client.list_objects("raw", prefix=bucket_prefix, recursive=True)
            
            for obj in objects:
                print(f"Processing {obj.object_name}...")
                
                # Get object content
                response = minio.client.get_object("raw", obj.object_name)
                data = json.loads(response.read())
                
                if not data:
                    print(f"Empty file: {obj.object_name}")
                    continue
                
                # Convert to CSV for COPY
                csv_io = json_to_csv_io(data)
                
                # Use COPY expert
                # We need to skip header, so we use COPY ... WITH CSV HEADER
                sql_limit = f"COPY {table_name} FROM STDIN WITH CSV HEADER"
                cur.copy_expert(sql_limit, csv_io)
                
                conn.commit()
                print(f"Loaded {len(data)} rows into {table_name}")
                
                # Remove processed object to avoid re-procesing duplicates in future runs
                minio.client.remove_object("raw", obj.object_name)
                print(f"Deleted {obj.object_name} from MinIO")
                
    except Exception as e:
        print(f"Error loading bronze: {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    load_bronze()
