----Create a table for import dataset

CREATE TABLE coupons (
    coupon_code VARCHAR(50),
	dicount_type VARCHAR(50),
	dicount_value NUMERIC(10,2),
	min_order_value NUMERIC(10,2),
	max_discount NUMERIC(10,2),
	valid_from DATE,
	valid_to DATE,
    campaign_type VARCHAR(100)
);

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
	full_name VARCHAR(50),
	gender VARCHAR(50),
	age INTEGER,
	email VARCHAR(80),
    city VARCHAR(100),
    state VARCHAR(100),
	signup_date DATE,
    acquisition_channel VARCHAR(100),
	signup_platform VARCHAR(50)
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR(200),
    category VARCHAR(100),
	is_chronic BOOLEAN,
    requires_prescription BOOLEAN,
	is_generic BOOLEAN,
	mrp NUMERIC(10,2),
	selling_price NUMERIC(10,2)
);



CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    order_date TIMESTAMP,
    order_status VARCHAR(50),
	payment_method VARCHAR(50),
    platform VARCHAR(50),
    coupon_code VARCHAR(50),
    subtotal NUMERIC(12,2),
    coupon_discount NUMERIC(12,2),
    delivery_fee NUMERIC(10,2),
    total_amount NUMERIC(12,2),
    delivery_date TIMESTAMP
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
	unit_mrp NUMERIC(10,2),
    unit_price NUMERIC(10,2)
);

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

----checking data

SELECT * FROM coupons ;
SELECT * FROM customers ;
SELECT * FROM products ;
SELECT * FROM orders ;
SELECT * FROM order_items ;

----Part 1 — Get the basic picture

--How many customers, orders and products are in the database?

SELECT COUNT(*) AS total_customers FROM customers

SELECT COUNT(*) AS total_orders FROM orders

SELECT COUNT(*) AS total_products FROM products

--How are customers distributed by city/state? Which locations have the most customers?

SELECT city, COUNT(customer_id) AS total_customers FROM customers
GROUP BY city 
ORDER BY total_customers DESC ;

SELECT state, COUNT(customer_id) AS total_customers FROM customers
GROUP BY state 
ORDER BY total_customers DESC ;

--How many orders are in each order status?

SELECT order_status , COUNT(order_id) as order_count FROM orders
GROUP BY order_status
ORDER BY order_count DESC ;

-- What is the total order value and average order value?

SELECT SUM(total_amount) AS total_order_value FROM orders ;

SELECT AVG(total_amount) AS average_order_value FROM orders ;

-- How does order value differ by platform?

SELECT platform , COUNT(order_id) AS total_orders FROM orders
GROUP BY platform
ORDER BY total_orders DESC ;

--Which acquisition channels have brought the most customers?

SELECT acquisition_channel, COUNT(customer_id) AS total_customers FROM customers
GROUP BY acquisition_channel 
ORDER BY total_customers DESC ;

--Do the acquisition channels also differ when you look at customers who actually placed an order?

SELECT acquisition_channel, COUNT(customer_id) AS total_customers FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders)
GROUP BY acquisition_channel 
ORDER BY total_customers DESC ;

----Part 2 — What are customers buying?

--Which product categories sell the most units?

SELECT p.category,SUM(oi.quantity) AS total_quantity FROM products p 
JOIN order_items oi 
ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY total_quantity DESC ;

--Which 10 products have the highest quantity sold?

SELECT p.product_name,SUM(oi.quantity) AS total_quantity FROM products p 
JOIN order_items oi 
ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY total_quantity DESC 
LIMIT 10 ;

--Which 10 products generate the most revenue using quantity × unit_price?

SELECT p.product_id, p.product_name, SUM(oi.quantity*oi.unit_price) AS total_revenue FROM products p 
JOIN order_items oi 
ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC 
LIMIT 10 ;

--Compare product MRP and selling price. Which products have the largest percentage discount?

SELECT product_name, product_id, mrp, selling_price, ROUND(((mrp - selling_price) / NULLIF(mrp, 0)) * 100,2) AS discount_percentage 
FROM products
WHERE mrp > selling_price
ORDER BY discount_percentage DESC; 

SELECT product_id, product_name, mrp, selling_price, SUM(mrp-selling_price) AS discount_amount FROM products
GROUP BY product_id, product_name, mrp, selling_price
ORDER BY discount_amount DESC; 

--Check whether generic and non-generic products show different sales patterns

SELECT CASE WHEN p.is_generic = true THEN 'Generic' else 'Non_Generic' END AS product_type,
SUM(oi.quantity) AS total_units_sold,
ROUND(SUM(oi.quantity*oi.unit_price),2) AS total_revenue,
COUNT(DISTINCT p.product_id) AS total_product FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.is_generic
ORDER BY total_revenue DESC ;

