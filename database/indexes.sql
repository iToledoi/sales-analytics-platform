-- indexes.sql
-- Performance Indexes


-- Customers
CREATE INDEX idx_customers_city
ON customers(customer_city);

CREATE INDEX idx_customers_state
ON customers(customer_state);

-- Orders
CREATE INDEX idx_orders_customer
ON orders(customer_id);

CREATE INDEX idx_orders_purchase_date
ON orders(order_purchase_timestamp);

CREATE INDEX idx_orders_status
ON orders(order_status);

-- Order Items
CREATE INDEX idx_items_product
ON order_items(product_id);

CREATE INDEX idx_items_seller
ON order_items(seller_id);

-- Products
CREATE INDEX idx_products_category
ON products(product_category_name);

-- Sellers
CREATE INDEX idx_sellers_state
ON sellers(seller_state);

-- Payments
CREATE INDEX idx_payments_type
ON order_payments(payment_type);

-- Reviews
CREATE INDEX idx_reviews_score
ON order_reviews(review_score);