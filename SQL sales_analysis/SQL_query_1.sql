create database sales_analysis;

-- BASIC QUESTIONS

-- 1.How many customers do not have DOB information available ?

SELECT COUNT(*) from customer_dim where dob ='';

-- 2.How many customers are there in each pincode and gender combination ?

SELECT p.pincode,c.gender,count(c.cust_id) from customer_dim c inner join 
pincode_dim p on c.primary_pincode=p.pincode group by p.pincode,c.gender order by p.pincode;

-- 3.Print product name and mrp for products which have more than 50000 mrp ?

SELECT product_name, mrp from product_dim where mrp >50000 ;

-- 4.How many delivery personal are there in each pincode ?

SELECT pincode,count(delivery_person_id) from delivery_person_dim 
group by pincode;

-- 5.For each Pin code, print the count of orders, sum of total amount paid, average amount
-- paid, maximum amount paid, minimum amount paid for the transactions which were
-- paid by 'cash'. Take only 'buy' order types ?

Select delivery_pincode,count(order_id),SUM(total_amount_paid),AVG(total_amount_paid),
MAX(total_amount_paid),MIN(total_amount_paid) from order_dim where payment_type='cash' and
order_type = 'buy' group by delivery_pincode;

-- 6. For each delivery_person_id, print the count of orders and total amount paid for
-- product_id = 12350 or 12348 and total units > 8. Sort the output by total amount paid in
-- descending order. Take only 'buy' order types

SELECT delivery_person_id,count(order_id),SUM(total_amount_paid) as total from order_dim 
where product_id in (12350,12348) and tot_units>8 and order_type ='buy'
group by delivery_person_id order by total desc;

-- 7. Print the Full names (first name plus last name) for customers that have email on
-- "gmail.com"?

SELECT CONCAT(first_name,' ',last_name) as full_name from customer_dim where
email like '%gmail.com' ;

-- 8. Which pincode has average amount paid more than 150,000? Take only 'buy' order types

select delivery_pincode ,avg(total_amount_paid) as avg_amount from order_dim
where  order_type ='buy'  group by
delivery_pincode having avg_amount>150000;

-- 9. Create following columns from order_dim data -
--  order_date
--  Order day
--  Order month
--  Order year

Select  order_date ,substring(order_date,7,4) as order_year,
substring(order_date,4,2) as order_month,
substring(order_date,1,2) as order_day from order_dim;

-- 10. How many total orders were there in each month and how many of them were
-- returned? Add a column for return rate too.
-- return rate = (100.0 * total return orders) / total buy orders
-- Hint: You will need to combine SUM() with CASE WHEN

select substring(order_date,4,2) as month,count(order_id) 
as total_orders,sum(case when order_type = 'Return' then 1 else 0 end) as return_orders,
(100.0 * sum(case when order_type = 'Return' then 1 else 0 end) / sum(case when order_type = 'Buy' then 1 else 0 end)) As return_rate
from order_dim group by month;

 
-- 11. How many units have been sold by each brand? Also get total returned units for each
-- brand.

SELECT p.brand,sum(case when o.order_type = 'Buy' then o.tot_units else 0 end) as sold_units,
sum(case when o.order_type = 'Return' then o.tot_units else 0 end) as returned_units
from product_dim p
inner join order_dim o on p.product_id = o.product_id
group by p.brand;

-- 12. How many distinct customers and delivery boys are there in each state?

select  p.state,count(distinct c.cust_id) as total_customers,count(distinct d.delivery_person_id)
as total_delivery_persons from customer_dim as c
inner join  pincode_dim p on p.pincode=c.primary_pincode 
inner join order_dim o on p.pincode = o.delivery_pincode
inner join delivery_person_dim as d on o.delivery_person_id = d.delivery_person_id 
group by p.state;


-- 13. For every customer, print how many total units were ordered, how many units were
-- ordered from their primary_pincode and how many were ordered not from the
-- primary_pincode. Also calulate the percentage of total units which were ordered from
-- primary_pincode(remember to multiply the numerator by 100.0). Sort by the
-- percentage column in descending order.

select c.cust_id,sum(o.tot_units) AS total_units,
sum(case when c.primary_pincode=o.delivery_pincode then o.tot_units else 0 end) as primary_pincode_units,
sum(case when  c.primary_pincode <> o.delivery_pincode  then o.tot_units else 0 end) as notprimary_pincode_units,
(100.0 * sum(case when o.delivery_pincode = c.primary_pincode then o.tot_units else 0 end) / SUM(o.tot_units)) as percent
from customer_dim c inner join order_dim o on c.cust_id = o.cust_id
group by c.cust_id order by percent desc;


