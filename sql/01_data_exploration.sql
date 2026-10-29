/*
Project: E-Commerce Sales Analysis
Dataset: Brazilian E-Commerce Public Dataset by Olist

Purpose:
Explore the dataset and validate the imported data before
performing sales and business analysis.

Tools:
PostgreSQL
*/

-- ============================================
-- 1. DATASET OVERVIEW
-- ============================================

-- Number of customers
SELECT COUNT(*) AS total_customer_records
FROM customers;

-- Number of orders
SELECT COUNT(*) AS total_orders
FROM orders;

-- Number of order items
SELECT COUNT(*) AS total_order_items
FROM order_items;

-- Number of products
SELECT COUNT(*) AS total_products
FROM products;

-- Number of translated product categories
SELECT COUNT(*) AS total_categories
FROM category_translation;

-- ============================================
-- 2. DATA QUALITY CHECKS
-- ============================================

-- Check missing values in customers
SELECT
    COUNT(*) AS total_rows,
    COUNT(customer_id) AS customer_id_count,
    COUNT(customer_unique_id) AS unique_id_count,
    COUNT(customer_zip_code_prefix) AS zip_code_count,
    COUNT(customer_city) AS city_count,
    COUNT(customer_state) AS state_count
FROM customers;

-- Check duplicate customer IDs
SELECT
    customer_id,
    COUNT(*) AS occurrences
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Check customers with multiple customer records
SELECT
    customer_unique_id,
    COUNT(*) AS occurrences
FROM customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1;

-- Check order status distribution
SELECT
    order_status,
    COUNT(*) AS number_of_orders
FROM orders
GROUP BY order_status
ORDER BY number_of_orders DESC;

-- Check missing values in orders
SELECT
    COUNT(*) AS total_orders,
    COUNT(order_id) AS order_id_count,
    COUNT(customer_id) AS customer_id_count,
    COUNT(order_status) AS status_count,
    COUNT(order_purchase_timestamp) AS purchase_date_count,
    COUNT(order_approved_at) AS approved_date_count,
    COUNT(order_delivered_carrier_date) AS carrier_date_count,
    COUNT(order_delivered_customer_date) AS delivered_date_count,
    COUNT(order_estimated_delivery_date) AS estimated_delivery_count
FROM orders;

-- Investigate orders with missing delivery dates
SELECT
    order_status,
    COUNT(*) AS missing_delivery_dates
FROM orders
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status
ORDER BY missing_delivery_dates DESC;

-- Investigate delivered orders with missing delivery date
SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- Check missing values in order items
SELECT
    COUNT(*) AS total_rows,
    COUNT(order_id) AS order_id_count,
    COUNT(order_item_id) AS order_item_id_count,
    COUNT(product_id) AS product_id_count,
    COUNT(seller_id) AS seller_id_count,
    COUNT(shipping_limit_date) AS shipping_date_count,
    COUNT(price) AS price_count,
    COUNT(freight_value) AS freight_count
FROM order_items;

-- Check for zero or negative prices
SELECT
    COUNT(*) AS invalid_price_records
FROM order_items
WHERE price <= 0;

-- Check for negative freight values
SELECT
    COUNT(*) AS negative_freight_records
FROM order_items
WHERE freight_value < 0;

-- Check missing values in products
SELECT
    COUNT(*) AS total_products,
    COUNT(product_id) AS product_id_count,
    COUNT(product_category_name) AS category_count,
    COUNT(product_name_length) AS name_length_count,
    COUNT(product_description_length) AS description_length_count,
    COUNT(product_photos_qty) AS photos_count,
    COUNT(product_weight_g) AS weight_count,
    COUNT(product_length_cm) AS length_count,
    COUNT(product_height_cm) AS height_count,
    COUNT(product_width_cm) AS width_count
FROM products;

-- Investigate products with missing categories
SELECT
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty
FROM products
WHERE product_category_name IS NULL;

-- Check missing physical product measurements
SELECT
    COUNT(*) AS total_products,
    COUNT(product_weight_g) AS weight_count,
    COUNT(product_length_cm) AS length_count,
    COUNT(product_height_cm) AS height_count,
    COUNT(product_width_cm) AS width_count
