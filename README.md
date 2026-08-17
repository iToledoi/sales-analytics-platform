# Olist Sales Analytics Platform

## Overview

This project is an end-to-end sales analytics platform built using the Olist Brazilian E-Commerce dataset.

The goal is to simulate a real-world analytics workflow, from raw data ingestion and cleaning through relational database design, SQL analysis, and executive reporting.

The project combines Python, PostgreSQL, SQL, and Excel to transform raw e-commerce data into actionable business insights.

---

## Business Objective

The objective of this project is to analyze Olist's e-commerce operations and answer key business questions related to:

- Sales performance and revenue growth
- Customer purchasing behavior
- Customer retention and repeat purchases
- Product and category performance
- Seller performance
- Payment methods
- Order fulfillment and delivery performance
- Customer satisfaction and reviews

The final deliverable will be an executive-level Excel dashboard supported by a PostgreSQL analytical database and documented SQL analysis.

---

## Dataset

The project uses the Olist Brazilian E-Commerce dataset, which contains approximately 100,000 orders and related information covering customers, products, sellers, payments, reviews, and geographic data.

### Primary Data Sources

- Customers
- Orders
- Order Items
- Order Payments
- Order Reviews
- Products
- Sellers
- Geolocation
- Product Category Translation

The observed order data spans from September 2016 through October 2018, with incomplete data at the beginning and end of the observation period.

---

## Project Architecture

The project follows an end-to-end analytics pipeline:

Raw CSV Data
        ↓
Python Data Cleaning & Validation
        ↓
Cleaned CSV Data
        ↓
PostgreSQL Relational Database
        ↓
SQL Exploratory & Business Analysis
        ↓
Excel Dashboard
        ↓
Business Recommendations

---

## Data Pipeline

### 1. Data Cleaning

Python and pandas are used to process the raw CSV files.

The cleaning pipeline performs tasks including:

- Handling missing values
- Removing duplicate records where appropriate
- Standardizing whitespace
- Cleaning currency fields
- Converting date and timestamp fields
- Normalizing CSV output
- Validating data quality

The cleaned datasets are written to the `data/cleaned/` directory.

### 2. Database Design

The cleaned data is loaded into PostgreSQL using a normalized relational schema.

The database includes:

- Primary keys
- Foreign keys
- Composite keys
- Constraints
- Indexes
- Referential integrity

The database structure is documented in:

- `database/schema.sql`
- `database/constraints.sql`
- `database/indexes.sql`

### 3. SQL Analysis

SQL is used to perform exploratory and business analysis, including:

- Aggregations
- Joins
- Common Table Expressions (CTEs)
- Window functions
- Conditional aggregation
- Date analysis
- Customer segmentation
- Revenue analysis
- Ranking
- Trend analysis

---

## Database Design



## Data Cleaning & Validation

Before beginning analysis, the database was validated for structural and data-quality issues.

Validation included:

- Primary key uniqueness
- Foreign key integrity
- Duplicate records
- Missing values
- Invalid payment values
- Invalid installment values
- Date consistency
- Order/payment relationships

Several source-data anomalies were identified and documented rather than silently modified.

For example, two credit-card payment records contain zero installments. These records were retained to preserve the source data and flagged as data-quality warnings.

---

## Exploratory Analysis

Initial exploratory analysis has identified several notable patterns.

### Sales Performance

The dataset contains approximately:

- 99,000 orders
- $16.0M in recorded payment value
- $160.99 average order value

Order volume increased substantially throughout 2017 and early 2018.

November 2017 recorded 7,544 orders compared with 4,631 in October 2017, representing approximately 63% month-over-month growth.

### Customer Behavior

Approximately 96,096 unique customers are represented in the dataset.

The observed repeat-purchase rate is approximately 3.12%.

Customer order frequency is heavily concentrated around first-time purchases, with approximately 93,099 customers placing a single order during the observation period.

Because customers who purchased near the end of the dataset had less opportunity to purchase again, repeat-purchase behavior will be treated as an observed rate rather than a definitive long-term retention metric.

