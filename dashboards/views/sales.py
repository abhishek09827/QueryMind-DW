
import streamlit as st
import pandas as pd
from db.connection import get_db_engine
from dashboards.components.charts import render_line_chart, render_bar_chart
from dashboards.components.filters import date_range_filter, state_filter

def show():
    st.title("Sales & Order Analysis")
    
    engine = get_db_engine()
    if not engine:
        return

    # Filters
    start_date, end_date = date_range_filter()
    
    # Load minimal data for filters
    filter_query = "SELECT DISTINCT customer_state FROM gold.dim_customers"
    try:
        ref_df = pd.read_sql(filter_query, engine)
        selected_states = state_filter(ref_df)
    except Exception:
        selected_states = []

    state_clause = ""
    if selected_states:
        states_str = "', '".join(selected_states)
        state_clause = f"AND dc.customer_state IN ('{states_str}')"

    # 1. Orders vs Revenue Trend (Daily)
    st.subheader("Daily Sales Trend")
    trend_query = f"""
        SELECT 
            DATE(fo.order_purchase_timestamp) as date,
            COUNT(DISTINCT fo.order_sk) as orders,
            SUM(fp.payment_value) as revenue
        FROM gold.fact_orders fo
        JOIN gold.fact_payments fp ON fo.order_sk = fp.order_sk
        JOIN gold.dim_customer dc ON fo.customer_sk = dc.customer_sk
        WHERE fo.order_purchase_timestamp BETWEEN '{start_date}' AND '{end_date}'
        {state_clause}
        GROUP BY 1
        ORDER BY 1
    """
    trend_df = pd.read_sql(trend_query, engine)
    
    if not trend_df.empty:
        # Dual axis is tricky in simple helper, show side by side or user choice
        chart_type = st.radio("Metric", ["Revenue", "Orders"], horizontal=True)
        metric_col = 'revenue' if chart_type == "Revenue" else 'orders'
        render_line_chart(trend_df, 'date', metric_col, f"Daily {chart_type}")

    # 2. Top Products
    col1, col2 = st.columns([2, 1])
    
    with col1:
        st.subheader("Top Products by Revenue")
        prod_query = f"""
            SELECT 
                dp.product_category_name as category,
                SUM(fp.payment_value) as revenue
            FROM gold.fact_orders fo
            JOIN gold.fact_order_items foi ON fo.order_sk = foi.order_sk
            JOIN gold.fact_payments fp ON fo.order_sk = fp.order_sk
            JOIN gold.dim_product dp ON foi.product_sk = dp.product_sk
            JOIN gold.dim_customer dc ON fo.customer_sk = dc.customer_sk
            WHERE fo.order_purchase_timestamp BETWEEN '{start_date}' AND '{end_date}'
            {state_clause}
            GROUP BY 1
            ORDER BY 2 DESC
            LIMIT 10
        """
        prod_df = pd.read_sql(prod_query, engine)
        render_bar_chart(prod_df, 'category', 'revenue', "Revenue by Category")

    with col2:
        st.subheader("Order Details")
        st.write("Recent 100 orders filtered")
        list_query = f"""
            SELECT 
                fo.order_id,
                fo.order_status,
                fo.order_purchase_timestamp,
                dc.customer_state
            FROM gold.fact_orders fo
            JOIN gold.dim_customer dc ON fo.customer_sk = dc.customer_sk
            WHERE fo.order_purchase_timestamp BETWEEN '{start_date}' AND '{end_date}'
            {state_clause}
            ORDER BY fo.order_purchase_timestamp DESC
            LIMIT 100
        """
        list_df = pd.read_sql(list_query, engine)
        st.dataframe(list_df, hide_index=True)
