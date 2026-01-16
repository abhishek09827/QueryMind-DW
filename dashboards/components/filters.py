
import streamlit as st
import pandas as pd
from datetime import date, datetime

def date_range_filter():
    """
    Renders a date range picker in the sidebar.
    Returns start_date and end_date.
    """
    st.sidebar.header("Date Filter")
    
    # Defaults (last 2 years for this dataset typically)
    default_start = date(2016, 1, 1)
    default_end = date(2018, 12, 31)
    
    date_range = st.sidebar.date_input(
        "Select Date Range",
        value=(default_start, default_end),
        min_value=date(2015, 1, 1),
        max_value=datetime.now().date()
    )
    
    if len(date_range) == 2:
        return date_range[0], date_range[1]
    else:
        return default_start, default_end

def state_filter(df: pd.DataFrame, col_name: str = "customer_state"):
    """
    Renders a multiselect for states.
    """
    st.sidebar.header("Filters")
    if df is not None and not df.empty and col_name in df.columns:
        states = sorted(df[col_name].unique().tolist())
        selected = st.sidebar.multiselect("Select State", states)
        return selected
    return []