### Payment Methods

Credit cards represent the dominant payment method.

Credit-card transactions account for approximately $12.54M in recorded payment value.

Other payment methods include:

- Boleto
- Voucher
- Debit Card

A small number of zero-value payment records were identified and flagged during validation.

### Product Categories

The highest-volume product categories by items sold include:

1. Bed, Bath & Table
2. Health & Beauty
3. Sports & Leisure
4. Furniture & Decoration
5. Computers & Accessories

Further analysis will compare item volume against sales value to identify the categories that generate the greatest financial contribution.

---

## Key Business Questions

The project will investigate questions such as:

### Sales

- How has sales performance changed over time?
- Which months generate the most revenue?
- What caused significant month-over-month changes?
- What is the average order value?
- Which product categories generate the most sales?

### Customers

- How many customers make repeat purchases?
- What does customer order frequency look like?
- Which customers generate the most value?
- How does purchasing behavior vary over time?

### Products

- Which categories sell the most units?
- Which categories generate the most revenue?
- Are high-volume categories also high-value categories?
- Which products have the highest average selling value?

### Sellers

- Which sellers generate the most orders?
- Which sellers generate the most sales?
- Is sales volume concentrated among a small number of sellers?

### Operations

- How long does delivery typically take?
- How often are orders delivered late?
- Does delivery performance vary by region?
- Does delivery performance appear to influence review scores?

### Customers & Satisfaction

- What is the distribution of review scores?
- Does delivery time correlate with customer satisfaction?
- Which categories receive the highest and lowest ratings?

---

## Tools & Technologies

### Programming & Analysis

- Python
- pandas
- NumPy

### Database

- PostgreSQL
- SQL
- pgAdmin 4

### Data Visualization & Reporting

- Microsoft Excel
- Pivot Tables
- Pivot Charts
- Power Query
- Excel Dashboard

### Development

- Git
- GitHub

---

## Project Structure

```text
sales-analytics-platform/
│
├── README.md
│
├── data/
│   ├── raw/
│   └── cleaned/
│
├── database/
│   ├── schema.sql
│   ├── constraints.sql
│   ├── indexes.sql
│   └── load_data.sql
│
├── sql/
│   ├── 01_exploratory_analysis.sql
│   ├── 02_sales_analysis.sql
│   ├── 03_customer_analysis.sql
│   ├── 04_product_analysis.sql
│   └── 05_business_insights.sql
│
├── python/
│   ├── clean_data.py
│   ├── config.py
│   ├── utils.py
│   └── validators.py
│
├── excel/
│   └── Olist_Executive_Dashboard.xlsx
│
├── reports/
│   └── data_quality_report.txt
│
└── images/
    └── dashboard.png
```
---

## Key Findings
(WIP will be updated)
Current findings include:

- Approximately 97% of orders are marked as delivered.
- Recorded payment value totals approximately $16.0M.
- Average order value is approximately $160.99.
- Approximately 3.12% of unique customers made more than one purchase during the observation period.
- November 2017 experienced approximately 63% month-over-month growth in order volume compared with October.
- Credit cards account for the majority of recorded payment value.
- The dataset contains incomplete periods at the beginning and end of the observation window.

---
  
## Future Analysis
The next stages of the project will include:

- Advanced SQL sales analysis
- Customer segmentation
- Product and category revenue analysis
- Seller performance analysis
- Delivery performance analysis
- Review and satisfaction analysis
- Excel executive dashboard
- Business recommendations
- Final portfolio documentation

---

## How to Run
### Requirements
- PostgreSQL
- pgAdmin 4
- Python 3.x
- pandas
- Git
  
### Database Setup
1. Create a PostgreSQL database.
2. Execute database/schema.sql.
3. Execute database/constraints.sql.
4. Execute database/indexes.sql.
5. Run the Python data-cleaning pipeline.
6. Load the cleaned CSV files using database/load_data.sql.
7. Execute the SQL analysis scripts in the sql/ directory.
