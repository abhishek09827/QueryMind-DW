import streamlit as st
import sys
import os
from dotenv import load_dotenv

# Add project root to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from llm.schema_loader import SchemaLoader
from llm.sql_generator import SQLGenerator
from llm.sql_validator import SQLValidator
from llm.executor import QueryExecutor
from llm.explainer import ResultExplainer

# Load env vars
load_dotenv()

st.set_page_config(page_title="QueryMind Analytics", layout="wide")

st.title("🧠 QueryMind: AI Analytics Layer")
st.markdown("Ask natural language questions about your data (Gold Layer only).")

# Sidebar - Configuration
with st.sidebar:
    st.header("Configuration")
    api_key = st.text_input("OpenAI API Key", type="password")
    if api_key:
        os.environ["OPENAI_API_KEY"] = api_key
    
    st.info("System is strictly READ-ONLY and restricted to Gold Schema.")

# Initialize components
@st.cache_resource
def get_components():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    manifest_path = os.path.join(base_dir, 'dbt', 'target', 'manifest.json')
    
    loader = SchemaLoader(manifest_path)
    try:
        schema = loader.load_schema()
    except FileNotFoundError:
        st.error("dbt manifest.json not found. Please run 'dbt compile' or 'dbt docs generate'.")
        return None, None, None, None

    generator = SQLGenerator(schema)
    validator = SQLValidator()
    executor = QueryExecutor()
    explainer = ResultExplainer()
    
    return generator, validator, executor, explainer

generator, validator, executor, explainer = get_components()

if generator:
    # User Input
    question = st.text_input("Enter your question:", placeholder="e.g., What is the total revenue by month?")

    if st.button("Run Analysis"):
        if not question:
            st.warning("Please enter a question.")
        else:
            with st.spinner("Generating SQL..."):
                sql = generator.generate_sql(question)
                
            st.subheader("Generated SQL")
            st.code(sql, language="sql")
            
            # Validate
            is_valid, error = validator.validate(sql)
            
            if not is_valid:
                st.error(f"SQL Validation Failed: {error}")
            else:
                st.success("SQL Validated Successfully")
                
                with st.spinner("Executing Query..."):
                    df, exec_error = executor.execute(sql)
                
                if exec_error:
                    st.error(f"Execution Error: {exec_error}")
                else:
                    st.subheader("Results")
                    st.dataframe(df)
                    
                    st.subheader("Explanation")
                    explanation = explainer.explain(question, sql, df)
                    st.write(explanation)
