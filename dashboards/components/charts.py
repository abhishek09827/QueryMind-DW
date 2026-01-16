
import streamlit as st
import pandas as pd
import altair as alt

def render_line_chart(df: pd.DataFrame, x_col: str, y_col: str, title: str, color: str = None):
    """
    Renders a line chart using Altair.
    """
    if df.empty:
        st.info(f"No data available for {title}")
        return

    c = alt.Chart(df).mark_line().encode(
        x=alt.X(x_col, title=x_col.replace("_", " ").title()),
        y=alt.Y(y_col, title=y_col.replace("_", " ").title()),
        tooltip=[x_col, y_col]
    ).properties(
        title=title
    )
    
    if color:
        c = c.encode(color=color)
        
    st.altair_chart(c, use_container_width=True)

def render_bar_chart(df: pd.DataFrame, x_col: str, y_col: str, title: str, color: str = None, limit: int = None):
    """
    Renders a bar chart using Altair.
    """
    if df.empty:
        st.info(f"No data available for {title}")
        return

    if limit:
        df = df.head(limit)

    c = alt.Chart(df).mark_bar().encode(
        x=alt.X(x_col, sort='-y', title=x_col.replace("_", " ").title()),
        y=alt.Y(y_col, title=y_col.replace("_", " ").title()),
        tooltip=[x_col, y_col]
    ).properties(
        title=title
    )
    
    if color:
        c = c.encode(color=color)

    st.altair_chart(c, use_container_width=True)
