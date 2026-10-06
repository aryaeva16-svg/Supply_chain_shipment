CREATE TABLE shipments (
    type VARCHAR(50),
    days_for_shipping_real INT,
    days_for_shipment_scheduled INT,
    benefit_per_order DECIMAL(12,2),
    sales_per_customer DECIMAL(12,2),
    delivery_status VARCHAR(50),
    late_delivery_risk TINYINT,
    category_name VARCHAR(100),
    customer_city VARCHAR(100),
    customer_country VARCHAR(100),
    customer_segment VARCHAR(50),
    customer_state VARCHAR(50),
    department_name VARCHAR(100),
    market VARCHAR(50),
    order_city VARCHAR(100),
    order_country VARCHAR(100),
    order_date_dateorders DATETIME,
    order_item_discount DECIMAL(12,2),
    order_item_discount_rate DECIMAL(6,4),
    order_item_product_price DECIMAL(12,2),
    order_item_profit_ratio DECIMAL(8,4),
    order_item_quantity INT,
    sales DECIMAL(12,2),
    order_item_total DECIMAL(12,2),
    order_profit_per_order DECIMAL(12,2),
    order_region VARCHAR(100),
    order_state VARCHAR(100),
    order_status VARCHAR(50),
    product_name VARCHAR(255),
    shipping_date_dateorders DATETIME,
    shipping_mode VARCHAR(50),
    route VARCHAR(150),
    delivery_delay_days INT,
    estimated_cost DECIMAL(12,2),
    cost_per_unit DECIMAL(12,4),
    storage_cost DECIMAL(12,2)
);

LOAD DATA INFILE '/path/to/dataco_cleaned.csv'
INTO TABLE shipments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- Aggregate shipment costs by route, carrier (shipping mode)
SELECT
    route,
    shipping_mode,
    COUNT(*) AS num_shipments,
    ROUND(SUM(estimated_cost), 2) AS total_cost,
    ROUND(AVG(estimated_cost), 2) AS avg_cost_per_shipment
FROM shipments
GROUP BY route, shipping_mode
ORDER BY total_cost DESC
LIMIT 20;
 -- Cost per unit delivered by geography (regional variance)
 SELECT
    order_region,
    ROUND(AVG(cost_per_unit), 2) AS avg_cost_per_unit,
    ROUND(MIN(cost_per_unit), 2) AS min_cost_per_unit,
    ROUND(MAX(cost_per_unit), 2) AS max_cost_per_unit,
    COUNT(*) AS num_orders
FROM shipments
GROUP BY order_region
ORDER BY avg_cost_per_unit DESC;
-- Slow-moving SKUs eating storage costs
SELECT
    product_name,
    SUM(order_item_quantity) AS total_units_sold,
    ROUND(SUM(storage_cost), 2) AS total_storage_cost,
    ROUND(AVG(days_for_shipment_scheduled), 1) AS avg_dwell_days
FROM shipments
GROUP BY product_name
HAVING total_units_sold < (SELECT AVG(order_item_quantity) FROM shipments)
ORDER BY total_storage_cost DESC
LIMIT 20;
-- late delivery cost impact
SELECT
    shipping_mode,
    ROUND(AVG(delivery_delay_days), 2) AS avg_delay_days,
    ROUND(SUM(estimated_cost), 2) AS total_cost,
    SUM(late_delivery_risk) AS late_deliveries
FROM shipments
GROUP BY shipping_mode
ORDER BY late_deliveries DESC;
-- cost rank within region
SELECT
    order_region,
    route,
    ROUND(AVG(cost_per_unit), 2) AS avg_cost_per_unit,
    RANK() OVER (PARTITION BY order_region ORDER BY AVG(cost_per_unit) DESC) AS cost_rank
FROM shipments
GROUP BY order_region, route
ORDER BY order_region, cost_rank;
