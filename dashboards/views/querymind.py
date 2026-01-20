
import streamlit as st
import os
import sys

# Ensure LLM modules can be imported
# (Assuming app.py sets path, but adding here for safety if run individually)
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

from llm.schema_loader import SchemaLoader
from llm.sql_generator import SQLGenerator
from llm.sql_validator import SQLValidator
from llm.executor import QueryExecutor
from llm.explainer import ResultExplainer

@st.cache_resource
def get_llm_components():
    """
    Initialize LLM components. Cached to avoid reloading schema every rerun.
    """
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    manifest_path = os.path.join(base_dir, 'dbt', 'target', 'manifest.json')
    
    loader = SchemaLoader(manifest_path)
    try:
        schema = loader.load_schema()
    except Exception as e:
        return None, None, None, None, f"Error loading schema: {e}"

    generator = SQLGenerator(schema)
    validator = SQLValidator()
    executor = QueryExecutor()
    explainer = ResultExplainer()
    
    return generator, validator, executor, explainer, None

def show():
    st.title("🧠 QueryMind: AI Analyst")
    st.markdown("Ask natural language questions about your data (e.g., *'What is the total revenue by state?'*)")

    generator, validator, executor, explainer, error = get_llm_components()
    
    if error:
        st.error(error)
        st.warning("Please ensure dbt manifest exists.")
        return

    if generator:
        question = st.text_input("Ask a question:", key="qm_input")
        
        if st.button("Generate & Run"):
            if not question:
                st.warning("Please enter a question.")
            else:
                with st.spinner("Thinking... (Generating SQL)"):
                    sql = generator.generate_sql(question)
                
                with st.expander("View Generated SQL", expanded=True):
                    st.code(sql, language="sql")
                
                # Validate
                is_valid, val_error = validator.validate(sql)
                
                if not is_valid:
                    st.error(f"SQL Validation Failed: {val_error}")
                else:
                    st.success("SQL Validated")
                    
                    with st.spinner("Running Query..."):
                        df, exec_error = executor.execute(sql)
                    
                    if exec_error:
                        st.error(f"Database Error: {exec_error}")
                    else:
                        st.subheader("Results")
                        st.dataframe(df)
                        
                        if not df.empty:
                            with st.spinner("Analyzing Results..."):
                                explanation = explainer.explain(question, sql, df)
                            st.info(explanation)
                        else:
                            st.warning("Query returned no results.")
