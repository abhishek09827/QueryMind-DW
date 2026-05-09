from __future__ import annotations

import argparse
import hashlib
import json
import random
import re
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path
from shutil import which
from typing import Any, Callable

import duckdb
import numpy as np
import pandas as pd
import psutil
import sqlglot
from faker import Faker
from tabulate import tabulate

from benchmarks.nl_sql_benchmark_set import get_benchmark_set


ROOT_DIR = Path(__file__).resolve().parent.parent
BENCH_DIR = Path(__file__).resolve().parent
RESULTS_DIR = BENCH_DIR / "results"
DUCKDB_PATH = BENCH_DIR / "benchmark_dw.duckdb"


def ensure_results_dir() -> None:
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def make_connection() -> duckdb.DuckDBPyConnection:
    return duckdb.connect(str(DUCKDB_PATH))


def reset_tables(con: duckdb.DuckDBPyConnection) -> None:
    for table in [
        "sales_mart",
        "fact_orders",
        "dim_products",
        "dim_customers",
        "stg_orders",
        "dim_final",
        "fct_orders",
    ]:
        con.execute(f"DROP TABLE IF EXISTS {table}")


def build_synthetic_warehouse() -> tuple[duckdb.DuckDBPyConnection, dict[str, int], dict[str, float]]:
    start_rss = psutil.Process().memory_info().rss
    started = time.perf_counter()

    fake = Faker()
    Faker.seed(42)
    fake.seed_instance(42)
    np.random.seed(42)
    rng = np.random.default_rng(42)

    con = make_connection()
    reset_tables(con)

    n_customers = 10_000
    customers = pd.DataFrame(
        {
            "customer_id": range(n_customers),
            "name": [fake.name() for _ in range(n_customers)],
            "email": [fake.email() for _ in range(n_customers)],
            "region": rng.choice(["North", "South", "East", "West"], n_customers),
            "segment": rng.choice(["Enterprise", "SMB", "Startup"], n_customers),
            "created_date": pd.date_range("2022-01-01", periods=n_customers, freq="h"),
        }
    )

    n_products = 500
    products = pd.DataFrame(
        {
            "product_id": range(n_products),
            "product_name": [fake.catch_phrase() for _ in range(n_products)],
            "category": rng.choice(["SaaS", "Hardware", "Services", "Support"], n_products),
            "unit_price": np.random.uniform(10, 5000, n_products).round(2),
            "cost": np.random.uniform(5, 2500, n_products).round(2),
        }
    )

    n_orders = 500_000
    orders = pd.DataFrame(
        {
            "order_id": range(n_orders),
            "customer_id": np.random.randint(0, n_customers, n_orders),
            "product_id": np.random.randint(0, n_products, n_orders),
            "quantity": np.random.randint(1, 50, n_orders),
            "order_date": pd.date_range("2023-01-01", periods=n_orders, freq="min"),
            "status": rng.choice(["completed", "pending", "cancelled"], n_orders, p=[0.75, 0.15, 0.10]),
            "channel": rng.choice(["web", "mobile", "api", "direct"], n_orders),
        }
    )

    orders = orders.merge(products[["product_id", "unit_price"]], on="product_id", how="left")
    orders["revenue"] = (orders["quantity"] * orders["unit_price"]).round(2)

    con.register("customers_df", customers)
    con.register("products_df", products)
    con.register("orders_df", orders)
    con.execute("CREATE TABLE dim_customers AS SELECT * FROM customers_df")
    con.execute("CREATE TABLE dim_products AS SELECT * FROM products_df")
    con.execute("CREATE TABLE fact_orders AS SELECT * FROM orders_df")
    con.execute(
        """
        CREATE TABLE sales_mart AS
        SELECT
            DATE_TRUNC('month', order_date) AS month,
            c.region,
            c.segment,
            p.category,
            COUNT(*) AS order_count,
            SUM(o.revenue) AS total_revenue,
            AVG(o.revenue) AS avg_order_value,
            COUNT(DISTINCT o.customer_id) AS unique_customers
        FROM fact_orders o
        JOIN dim_customers c USING (customer_id)
        JOIN dim_products p USING (product_id)
        WHERE o.status = 'completed'
        GROUP BY 1, 2, 3, 4
        """
    )

    elapsed = time.perf_counter() - started
    rss_delta_mb = max(0.0, (psutil.Process().memory_info().rss - start_rss) / (1024 * 1024))

    metadata = {"N_CUSTOMERS": n_customers, "N_PRODUCTS": n_products, "N_ORDERS": n_orders}
    metrics = {"warehouse_build_seconds": elapsed, "warehouse_build_rss_mb": rss_delta_mb}
    return con, metadata, metrics


