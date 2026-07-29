-- constraints.sql
-- Foreign Keys and Data Validation

-- Orders
ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

-- Products
ALTER TABLE products
ADD CONSTRAINT fk_products_category
FOREIGN KEY (product_category_name)
REFERENCES product_category_name_translation(product_category_name);

-- Order Items
ALTER TABLE order_items
ADD CONSTRAINT fk_items_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_items_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_items_seller
FOREIGN KEY (seller_id)
REFERENCES sellers(seller_id);

-- Payments
ALTER TABLE order_payments
ADD CONSTRAINT fk_payments_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id);


-- Reviews
ALTER TABLE order_reviews
ADD CONSTRAINT fk_reviews_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

-- CHECK Constraints
ALTER TABLE order_reviews
ADD CONSTRAINT chk_review_score
CHECK (review_score BETWEEN 1 AND 5);

ALTER TABLE order_payments
ADD CONSTRAINT chk_payment_value
CHECK (payment_value >= 0);

ALTER TABLE products
ADD CONSTRAINT chk_product_weight
CHECK (product_weight_g >= 0);