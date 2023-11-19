SELECT
   EXTRACT(MONTH from order_purchase_timestamp) as Month,
   COUNT(order_id)as No_of_orders
  FROM `Target.orders`
  GROUP BY Month
  ORDER BY 1;

-- Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).
-- You can use the "payment_value" column in the payments table to get the cost of orders.

  SELECT ((total_cost_2018 - total_cost_2017) / total_cost_2017) * 100 AS percentage_increase
FROM
 (SELECT
   (SELECT SUM(payment_value)
    FROM `Target.payments` as p
    JOIN `Target.orders` as o ON p.order_id = o.order_id
    WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2017
      AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8) AS total_cost_2017,
   (SELECT SUM(payment_value)
    FROM `Target.payments` as p
    JOIN `Target.orders` as o ON p.order_id = o.order_id
    WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
      AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8) AS total_cost_2018
 ) AS costs


--During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
-- 0-6 hrs : Dawn
-- 7-12 hrs : Mornings
-- 13-18 hrs : Afternoon
-- 19-23 hrs : Night
 
SELECT
  CASE
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 and 6 THEN 'Dawn'
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 and 12 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 and 18 THEN 'Afternoon'
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 19 and 23 THEN 'Night'
  END AS Time_of_day,
  COUNT(*) AS No_of_orders
FROM
  `Target.orders`
GROUP BY
  time_of_day
ORDER BY
  No_of_orders DESC;

--   Evolution of E-commerce orders in the Brazil region:
-- A. Get the month on month no. of orders placed in each state.


SELECT
   c.customer_state,
   EXTRACT(MONTH FROM order_purchase_timestamp) AS Month,
   COUNT(order_id) AS No_of_orders
FROM `Target.orders` AS o
LEFT JOIN `Target.customers` AS c
ON o.customer_id = c.customer_id
GROUP BY Month, c.customer_state
ORDER BY c.customer_state, Month;

--How are the customers distributed across all the states?

SELECT
   customer_state,
   COUNT(customer_unique_id) AS No_of_unique_customers
FROM `Target.customers`
GROUP BY customer_state
ORDER BY customer_state

--Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.

-- Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).
-- You can use the "payment_value" column in the payments table to get the cost of orders.

with year2017 as (
SELECT
 EXTRACT(YEAR from order_purchase_timestamp) as Year,
 EXTRACT(MONTH from order_purchase_timestamp) as Month,
 round(SUM(payment_value),0) as cost_of_orders,
FROM `Target.payments` as p
JOIN `Target.orders` as o
 ON
p.order_id = o.order_id
group by Year,Month
having Year = 2017 and Month between 1 and 8
order by year,Month),
year2018 as (
SELECT
 EXTRACT(YEAR from order_purchase_timestamp) as Year,
 EXTRACT(MONTH from order_purchase_timestamp) as Month,
 round(SUM(payment_value),0) as cost_of_orders
FROM `Target.payments` as p
JOIN `Target.orders` as o
 ON
p.order_id = o.order_id
group by Year,Month
having Year = 2018 and Month between 1 and 8
order by year,Month),
prd as 
(select
product_id
from `Target.products`)
select
  distinct prd.product_id,
  year2017.cost_of_orders AS Cost_2017,
  year2018.cost_of_orders AS Cost_2018
from year2017,year2018,prd



SELECT
o.order_id,
EXTRACT(Date FROM order_purchase_timestamp) as Date
FROM `Target.orders` as o
join `Target.payments` as p
on o.order_id = p.order_id

--Calculate the Total & Average value of order price for each state.
SELECT
 customer_state,
 ROUND(sum(o.price),0) AS total_price,
 ROUND(avg(o.price),0) AS average_price
FROM `Target.order_items`AS o
JOIN `Target.orders` AS od
ON o.order_id = od.order_id
JOIN `Target.customers` AS c
ON od.customer_id = c.customer_id
GROUP BY 
 customer_state
ORDER BY customer_state

--Calculate the Total & Average value of order freight for each state.

SELECT
 customer_state,
 ROUND(sum(o.freight_value),0) AS total_freight_value,
 ROUND(avg(o.freight_value),0) AS average_freight_value
FROM `Target.order_items`AS o
JOIN `Target.orders` AS od
ON o.order_id = od.order_id
JOIN `Target.customers` AS c
ON od.customer_id = c.customer_id
GROUP BY 
 customer_state
ORDER BY customer_state

-- Find the no. of days taken to deliver each order from the order’s purchase date as delivery time.
-- Also, calculate the difference (in days) between the estimated & actual delivery date of an order.Do this in a single query.

SELECT
order_id,
extract(DATE FROM order_purchase_timestamp)as order_purchase_date,
extract(DATE FROM order_delivered_customer_date) as order_deliverd_date,
extract(DATE FROM order_estimated_delivery_date)as Estimated_delivery_date,
DATE_DIFF((extract(DATE FROM order_delivered_customer_date)),(extract(DATE FROM order_purchase_timestamp)),Day) as Time_To_Deliver,
DATE_DIFF((extract(DATE FROM order_estimated_delivery_date)) ,(extract(DATE FROM order_delivered_customer_date)), Day) as Diff_Estimated_Delivery
FROM `Target.orders`
order by order_purchase_date