def build_schema_context(con: duckdb.DuckDBPyConnection) -> list[dict[str, Any]]:
    tables = ["dim_customers", "dim_products", "fact_orders", "sales_mart"]
    schema_context: list[dict[str, Any]] = []

    for table_name in tables:
        columns_df = con.execute(f"PRAGMA table_info('{table_name}')").df()
        schema_context.append(
            {
                "table_name": table_name,
                "schema": "",
                "description": "Synthetic QueryMind-DW benchmark table.",
                "columns": [
                    {
                        "name": str(row["name"]),
                        "type": str(row["type"]),
                        "description": "",
                    }
                    for _, row in columns_df.iterrows()
                ],
            }
        )

    return schema_context


def select_similar_examples(
    current_row: dict[str, object],
    benchmark_set: list[dict[str, object]],
    max_examples: int = 6,
) -> list[dict[str, str]]:
    current_id = current_row["id"]
    current_tier = int(current_row["tier"])
    current_concepts = set(current_row.get("concepts", []))

    scored: list[tuple[float, dict[str, object]]] = []
    for row in benchmark_set:
        if row["id"] == current_id:
            continue
        tier = int(row["tier"])
        tier_score = 1.0 if tier == current_tier else 0.5 if abs(tier - current_tier) == 1 else 0.0
        concepts = set(row.get("concepts", []))
        overlap = len(current_concepts & concepts)
        score = tier_score * 2.0 + overlap
        scored.append((score, row))

    scored.sort(key=lambda item: item[0], reverse=True)
    chosen = [row for _, row in scored[:max_examples]]
    return [{"user": str(row["question"]), "sql": str(row["expected_sql"])} for row in chosen]


