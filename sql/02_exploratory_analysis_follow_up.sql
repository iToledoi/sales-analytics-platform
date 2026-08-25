-- A. Confirm the true dataset boundaries
SELECT
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- B. Investigate the customer distribution
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

-- D. Investigate the November 2017 spike
SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    COUNT(*) AS orders
FROM orders
WHERE order_purchase_timestamp >= '2017-10-01'
  AND order_purchase_timestamp < '2017-12-01'
GROUP BY month
ORDER BY month;

WITH monthly_orders AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp) AS month,
        COUNT(*) AS orders
    FROM orders
    WHERE order_purchase_timestamp >= '2017-10-01'
      AND order_purchase_timestamp < '2017-12-01'
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
)

SELECT
    month,
    orders,
    ROUND(
        (
            orders - LAG(orders) OVER (ORDER BY month)
        ) * 100.0
        / LAG(orders) OVER (ORDER BY month),
        2
    ) AS month_over_month_growth
FROM monthly_orders
ORDER BY month;

-- E. Payment anomalies
SELECT
    payment_type,
    COUNT(*) AS transactions,
    COUNT(*) FILTER (
        WHERE payment_value = 0
    ) AS zero_value_transactions,
    ROUND(SUM(payment_value)::numeric, 2) AS total_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_value DESC;

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM order_payments
WHERE payment_value = 0
ORDER BY payment_type, order_id;