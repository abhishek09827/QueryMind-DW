FROM apache/airflow:2.7.1
COPY kafka/requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt
RUN pip install --no-cache-dir dbt-postgres
