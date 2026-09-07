-- ==========================================================
-- 03 SALES ANALYSIS
-- ==========================================================

-- ==========================================================
-- 1. ORDER-LEVEL FINANCIAL MODEL
-- ==========================================================

SELECT
    oi.order_id,
    SUM(oi.price) AS product_sales,
    SUM(oi.freight_value) AS freight_value,
    SUM(oi.price + oi.freight_value) AS total_order_value
FROM order_items oi
GROUP BY oi.order_id
ORDER BY total_order_value DESC;

-- ==========================================================
-- 2. Sales trends over time
-- ==========================================================

-- Monthly trends
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;

-- Calculate month-over-month growth
WITH monthly_orders AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        COUNT(DISTINCT o.order_id) AS orders,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT
    month,
    orders,
    total_revenue,
    LAG(total_revenue, 1) OVER (ORDER BY month) AS previous_month_revenue,
    ROUND(((total_revenue - LAG(total_revenue, 1) OVER (ORDER BY month)) / LAG(total_revenue, 1) OVER (ORDER BY month)) * 100, 2) AS month_over_month_growth
FROM monthly_orders
ORDER BY month;

-- Calculate year-over-year growth
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(oi.price + oi.freight_value) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)

SELECT
    month,
    ROUND(revenue::numeric, 2) AS revenue,
    ROUND(
        LAG(revenue, 12) OVER (ORDER BY month)::numeric,
        2
    ) AS previous_year_revenue,
    ROUND(
        (
            (revenue - LAG(revenue, 12) OVER (ORDER BY month))
            /
            NULLIF(LAG(revenue, 12) OVER (ORDER BY month), 0)
            * 100
        )::numeric,
        2
    ) AS year_over_year_growth
FROM monthly_sales
ORDER BY month;

-- ==========================================================
-- 3. Product/category performance
-- ==========================================================

--COmpare items sold, product sales, freight, total value, average item price, % of total sales
SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;

SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS average_item_price,
    ROUND((SUM(oi.price + oi.freight_value) / SUM(SUM(oi.price + oi.freight_value)) OVER ()) * 100, 2) AS percent_of_total_sales
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;


-- ==========================================================
-- 4. Seller performance
-- ==========================================================

-- Analyze sellers and rank them
SELECT
    s.seller_id,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS average_item_price,
    ROUND((SUM(oi.price + oi.freight_value) / SUM(SUM(oi.price + oi.freight_value)) OVER ()) * 100, 2) AS percent_of_total_sales
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY s.seller_id
ORDER BY total_revenue DESC;

SELECT 
    s.seller_id,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS average_item_price,
    ROUND((SUM(oi.price + oi.freight_value) / SUM(SUM(oi.price + oi.freight_value)) OVER ()) * 100, 2) AS percent_of_total_sales,
    RANK() OVER (ORDER BY SUM(oi.price + oi.freight_value) DESC) AS revenue_rank
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY s.seller_id
ORDER BY revenue_rank;

-- ==========================================================
-- 5. Sales concentration
-- ==========================================================

-- Identify which product categories are driving the most revenue, and percent of total sales
WITH seller_sales AS (
    SELECT
        s.seller_id,
        SUM(oi.price + oi.freight_value) AS total_revenue
    FROM sellers s
    JOIN order_items oi
        ON s.seller_id = oi.seller_id
    GROUP BY s.seller_id
),

ranked_sellers AS (
    SELECT
        seller_id,
        total_revenue,
        RANK() OVER (
            ORDER BY total_revenue DESC
        ) AS revenue_rank,
        SUM(total_revenue) OVER () AS marketplace_revenue,
        SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue
    FROM seller_sales
)

SELECT
    seller_id,
    revenue_rank,
    ROUND(total_revenue::numeric, 2) AS total_revenue,
    ROUND(
        (total_revenue / marketplace_revenue * 100)::numeric,
        2
    ) AS percent_of_total_sales,
    ROUND(
        (cumulative_revenue / marketplace_revenue * 100)::numeric,
        2
    ) AS cumulative_percent_of_sales
FROM ranked_sellers
ORDER BY revenue_rank;

-- ==========================================================
-- 6. What is driving AOV? (Average Order Value)
-- ==========================================================

-- Calculate monthly AOV at the order level

WITH order_values AS (
    SELECT
        o.order_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)
)

SELECT
    month,
    COUNT(order_id) AS orders,
    ROUND(SUM(order_value)::numeric, 2) AS total_revenue,
    ROUND(AVG(order_value)::numeric, 2) AS average_order_value
FROM order_values
GROUP BY month
ORDER BY month;

-- Calculate AOV growth
WITH order_values AS (
    SELECT
        o.order_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)
),

monthly_aov AS (
    SELECT
        month,
        AVG(order_value) AS average_order_value
    FROM order_values
    GROUP BY month
)

SELECT
    month,
    ROUND(average_order_value::numeric, 2) AS average_order_value,
    ROUND(
        LAG(average_order_value) OVER (ORDER BY month)::numeric,
        2
    ) AS previous_month_aov,
    ROUND(
        (
            (average_order_value -
                LAG(average_order_value) OVER (ORDER BY month))
            /
            NULLIF(LAG(average_order_value) OVER (ORDER BY month), 0)
        )::numeric * 100,
        2
    ) AS month_over_month_aov_growth
FROM monthly_aov
ORDER BY month;

-- Analyze the trends in average order value over time
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(AVG(oi.price + oi.freight_value), 2) AS average_order_value,
    LAG(AVG(oi.price + oi.freight_value), 1) OVER (ORDER BY DATE_TRUNC('month', o.order_purchase_timestamp)) AS previous_month_aov,
    ROUND(((AVG(oi.price + oi.freight_value) - LAG(AVG(oi.price + oi.freight_value), 1) OVER (ORDER BY DATE_TRUNC('month', o.order_purchase_timestamp))) / LAG(AVG(oi.price + oi.freight_value), 1) OVER (ORDER BY DATE_TRUNC('month', o.order_purchase_timestamp))) * 100, 2) AS month_over_month_aov_growth
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;

-- ==========================================================
-- 7. Key Sales Findings
-- ==========================================================

-- Identify top-selling products, categories, and sellers
SELECT
    p.product_id,
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_category_name
ORDER BY total_revenue DESC
LIMIT 10;
