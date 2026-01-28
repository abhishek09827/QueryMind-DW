# 🔄 System Lifecycle & Workflow Guide

This document explains "what happens when" in the QueryMind system. It maps the project folders to the runtime lifecycle, from the moment you run `docker-compose up` to when a user asks a question.

---

## 🚀 Part 1: The Boot Sequence (Startup)
*Which folders initiate when you turn the system on.*

When you run `docker-compose up`, services start in a specific order defined by dependencies.

| T+ (Time) | Service | Active Folder/File | What Happens? |
| :--- | :--- | :--- | :--- |
| **0s** | **Postgres** | `init_db.sql` | Database starts. the `init_db.sql` file is **automatically executed** to create the `warehouse` database and users. |
| **5s** | **MinIO** | *Internal* | Object storage starts. Ready to accept files on port 9000. |
| **5s** | **Kafka** | `kafka/` (Config) | Message broker starts. Zookeeper coordinates the cluster. |
| **10s** | **Airflow Init** | `airflow/` | Runs ephemeral tasks: upgrades the Airflow internal DB and creates the `admin` user. **Exits** once done. |
| **30s** | **Airflow Scheduler** | `airflow/dags/` | The "Heartbeat" starts. It scans the `airflow/dags/` folder every few seconds looking for Python files (`etl_pipeline.py`). |
| **35s** | **Streamlit** | `app/` | *Manual Start*: You run `streamlit run app/streamlit_app.py`. It connects to Postgres and waits for user input. |

---

## 🔄 Part 2: The App Workflows (Runtime)
*How the code executes during operation.*

### Workflow A: The Data Pipeline (Background Loop)
**Trigger:** Scheduled by Airflow (e.g., Daily) or Triggered Manually.

1.  **Ingestion (Producer)**
    *   **Folder:** `kafka/`
    *   **Action:** Airflow runs `kafka/producer.py`. It reads raw data (e.g., CSVs) and pushes messages to the **Kafka Topic**.

2.  **Staging (Consumer)**
    *   **Folder:** `kafka/` & `minio/`
    *   **Action:** Airflow runs `kafka/consumer.py`. It listens to Kafka, batches messages, and saves them as JSON/Parquet files in **MinIO** (Data Lake).

3.  **Loading (Bronze)**
    *   **Folder:** `sql/`
    *   **Action:** Airflow runs `sql/load_bronze.py`. It reads files from MinIO and inserts raw rows into **Postgres** (Bronze Tables).

4.  **Transformation (Silver/Gold)**
    *   **Folder:** `dbt/`
    *   **Action:** Airflow runs `dbt run`.
    *   *Logic:* Postgres performs SQL transformations defined in `dbt/models/`. Raw data is cleaned (Silver) and aggregated (Gold).
    *   **Result:** Analytics-ready tables in Postgres.

---

### Workflow B: The User Query (Interactive Loop)
**Trigger:** User clicks "Run Analysis" on the Streamlit UI.

1.  **Question Received**
    *   **Folder:** `app/`
    *   **Action:** `streamlit_app.py` captures the string "How many orders in June?".

2.  **Schema Lookup**
    *   **Folder:** `llm/`
    *   **Action:** `schema_loader.py` reads `dbt/target/manifest.json`. It finds the relevant table names (e.g., `fact_orders`) to help the AI.

3.  **Code Generation**
    *   **Folder:** `llm/`
    *   **Action:** `sql_generator.py` sends the [Schema + Question] to the LLM (OpenAI/Gemini).
    *   **Return:** The LLM returns a SQL Query: `SELECT COUNT(*) FROM...`

4.  **Execution & Answer**
    *   **Folder:** `llm/`
    *   **Action:**
        *   `executor.py` runs the SQL against the **Postgres Gold Tables**.
        *   `explainer.py` takes the result (e.g., "500") and writes a natural language sentence.
