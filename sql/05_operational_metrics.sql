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
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
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
-- 2. Average Delivery Time
-- ==========================================================

-- Average delivery time
SELECT
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp) / 86400)::numeric,2) AS average_delivery_days
FROM orders o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;


-- ==========================================================
-- 3. Median Delivery Time
-- ==========================================================

-- Median delivery time

SELECT
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY EXTRACT(
                EPOCH FROM (
                    o.order_delivered_customer_date
                    - o.order_purchase_timestamp
                )
            ) / 86400
        )::numeric,
        2
    ) AS median_delivery_days
FROM orders o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;

-- ==========================================================
-- 4. Delivery Performance by seller
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
-- 5. Delivery Performance by state
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
-- 6. Estimated vs. Actual Delivery Time
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


-- ==========================================================
-- 7. Delivery Performance by Seller
-- ==========================================================

-- Delivery performance by seller

WITH seller_orders AS (
    SELECT DISTINCT
        oi.order_id,
        oi.seller_id
    FROM order_items oi
)

SELECT
    so.seller_id,
    COUNT(*) AS delivered_orders,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date::date
                 < o.order_estimated_delivery_date::date
            THEN 1 ELSE 0
        END
    ) AS early_deliveries,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date::date
                 = o.order_estimated_delivery_date::date
            THEN 1 ELSE 0
        END
    ) AS on_time_deliveries,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date::date
                 > o.order_estimated_delivery_date::date
            THEN 1 ELSE 0
        END
    ) AS late_deliveries,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date::date
                     > o.order_estimated_delivery_date::date
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_rate

FROM seller_orders so
JOIN orders o
    ON so.order_id = o.order_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY so.seller_id
ORDER BY late_rate DESC;

-- ==========================================================
-- 8. Review Score vs. Delivery Performance
-- ==========================================================

-- Review score vs. delivery performance

WITH order_reviews AS (
    SELECT
        order_id,
        AVG(review_score) AS average_review_score
    FROM order_reviews
    GROUP BY order_id
),

delivery_performance AS (
    SELECT
        o.order_id,

        CASE
            WHEN o.order_delivered_customer_date::date
                 < o.order_estimated_delivery_date::date
                THEN 'Early'

            WHEN o.order_delivered_customer_date::date
                 = o.order_estimated_delivery_date::date
                THEN 'On Time'

            ELSE 'Late'
        END AS delivery_status

    FROM orders o

    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)

SELECT
    dp.delivery_status,
    COUNT(*) AS orders,
    ROUND(AVG(r.average_review_score)::numeric, 2) AS average_review_score

FROM delivery_performance dp
JOIN order_reviews r
    ON dp.order_id = r.order_id

GROUP BY dp.delivery_status
ORDER BY dp.delivery_status;

-- ==========================================================
-- 9. Overall Delivery Performance Percentages
-- ==========================================================

-- Overall delivery performance

SELECT
    COUNT(*) AS delivered_orders,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date::date
                 < o.order_estimated_delivery_date::date
            THEN 1 ELSE 0
        END
    ) AS early_deliveries,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date::date
                 = o.order_estimated_delivery_date::date
            THEN 1 ELSE 0
        END
    ) AS on_time_deliveries,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date::date
                 > o.order_estimated_delivery_date::date
            THEN 1 ELSE 0
        END
    ) AS late_deliveries,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date::date
                     <= o.order_estimated_delivery_date::date
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS on_time_or_early_rate,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date::date
                     > o.order_estimated_delivery_date::date
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_rate

FROM orders o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL;