from __future__ import annotations

from textwrap import dedent


def _sql(text: str) -> str:
    return dedent(text).strip()


BENCHMARK_SET = [
    # Tier 1: Simple aggregations
    {
        "id": "T1-001",
        "question": "What is the total revenue from completed orders?",
        "expected_sql": _sql(
            """
            SELECT SUM(revenue) AS total_revenue
            FROM fact_orders
            WHERE status = 'completed'
            """
        ),
        "tier": 1,
        "concepts": ["aggregation", "filter"],
    },
    {
        "id": "T1-002",
        "question": "How many orders were placed in January 2023?",
        "expected_sql": _sql(
            """
            SELECT COUNT(*) AS order_count
            FROM fact_orders
            WHERE order_date >= DATE '2023-01-01'
              AND order_date < DATE '2023-02-01'
            """
        ),
        "tier": 1,
        "concepts": ["count", "date_filter"],
    },
    {
        "id": "T1-003",
        "question": "What is the average order value for completed orders?",
        "expected_sql": _sql(
            """
            SELECT AVG(revenue) AS avg_order_value
            FROM fact_orders
            WHERE status = 'completed'
            """
        ),
        "tier": 1,
        "concepts": ["aggregation", "average", "filter"],
    },
    {
        "id": "T1-004",
        "question": "How many completed orders are there in total?",
        "expected_sql": _sql(
            """
            SELECT COUNT(*) AS order_count
            FROM fact_orders
            WHERE status = 'completed'
            """
        ),
        "tier": 1,
        "concepts": ["count", "filter"],
    },
    {
        "id": "T1-005",
        "question": "How many unique customers placed completed orders?",
        "expected_sql": _sql(
            """
            SELECT COUNT(DISTINCT customer_id) AS unique_customers
            FROM fact_orders
            WHERE status = 'completed'
            """
        ),
        "tier": 1,
        "concepts": ["count_distinct", "filter"],
    },
    {
        "id": "T1-006",
        "question": "What is the total revenue from the web channel?",
        "expected_sql": _sql(
            """
            SELECT SUM(revenue) AS total_revenue
            FROM fact_orders
            WHERE channel = 'web'
            """
        ),
        "tier": 1,
        "concepts": ["aggregation", "filter"],
    },
    {
        "id": "T1-007",
        "question": "How many cancelled orders are there?",
        "expected_sql": _sql(
            """
            SELECT COUNT(*) AS order_count
            FROM fact_orders
            WHERE status = 'cancelled'
            """
        ),
        "tier": 1,
        "concepts": ["count", "filter"],
    },
    {
        "id": "T1-008",
        "question": "What is the total quantity sold in completed orders?",
        "expected_sql": _sql(
            """
            SELECT SUM(quantity) AS total_quantity
            FROM fact_orders
            WHERE status = 'completed'
            """
        ),
        "tier": 1,
        "concepts": ["sum", "filter"],
    },
    {
        "id": "T1-009",
        "question": "What is the highest revenue from a single completed order?",
        "expected_sql": _sql(
            """
            SELECT MAX(revenue) AS max_revenue
            FROM fact_orders
            WHERE status = 'completed'
            """
        ),
        "tier": 1,
        "concepts": ["max", "filter"],
    },
    {
        "id": "T1-010",
        "question": "What is the lowest revenue from a single completed order?",
        "expected_sql": _sql(
            """
            SELECT MIN(revenue) AS min_revenue
            FROM fact_orders
            WHERE status = 'completed'
            """
        ),
        "tier": 1,
        "concepts": ["min", "filter"],
    },
    {
        "id": "T1-011",
        "question": "What is the average quantity per order for API channel orders?",
        "expected_sql": _sql(
            """
            SELECT AVG(quantity) AS avg_quantity
            FROM fact_orders
            WHERE channel = 'api'
            """
        ),
        "tier": 1,
        "concepts": ["average", "filter"],
    },
    {
        "id": "T1-012",
        "question": "What is the total revenue in the second quarter of 2023?",
        "expected_sql": _sql(
            """
            SELECT SUM(revenue) AS total_revenue
            FROM fact_orders
            WHERE order_date >= DATE '2023-04-01'
              AND order_date < DATE '2023-07-01'
            """
        ),
        "tier": 1,
        "concepts": ["aggregation", "date_filter"],
    },
    {
        "id": "T1-013",
        "question": "How many orders were placed on March 15, 2023?",
        "expected_sql": _sql(
            """
            SELECT COUNT(*) AS order_count
            FROM fact_orders
            WHERE order_date >= DATE '2023-03-15'
              AND order_date < DATE '2023-03-16'
            """
        ),
        "tier": 1,
        "concepts": ["count", "date_filter"],
    },
    {
        "id": "T1-014",
        "question": "What is the total revenue from direct channel orders in 2023?",
        "expected_sql": _sql(
            """
            SELECT SUM(revenue) AS total_revenue
            FROM fact_orders
            WHERE channel = 'direct'
              AND EXTRACT(YEAR FROM order_date) = 2023
            """
        ),
        "tier": 1,
        "concepts": ["aggregation", "filter", "date_filter"],
    },
    {
        "id": "T1-015",
        "question": "How many distinct products were sold in completed orders?",
        "expected_sql": _sql(
            """
            SELECT COUNT(DISTINCT product_id) AS distinct_products
            FROM fact_orders
            WHERE status = 'completed'
            """
        ),
        "tier": 1,
        "concepts": ["count_distinct", "filter"],
    },
    # Tier 2: Joins and grouping
    {
        "id": "T2-001",
        "question": "Show revenue by region for 2023.",
        "expected_sql": _sql(
            """
            SELECT c.region, SUM(o.revenue) AS total_revenue
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            WHERE EXTRACT(YEAR FROM o.order_date) = 2023
              AND o.status = 'completed'
            GROUP BY c.region
            ORDER BY total_revenue DESC, c.region
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by", "date_filter"],
    },
    {
        "id": "T2-002",
        "question": "Show order counts by customer segment for completed orders.",
        "expected_sql": _sql(
            """
            SELECT c.segment, COUNT(*) AS order_count
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            WHERE o.status = 'completed'
            GROUP BY c.segment
            ORDER BY order_count DESC, c.segment
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by", "filter"],
    },
    {
        "id": "T2-003",
        "question": "Show revenue by product category.",
        "expected_sql": _sql(
            """
            SELECT p.category, SUM(o.revenue) AS total_revenue
            FROM fact_orders o
            JOIN dim_products p USING (product_id)
            WHERE o.status = 'completed'
            GROUP BY p.category
            ORDER BY total_revenue DESC, p.category
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by", "filter"],
    },
    {
        "id": "T2-004",
        "question": "What is the average completed order value by channel?",
        "expected_sql": _sql(
            """
            SELECT o.channel, AVG(o.revenue) AS avg_order_value
            FROM fact_orders o
            WHERE o.status = 'completed'
            GROUP BY o.channel
            ORDER BY avg_order_value DESC, o.channel
            """
        ),
        "tier": 2,
        "concepts": ["group_by", "average", "filter"],
    },
    {
        "id": "T2-005",
        "question": "Show revenue by region and segment.",
        "expected_sql": _sql(
            """
            SELECT c.region, c.segment, SUM(o.revenue) AS total_revenue
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            WHERE o.status = 'completed'
            GROUP BY c.region, c.segment
            ORDER BY total_revenue DESC, c.region, c.segment
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by"],
    },
    {
        "id": "T2-006",
        "question": "Show the number of completed orders by month.",
        "expected_sql": _sql(
            """
            SELECT DATE_TRUNC('month', o.order_date) AS month,
                   COUNT(*) AS order_count
            FROM fact_orders o
            WHERE o.status = 'completed'
            GROUP BY 1
            ORDER BY month
            """
        ),
        "tier": 2,
        "concepts": ["group_by", "date_trunc", "filter"],
    },
    {
        "id": "T2-007",
        "question": "Show revenue by region and product category.",
        "expected_sql": _sql(
            """
            SELECT c.region, p.category, SUM(o.revenue) AS total_revenue
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            JOIN dim_products p USING (product_id)
            WHERE o.status = 'completed'
            GROUP BY c.region, p.category
            ORDER BY total_revenue DESC, c.region, p.category
            """
        ),
        "tier": 2,
        "concepts": ["multi_join", "group_by"],
    },
    {
        "id": "T2-008",
        "question": "Show completed order counts by category and channel.",
        "expected_sql": _sql(
            """
            SELECT p.category, o.channel, COUNT(*) AS order_count
            FROM fact_orders o
            JOIN dim_products p USING (product_id)
            WHERE o.status = 'completed'
            GROUP BY p.category, o.channel
            ORDER BY order_count DESC, p.category, o.channel
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by"],
    },
    {
        "id": "T2-009",
        "question": "What are the top five regions by completed revenue?",
        "expected_sql": _sql(
            """
            SELECT c.region, SUM(o.revenue) AS total_revenue
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            WHERE o.status = 'completed'
            GROUP BY c.region
            ORDER BY total_revenue DESC, c.region
            LIMIT 5
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by", "limit"],
    },
    {
        "id": "T2-010",
        "question": "Show average quantity sold by category.",
        "expected_sql": _sql(
            """
            SELECT p.category, AVG(o.quantity) AS avg_quantity
            FROM fact_orders o
            JOIN dim_products p USING (product_id)
            WHERE o.status = 'completed'
            GROUP BY p.category
            ORDER BY avg_quantity DESC, p.category
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by", "average"],
    },
    {
        "id": "T2-011",
        "question": "Show revenue by customer segment and product category.",
        "expected_sql": _sql(
            """
            SELECT c.segment, p.category, SUM(o.revenue) AS total_revenue
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            JOIN dim_products p USING (product_id)
            WHERE o.status = 'completed'
            GROUP BY c.segment, p.category
            ORDER BY total_revenue DESC, c.segment, p.category
            """
        ),
        "tier": 2,
        "concepts": ["multi_join", "group_by"],
    },
    {
        "id": "T2-012",
        "question": "Show completed order revenue by month and region.",
        "expected_sql": _sql(
            """
            SELECT DATE_TRUNC('month', o.order_date) AS month,
                   c.region,
                   SUM(o.revenue) AS total_revenue
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            WHERE o.status = 'completed'
            GROUP BY 1, 2
            ORDER BY month, c.region
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by", "date_trunc"],
    },
    {
        "id": "T2-013",
        "question": "Show order counts by product category for mobile orders.",
        "expected_sql": _sql(
            """
            SELECT p.category, COUNT(*) AS order_count
            FROM fact_orders o
            JOIN dim_products p USING (product_id)
            WHERE o.channel = 'mobile'
            GROUP BY p.category
            ORDER BY order_count DESC, p.category
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by", "filter"],
    },
    {
        "id": "T2-014",
        "question": "Show revenue by channel and region.",
        "expected_sql": _sql(
            """
            SELECT o.channel, c.region, SUM(o.revenue) AS total_revenue
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            WHERE o.status = 'completed'
            GROUP BY o.channel, c.region
            ORDER BY total_revenue DESC, o.channel, c.region
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by"],
    },
    {
        "id": "T2-015",
        "question": "Show distinct completed customers by product category.",
        "expected_sql": _sql(
            """
            SELECT p.category, COUNT(DISTINCT o.customer_id) AS unique_customers
            FROM fact_orders o
            JOIN dim_products p USING (product_id)
            WHERE o.status = 'completed'
            GROUP BY p.category
            ORDER BY unique_customers DESC, p.category
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by", "count_distinct"],
    },
    {
        "id": "T2-016",
        "question": "Show cancelled order counts by region.",
        "expected_sql": _sql(
            """
            SELECT c.region, COUNT(*) AS order_count
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            WHERE o.status = 'cancelled'
            GROUP BY c.region
            ORDER BY order_count DESC, c.region
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by", "filter"],
    },
    {
        "id": "T2-017",
        "question": "Show revenue by customer segment and channel.",
        "expected_sql": _sql(
            """
            SELECT c.segment, o.channel, SUM(o.revenue) AS total_revenue
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            WHERE o.status = 'completed'
            GROUP BY c.segment, o.channel
            ORDER BY total_revenue DESC, c.segment, o.channel
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by"],
    },
    {
        "id": "T2-018",
        "question": "Show average completed order value by segment and channel.",
        "expected_sql": _sql(
            """
            SELECT c.segment, o.channel, AVG(o.revenue) AS avg_order_value
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            WHERE o.status = 'completed'
            GROUP BY c.segment, o.channel
            ORDER BY avg_order_value DESC, c.segment, o.channel
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by", "average"],
    },
    {
        "id": "T2-019",
        "question": "Show revenue by category for the fourth quarter of 2023.",
        "expected_sql": _sql(
            """
            SELECT p.category, SUM(o.revenue) AS total_revenue
            FROM fact_orders o
            JOIN dim_products p USING (product_id)
            WHERE o.status = 'completed'
              AND o.order_date >= DATE '2023-10-01'
              AND o.order_date < DATE '2024-01-01'
            GROUP BY p.category
            ORDER BY total_revenue DESC, p.category
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by", "date_filter"],
    },
    {
        "id": "T2-020",
        "question": "Show completed order counts by region for API channel orders.",
        "expected_sql": _sql(
            """
            SELECT c.region, COUNT(*) AS order_count
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            WHERE o.status = 'completed'
              AND o.channel = 'api'
            GROUP BY c.region
            ORDER BY order_count DESC, c.region
            """
        ),
        "tier": 2,
        "concepts": ["join", "group_by", "filter"],
    },
    # Tier 3: Multi-join and subqueries
    {
        "id": "T3-001",
        "question": "Who are the top 10 customers by revenue?",
        "expected_sql": _sql(
            """
            SELECT c.name,
                   c.email,
                   SUM(o.revenue) AS total_revenue,
                   COUNT(*) AS order_count
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            WHERE o.status = 'completed'
            GROUP BY c.customer_id, c.name, c.email
            ORDER BY total_revenue DESC, c.customer_id
            LIMIT 10
            """
        ),
        "tier": 3,
        "concepts": ["multi_join", "group_by", "limit"],
    },
    {
        "id": "T3-002",
        "question": "What are the top 10 products by revenue?",
        "expected_sql": _sql(
            """
            SELECT p.product_name,
                   p.category,
                   SUM(o.revenue) AS total_revenue
            FROM fact_orders o
            JOIN dim_products p USING (product_id)
            WHERE o.status = 'completed'
            GROUP BY p.product_id, p.product_name, p.category
            ORDER BY total_revenue DESC, p.product_id
            LIMIT 10
            """
        ),
        "tier": 3,
        "concepts": ["join", "group_by", "limit"],
    },
    {
        "id": "T3-003",
        "question": "Which customers spend above the average customer revenue?",
        "expected_sql": _sql(
            """
            WITH customer_revenue AS (
                SELECT o.customer_id, SUM(o.revenue) AS total_revenue
                FROM fact_orders o
                WHERE o.status = 'completed'
                GROUP BY o.customer_id
            )
            SELECT c.name, c.email, cr.total_revenue
            FROM customer_revenue cr
            JOIN dim_customers c USING (customer_id)
            WHERE cr.total_revenue > (
                SELECT AVG(total_revenue)
                FROM customer_revenue
            )
            ORDER BY cr.total_revenue DESC, c.customer_id
            """
        ),
        "tier": 3,
        "concepts": ["cte", "subquery", "aggregation"],
    },
    {
        "id": "T3-004",
        "question": "Which products have revenue above the average product revenue?",
        "expected_sql": _sql(
            """
            WITH product_revenue AS (
                SELECT o.product_id, SUM(o.revenue) AS total_revenue
                FROM fact_orders o
                WHERE o.status = 'completed'
                GROUP BY o.product_id
            )
            SELECT p.product_name, p.category, pr.total_revenue
            FROM product_revenue pr
            JOIN dim_products p USING (product_id)
            WHERE pr.total_revenue > (
                SELECT AVG(total_revenue)
                FROM product_revenue
            )
            ORDER BY pr.total_revenue DESC, p.product_id
            """
        ),
        "tier": 3,
        "concepts": ["cte", "subquery", "aggregation"],
    },
    {
        "id": "T3-005",
        "question": "Which customers placed orders in all four channels?",
        "expected_sql": _sql(
            """
            SELECT c.customer_id, c.name, c.email
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            WHERE o.status = 'completed'
            GROUP BY c.customer_id, c.name, c.email
            HAVING COUNT(DISTINCT o.channel) = 4
            ORDER BY c.customer_id
            """
        ),
        "tier": 3,
        "concepts": ["join", "group_by", "having"],
    },
    {
        "id": "T3-006",
        "question": "Which customers have never had a cancelled order?",
        "expected_sql": _sql(
            """
            SELECT c.customer_id, c.name, c.email
            FROM dim_customers c
            WHERE NOT EXISTS (
                SELECT 1
                FROM fact_orders o
                WHERE o.customer_id = c.customer_id
                  AND o.status = 'cancelled'
            )
            ORDER BY c.customer_id
            """
        ),
        "tier": 3,
        "concepts": ["subquery", "anti_join", "filter"],
    },
    {
        "id": "T3-007",
        "question": "Which categories have revenue above the average category revenue?",
        "expected_sql": _sql(
            """
            WITH category_revenue AS (
                SELECT p.category, SUM(o.revenue) AS total_revenue
                FROM fact_orders o
                JOIN dim_products p USING (product_id)
                WHERE o.status = 'completed'
                GROUP BY p.category
            )
            SELECT category, total_revenue
            FROM category_revenue
            WHERE total_revenue > (
                SELECT AVG(total_revenue)
                FROM category_revenue
            )
            ORDER BY total_revenue DESC, category
            """
        ),
        "tier": 3,
        "concepts": ["cte", "subquery", "group_by"],
    },
    {
        "id": "T3-008",
        "question": "Which regions have revenue above the average region revenue?",
        "expected_sql": _sql(
            """
            WITH region_revenue AS (
                SELECT c.region, SUM(o.revenue) AS total_revenue
                FROM fact_orders o
                JOIN dim_customers c USING (customer_id)
                WHERE o.status = 'completed'
                GROUP BY c.region
            )
            SELECT region, total_revenue
            FROM region_revenue
            WHERE total_revenue > (
                SELECT AVG(total_revenue)
                FROM region_revenue
            )
            ORDER BY total_revenue DESC, region
            """
        ),
        "tier": 3,
        "concepts": ["cte", "subquery", "group_by"],
    },
    {
        "id": "T3-009",
        "question": "What are the top five categories among Enterprise customers?",
        "expected_sql": _sql(
            """
            SELECT p.category, SUM(o.revenue) AS total_revenue
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            JOIN dim_products p USING (product_id)
            WHERE o.status = 'completed'
              AND c.segment = 'Enterprise'
            GROUP BY p.category
            ORDER BY total_revenue DESC, p.category
            LIMIT 5
            """
        ),
        "tier": 3,
        "concepts": ["multi_join", "group_by", "filter", "limit"],
    },
    {
        "id": "T3-010",
        "question": "Which customers have more than 10 completed orders and above average revenue?",
        "expected_sql": _sql(
            """
            WITH customer_stats AS (
                SELECT o.customer_id,
                       COUNT(*) AS order_count,
                       SUM(o.revenue) AS total_revenue
                FROM fact_orders o
                WHERE o.status = 'completed'
                GROUP BY o.customer_id
            )
            SELECT c.customer_id, c.name, c.email, cs.order_count, cs.total_revenue
            FROM customer_stats cs
            JOIN dim_customers c USING (customer_id)
            WHERE cs.order_count > 10
              AND cs.total_revenue > (
                  SELECT AVG(total_revenue)
                  FROM customer_stats
              )
            ORDER BY cs.total_revenue DESC, c.customer_id
            """
        ),
        "tier": 3,
        "concepts": ["cte", "subquery", "having"],
    },
    {
        "id": "T3-011",
        "question": "Which products have been purchased by at least 1,000 unique customers?",
        "expected_sql": _sql(
            """
            SELECT p.product_id, p.product_name, COUNT(DISTINCT o.customer_id) AS unique_customers
            FROM fact_orders o
            JOIN dim_products p USING (product_id)
            WHERE o.status = 'completed'
            GROUP BY p.product_id, p.product_name
            HAVING COUNT(DISTINCT o.customer_id) >= 1000
            ORDER BY unique_customers DESC, p.product_id
            """
        ),
        "tier": 3,
        "concepts": ["join", "group_by", "having", "count_distinct"],
    },
    {
        "id": "T3-012",
        "question": "Which customers have more revenue than the average customer in the same region?",
        "expected_sql": _sql(
            """
            WITH customer_revenue AS (
                SELECT o.customer_id, SUM(o.revenue) AS total_revenue
                FROM fact_orders o
                WHERE o.status = 'completed'
                GROUP BY o.customer_id
            ),
            region_average AS (
                SELECT c.region, AVG(cr.total_revenue) AS avg_region_revenue
                FROM customer_revenue cr
                JOIN dim_customers c USING (customer_id)
                GROUP BY c.region
            )
            SELECT c.customer_id, c.name, c.email, c.region, cr.total_revenue
            FROM customer_revenue cr
            JOIN dim_customers c USING (customer_id)
            JOIN region_average ra ON ra.region = c.region
            WHERE cr.total_revenue > ra.avg_region_revenue
            ORDER BY cr.total_revenue DESC, c.customer_id
            """
        ),
        "tier": 3,
        "concepts": ["cte", "subquery", "join"],
    },
    {
        "id": "T3-013",
        "question": "Which regions have API revenue higher than mobile revenue?",
        "expected_sql": _sql(
            """
            WITH region_channel_revenue AS (
                SELECT c.region,
                       SUM(CASE WHEN o.channel = 'api' THEN o.revenue ELSE 0 END) AS api_revenue,
                       SUM(CASE WHEN o.channel = 'mobile' THEN o.revenue ELSE 0 END) AS mobile_revenue
                FROM fact_orders o
                JOIN dim_customers c USING (customer_id)
                WHERE o.status = 'completed'
                GROUP BY c.region
            )
            SELECT region, api_revenue, mobile_revenue
            FROM region_channel_revenue
            WHERE api_revenue > mobile_revenue
            ORDER BY (api_revenue - mobile_revenue) DESC, region
            """
        ),
        "tier": 3,
        "concepts": ["cte", "case", "group_by"],
    },
    {
        "id": "T3-014",
        "question": "Which customers had their latest order in December 2023?",
        "expected_sql": _sql(
            """
            WITH last_order AS (
                SELECT o.customer_id, MAX(o.order_date) AS last_order_date
                FROM fact_orders o
                GROUP BY o.customer_id
            )
            SELECT c.customer_id, c.name, c.email, lo.last_order_date
            FROM last_order lo
            JOIN dim_customers c USING (customer_id)
            WHERE lo.last_order_date >= DATE '2023-12-01'
              AND lo.last_order_date < DATE '2024-01-01'
            ORDER BY lo.last_order_date DESC, c.customer_id
            """
        ),
        "tier": 3,
        "concepts": ["cte", "subquery", "date_filter"],
    },
    {
        "id": "T3-015",
        "question": "Which customers have more completed orders than the average customer?",
        "expected_sql": _sql(
            """
            WITH customer_orders AS (
                SELECT o.customer_id, COUNT(*) AS order_count
                FROM fact_orders o
                WHERE o.status = 'completed'
                GROUP BY o.customer_id
            )
            SELECT c.customer_id, c.name, c.email, co.order_count
            FROM customer_orders co
            JOIN dim_customers c USING (customer_id)
            WHERE co.order_count > (
                SELECT AVG(order_count)
                FROM customer_orders
            )
            ORDER BY co.order_count DESC, c.customer_id
            """
        ),
        "tier": 3,
        "concepts": ["cte", "subquery", "aggregation"],
    },
    # Tier 4: Window functions and CTEs
    {
        "id": "T4-001",
        "question": "Show month-over-month revenue growth rate.",
        "expected_sql": _sql(
            """
            WITH monthly AS (
                SELECT DATE_TRUNC('month', order_date) AS month,
                       SUM(revenue) AS revenue
                FROM fact_orders
                WHERE status = 'completed'
                GROUP BY 1
            )
            SELECT month,
                   revenue,
                   LAG(revenue) OVER (ORDER BY month) AS prev_month,
                   ROUND(
                       100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
                       / LAG(revenue) OVER (ORDER BY month),
                       2
                   ) AS growth_pct
            FROM monthly
            ORDER BY month
            """
        ),
        "tier": 4,
        "concepts": ["cte", "window_function", "lag"],
    },
    {
        "id": "T4-002",
        "question": "Show running total revenue by month.",
        "expected_sql": _sql(
            """
            WITH monthly AS (
                SELECT DATE_TRUNC('month', order_date) AS month,
                       SUM(revenue) AS revenue
                FROM fact_orders
                WHERE status = 'completed'
                GROUP BY 1
            )
            SELECT month,
                   revenue,
                   SUM(revenue) OVER (
                       ORDER BY month
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                   ) AS running_revenue
            FROM monthly
            ORDER BY month
            """
        ),
        "tier": 4,
        "concepts": ["cte", "window_function", "running_total"],
    },
    {
        "id": "T4-003",
        "question": "Rank regions by monthly revenue.",
        "expected_sql": _sql(
            """
            WITH monthly_region AS (
                SELECT DATE_TRUNC('month', o.order_date) AS month,
                       c.region,
                       SUM(o.revenue) AS revenue
                FROM fact_orders o
                JOIN dim_customers c USING (customer_id)
                WHERE o.status = 'completed'
                GROUP BY 1, 2
            )
            SELECT month,
                   region,
                   revenue,
                   RANK() OVER (PARTITION BY month ORDER BY revenue DESC) AS revenue_rank
            FROM monthly_region
            ORDER BY month, revenue_rank, region
            """
        ),
        "tier": 4,
        "concepts": ["cte", "window_function", "rank"],
    },
    {
        "id": "T4-004",
        "question": "Show the top 3 products in each category by revenue.",
        "expected_sql": _sql(
            """
            WITH product_revenue AS (
                SELECT p.category,
                       p.product_id,
                       p.product_name,
                       SUM(o.revenue) AS revenue
                FROM fact_orders o
                JOIN dim_products p USING (product_id)
                WHERE o.status = 'completed'
                GROUP BY p.category, p.product_id, p.product_name
            ),
            ranked_products AS (
                SELECT category,
                       product_id,
                       product_name,
                       revenue,
                       ROW_NUMBER() OVER (
                           PARTITION BY category
                           ORDER BY revenue DESC, product_id
                       ) AS rn
                FROM product_revenue
            )
            SELECT category, product_id, product_name, revenue, rn
            FROM ranked_products
            WHERE rn <= 3
            ORDER BY category, rn, product_id
            """
        ),
        "tier": 4,
        "concepts": ["cte", "window_function", "row_number"],
    },
    {
        "id": "T4-005",
        "question": "Rank customers within each region by revenue.",
        "expected_sql": _sql(
            """
            WITH customer_revenue AS (
                SELECT c.region,
                       c.customer_id,
                       c.name,
                       SUM(o.revenue) AS total_revenue
                FROM fact_orders o
                JOIN dim_customers c USING (customer_id)
                WHERE o.status = 'completed'
                GROUP BY c.region, c.customer_id, c.name
            )
            SELECT region,
                   customer_id,
                   name,
                   total_revenue,
                   DENSE_RANK() OVER (
                       PARTITION BY region
                       ORDER BY total_revenue DESC, customer_id
                   ) AS revenue_rank
            FROM customer_revenue
            ORDER BY region, revenue_rank, customer_id
            """
        ),
        "tier": 4,
        "concepts": ["cte", "window_function", "dense_rank"],
    },
    {
        "id": "T4-006",
        "question": "Show each category's share of monthly completed revenue.",
        "expected_sql": _sql(
            """
            WITH monthly_category AS (
                SELECT DATE_TRUNC('month', o.order_date) AS month,
                       p.category,
                       SUM(o.revenue) AS revenue
                FROM fact_orders o
                JOIN dim_products p USING (product_id)
                WHERE o.status = 'completed'
                GROUP BY 1, 2
            )
            SELECT month,
                   category,
                   revenue,
                   ROUND(
                       100.0 * revenue
                       / SUM(revenue) OVER (PARTITION BY month),
                       2
                   ) AS revenue_share_pct
            FROM monthly_category
            ORDER BY month, revenue_share_pct DESC, category
            """
        ),
        "tier": 4,
        "concepts": ["cte", "window_function", "share"],
    },
    {
        "id": "T4-007",
        "question": "Show a 3-month moving average of monthly revenue.",
        "expected_sql": _sql(
            """
            WITH monthly AS (
                SELECT DATE_TRUNC('month', order_date) AS month,
                       SUM(revenue) AS revenue
                FROM fact_orders
                WHERE status = 'completed'
                GROUP BY 1
            )
            SELECT month,
                   revenue,
                   AVG(revenue) OVER (
                       ORDER BY month
                       ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
                   ) AS moving_avg_3m
            FROM monthly
            ORDER BY month
            """
        ),
        "tier": 4,
        "concepts": ["cte", "window_function", "moving_average"],
    },
    {
        "id": "T4-008",
        "question": "Show cumulative completed order counts by month.",
        "expected_sql": _sql(
            """
            WITH monthly AS (
                SELECT DATE_TRUNC('month', order_date) AS month,
                       COUNT(*) AS order_count
                FROM fact_orders
                WHERE status = 'completed'
                GROUP BY 1
            )
            SELECT month,
                   order_count,
                   SUM(order_count) OVER (
                       ORDER BY month
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                   ) AS cumulative_order_count
            FROM monthly
            ORDER BY month
            """
        ),
        "tier": 4,
        "concepts": ["cte", "window_function", "running_total"],
    },
    {
        "id": "T4-009",
        "question": "Show the revenue percentile rank of customers.",
        "expected_sql": _sql(
            """
            WITH customer_revenue AS (
                SELECT o.customer_id,
                       SUM(o.revenue) AS total_revenue
                FROM fact_orders o
                WHERE o.status = 'completed'
                GROUP BY o.customer_id
            )
            SELECT customer_id,
                   total_revenue,
                   PERCENT_RANK() OVER (ORDER BY total_revenue) AS revenue_percentile
            FROM customer_revenue
            ORDER BY total_revenue DESC, customer_id
            """
        ),
        "tier": 4,
        "concepts": ["cte", "window_function", "percent_rank"],
    },
    {
        "id": "T4-010",
        "question": "Show month-over-month order count change by channel.",
        "expected_sql": _sql(
            """
            WITH monthly_channel AS (
                SELECT DATE_TRUNC('month', o.order_date) AS month,
                       o.channel,
                       COUNT(*) AS order_count
                FROM fact_orders o
                WHERE o.status = 'completed'
                GROUP BY 1, 2
            )
            SELECT month,
                   channel,
                   order_count,
                   LAG(order_count) OVER (
                       PARTITION BY channel
                       ORDER BY month
                   ) AS prev_month_count,
                   order_count - LAG(order_count) OVER (
                       PARTITION BY channel
                       ORDER BY month
                   ) AS delta_count
            FROM monthly_channel
            ORDER BY channel, month
            """
        ),
        "tier": 4,
        "concepts": ["cte", "window_function", "lag"],
    },
]


def get_benchmark_set() -> list[dict[str, object]]:
    return list(BENCHMARK_SET)

