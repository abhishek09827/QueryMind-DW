
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
        
    c = _apply_theme(c)
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

    c = alt.Chart(df).mark_bar(cornerRadiusTopLeft=4, cornerRadiusTopRight=4).encode(
        x=alt.X(x_col, sort='-y', title=x_col.replace("_", " ").title()),
        y=alt.Y(y_col, title=y_col.replace("_", " ").title()),
        tooltip=[x_col, y_col]
    ).properties(
        title=title
    )
    
    if color:
        c = c.encode(color=color)

    c = _apply_theme(c)
    st.altair_chart(c, use_container_width=True)

def _apply_theme(chart: alt.Chart) -> alt.Chart:
    """
    Applies custom Tailwind-like theme to Altair chart.
    """
    return chart.configure_title(
        font='Inter',
        fontSize=16,
        anchor='start',
        color='#0f172a',
        subtitleFont='Inter',
        subtitleColor='#64748b'
    ).configure_axis(
        labelFont='Inter',
        titleFont='Inter',
        labelColor='#64748b',
        titleColor='#475569',
        grid=False,
        domainColor='#e2e8f0'
    ).configure_view(
        strokeWidth=0
    ).configure_legend(
        labelFont='Inter',
        titleFont='Inter'
    )
