
import streamlit as st
import pandas as pd
from db.connection import get_db_engine
from dashboards.components.kpi import kpi_card
from dashboards.components.filters import date_range_filter

def show():
    st.title("Delivery & Operations")
    
    engine = get_db_engine()
    if not engine:
        return

    # Filters
    start_date, end_date = date_range_filter()

    # 1. Delivery KPIs
    # Note: delivery_time is difference between delivered vs purchased (or approved)
    # Delay is if delivered > estimated
    
    ops_query = f"""
        SELECT 
            AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp))/86400) as avg_days_to_deliver,
            COUNT(order_sk) FILTER (WHERE order_delivered_customer_date > order_estimated_delivery_date) as late_orders,
            COUNT(order_sk) as total_delivered_orders
        FROM gold.fact_orders
        WHERE order_purchase_timestamp BETWEEN '{start_date}' AND '{end_date}'
        AND order_status = 'delivered'
        AND order_delivered_customer_date IS NOT NULL
    """
    
    try:
        ops_df = pd.read_sql(ops_query, engine)
        
        avg_days = ops_df['avg_days_to_deliver'].iloc[0] or 0
        late = ops_df['late_orders'].iloc[0] or 0
        total = ops_df['total_delivered_orders'].iloc[0] or 1
        late_pct = (late / total) * 100
        
        col1, col2, col3 = st.columns(3)
        with col1:
            kpi_card("Avg Delivery Days", avg_days, suffix=" days")
        with col2:
            kpi_card("Late Orders", late)
        with col3:
            kpi_card("Late %", late_pct, suffix="%")
            
    except Exception as e:
        st.error(f"Error loading Ops KPIs: {e}")

    # 2. Late Orders Table
    st.subheader("Recent Delayed Orders")
    late_query = f"""
        SELECT 
            fo.order_id,
            DATE(fo.order_purchase_timestamp) as purchase_date,
            DATE(fo.order_estimated_delivery_date) as estimated,
            DATE(fo.order_delivered_customer_date) as actual,
            ds.seller_id
        FROM gold.fact_orders fo
        LEFT JOIN gold.dim_seller ds ON fo.seller_sk = ds.seller_sk
        WHERE fo.order_purchase_timestamp BETWEEN '{start_date}' AND '{end_date}'
        AND fo.order_status = 'delivered'
        AND fo.order_delivered_customer_date > fo.order_estimated_delivery_date
        ORDER BY (fo.order_delivered_customer_date - fo.order_estimated_delivery_date) DESC
        LIMIT 50
    """
    late_df = pd.read_sql(late_query, engine)
    st.dataframe(late_df)
