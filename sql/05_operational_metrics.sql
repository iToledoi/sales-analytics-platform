-- ==========================================================
-- 05 OPERATIONAL METRICS
-- ==========================================================

-- ==========================================================
-- 1. Delivery Performance over time
-- ==========================================================

-- Investigate delivery performance over time by week
SELECT
    DATE_TRUNC('week', o.order_purchase_timestamp) AS week,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN o.order_delivered_customer_date < o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS early_deliveries,
    SUM(CASE WHEN o.order_delivered_customer_date = o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_deliveries
FROM orders o
GROUP BY DATE_TRUNC('week', o.order_purchase_timestamp)
ORDER BY week;

-- Investigate delivery performance over time by month
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN o.order_delivered_customer_date < o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS early_deliveries,
    SUM(CASE WHEN o.order_delivered_customer_date = o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_deliveries
FROM orders o
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;

-- Investigate delivery performance over time by year
SELECT
    DATE_TRUNC('year', o.order_purchase_timestamp) AS year,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN o.order_delivered_customer_date < o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS early_deliveries,
    SUM(CASE WHEN o.order_delivered_customer_date = o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_deliveries
FROM orders o
GROUP BY DATE_TRUNC('year', o.order_purchase_timestamp)
ORDER BY year;

-- ==========================================================
-- 2. Dilvery Performance by seller
-- ==========================================================

-- Investigate seller performance
SELECT
    s.seller_id,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN o.order_delivered_customer_date < o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS early_deliveries,
    SUM(CASE WHEN o.order_delivered_customer_date = o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_deliveries
FROM orders o
JOIN sellers s
    ON o.seller_id = s.seller_id
GROUP BY s.seller_id
ORDER BY s.seller_id;

-- ==========================================================
-- 3. Delivery Performance by state
-- ==========================================================

-- Investigate geographic differences
SELECT
    s.seller_state,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN o.order_delivered_customer_date < o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS early_deliveries,
    SUM(CASE WHEN o.order_delivered_customer_date = o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_deliveries
FROM orders o
JOIN sellers s
    ON o.seller_id = s.seller_id
GROUP BY s.seller_state
ORDER BY s.seller_state;

-- ==========================================================
-- 4. Estimated vs. Actual Delivery Time
-- ==========================================================

-- Cacluate delivery variance (early, on time, late) by month
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    CASE
        WHEN o.order_delivered_carrier_date IS NULL OR o.order_delivered_customer_date IS NULL THEN 'Unknown'
        WHEN o.order_delivered_customer_date < o.order_estimated_delivery_date THEN 'Early'
        WHEN o.order_delivered_customer_date = o.order_estimated_delivery_date THEN 'On Time'
        ELSE 'Late'
    END AS delivery_variance,
    COUNT(*) AS order_count
FROM orders o
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp), delivery_variance
ORDER BY month, delivery_variance;