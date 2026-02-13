"""
Get Products Lambda Function

Queries the product catalog from Aurora PostgreSQL.
Uses ElastiCache Redis for caching to reduce database load.

In a production setup, this would use a connection pool (e.g., psycopg2)
and proper VPC configuration to reach Aurora and Redis.
"""

import json
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_NAME = os.environ.get("DB_NAME", "ecommerce")
REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = os.environ.get("REDIS_PORT", "6379")

# Cache TTL in seconds
CACHE_TTL = 300  # 5 minutes


def handler(event, context):
    """
    Handle GET /products request.

    Checks Redis cache first, falls back to Aurora if cache miss.

    Args:
        event: API Gateway proxy event
        context: Lambda context

    Returns:
        API Gateway proxy response
    """
    logger.info("Get products request received")
    logger.info("Path: %s", event.get("path", "/"))
    logger.info("Query params: %s", json.dumps(event.get("queryStringParameters") or {}))

    try:
        # Extract query parameters
        params = event.get("queryStringParameters") or {}
        category = params.get("category", "all")
        page = int(params.get("page", "1"))
        limit = min(int(params.get("limit", "20")), 100)  # Max 100

        cache_key = f"products:{category}:page{page}:limit{limit}"
        logger.info("Cache key: %s", cache_key)

        # --- Step 1: Try Redis cache ---
        # In production, uncomment and use redis-py:
        # import redis
        # r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT)
        # cached = r.get(cache_key)
        # if cached:
        #     logger.info("Cache HIT for %s", cache_key)
        #     return response(200, json.loads(cached))

        logger.info("Cache MISS for %s (Redis not connected in demo mode)", cache_key)

        # --- Step 2: Query Aurora ---
        # In production, uncomment and use psycopg2:
        # import psycopg2
        # conn = psycopg2.connect(
        #     host=DB_HOST,
        #     dbname=DB_NAME,
        #     user="dbadmin",
        #     password="from-secrets-manager"
        # )
        # cursor = conn.cursor()
        # cursor.execute(
        #     "SELECT id, name, price, category, description FROM products "
        #     "WHERE category = %s OR %s = 'all' "
        #     "ORDER BY name LIMIT %s OFFSET %s",
        #     (category, category, limit, (page - 1) * limit)
        # )
        # products = [
        #     {"id": r[0], "name": r[1], "price": float(r[2]),
        #      "category": r[3], "description": r[4]}
        #     for r in cursor.fetchall()
        # ]

        # Mock product data for demo purposes
        products = [
            {
                "id": "prod-001",
                "name": "Wireless Headphones",
                "price": 79.99,
                "category": "electronics",
                "description": "High-quality wireless headphones with noise cancellation",
                "in_stock": True,
            },
            {
                "id": "prod-002",
                "name": "USB-C Cable",
                "price": 12.99,
                "category": "electronics",
                "description": "Durable braided USB-C charging cable, 2m",
                "in_stock": True,
            },
            {
                "id": "prod-003",
                "name": "Laptop Stand",
                "price": 45.00,
                "category": "accessories",
                "description": "Ergonomic aluminum laptop stand",
                "in_stock": True,
            },
            {
                "id": "prod-004",
                "name": "Mechanical Keyboard",
                "price": 129.99,
                "category": "electronics",
                "description": "RGB mechanical keyboard with Cherry MX switches",
                "in_stock": False,
            },
        ]

        # Filter by category if specified
        if category != "all":
            products = [p for p in products if p["category"] == category]

        result = {
            "products": products,
            "pagination": {
                "page": page,
                "limit": limit,
                "total": len(products),
            },
            "cache": "MISS",
        }

        # --- Step 3: Store in Redis cache ---
        # r.setex(cache_key, CACHE_TTL, json.dumps(result))

        return response(200, result)

    except Exception as e:
        logger.error("Error fetching products: %s", str(e))
        return response(500, {"error": "Internal server error"})


def response(status_code, body):
    """Build API Gateway proxy response."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
        },
        "body": json.dumps(body),
    }
