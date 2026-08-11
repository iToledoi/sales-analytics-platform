-- ==========================================================
-- Olist Sales Analytics Platform
-- verify_database.sql
-- Database Validation
-- ==========================================================


-- ==========================================================
-- 1. ROW COUNTS
-- ==========================================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM geolocation

UNION ALL

SELECT 'orders', COUNT(*)
FROM orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM order_items

UNION ALL

SELECT 'order_payments', COUNT(*)
FROM order_payments

UNION ALL

SELECT 'order_reviews', COUNT(*)
FROM order_reviews

UNION ALL

SELECT 'products', COUNT(*)
FROM products

UNION ALL

SELECT 'sellers', COUNT(*)
FROM sellers

UNION ALL

SELECT 'product_category_name_translation', COUNT(*)
FROM product_category_name_translation

ORDER BY table_name;

-- ==========================================================
-- 2. PRIMARY KEY VALIDATION
-- ==========================================================

--Customers
SELECT customer_id, COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

--Orders
SELECT order_id, COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

--Order Items
SELECT order_id, order_item_id, COUNT(*) AS duplicate_count
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

--Products
SELECT product_id, COUNT(*) AS duplicate_count
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

--Sellers
SELECT seller_id, COUNT(*) AS duplicate_count
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- ==========================================================
-- 3. COMPOSITE KEYS
-- ==========================================================

--Order Items
SELECT
    order_id,
    order_item_id,
    COUNT(*)
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

--Payments
SELECT
    order_id,
    payment_sequential,
    COUNT(*)
FROM order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

-- ==========================================================
-- 4. FOREIGN KEY VALIDATION
-- ==========================================================

--Orders → Customers
SELECT COUNT(*) AS orphaned_orders
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

--Order Items → Orders
SELECT COUNT(*) AS orphaned_order_items
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

--Order Items → Products
SELECT COUNT(*) AS orphaned_products
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

--Order Items → Sellers
SELECT COUNT(*) AS orphaned_sellers
FROM order_items oi
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

--Payments → Orders
SELECT COUNT(*) AS orphaned_payments
FROM order_payments op
LEFT JOIN orders o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

--Reviews → Orders
SELECT COUNT(*) AS orphaned_reviews
FROM order_reviews r
LEFT JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- ==========================================================
-- 5. NULL VALIDATION
-- ==========================================================

--Customers
SELECT COUNT(*) AS invalid_customers
FROM customers
WHERE customer_id IS NULL;

--Orders
SELECT COUNT(*) AS invalid_orders
FROM orders
WHERE order_id IS NULL
   OR customer_id IS NULL;

--Order Items
SELECT COUNT(*) AS invalid_order_items
FROM order_items
WHERE order_id IS NULL
   OR order_item_id IS NULL
   OR product_id IS NULL
   OR seller_id IS NULL;

--Products
SELECT COUNT(*) AS invalid_products
FROM products
WHERE product_id IS NULL;

--Sellers
SELECT COUNT(*) AS invalid_sellers
FROM sellers
WHERE seller_id IS NULL;

-- ==========================================================
-- 6. BUSINESS/DATA VALIDATION
-- ==========================================================

--Review scores
SELECT COUNT(*) AS invalid_reviews
FROM order_reviews
WHERE review_score NOT BETWEEN 1 AND 5;

-- Payment values
SELECT COUNT(*) AS negative_payments
FROM order_payments
WHERE payment_value < 0;

-- Payment installments
SELECT COUNT(*) AS invalid_installments
FROM order_payments
WHERE payment_installments <= 0;

-- Product dimensions
SELECT COUNT(*) AS invalid_product_dimensions
FROM products
WHERE product_weight_g < 0
   OR product_length_cm < 0
   OR product_height_cm < 0
   OR product_width_cm < 0;

-- ==========================================================
-- 7. DATE VALIDATION
-- ==========================================================

-- Orders should not be delivered before they are purchased
SELECT COUNT(*) AS invalid_delivery_dates
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

SELECT COUNT(*) AS invalid_approval_dates
FROM orders
WHERE order_approved_at < order_purchase_timestamp;

SELECT COUNT(*) AS invalid_estimated_dates
FROM orders
WHERE order_estimated_delivery_date < order_purchase_timestamp;

-- ==========================================================
-- 8. ORDER STATUS VALIDATION
-- ==========================================================

SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- ==========================================================
-- 9. DUPLICATE VALIDATION DEBUG
-- ==========================================================

SELECT
    review_id,
    order_id,
    COUNT(*)
FROM order_reviews
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;