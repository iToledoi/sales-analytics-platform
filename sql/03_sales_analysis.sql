-- ==========================================================
-- 02 SALES ANALYSIS
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
SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
    ROUND((SUM(oi.price + oi.freight_value) / SUM(SUM(oi.price + oi.freight_value)) OVER ()) * 100, 2) AS percent_of_total_sales
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY percent_of_total_sales DESC;

-- ==========================================================
-- 6. What is driving AOV? (Average Order Value)
-- ==========================================================

-- Calculate average order value over time
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(AVG(oi.price + oi.freight_value), 2) AS average_order_value
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
    p.product_name,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 10;
