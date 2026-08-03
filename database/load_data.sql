-- load_sata.sql

COPY customers
FROM 'D:\CodingProjects\sales-analytics-platform\data\cleaned\customers.csv'
DELIMITER ','
CSV HEADER;

COPY geolocation
FROM 'D:\CodingProjects\sales-analytics-platform\data\cleaned\geolocation.csv'
DELIMITER ','
CSV HEADER
ENCODING 'ISO-8859-1';

COPY order_items
FROM 'D:\CodingProjects\sales-analytics-platform\data\cleaned\order_items.csv'
DELIMITER ','
CSV HEADER;

COPY order_payments
FROM 'D:\CodingProjects\sales-analytics-platform\data\cleaned\order_payments.csv'
DELIMITER ','
CSV HEADER;

COPY order_reviews
FROM 'D:\CodingProjects\sales-analytics-platform\data\cleaned\order_reviews.csv'
DELIMITER ','
CSV HEADER;

COPY orders
FROM 'D:\CodingProjects\sales-analytics-platform\data\cleaned\orders.csv'
DELIMITER ','
CSV HEADER;

COPY product_category_name_translation
FROM 'D:\CodingProjects\sales-analytics-platform\data\cleaned\product_category_name_translation.csv'
DELIMITER ','
CSV HEADER;

COPY products
FROM 'D:\CodingProjects\sales-analytics-platform\data\cleaned\products.csv'
DELIMITER ','
CSV HEADER;

COPY sellers
FROM 'D:\CodingProjects\sales-analytics-platform\data\cleaned\sellers.csv'
DELIMITER ','
CSV HEADER;