
import streamlit as st

def kpi_card(title: str, value: any, delta: any = None, prefix: str = "", suffix: str = ""):
    """
    Renders a KPI card using st.metric.
    Handles formatting of values.
    """
    formatted_value = value
    
    if isinstance(value, (int, float)):
        if "Revenue" in title or "Value" in title or prefix == "$":
             formatted_value = f"${value:,.2f}"
        elif isinstance(value, float):
             formatted_value = f"{value:,.2f}"
        else:
             formatted_value = f"{value:,}"
    
    formatted_value = f"{prefix}{formatted_value}{suffix}"
    
    st.metric(label=title, value=formatted_value, delta=delta)
