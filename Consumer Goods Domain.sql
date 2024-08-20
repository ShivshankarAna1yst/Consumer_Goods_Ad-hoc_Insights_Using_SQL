-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.

select market 
from dim_customer 
where customer like "%Atliq Exclusive%" and region = "APAC";

-- 2. What is the percentage of unique product increase in 2021 vs. 2020?
with cte1 as (select
	COUNT(DISTINCT CASE WHEN s.fiscal_year = 2020 THEN p.product_code END) AS unique_product_2020,
	COUNT(DISTINCT CASE WHEN s.fiscal_year = 2021 THEN p.product_code END) AS unique_product_2021
FROM fact_sales_monthly s
cross join dim_product p using(product_code))
select 
	*,
    round((unique_product_2021-unique_product_2020)/unique_product_2020*100,2) as percantage_chg
from cte1;

-- 3. Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count
select 
	segment,
    count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;

-- 4. Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment, product_count_2020, product_count_2021, difference
with cte1 as (select
	p.segment,
	COUNT(DISTINCT CASE WHEN s.fiscal_year = 2020 THEN p.product_code END) AS unique_product_2020,
	COUNT(DISTINCT CASE WHEN s.fiscal_year = 2021 THEN p.product_code END) AS unique_product_2021
FROM fact_sales_monthly s
cross join dim_product p using(product_code)
group by p.segment)
select 
	*,
    unique_product_2021-unique_product_2020 as Difference
from cte1
order by Difference desc;


-- 5. Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost
select 
	p.product_code,
    p.product,
    manufacturing_cost
from dim_product p 
join fact_manufacturing_cost m on
	m.product_code = p.product_code
where manufacturing_cost = (select  min(manufacturing_cost) from fact_manufacturing_cost) 
	or manufacturing_cost = (select  max(manufacturing_cost) from fact_manufacturing_cost);
	
    
-- 6. Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage
select 
	c.customer_code,
    c.customer,
    round(avg(pre_invoice_discount_pct)*100,2) as average_discount_percentage
from dim_customer c
join fact_pre_invoice_deductions pre
	on pre.customer_code = c.customer_code
where pre.fiscal_year = 2021 and c.market = "india"
group by c.customer_code, c.customer
order by average_discount_percentage desc
limit 5;


-- 7. Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount
select
	monthname(date) as month,
    fiscal_year,
    round(sum(total_gross_price)/1000000,2) as gross_sales_mls
from gross_sales g 
join dim_customer c using(customer_code)
where c.customer like "%Atliq Exclusive%"
group by month, fiscal_year
order by gross_sales_mls desc;


-- 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity
 with cte1 as (SELECT
        CASE
            WHEN MONTH(date) IN (9, 10, 11) THEN 'Q1 '
            WHEN MONTH(date) IN (12, 1, 2) THEN 'Q2 '
            WHEN MONTH(date) IN (3, 4, 5) THEN 'Q3 '
            WHEN MONTH(date) IN (6, 7, 8) THEN 'Q4 '
        END AS Quarter,
        round(sum(sold_quantity)/1000000,2) as total_sold_quantity_mls
    FROM fact_sales_monthly s
    join fact_gross_price g on g.product_code = s.product_code and g.fiscal_year = s.fiscal_year
    where s.fiscal_year = 2020
    group by Quarter)
    select 
		Quarter, total_sold_quantity_mls
	from cte1
    order by total_sold_quantity_mls desc;


-- 9. Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage
with cte1 as (select 
	channel,
	sold_quantity*gross_price as total_gross_sales
from fact_sales_monthly s
join fact_gross_price g 
	on g.product_code = s.product_code and 
    g.fiscal_year = s.fiscal_year
join dim_customer c 
	on c.customer_code = s.customer_code
group by channel, total_gross_sales),
	cte2 as (select 
		channel, 
		round(sum(total_gross_sales)/1000000,2) as gross_sales_mls
	from cte1 
	group by channel)
select 
	*,
    gross_sales_mls*100/sum(gross_sales_mls) over() as percentage
from cte2;


-- 10. Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order
with cte1 as (select 
	division,
    s.product_code,
    product,
	sum(sold_quantity) as sold_qty
from fact_sales_monthly s
join dim_product p 
	on p.product_code = s.product_code
where fiscal_year = 2021
group by division, s.product_code, product),
	cte2 as (select 
		*,
		dense_rank() over(partition by division order by sold_qty desc) as rn
	from cte1)
select * from cte2 where rn <= 3;



