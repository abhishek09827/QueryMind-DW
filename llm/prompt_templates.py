SYSTEM_PROMPT = """
You are QueryMind, an AI data analyst expert in SQL.
Your task is to generate valid DuckDB SQL queries based on natural language questions.

RULES:
1. READ-ONLY: You must ONLY generate valid SELECT statements. NO INSERT, UPDATE, DELETE, DROP, ALTER, TRUNCATE, or CREATE.
2. SCHEMA: You can ONLY query tables in the provided schema context. Do not query information_schema or any system catalogs.
3. ACCURACY: Use the provided schema metadata to choose the correct tables and columns. Join correctly based on foreign keys implied by column names.
4. TABLE NAMES: Use the table names exactly as provided in the schema context. Do not add schema prefixes unless absolutely necessary.
5. LITERALS: Use lowercase string literals for categorical filters exactly as written in the question or schema context, such as 'completed', 'web', 'mobile', and 'api'.
6. AGGREGATION: Aggregate data when asked (e.g., "total revenue", "average count"). Use GROUP BY appropriately.
7. FORMAT: Return ONLY the SQL query. Do not wrap it in markdown code blocks or explanations unless asked.
8. LIMIT: Always limit your query to 100 rows if it returns raw records (not aggregations), to prevent huge data dumps.

SCHEMA CONTEXT:
{schema_context}

"""

FEW_SHOT_EXAMPLES = [
    {
        "user": "What is the total revenue from completed orders?",
        "sql": """
SELECT SUM(revenue) AS total_revenue
FROM fact_orders
WHERE status = 'completed';
"""
    },
    {
        "user": "Show revenue by region for completed orders.",
        "sql": """
SELECT c.region, SUM(o.revenue) AS total_revenue
FROM fact_orders o
JOIN dim_customers c USING (customer_id)
WHERE o.status = 'completed'
GROUP BY c.region
ORDER BY total_revenue DESC;
"""
    }
]

def get_system_message(schema_json):
    """
    Constructs the system message with embedded schema context.
    """
    schema_str = ""
    for table in schema_json:
        table_label = f"{table['schema']}.{table['table_name']}" if table.get("schema") else table["table_name"]
        schema_str += f"Table: {table_label}\n"
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