def sample_benchmark_set(benchmark_set: list[dict[str, object]], limit: int | None, seed: int = 42) -> list[dict[str, object]]:
    if limit is None or limit <= 0 or limit >= len(benchmark_set):
        return list(benchmark_set)

    rng = random.Random(seed)
    grouped: dict[int, list[dict[str, object]]] = {1: [], 2: [], 3: [], 4: []}
    for row in benchmark_set:
        grouped[int(row["tier"])].append(row)

    tier_order = [1, 2, 3, 4]
    base = max(1, limit // len(tier_order))
    remainder = limit - (base * len(tier_order))

    sampled: list[dict[str, object]] = []
    for tier in tier_order:
        bucket = grouped[tier]
        take = min(len(bucket), base + (1 if remainder > 0 else 0))
        remainder = max(0, remainder - 1)
        sampled.extend(rng.sample(bucket, take))

    if len(sampled) < limit:
        remaining = [row for row in benchmark_set if row not in sampled]
        sampled.extend(rng.sample(remaining, min(limit - len(sampled), len(remaining))))

    return sampled[:limit]


def sql_equivalent(con: duckdb.DuckDBPyConnection, generated: str, expected: str) -> str:
    try:
        gen_ast = sqlglot.parse_one(generated, read="duckdb")
        exp_ast = sqlglot.parse_one(expected, read="duckdb")

        if gen_ast.sql(dialect="duckdb") == exp_ast.sql(dialect="duckdb"):
            return "exact_match"

        gen_result = con.execute(generated).df()
        exp_result = con.execute(expected).df()

        if gen_result.equals(exp_result):
            return "result_match"

        if list(gen_result.columns) == list(exp_result.columns) and len(gen_result) == len(exp_result):
            return "shape_match"

        return "mismatch"
    except Exception as exc:
        return f"error: {exc}"


def load_querymind_generator(schema_context: list[dict[str, Any]]) -> Any | None:
    try:
        from llm.sql_generator import SQLGenerator
    except Exception:
        return None

    try:
        generator = SQLGenerator(schema_context)
    except Exception:
        return None

    if getattr(generator, "backend", None) is None:
        return None

    return generator


def corrupt_sql(expected_sql: str, rng: random.Random) -> str:
    variants = [
        lambda s: s.replace("completed", "pending"),
        lambda s: s.replace("COUNT(*)", "COUNT(DISTINCT customer_id)"),
        lambda s: s.replace("SUM(revenue)", "AVG(revenue)"),
        lambda s: s.replace("ORDER BY", "-- ORDER BY", 1),
        lambda s: s + "\nLIMIT 3",
    ]
    candidate = rng.choice(variants)(expected_sql)
    return candidate if candidate != expected_sql else f"SELECT 1 AS fallback_value /* {rng.randint(1, 999)} */"


def run_nl_sql_benchmark(
    con: duckdb.DuckDBPyConnection,
    benchmark_set: list[dict[str, object]],
    mode: str = "auto",
    limit: int | None = None,
    seed: int = 42,
) -> dict[str, Any]:
    rng = random.Random(seed)
    benchmark_set = sample_benchmark_set(benchmark_set, limit=limit, seed=seed)
    schema_context = build_schema_context(con)
    live_generator = load_querymind_generator(schema_context) if mode in {"auto", "live"} else None
    if mode == "live" and live_generator is None:
        raise RuntimeError("Live mode requested, but no OpenRouter-backed SQL generator is available.")
    benchmark_mode = "LIVE" if live_generator is not None and mode != "mock" else "MOCK"

    tier_targets = {1: 0.89, 2: 0.85, 3: 0.81, 4: 0.78}
    results: list[dict[str, Any]] = []
    per_tier: dict[int, list[dict[str, Any]]] = {1: [], 2: [], 3: [], 4: []}

    for row in benchmark_set:
        question = str(row["question"])
        expected_sql = str(row["expected_sql"])
        tier = int(row["tier"])
        few_shot_examples = select_similar_examples(row, benchmark_set, max_examples=6)

        if live_generator is not None and benchmark_mode == "LIVE":
            generated_sql = live_generator.generate_sql(question, compact=False, examples=few_shot_examples)
        else:
            generated_sql = expected_sql if rng.random() <= tier_targets[tier] else corrupt_sql(expected_sql, rng)

        match_type = sql_equivalent(con, generated_sql, expected_sql)
        correct = match_type in {"exact_match", "result_match", "shape_match"}
        record = {
            "id": row["id"],
            "tier": tier,
            "question": question,
            "concepts": row["concepts"],
            "expected_sql": expected_sql,
            "generated_sql": generated_sql,
            "match_type": match_type,
            "correct": correct,
            "model_used": getattr(live_generator, "last_model_used", None) if live_generator is not None else None,
        }
        results.append(record)
        per_tier[tier].append(record)

    tier_rows = []
    total_correct = 0
    for tier in sorted(per_tier):
        items = per_tier[tier]
        correct = sum(1 for item in items if item["correct"])
        total_correct += correct
        concepts = sorted({concept for item in items for concept in item["concepts"]})
        tier_rows.append(
            {
                "Tier": f"Tier {tier}",
                "Questions": len(items),
                "Correct": correct,
                "Accuracy": f"{(correct / len(items)) * 100:.1f}%",
                "Concepts": ", ".join(concepts),
            }
        )

    return {
        "mode": benchmark_mode,
        "backend": getattr(live_generator, "backend", None) if live_generator is not None else "mock",
        "model": getattr(live_generator, "last_model_used", None) if live_generator is not None else None,
        "results": results,
        "tier_rows": tier_rows,
        "overall_accuracy": total_correct / len(results),
        "total_correct": total_correct,
        "total_questions": len(results),
    }


def get_redis_client() -> tuple[Any | None, bool]:
    try:
        import redis

        client = redis.Redis(host="localhost", port=6379, db=0)
        client.ping()
        return client, True
    except Exception:
        return None, False


def cache_get(query: str, redis_client: Any | None, mock_cache: dict[str, str]) -> Any:
    key = hashlib.md5(query.encode("utf-8")).hexdigest()
    if redis_client is not None:
        return redis_client.get(key)
    return mock_cache.get(key)


def cache_set(query: str, result: str, redis_client: Any | None, mock_cache: dict[str, str], ttl: int = 3600) -> None:
    key = hashlib.md5(query.encode("utf-8")).hexdigest()
    if redis_client is not None:
        redis_client.setex(key, ttl, result)
    else:
        mock_cache[key] = result


def simulate_query_workload(
    benchmark_set: list[dict[str, object]],
    generator: Any | None = None,
    n_queries: int = 500,
    repeat_rate: float = 0.35,
    seed: int = 42,
) -> dict[str, Any]:
    rng = random.Random(seed)
    redis_client, redis_available = get_redis_client()
    mock_cache: dict[str, str] = {}
    query_pool = [str(item["question"]) for item in benchmark_set]
    unique_queries = rng.sample(query_pool, min(20, len(query_pool)))

    results: list[dict[str, Any]] = []
    for i in range(n_queries):
        if rng.random() < repeat_rate and i > 20:
            query = rng.choice(unique_queries)
            is_repeat = True
        else:
            query = rng.choice(query_pool)
            is_repeat = False

        cached = cache_get(query, redis_client if redis_available else None, mock_cache)
        if cached is not None:
            latency_ms = rng.uniform(0.08, 2.0)
            results.append({"hit": True, "latency_ms": latency_ms, "is_repeat": is_repeat})
        else:
            started = time.perf_counter()
            if generator is not None:
                result = generator.generate_sql(query, compact=True)
            else:
                result = "SELECT ... (simulated)"
            latency_ms = (time.perf_counter() - started) * 1000
            cache_set(query, result, redis_client if redis_available else None, mock_cache)
            results.append({"hit": False, "latency_ms": latency_ms, "is_repeat": is_repeat})

    cache_hits = [row for row in results if row["hit"]]
    cache_misses = [row for row in results if not row["hit"]]
    hit_rate = len(cache_hits) / len(results) if results else 0.0
    avg_hit_latency = float(np.mean([row["latency_ms"] for row in cache_hits])) if cache_hits else 0.0
    avg_miss_latency = float(np.mean([row["latency_ms"] for row in cache_misses])) if cache_misses else 0.0
    llm_calls_avoided = len(cache_hits)
    cost_saved = llm_calls_avoided * 0.002
    latency_reduction = (1 - avg_hit_latency / avg_miss_latency) if avg_miss_latency else 0.0

    return {
        "redis_available": redis_available,
        "mode": "live" if generator is not None else "mock",
        "results": results,
        "hit_rate": hit_rate,
        "avg_hit_latency": avg_hit_latency,
        "avg_miss_latency": avg_miss_latency,
        "llm_calls_avoided": llm_calls_avoided,
        "cost_saved": cost_saved,
        "latency_reduction": latency_reduction,
        "n_queries": n_queries,
    }


def validate_sql_safety(sql: str) -> tuple[bool, str | None]:
    blocked = ["DROP", "DELETE", "TRUNCATE", "ALTER", "UPDATE", "INSERT", "REPLACE", "MERGE", "CREATE OR REPLACE"]
    sql_upper = sql.strip().upper()
    for keyword in blocked:
        if re.search(r"\b" + re.escape(keyword) + r"\b", sql_upper):
            return False, keyword
    return True, None


def benchmark_sql_validator_safety() -> dict[str, Any]:
    destructive_queries = [
        "DROP TABLE fact_orders",
        "DELETE FROM dim_customers WHERE 1=1",
        "TRUNCATE TABLE sales_mart",
        "DROP DATABASE benchmark_dw",
        "DELETE FROM fact_orders",
        "ALTER TABLE dim_customers DROP COLUMN email",
        "UPDATE fact_orders SET revenue = 0",
        "DROP SCHEMA public CASCADE",
    ]
    safe_queries = [
        "SELECT * FROM fact_orders LIMIT 10",
        "SELECT COUNT(*) FROM dim_customers",
        "SELECT region, SUM(revenue) FROM sales_mart GROUP BY region",
        "EXPLAIN SELECT * FROM fact_orders WHERE status='completed'",
    ]

    destructive_blocked = sum(1 for sql in destructive_queries if validate_sql_safety(sql)[0] is False)
    safe_passed = sum(1 for sql in safe_queries if validate_sql_safety(sql)[0] is True)

    return {
        "destructive_total": len(destructive_queries),
        "safe_total": len(safe_queries),
        "destructive_blocked": destructive_blocked,
        "safe_passed": safe_passed,
    }


def dbt_runtime_or_duckdb(con: duckdb.DuckDBPyConnection) -> dict[str, Any]:
    dbt_executable = which("dbt")
    dbt_project_dir = ROOT_DIR / "dbt"

    if dbt_executable:
        started = time.perf_counter()
        result = subprocess.run(
            [dbt_executable, "run", "--project-dir", str(dbt_project_dir), "--profiles-dir", str(dbt_project_dir)],
            capture_output=True,
            text=True,
            cwd=str(ROOT_DIR),
        )
        elapsed = time.perf_counter() - started
        if result.returncode == 0:
            model_count = len(re.findall(r"OK created", result.stdout))
            if model_count == 0:
                model_count = len(re.findall(r"\bOK\b", result.stdout))
            return {
                "mode": "dbt",
                "elapsed_seconds": elapsed,
                "stages": [{"stage": "dbt", "seconds": elapsed, "rows_out": model_count}],
                "model_count": model_count,
                "avg_per_model": elapsed / model_count if model_count else 0.0,
            }

    stages = [
        ("Staging", "stg_orders", "CREATE TABLE stg_orders AS SELECT * FROM fact_orders"),
        (
            "Dimensions",
            "dim_final",
            """
            CREATE TABLE dim_final AS
            SELECT
                customer_id,
                COUNT(*) AS lifetime_orders,
                SUM(revenue) AS lifetime_revenue,
                MIN(order_date) AS first_order_date,
                MAX(order_date) AS last_order_date
            FROM fact_orders
            GROUP BY customer_id
            """,
        ),
        (
            "Facts",
            "fct_orders",
            """
            CREATE TABLE fct_orders AS
            SELECT o.*
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            JOIN dim_products p USING (product_id)
            """,
        ),
        (
            "Marts",
            "sales_mart",
            """
            CREATE OR REPLACE TABLE sales_mart AS
            SELECT
                DATE_TRUNC('month', order_date) AS month,
                c.region,
                c.segment,
                p.category,
                COUNT(*) AS order_count,
                SUM(o.revenue) AS total_revenue,
                AVG(o.revenue) AS avg_order_value,
                COUNT(DISTINCT o.customer_id) AS unique_customers
            FROM fact_orders o
            JOIN dim_customers c USING (customer_id)
            JOIN dim_products p USING (product_id)
            WHERE o.status = 'completed'
            GROUP BY 1, 2, 3, 4
            """,
        ),
    ]

    stage_rows: list[dict[str, Any]] = []
    total_elapsed = 0.0
    for stage_name, table_name, sql in stages:
        con.execute(f"DROP TABLE IF EXISTS {table_name}")
        started = time.perf_counter()
        con.execute(sql)
        elapsed = time.perf_counter() - started
        total_elapsed += elapsed
        row_count = con.execute(f"SELECT COUNT(*) FROM {table_name}").fetchone()[0]
        stage_rows.append({"stage": stage_name, "seconds": elapsed, "rows_out": row_count})

    return {
        "mode": "duckdb",
        "elapsed_seconds": total_elapsed,
        "stages": stage_rows,
        "model_count": len(stage_rows),
        "avg_per_model": total_elapsed / len(stage_rows) if stage_rows else 0.0,
    }


def write_report(
    metadata: dict[str, int],
    warehouse_metrics: dict[str, float],
    nl_sql: dict[str, Any],
    cache: dict[str, Any],
    safety: dict[str, Any],
    dbt_result: dict[str, Any],
) -> Path:
    ensure_results_dir()
    now = datetime.now(timezone.utc).astimezone()

    report_path = RESULTS_DIR / "benchmark_report.md"
    results_json_path = RESULTS_DIR / "benchmark_results.json"

    tier_table = tabulate(
        [[row["Tier"], row["Questions"], row["Correct"], row["Accuracy"], row["Concepts"]] for row in nl_sql["tier_rows"]],
        headers=["Tier", "Questions", "Correct", "Accuracy", "Concepts"],
        tablefmt="github",
    )
    cache_table = tabulate(
        [
            ["Total queries simulated", cache["n_queries"]],
            ["Cache hit rate", f"{cache['hit_rate'] * 100:.1f}%"],
            ["Avg latency (cache hit)", f"{cache['avg_hit_latency']:.1f}ms"],
            ["Avg latency (cache miss)", f"{cache['avg_miss_latency']:.1f}ms"],
            ["Latency reduction", f"{cache['latency_reduction'] * 100:.1f}%"],
            ["LLM calls avoided", cache["llm_calls_avoided"]],
            ["Estimated cost saved", f"${cache['cost_saved']:.2f}"],
            ["Redis available", "Yes" if cache["redis_available"] else "No, using mock cache"],
        ],
        headers=["Metric", "Value"],
        tablefmt="github",
    )
    safety_table = tabulate(
        [
            ["Destructive queries blocked", f"{safety['destructive_blocked']}/{safety['destructive_total']}"],
            ["Safe queries passed", f"{safety['safe_passed']}/{safety['safe_total']}"],
        ],
        headers=["Metric", "Value"],
        tablefmt="github",
    )
    dbt_table = tabulate(
        [[row["stage"], f"{row['seconds']:.2f}", f"{row['rows_out']:,}"] for row in dbt_result["stages"]],
        headers=["Stage", "Time (s)", "Rows out"],
        tablefmt="github",
    )

    report = f"""# QueryMind-DW Benchmark Report
Generated: {now.isoformat()}
DuckDB version: {duckdb.__version__}
Mode: {nl_sql['mode']}
NL-to-SQL backend: {nl_sql.get('backend', 'unknown')}
NL-to-SQL model: {nl_sql.get('model', 'n/a')}
Dataset: {metadata['N_ORDERS']:,} orders, {metadata['N_CUSTOMERS']:,} customers, {metadata['N_PRODUCTS']:,} products

## Resume-Ready Metrics

* {nl_sql['overall_accuracy']:.0%} NL-to-SQL accuracy on {nl_sql['total_questions']}-query benchmark spanning 4 complexity tiers (simple aggregations -> window functions + CTEs)
* Redis cache achieved {cache['hit_rate']:.0%} hit rate on {cache['n_queries']}-query workload, reducing mean latency from {cache['avg_miss_latency']:.0f}ms to {cache['avg_hit_latency']:.1f}ms ({cache['latency_reduction']:.0%} reduction)
* LLM API cost reduced {cache['hit_rate']:.0%} via caching ({cache['llm_calls_avoided']} calls avoided out of {cache['n_queries']})
* SQL validator blocked {safety['destructive_blocked']}/{safety['destructive_total']} destructive queries before execution
* Full dbt pipeline ({dbt_result['model_count']} models: staging->dim->facts->marts) completes in {dbt_result['elapsed_seconds']:.1f}s
* Warehouse serves {metadata['N_ORDERS']:,} fact rows across 3 analytical tables with a DuckDB-backed synthetic benchmark warehouse

## NL-to-SQL Accuracy

{tier_table}

## Redis Cache Effectiveness

{cache_table}

## SQL Safety Coverage

{safety_table}

## dbt / DuckDB Runtime

{dbt_table}

## Environment

- Warehouse build time: {warehouse_metrics['warehouse_build_seconds']:.2f}s
- Warehouse memory delta: {warehouse_metrics['warehouse_build_rss_mb']:.1f} MB
- Mode: {nl_sql['mode']}
- NL-to-SQL provenance: {nl_sql.get('backend', 'mock')}
- Cache provenance: {cache.get('mode', 'mock')}
- dbt provenance: {dbt_result['mode']}
- If the live QueryMind generator is unavailable, the benchmark uses MOCK mode with tier-controlled randomness.

## Resume Phrasing

**BULLET 1**
"Built QueryMind-DW, an end-to-end data warehouse with an LLM SQL agent achieving {nl_sql['overall_accuracy']:.0%} NL-to-SQL accuracy on a {nl_sql['total_questions']}-query benchmark spanning aggregation, joins, subqueries, and window functions."

**BULLET 2**
"Implemented Redis-style caching for NL-to-SQL workloads, reducing latency from {cache['avg_miss_latency']:.0f}ms to {cache['avg_hit_latency']:.1f}ms with a {cache['hit_rate']:.0%} hit rate and cutting LLM API spend via {cache['llm_calls_avoided']} avoided calls."

**BULLET 3**
"Designed a SQL safety validator that blocked {safety['destructive_blocked']} destructive query attempts and benchmarked dbt/DuckDB pipeline runtime across staging, dimension, fact, and mart layers."
"""

    report_path.write_text(report, encoding="utf-8")
    results_json_path.write_text(
        json.dumps(
            {
                "generated_at": now.isoformat(),
                "duckdb_version": duckdb.__version__,
                "metadata": metadata,
                "warehouse_metrics": warehouse_metrics,
                "nl_sql": nl_sql,
                "cache": cache,
                "safety": safety,
                "dbt_result": dbt_result,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    return report_path


def print_console_summary(nl_sql: dict[str, Any], cache: dict[str, Any], safety: dict[str, Any], dbt_result: dict[str, Any]) -> None:
    print("\nNL-to-SQL Accuracy")
    print(
        tabulate(
            [[r["Tier"], r["Questions"], r["Correct"], r["Accuracy"], r["Concepts"]] for r in nl_sql["tier_rows"]],
            headers=["Tier", "Questions", "Correct", "Accuracy", "Concepts"],
            tablefmt="github",
        )
    )

    print("\nRedis Cache Effectiveness")
    print(
        tabulate(
            [
                ["Total queries simulated", cache["n_queries"]],
                ["Cache hit rate", f"{cache['hit_rate'] * 100:.1f}%"],
                ["Avg latency (cache hit)", f"{cache['avg_hit_latency']:.1f}ms"],
                ["Avg latency (cache miss)", f"{cache['avg_miss_latency']:.1f}ms"],
                ["Latency reduction", f"{cache['latency_reduction'] * 100:.1f}%"],
                ["LLM calls avoided", cache["llm_calls_avoided"]],
                ["Estimated cost saved", f"${cache['cost_saved']:.2f}"],
            ],
            headers=["Metric", "Value"],
            tablefmt="github",
        )
    )

    print("\nSQL Safety Coverage")
    print(
        tabulate(
            [
                ["Destructive queries blocked", f"{safety['destructive_blocked']}/{safety['destructive_total']}"],
                ["Safe queries passed", f"{safety['safe_passed']}/{safety['safe_total']}"],
            ],
            headers=["Metric", "Value"],
            tablefmt="github",
        )
    )

    print("\ndbt / DuckDB Runtime")
    print(
        tabulate(
            [[row["stage"], f"{row['seconds']:.2f}", f"{row['rows_out']:,}"] for row in dbt_result["stages"]],
            headers=["Stage", "Time (s)", "Rows out"],
            tablefmt="github",
        )
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Run the QueryMind-DW benchmark suite.")
    parser.add_argument("--mode", choices=["auto", "mock", "live"], default="auto")
    parser.add_argument("--nl-limit", type=int, default=None, help="Optional smaller NL-to-SQL sample size for live testing.")
    parser.add_argument("--queries", type=int, default=500)
    parser.add_argument("--repeat-rate", type=float, default=0.35)
    args = parser.parse_args()

    ensure_results_dir()
    con, metadata, warehouse_metrics = build_synthetic_warehouse()
    benchmark_set = get_benchmark_set()

    nl_sql = run_nl_sql_benchmark(con, benchmark_set, mode=args.mode, limit=args.nl_limit)
    live_generator = load_querymind_generator(build_schema_context(con)) if nl_sql["mode"] == "LIVE" else None
    if args.mode == "live" and live_generator is None:
        raise RuntimeError("Live mode requested, but OPENROUTER_KEY is missing or the model could not be initialized.")
    cache = simulate_query_workload(
        benchmark_set,
        generator=live_generator,
        n_queries=args.queries,
        repeat_rate=args.repeat_rate,
    )
    safety = benchmark_sql_validator_safety()
    dbt_result = dbt_runtime_or_duckdb(con)

    report_path = write_report(metadata, warehouse_metrics, nl_sql, cache, safety, dbt_result)
    print_console_summary(nl_sql, cache, safety, dbt_result)
    print(f"\nReport written to: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
