
import streamlit as st
import pandas as pd
import altair as alt
from db.connection import get_db_engine
from dashboards.components.charts import render_bar_chart

def show():
    st.title("Customer Analytics")
    
    engine = get_db_engine()
    if not engine:
        return

    # 1. Customer Segmentation strategy
    # Calculate Frequency distribution
    st.subheader("Customer Retention Overview")
    
    retention_query = """
        WITH customer_orders AS (
            SELECT 
                customer_sk,
                COUNT(order_sk) as order_count
            FROM gold.fact_orders
            GROUP BY 1
        )
        SELECT 
            CASE 
                WHEN order_count = 1 THEN 'One-time'
                WHEN order_count BETWEEN 2 AND 5 THEN 'Returning (2-5)'
                ELSE 'VIP (5+)'
            END as segment,
            COUNT(customer_sk) as num_customers
        FROM customer_orders
        GROUP BY 1
    """
    try:
        ret_df = pd.read_sql(retention_query, engine)
        
        col1, col2 = st.columns(2)
        
        with col1:
            total_customers = ret_df['num_customers'].sum()
            st.metric("Total Customers", f"{total_customers:,}")
            
            # Pie Chart using Altair
            base = alt.Chart(ret_df).encode(theta=alt.Theta("num_customers", stack=True))
            pie = base.mark_arc(outerRadius=120).encode(
                color=alt.Color("segment"),
                order=alt.Order("num_customers", sort="descending"),
                tooltip=["segment", "num_customers"]
            )
            st.altair_chart(pie, use_container_width=True)
            
        with col2:
            st.write("Segment Stats")
            st.dataframe(ret_df)

    except Exception as e:
        st.error(f"Error executing retention query: {e}")

    # 2. Geo Distribution
    st.subheader("Geographic Distribution")
    geo_query = """
        SELECT 
            customer_state,
            COUNT(customer_sk) as customer_count
        FROM gold.dim_customer
        GROUP BY 1
        ORDER BY 2 DESC
    """
    geo_df = pd.read_sql(geo_query, engine)
    render_bar_chart(geo_df, 'customer_state', 'customer_count', "Customers by State")
