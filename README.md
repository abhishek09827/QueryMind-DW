# 🚀 QueryMind: Data Warehouse & AI Analytics Platform

[![Olist E-Commerce](https://img.shields.io/badge/Dataset-Olist%20E--Commerce-blue.svg)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
[![Architecture](https://img.shields.io/badge/Architecture-Medallion-orange.svg)](https://www.databricks.com/glossary/medallion)
[![Stack](https://img.shields.io/badge/Stack-Postgres%20%7C%20dbt%20%7C%20Airflow%20%7C%20Kafka%20%7C%20MinIO-green.svg)]()
[![CI Status](https://github.com/username/repo/actions/workflows/ci.yml/badge.svg)](https://github.com/username/repo/actions)

Production-grade data platform implementing a **Medallion Architecture** (Bronze/Silver/Gold) on the Olist Brazilian E-Commerce dataset. This project integrates a traditional SQL warehouse with a modern data stack, featuring an end-to-end ELT pipeline, LLM-powered analytics (**QueryMind**), and interactive dashboards.

---

## 🏗️ Architecture

The platform follows a modern data stack approach, processing data from raw CSVs to actionable insights.

![Architecture Diagram](architecture.png)

```mermaid
graph LR
    subgraph Sources
        CSV[CSV Files]
    end

    subgraph Ingestion["Ingestion Layer"]
        Kafka[Apache Kafka]
        MinIO[MinIO Data Lake]
    end

    subgraph Warehouse["Data Warehouse (Postgres)"]
        Bronze[(Bronze Layer)]
        Silver[(Silver Layer)]
        Gold[(Gold Layer)]
    end

    subgraph Analytics["Analytics & AI"]
        dbt[dbt Core]
        QueryMind[QueryMind AI]
        Streamlit[Dashboards]
    end

    CSV -->|Producer| Kafka
    Kafka -->|Consumer| MinIO
    MinIO -->|Loader| Bronze
    Bronze -->|dbt| Silver
    Silver -->|dbt| Gold
    Gold -->|Reads| QueryMind
    Gold -->|Reads| Streamlit
```

### Data Layers
1. **Bronze (Raw)**: Direct ingest from CSVs. Exact copies of source structure.
2. **Silver (Cleaned)**: Deduplicated, standardized, properly cast types.
   - *Transformations*: Trimming, Lowercase/Uppercase standardization, Timestamp conversion, NULL handling.
3. **Gold (Dimensional)**: Star Schema for analytics.
   - *Facts*: `fact_orders`, `fact_order_items`, `fact_payments`, `fact_reviews`
   - *Dimensions*: `dim_customer` (SCD Type 2), `dim_product`, `dim_seller`, `dim_date`

### Data Model (Gold Layer)
```mermaid
erDiagram
    FACT_ORDERS ||--o{ DIM_CUSTOMER : has
    FACT_ORDERS ||--o{ DIM_DATE : "purchased on"
    FACT_ORDERS ||--|{ FACT_ORDER_ITEMS : contains
    FACT_ORDER_ITEMS }|--|| DIM_PRODUCT : "is a"
    FACT_ORDER_ITEMS }|--|| DIM_SELLER : "sold by"
    FACT_REVIEWS }|--|| FACT_ORDERS : "reviews"
```

---

## 🛠️ Technology Stack

- **Ingestion**: Apache Kafka, MinIO (S3-compatible object storage)
- **Orchestration**: Apache Airflow
- **Warehousing**: PostgreSQL
- **Transformation**: dbt Core (Data Build Tool)
- **Application**: Streamlit (Dashboards & AI Interface)
- **AI/LLM**: OpenAI GPT-4 (via QueryMind)

---

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Python 3.10+
- OpenAI API Key (for QueryMind)

### 1. Start Infrastructure
Launch the containerized environment (Postgres, Kafka, MinIO, Airflow):
```bash
docker-compose up -d
```

### 2. Configure Environment
Create a `.env` file in the root directory:
```env
OPENAI_API_KEY=sk-...
POSTGRES_HOST=localhost
POSTGRES_USER=warehouse_user
POSTGRES_PASSWORD=warehouse_pass
POSTGRES_DB=warehouse_db
```

### 3. Initialize & Load Data
You can run the end-to-end pipeline via Airflow or execute individual steps.

**Option A: Airflow (Recommended)**
1. Access Airflow at `http://localhost:8080` (Credentials: `admin`/`admin`).
2. Trigger the `olist_etl_pipeline` DAG.

![Airflow DAG - Pipeline View](https://via.placeholder.com/800x300?text=Insert+Airflow+DAG+Screenshot+Here)

**Option B: Manual Execution**
1. Load Bronze Layer (Raw):
   ```bash
   psql -h localhost -U warehouse_user -d warehouse_db -f scripts/bronze/00_run_all_bronze.sql
   ```
   *(Note: individual scripts are in `scripts/bronze/`)*

2. Build Silver & Gold Layers (dbt):
   ```bash
   cd dbt
   dbt run
   ```

---

## 📂 Project Structure

```
.
├── .github/            # CI/CD Workflows
├── app/                # Streamlit Application (AI Interface)
├── dashboards/         # Analytical Dashboards (Streamlit)
├── data_utils/         # Data Generation & Validation Utilities
├── datasets/           # Raw CSV Files (Olist Dataset)
├── dbt/                # dbt Project (Transformations & Tests)
├── kafka/              # Kafka Producers & Consumers
├── llm/                # QueryMind AI Core Logic
├── scripts/            # SQL & Shell Scripts
│   ├── bronze/         # DDL & Copy commands for Raw Data
│   ├── silver/         # (Legacy) SQL Scripts for Silver
│   └── gold/           # (Legacy) SQL Scripts for Gold
└── tests/              # Unit & SQL Tests
```

---

## 🧠 QueryMind: AI Analytics

QueryMind allows natural language querying of the Gold schema. It ensures safety by being **Read-Only** and context-aware.

**How to Run**:
```bash
streamlit run app/streamlit_app.py
```

![QueryMind UI - Chat Interface]

**Features**:
- **Zero-Config Schema Awareness**: Automatically builds prompts from dbt metadata.
- **Strictly Read-Only**: Validator blocks harmful commands.
- **Gold-Layer Only**: Restricts queries to the analytical schema.

---

## 📊 Analytics Dashboards

Interactive visualization of key metrics built with Streamlit.

**How to Run**:
```bash
streamlit run dashboards/app.py
```

<img width="2560" height="1440" alt="image" src="https://github.com/user-attachments/assets/6029351d-65a4-40f3-9f2f-3691c266c697" />


**Key Modules**:
- **Executive Overview**: High-level KPIs.
- **Micro-Segmentation**: Customer analysis.
- **Operations**: Delivery & Logistics performance.

---

## 🔄 CI/CD & Testing

### Continuous Integration
We use GitHub Actions to ensure code quality and stability. The CI pipeline (`.github/workflows/ci.yml`):
- **Triggers**: On push to `main` and all Pull Requests.
- **Checks**:
  - **Linting**: Uses `ruff` to enforce PEP 8 style and catch common errors.
  - **Testing**: Runs `pytest` for Python unit tests.

### Tests
The project includes multiple testing layers:
1. **Unit Tests**: Python tests in `tests/` for the LLM components (Validator, Prompt Builder).
   ```bash
   pytest tests/test_llm.py
   ```
2. **dbt Tests**: Data integrity tests (unique, not_null) run via `dbt test`.
3. **Linting**: Run `ruff check .` to verify code style.

### Deployment
Deployment to Streamlit Cloud is currently manual (or triggered via `workflow_dispatch` in GitHub Actions). 

---

## 👩‍💻 Development

### dbt Workflow
To modify transformations or add new models:
1. Edit models in `dbt/models/`.
2. Run tests to ensure integrity:
   ```bash
   dbt test
   ```
3. Generate documentation:
   ```bash
   dbt docs generate
   dbt docs serve
   ```

### Python/App Development
- **Streamlit**: App code is in `app/` and `dashboards/`.
- **LLM Logic**: Logic resides in `llm/` (Prompt Engineering, SQL Generation).