--Find out the top 5 states with the highest & lowest average freight value.

WITH avg_freight AS (
  SELECT
    c.customer_state,
    ROUND(AVG(o.freight_value),0) AS average_freight_value,
    ROW_NUMBER() OVER (ORDER BY AVG(o.freight_value)) AS rn_asc,
    ROW_NUMBER() OVER (ORDER BY AVG(o.freight_value) DESC) AS rn_desc
  FROM `Target.order_items` AS o
  JOIN `Target.orders` AS od ON o.order_id = od.order_id
  JOIN `Target.customers` AS c ON od.customer_id = c.customer_id
  GROUP BY
    c.customer_state
)
SELECT
  CASE
    WHEN rn_desc <= 5 THEN 'Top 5 states with Highest_avg_freight_value'
    WHEN rn_asc <= 5 THEN 'Top 5 states with lowest_avg_freight_value'
    ELSE ''
  END AS freight_category,
   customer_state,
  average_freight_value
FROM avg_freight
WHERE rn_asc <= 5 OR rn_desc <= 5
ORDER BY average_freight_value;


(SELECT
    c.customer_state,
    ROUND(AVG(o.freight_value),0) AS average_freight_value,
  FROM `Target.order_items` AS o
  JOIN `Target.orders` AS od ON o.order_id = od.order_id
  JOIN `Target.customers` AS c ON od.customer_id = c.customer_id
  GROUP BY
    c.customer_state
  )

  SELECT customer_state,average_order_freight
FROM
(
 SELECT c.customer_state,
    ROUND(AVG(oi.freight_value),2) AS average_order_freight
FROM `Target.orders` AS o
LEFT JOIN `Target.customers` AS c ON
o.customer_id = c.customer_id
LEFT JOIN `Target.order_items` AS oi ON
oi.order_id = o.order_id
GROUP BY c.customer_state
)
ORDER BY average_order_freight DESC
LIMIT 5

--Find out the top 5 states with the highest & lowest average delivery time.
    
WITH avg_freight AS (
  SELECT
    c.customer_state,
    ROUND(AVG(DATE_DIFF((extract(DATE FROM order_delivered_customer_date)),(extract(DATE FROM order_purchase_timestamp)),Day)),0)as Avg_Delivery_time,
    ROW_NUMBER() OVER (ORDER BY AVG(DATE_DIFF((extract(DATE FROM order_delivered_customer_date)),(extract(DATE FROM order_purchase_timestamp)),Day))) AS rn_asc,
    ROW_NUMBER() OVER (ORDER BY AVG(DATE_DIFF((extract(DATE FROM order_delivered_customer_date)),(extract(DATE FROM order_purchase_timestamp)),Day)) DESC) AS rn_desc
  FROM `Target.order_items` AS o
  JOIN `Target.orders` AS od ON o.order_id = od.order_id
  JOIN `Target.customers` AS c ON od.customer_id = c.customer_id
  GROUP BY
    c.customer_state
)
SELECT
  CASE
    WHEN rn_desc <= 5 THEN 'Top 5 states with Highest_Avg_Delivery_time'
    WHEN rn_asc <= 5 THEN 'Top 5 states with lowest_Avg_Delivery_time'
    ELSE ''
  END AS freight_category,
   customer_state,
  Avg_Delivery_time
FROM avg_freight
WHERE rn_asc <= 5 OR rn_desc <= 5
ORDER BY Avg_Delivery_time;

--Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.

WITH avg_delivery AS (
  SELECT
    c.customer_state,
    ROUND((AVG(DATE_DIFF(DATE(order_estimated_delivery_date), DATE(order_delivered_customer_date), DAY))),0) as Avg_diff_estimated_delivery,
    ROW_NUMBER() OVER (ORDER BY AVG(DATE_DIFF(DATE(order_estimated_delivery_date), DATE(order_delivered_customer_date), DAY))DESC) AS top_fast_delivery
  FROM `Target.order_items` AS o
  JOIN `Target.orders` AS od ON o.order_id = od.order_id
  JOIN `Target.customers` AS c ON od.customer_id = c.customer_id
  WHERE order_delivered_customer_date IS NOT NULL 
  GROUP BY
    c.customer_state
)
SELECT
   customer_state as Top_5_fast_delivery_states,
   Avg_diff_estimated_delivery
FROM avg_delivery
WHERE top_fast_delivery <= 5
ORDER BY Avg_diff_estimated_delivery DESC;


-- 6.Analysis based on the payments:
-- Find the month on month no. of orders placed using different payment types.

SELECT
EXTRACT(YEAR FROM order_purchase_timestamp) as Year,
EXTRACT(MONTH FROM order_purchase_timestamp) as Month,
payment_type,
count(p.order_id) as No_of_orders
FROM `Target.payments` as p
JOIN `Target.orders` as o ON
p.order_id = o.order_id
GROUP BY Year,Month,payment_type
ORDER BY Year,Month,payment_type

-- B. Find the no. of orders placed on the basis of the payment installments that have been paid.

SELECT
payment_installments,
count(order_id) as No_of_Orders
FROM `Target.payments`
WHERE payment_installments <> 0
GROUP BY payment_installments

