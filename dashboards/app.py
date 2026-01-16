
import streamlit as st
import os
import sys

# Add project root to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from dashboards.pages import overview, sales, customers, operations, querymind

st.set_page_config(
    page_title="Data Warehouse Dashboard",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Sidebar Navigation
st.sidebar.title("Navigation")
page = st.sidebar.radio(
    "Go to",
    ["Executive Overview", "Sales Analysis", "Customer Analytics", "Operations", "QueryMind AI"]
)

st.sidebar.markdown("---")
st.sidebar.markdown("### About")
st.sidebar.info(
    "**Data Warehouse Dashboard**\n\n"
    "Built with Streamlit, dbt, and Postgres.\n"
    "Powered by QueryMind (Gemini LLM)."
)

# Routing
if page == "Executive Overview":
    overview.show()
elif page == "Sales Analysis":
    sales.show()
elif page == "Customer Analytics":
    customers.show()
elif page == "Operations":
    operations.show()
elif page == "QueryMind AI":
    querymind.show()
