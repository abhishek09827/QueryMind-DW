from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
import sys

# Add project root to sys path so we can import modules if needed
sys.path.append('/opt/airflow')

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'generic_data_pipeline',
    default_args=default_args,
    description='End-to-End Data Pipeline: Kafka -> MinIO -> Postgres -> dbt',
    schedule_interval=timedelta(days=1),
    catchup=False
)

# 1. Ingest Data (Producer)
# Assuming 'datasets' and 'kafka' are mounted
t1_produce = BashOperator(
    task_id='ingest_csv_to_kafka',
    bash_command='python /opt/airflow/kafka/producer.py',
    dag=dag
)

# 2. Consume Data (Consumer)
# Run for 60 seconds to process the batch
t2_consume = BashOperator(
    task_id='consume_kafka_to_minio',
    bash_command='timeout 60s python /opt/airflow/kafka/consumer.py || true',
    dag=dag
)

# 3. Load to Postgres
t3_load = BashOperator(
    task_id='load_minio_to_postgres',
    bash_command='python /opt/airflow/sql/load_bronze.py',
    dag=dag
)

# 4. dbt Transformations
t4_dbt_run = BashOperator(
    task_id='dbt_run',
    bash_command='cd /opt/airflow/dbt && dbt run',
    dag=dag
)

t5_dbt_test = BashOperator(
    task_id='dbt_test',
    bash_command='cd /opt/airflow/dbt && dbt test',
    dag=dag
)

# Dependencies
t1_produce >> t2_consume >> t3_load >> t4_dbt_run >> t5_dbt_test