-- 14. For each product name, print the sum of number of units, total amount paid, total
-- displayed selling price, total mrp of these units, and finally the net discount from selling
-- price.
-- (i.e. 100.0 - 100.0 * total amount paid / total displayed selling price) &
-- the net discount from mrp (i.e. 100.0 - 100.0 * total amount paid / total mrp)

select p.product_name,sum(o.tot_units),sum(o.total_amount_paid) ,
sum(o.displayed_selling_price_per_unit * o.tot_units),sum(p.mrp * o.tot_units),
100.0 - 100.0 * sum(o.total_amount_paid) / sum(o.displayed_selling_price_per_unit * o.tot_units) as net_discount,
100.0 - 100.0 * sum(o.total_amount_paid) / sum(p.mrp * o.tot_units) as net_discount_from_mrp
from product_dim p inner join order_dim o on p.product_id = o.product_id
group by p.product_name;


-- Advance Questions:
-- 15. For every order_id (exclude returns), get the product name and calculate the discount
-- percentage from selling price. Sort by highest discount and print only those rows where
-- discount percentage was above 10.10%.

Select order_id,product_name,
round(100 * (displayed_selling_price_per_unit - total_amount_paid / tot_units) / displayed_selling_price_per_unit, 2) AS discount_percentage
from order_dim
inner join product_dim on product_dim.product_id = order_dim.product_id
where order_type != 'return' and (total_amount_paid / tot_units) < displayed_selling_price_per_unit
having discount_percentage > 10.10 order by discount_percentage desc;



-- 16. Using the per unit procurement cost in product_dim, find which product category has
-- made the most profit in both absolute amount and percentage
-- Absolute Profit = Total Amt Sold - Total Procurement Cost
-- Percentage Profit = 100.0 * Total Amt Sold / Total Procurement Cost - 100.0

select p.category,sum(o.total_amount_paid) - sum(o.tot_units * p.procurement_cost_per_unit) as absolute_profit,
(100.0 * sum(o.total_amount_paid) / SUM(o.tot_units * p.procurement_cost_per_unit) - 100.0) as percentage_profit
from order_dim o inner join product_dim p on o.product_id = p.product_id
where o.order_type = 'buy' group by p.category order by absolute_profit DESC limit 1;


-- 17. For every delivery person(use their name), print the total number of order ids (exclude
-- returns) by month in separate columns i.e. there should be one row for each
-- delivery_person_id and 12 columns for every month in the year

select d.name,
sum(case when substring(o.order_date,4,2) = 01 then 1 else 0 END) as jan,
sum(case when substring(o.order_date,4,2) = 02 then 1 else 0 end) as feb,
sum(case when substring(o.order_date,4,2) = 03 then 1 else 0 END) as mar,
sum(case when substring(o.order_date,4,2) = 04 then 1 else 0 end) as apr,
sum(case when substring(o.order_date,4,2) = 05 then 1 else 0 end) as may,
sum(case when substring(o.order_date,4,2) = 06 then 1 else 0 end) as june,
sum(case when substring(o.order_date,4,2) = 07 then 1 else 0 end) as july,
sum(case when substring(o.order_date,4,2) = 08 then 1 else 0 end) as august,
sum(case when substring(o.order_date,4,2) = 09 then 1 else 0 end) as sep,
sum(case when substring(o.order_date,4,2) = 10 then 1 else 0 end) as oct,
sum(case when substring(o.order_date,4,2) = 11 then 1 else 0 end) as nov,
sum(case when substring(o.order_date,4,2) = 12 then 1 else 0 end) as dece
from order_dim o left join delivery_person_dim d on o.delivery_person_id = d.delivery_person_id 
where o.order_type != 'return' group by d.name order by d.name;

-- 18. For each gender - male and female - find the absolute and percentage profit (like in
-- Q15) by product name
-- Absolute Profit = Total Amt Sold - Total Procurement Cost
-- Percentage Profit = 100.0 * Total Amt Sold / Total Procurement Cost - 100.0
 
Select c.gender,sum(o.total_amount_paid - (p.procurement_cost_per_unit * o.tot_units)) as absolute_profit,
100.0 * sum(o.total_amount_paid) / sum(p.procurement_cost_per_unit * o.tot_units) - 100.0 as percentage_profit
from customer_dim as c inner join order_dim as o on c.cust_id = o.cust_id
inner join product_dim as p on o.product_id = p.product_id where o.order_type = 'buy'
group by c.gender;

-- 19. Generally the more numbers of units you buy, the more discount seller will give you. For
-- 'Dell AX420' is there a relationship between number of units ordered and average
-- discount from selling price? Take only 'buy' order types

select tot_units,avg(o.displayed_selling_price_per_unit - o.total_amount_paid / tot_units) as avg_discount
from order_dim o inner join product_dim p on o.product_id = p.product_id
where product_name = 'Dell AX420' and order_type = 'buy'
group by tot_units order by avg_discount desc;






