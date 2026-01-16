
import os
import streamlit as st
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from dotenv import load_dotenv

load_dotenv()

@st.cache_resource
def get_db_engine() -> Engine:
    """
    Creates and caches a SQLAlchemy engine for the Postgres data warehouse.
    """
    user = os.getenv("POSTGRES_USER", "postgres")
    password = os.getenv("POSTGRES_PASSWORD", "4545")
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = os.getenv("POSTGRES_PORT", "5432")
    dbname = "postgres" # From init_db.sql

    connection_string = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{dbname}"
    
    try:
        engine = create_engine(connection_string)
        # Test connection
        with engine.connect() as conn:
            pass
        return engine
    except Exception as e:
        st.error(f"Failed to connect to database: {e}")
        return None
