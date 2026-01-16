
import streamlit as st
import pandas as pd
from db.connection import get_db_engine
from dashboards.components.kpi import kpi_card
from dashboards.components.charts import render_line_chart, render_bar_chart
from dashboards.components.filters import date_range_filter

def show():
    st.title("Executive Overview")
    
    # Filters
    start_date, end_date = date_range_filter()
    
    engine = get_db_engine()
    if not engine:
        return

    # 1. KPIs
    # Revenue, Orders, Customers, AOV
    kpi_query = f"""
        SELECT 
            COUNT(DISTINCT fo.order_sk) as total_orders,
            COUNT(DISTINCT fo.customer_sk) as active_customers,
            SUM(fp.payment_value) as total_revenue
        FROM gold.fact_orders fo
        JOIN gold.fact_payments fp ON fo.order_sk = fp.order_sk
        WHERE fo.order_purchase_timestamp BETWEEN '{start_date}' AND '{end_date}'
        AND fo.order_status = 'delivered'
    """
    
    try:
        kpi_df = pd.read_sql(kpi_query, engine)
        
        col1, col2, col3, col4 = st.columns(4)
        
        total_rev = kpi_df['total_revenue'].iloc[0] if not kpi_df.empty else 0
        total_orders = kpi_df['total_orders'].iloc[0] if not kpi_df.empty else 0
        active_customers = kpi_df['active_customers'].iloc[0] if not kpi_df.empty else 0
        aov = total_rev / total_orders if total_orders > 0 else 0
        
        with col1:
            kpi_card("Total Revenue", total_rev, prefix="$")
        with col2:
            kpi_card("Total Orders", total_orders)
        with col3:
            kpi_card("Avg Order Value", aov, prefix="$")
        with col4:
            kpi_card("Active Customers", active_customers)

    except Exception as e:
        st.error(f"Error loading KPIs: {e}")

    # 2. Charts
    col_left, col_right = st.columns(2)
    
    with col_left:
        # Revenue over time
        trend_query = f"""
            SELECT 
                DATE_TRUNC('month', fo.order_purchase_timestamp) as month,
                SUM(fp.payment_value) as revenue
            FROM gold.fact_orders fo
            JOIN gold.fact_payments fp ON fo.order_sk = fp.order_sk
            WHERE fo.order_purchase_timestamp BETWEEN '{start_date}' AND '{end_date}'
            AND fo.order_status = 'delivered'
            GROUP BY 1
            ORDER BY 1
        """
        trend_df = pd.read_sql(trend_query, engine)
        if not trend_df.empty:
            render_line_chart(trend_df, 'month', 'revenue', "Monthly Revenue Trend")
        else:
            st.info("No data for revenue trend")

    with col_right:
        # Orders by State (Top 10)
        # Verify schema: gold.dim_customers (customer_state) or gold.fact_orders -> dim_customers
        # Joining fact_orders -> dim_customers on customer_sk
        state_query = f"""
            SELECT 
                dc.customer_state as state,
                COUNT(fo.order_sk) as orders
            FROM gold.fact_orders fo
            JOIN gold.dim_customer dc ON fo.customer_sk = dc.customer_sk
            WHERE fo.order_purchase_timestamp BETWEEN '{start_date}' AND '{end_date}'
            GROUP BY 1
            ORDER BY 2 DESC
            LIMIT 10
        """
        state_df = pd.read_sql(state_query, engine)
        if not state_df.empty:
            render_bar_chart(state_df, 'state', 'orders', "Top 10 States by Orders", limit=10)
        else:
            st.info("No data for state analysis")
