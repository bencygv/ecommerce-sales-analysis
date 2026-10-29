-- =====================================================
-- E-COMMERCE SALES ANALYSIS
-- =====================================================
-- DATA TRANSFORMATION
-- =====================================================
-- Create an analysis-ready dataset for Power BI
-- =====================================================

CREATE OR REPLACE VIEW
sales_analysis AS

SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS purchase_year,
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS purchase_month,
    o.order_delivered_customer_date,
    EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) AS delivery_days,
    o.order_estimated_delivery_date,
    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN 'Not Delivered'
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,
    oi.product_id,
    p.product_category_name,
    COALESCE(ct.product_category_name_english,'Unknown') AS product_category,
    oi.price,
    oi.freight_value,
    ROUND(oi.price + oi.freight_value, 2) AS total_item_value
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name;

-- Validate the analysis-ready view

SELECT COUNT(*) AS total_rows
FROM sales_analysis;