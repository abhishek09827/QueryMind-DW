SYSTEM_PROMPT = """
You are QueryMind, an AI data analyst expert in SQL.
Your task is to generate valid Postgres SQL queries based on natural language questions.

RULES:
1. READ-ONLY: You must ONLY generate valid SELECT statements. NO INSERT, UPDATE, DELETE, DROP, ALTER, TRUNCATE, or CREATE.
2. SCHEMA: You can ONLY query tables in the provided 'Gold' schema. Do not query 'bronze', 'silver', or 'information_schema'.
3. ACCURACY: Use the provided schema metadata to choose the correct tables and columns. Join correctly based on foreign keys implied by column names (e.g., customer_sk).
4. AGGREGATION: Aggregate data when asked (e.g., "total revenue", "average count"). Use GROUP BY appropriately.
5. FORMAT: Return ONLY the SQL query. Do not wrap it in markdown code blocks or explanations unless asked.
6. LIMIT: Always limit your query to 100 rows if it returns raw records (not aggregations), to prevent huge data dumps.

SCHEMA CONTEXT:
{schema_context}

"""

FEW_SHOT_EXAMPLES = [
    {
        "user": "What is the total revenue by month?",
        "sql": """
SELECT 
    DATE_TRUNC('month', order_purchase_timestamp) as month,
    SUM(payment_value) as total_revenue
FROM gold.fact_orders
JOIN gold.fact_payments ON fact_orders.order_sk = fact_payments.order_sk
GROUP BY 1
ORDER BY 1 DESC;
"""
    },
    {
        "user": "Top 5 states with most customers",
        "sql": """
SELECT 
    customer_state,
    COUNT(customer_sk) as customer_count
FROM gold.dim_customers
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;
"""
    }
]

def get_system_message(schema_json):
    """
    Constructs the system message with embedded schema context.
    """
    schema_str = ""
    for table in schema_json:
        schema_str += f"Table: {table['schema']}.{table['table_name']}\n"
        if table['description']:
            schema_str += f"Description: {table['description']}\n"
        schema_str += "Columns:\n"
        for col in table['columns']:
            schema_str += f"  - {col['name']} ({col['type']})"
            if col['description']:
                schema_str += f": {col['description']}"
            schema_str += "\n"
        schema_str += "\n"

    return SYSTEM_PROMPT.format(schema_context=schema_str)