FROM products;

-- Investigate products with missing physical measurements
SELECT
    product_id,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM products
WHERE product_weight_g IS NULL
   OR product_length_cm IS NULL
   OR product_height_cm IS NULL
   OR product_width_cm IS NULL;

SELECT 
    product_category_name,
    product_category_name_english
FROM category_translation;

-- Check product categories without an English translation
SELECT DISTINCT
    p.product_category_name
FROM products p
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND ct.product_category_name_english IS NULL;

-- ============================================
-- 3. BUSINESS ANALYSIS
-- ============================================

-- Calculate total sales revenue
SELECT
    ROUND(SUM(price), 2) AS total_sales_revenue
FROM order_items;

-- Calculate total freight value
SELECT
    ROUND(SUM(freight_value), 2) AS total_freight_value
FROM order_items;

-- Calculate total sales revenue
SELECT
    ROUND(AVG(price), 2) AS average_item_price
FROM order_items;

-- Calculate average order value
SELECT
    ROUND(AVG(order_total), 2) AS average_order_value
FROM (
    SELECT
        order_id,
        SUM(price) AS order_total
    FROM order_items
    GROUP BY order_id
) AS order_totals;

-- Calculate average number of items per order
SELECT
    ROUND(AVG(item_count), 2) AS average_items_per_order
FROM (
    SELECT
        order_id,
        COUNT(*) AS item_count
    FROM order_items
    GROUP BY order_id
) AS order_item_counts;

-- Monthly sales trend
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price), 2) AS monthly_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;

-- Check if in NOvember there was any sales
SELECT COUNT(order_id) AS november_orders
FROM orders
WHERE order_purchase_timestamp >= '2016-11-01'
  AND order_purchase_timestamp < '2016-12-01';

-- Which product categories generated the most revenue?
SELECT
    p.product_category_name,
    ROUND(SUM(oi.price), 2) AS product_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY product_revenue DESC;

-- Which product categories sold the most items?
SELECT
    p.product_category_name,
    COUNT(*) AS total_items_sold
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_items_sold DESC;

-- Which Brazilian states generated the most orders?
SELECT
    c.customer_state,
    COUNT(o.order_id) AS total_orders
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC;

-- Which Brazilian states generated the most sales revenue?
SELECT
    c.customer_state,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

-- Which cities generated the most sales revenue?
SELECT
    c.customer_city,
    c.customer_state,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_city, c.customer_state
ORDER BY total_revenue DESC;

-- How many customers are repeat customers and what percentage do they represent?
SELECT
    COUNT(*) AS repeat_customers,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(DISTINCT customer_unique_id)
         FROM customers),
        2
    ) AS repeat_customer_percentage
FROM (
    SELECT customer_unique_id
    FROM customers
    GROUP BY customer_unique_id
    HAVING COUNT(*) > 1
) AS repeat_customers;

-- What are the top 10 product categories by revenue in English?
SELECT
    ct.product_category_name_english AS category,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY ct.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;

-- How did the number of orders change month by month?
SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY month;

-- What is the average delivery time in days?
SELECT
    ROUND(
        AVG(EXTRACT(DAY FROM
            order_delivered_customer_date - order_purchase_timestamp
        )),
        2
    ) AS average_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- How many delivered orders were late and what percentage were late?
SELECT
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date > order_estimated_delivery_date
    ) AS late_orders,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_delivered_customer_date > order_estimated_delivery_date
        ) * 100.0 / COUNT(*),
        2
    ) AS late_delivery_percentage

FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- Which states have the highest average order value?
SELECT
    customer_state,
    ROUND(AVG(order_total), 2) AS average_order_value
FROM (
    SELECT
        c.customer_state,
        o.order_id,
        SUM(oi.price) AS order_total
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_state, o.order_id
) AS state_orders
GROUP BY customer_state
ORDER BY average_order_value DESC;

-- Which product categories have the highest average product price?
SELECT
    ct.product_category_name_english AS category,
    ROUND(AVG(oi.price), 2) AS average_product_price
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY ct.product_category_name_english
ORDER BY average_product_price DESC
LIMIT 10;