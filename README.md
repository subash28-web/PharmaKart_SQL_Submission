# PharmaKart SQL Analysis

## Project Description
SQL-based analysis of customer, sales, product, coupon, and delivery data.

## Tools Used
- PostgreSQL
- pgAdmin 4
- SQL

## Database Tables
- customers
- orders
- order_items
- products
- coupons

## How to Run
1. Create a PostgreSQL database named 'pharmakart_db'.
2. Import the five source data files.
3. Open 'Raushbyte SQL assignment.sql' in pgAdmin Query Tool.
4. Execute the queries in order, after confirming the database schema.

## Assumptions
- Order-status filters are documented in the relevant queries.
- Product revenue is calculated as quantity × unit price.
- Delivery time is calculated only when both order and delivery dates are available.
- Customer segments use the thresholds documented in the SQL analysis.
- Data discrepancies are investigated rather than automatically treated as errors.