--Check whether prescription and non-prescription products show different sales patterns

SELECT CASE WHEN p.requires_prescription = true THEN 'Prescription' else 'Non_Prescription' END AS product_type,
SUM(oi.quantity) AS total_units_sold,
ROUND(SUM(oi.quantity*oi.unit_price),2) AS total_revenue,
COUNT(DISTINCT p.product_id) AS total_product FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.requires_prescription
ORDER BY total_revenue DESC ;

----Part 3 — Marketing wants to understand coupons

-- Which coupon codes are used most often?

SELECT coupon_code, COUNT(order_id) AS total_order FROM orders
WHERE coupon_code IS not null
GROUP BY coupon_code
ORDER BY total_order DESC ;

--Join the coupon information to the orders and compare usage across campaign types?


SELECT c.campaign_type, COUNT(o.order_id) AS total_orders, COUNT(DISTINCT o.coupon_code) AS unique_coupons FROM orders o
JOIN coupons c ON o.coupon_code = c.coupon_code
GROUP BY c.campaign_type
ORDER BY total_orders DESC;

--How much discount has been given through each coupon code?

SELECT coupon_code, COUNT(order_id) AS total_order, ROUND(SUM(coupon_discount), 2) AS total_discount_given FROM orders
WHERE coupon_code IS not null
GROUP BY coupon_code
ORDER BY total_discount_given DESC ;

--Compare customers who used a coupon with customers who did not. Look at order count andspending.


SELECT CASE WHEN coupon_code IS not null AND TRIM(coupon_code) <> '' THEN 'Coupon Used' ELSE 'No Coupon' END AS coupon_status,
COUNT(DISTINCT customer_id) AS total_customers,
COUNT(order_id) AS total_orders,
ROUND(SUM(total_amount), 2) AS total_spending,
ROUND(AVG(total_amount), 2) AS avg_order_value FROM orders
GROUP BY CASE WHEN coupon_code IS not null AND TRIM(coupon_code) <> '' THEN 'Coupon Used' ELSE 'No Coupon' END
ORDER BY total_spending DESC;

--Find orders with unusually large coupon discounts and investigate which coupon codes are involved    

WITH discount_stats AS (
    SELECT
        AVG(coupon_discount) AS avg_discount,
        STDDEV_POP(coupon_discount) AS std_discount
    FROM orders
    WHERE coupon_code IS NOT NULL
      AND TRIM(coupon_code) <> ''
      AND coupon_discount IS NOT NULL
)
SELECT
    o.order_id,
    o.customer_id,
    o.coupon_code,
    o.coupon_discount,
    ROUND(d.avg_discount, 2) AS avg_discount,
    ROUND(d.std_discount, 2) AS std_discount
FROM orders o
CROSS JOIN discount_stats d
WHERE o.coupon_code IS NOT NULL
  AND TRIM(o.coupon_code) <> ''
  AND o.coupon_discount > d.avg_discount + (2 * d.std_discount)
ORDER BY o.coupon_discount DESC;

----Part 4 — Finance found a mismatch

--Using order_items, calculate the item-level amount as quantity × unit_price.

SELECT order_id, quantity, unit_price, SUM(quantity*unit_price) AS total_revenue FROM order_items
GROUP BY order_id, quantity, unit_price 
ORDER BY order_id ;

--Compare the item-level total with the order subtotal for each order.

SELECT order_id, SUM(subtotal) AS order_subtotal FROM orders
GROUP BY order_id
ORDER BY order_id ;

--Find orders where the two numbers do not match.


----Part 5 — Delivery check

--Calculate delivery time from order_date to delivery_date where both dates are available.

SELECT order_id, order_date, delivery_date, delivery_date::date - order_date::date AS delivery_days FROM orders
WHERE order_date IS NOT NULL AND delivery_date IS NOT NULL AND delivery_date >= order_date
ORDER BY delivery_days DESC ;

--Find the average delivery time.


SELECT ROUND( AVG(delivery_date::date - order_date::date), 2) AS avg_delivery_days, COUNT(*) AS total_delivered_orders
FROM orders
WHERE order_date IS NOT NULL AND delivery_date IS NOT NULL AND delivery_date >= order_date;

--Compare delivery time by platform and by location

SELECT
    platform,
    COUNT(*) AS total_orders,
    ROUND(
        AVG(delivery_date::date - order_date::date),
        2
    ) AS avg_delivery_days,
    MAX(delivery_date::date - order_date::date)
        AS max_delivery_days
FROM orders
WHERE order_date IS NOT NULL
  AND delivery_date IS NOT NULL
  AND delivery_date >= order_date
GROUP BY platform
ORDER BY avg_delivery_days;


select * from orders

