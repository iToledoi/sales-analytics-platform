-- ==========================================================
-- 04 CUSTOMER ANALYSIS
-- ==========================================================

-- ==========================================================
-- 1. Customer acquisition
-- ==========================================================

-- New customers acquired over time by month
WITH customer_first_order AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC(
            'month',
            MIN(o.order_purchase_timestamp)
        ) AS first_order_month
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)

SELECT
    first_order_month AS month,
    COUNT(*) AS new_customers
FROM customer_first_order
GROUP BY first_order_month
ORDER BY first_order_month;

-- Customer growth over time by month
WITH monthly_customers AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        COUNT(DISTINCT c.customer_unique_id) AS new_customers
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT
    month,
    new_customers,
    LAG(new_customers, 1) OVER (ORDER BY month) AS previous_month_customers,
    ROUND(((new_customers - LAG(new_customers, 1) OVER (ORDER BY month)) / LAG(new_customers, 1) OVER (ORDER BY month)) * 100, 2) AS month_over_month_growth
FROM monthly_customers
ORDER BY month;

-- ==========================================================
-- 2. Customer behavior
-- ==========================================================

-- Orders per customer distribution
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)

SELECT
    order_count,
    COUNT(*) AS customers
FROM customer_orders
GROUP BY order_count
ORDER BY order_count;

-- One time vs repeat customers
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(DISTINCT CASE WHEN order_count = 1 THEN customer_unique_id END) AS one_time_customers,
    COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_unique_id END) AS repeat_customers
FROM customer_orders;

-- Avergae orders per customer
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    AVG(order_count) AS average_orders_per_customer
FROM customer_orders;

-- ==========================================================
-- 3. Customer value
-- ==========================================================

-- Customer lifetime value (CLV) by month
WITH customer_value AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.price + oi.freight_value) AS lifetime_value
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    total_orders,
    ROUND(lifetime_value::numeric, 2) AS lifetime_value
FROM customer_value
ORDER BY lifetime_value DESC;

-- Top customers by spending
SELECT
    c.customer_unique_id,
    SUM(oi.price + oi.freight_value) AS total_spent
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;

-- Revenue distribution by customer segment
WITH customer_segments AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price + oi.freight_value) AS total_spent
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN total_spent < 100 THEN 'Low Value'
        WHEN total_spent BETWEEN 100 AND 500 THEN 'Medium Value'
        ELSE 'High Value'
    END AS customer_segment,
    COUNT(DISTINCT customer_unique_id) AS customer_count
FROM customer_segments
GROUP BY customer_segment;

-- ==========================================================
-- 4. Customer Retention
-- ==========================================================

-- Calculate the repeat purchase rate
SELECT
    COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_unique_id END) * 100.0 / COUNT(DISTINCT customer_unique_id) AS repeat_purchase_rate
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) AS customer_orders;

-- Average time between purchases
SELECT
    AVG(time_between_purchases) AS average_time_between_purchases
FROM (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp - LAG(o.order_purchase_timestamp) OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) AS time_between_purchases
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
) AS customer_purchases;

-- Cohort analysis for customer retention
WITH customer_cohorts AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', MIN(o.order_purchase_timestamp)) AS cohort_month,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id, DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT
    cohort_month,
    order_month,
    COUNT(DISTINCT customer_unique_id) AS retained_customers
FROM customer_cohorts
GROUP BY cohort_month, order_month
ORDER BY cohort_month, order_month;

-- ==========================================================
-- 5. Customer segmentation
-- ==========================================================

-- Customer segmentation based on RFM (Recency, Frequency, Monetary) analysis
WITH customer_rfm AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.price + oi.freight_value) AS total_spent
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    last_order_date,
    order_count,
    total_spent,
    CASE
        WHEN last_order_date = MAX(o.order_purchase_timestamp) - INTERVAL '30 days' THEN 'Active'
        WHEN last_order_date >= MAX(o.order_purchase_timestamp) - INTERVAL '90 days' THEN 'At Risk'
        ELSE 'Churned'
    END AS recency_segment,
    CASE
        WHEN order_count = 1 THEN 'One-time'
        WHEN order_count BETWEEN 2 AND 5 THEN 'Occasional'
        ELSE 'Frequent'
    END AS frequency_segment,
    CASE
        WHEN total_spent < 100 THEN 'Low Value'
        WHEN total_spent BETWEEN 100 AND 500 THEN 'Medium Value'
        ELSE 'High Value'
    END AS monetary_segment
FROM customer_rfm
ORDER BY total_spent DESC;