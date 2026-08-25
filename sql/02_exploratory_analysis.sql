-- ==========================================================
-- 1. Dataset Overview
-- ==========================================================

-- Count the number of records in each table
SELECT
    COUNT(*) AS total_orders,
    MIN(order_purchase_timestamp) AS first_order_date,
    MAX(order_purchase_timestamp) AS last_order_date
FROM orders;

-- Compare the number of records in each table
SELECT
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT customer_unique_id) AS unique_customer_ids
FROM customers;

-- Count the number of records in the order_items table
SELECT
    COUNT(*) AS total_order_items,
    COUNT(DISTINCT seller_id) AS total_sellers,
    COUNT(DISTINCT product_id) AS total_products,
    COUNT(DISTINCT order_id) AS total_order_items
FROM order_items;

-- Dataset timeperiod boundaries
SELECT
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- ==========================================================
-- 2. Order Status
-- ==========================================================

SELECT order_status, COUNT(*) AS total_orders,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS percentage_of_orders
FROM orders
GROUP BY order_status;

-- ==========================================================
-- 3. Revenue Overview
-- ==========================================================

-- Calculate total revenue
SELECT ROUND(SUM(payment_value), 2) AS total_revenue
FROM order_payments;

-- Calculate average payment value per order
SELECT ROUND(AVG(payment_value), 2) AS average_payment_value
FROM order_payments;

-- Calculate the minimum and maximum payment values
SELECT ROUND(MIN(payment_value), 2) AS minimum_payment_value,
        ROUND(MAX(payment_value), 2) AS maximum_payment_value
FROM order_payments;

-- ==========================================================
-- 4. Revenue by month
-- ==========================================================

SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    ROUND(SUM(payment_value), 2) AS total_revenue
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY month
ORDER BY month;

-- ==========================================================
-- 5. Orders by Month
-- ==========================================================

SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    COUNT(*) AS total_orders
FROM orders
GROUP BY month
ORDER BY month;

-- Investigate the November 2017 spike

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

-- ==========================================================
-- 6. Average Order Value
-- ==========================================================

WITH order_totals AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_order_value
    FROM order_payments
    GROUP BY order_id
)

SELECT 
    ROUND(AVG(total_order_value), 2) AS average_order_value
FROM order_totals;

-- ==========================================================
-- 7. Customer Overview
-- ==========================================================

SELECT COUNT(*) AS total_customer_records,
        COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers;

-- Investiage repeat customers
SELECT customer_unique_id,
        COUNT(*) AS total_customer_records
FROM customers
GROUP By customer_unique_id
HAVING COUNT(*) > 1
ORDER BY total_customer_records DESC;

-- ==========================================================
-- 8. Repeat Customer Rate
-- ==========================================================

WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)

SELECT 
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE total_orders > 1) AS repeat_customers,
    ROUND(COUNT(*) FILTER (WHERE total_orders > 1) * 100.0 / COUNT(*), 2) AS repeat_customer_percentage
FROM customer_orders;

-- Number of orders that customers are making
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

-- ==========================================================
-- 9. Product categories
-- ==========================================================

-- Find out what cusotmers are buying
SELECT
    COALESCE(p.product_category_name, 'Unknown') AS product_category,
    COUNT(*) AS items_sold

FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY product_category
ORDER BY items_sold DESC
LIMIT 20;

-- ==========================================================
-- 10. Sellers overview
-- ==========================================================

-- Find out which sellers are selling the most
SELECT
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS total_items_sold
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.seller_state
ORDER BY total_items_sold DESC
LIMIT 20;

-- ==========================================================
-- 11. Geography Overview
-- ==========================================================

-- Find out where customers are located at the state level
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY orders DESC;

-- ==========================================================
-- 12. Payment methods Overview
-- ==========================================================

SELECT
    payment_type,
    COUNT(*) AS payment_count,
    ROUND(SUM(payment_value), 2) AS total_revenue,
    ROUND(AVG(payment_value), 2) AS average_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_revenue DESC;

-- Investigate Payment anomalies
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

-- Investigate Payment anomalies cont. 
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM order_payments
WHERE payment_value = 0
ORDER BY payment_type, order_id;

-- ==========================================================
-- 13. Reviews Overview
-- ==========================================================

-- View customer satisfaction by looking at the distribution of review scores
SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM order_reviews), 2) AS percentage_of_reviews
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;