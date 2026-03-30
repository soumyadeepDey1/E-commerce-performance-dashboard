create database fuzzy_factory;
use fuzzy_factory;
CREATE TABLE website_sessions (
    website_session_id INT PRIMARY KEY,
    created_at DATETIME,
    user_id INT,
    is_repeat_session TINYINT,
    utm_source VARCHAR(50),
    utm_campaign VARCHAR(50),
    utm_content VARCHAR(50),
    device_type VARCHAR(20),
    http_referer VARCHAR(100)
);
CREATE TABLE website_pageviews (
    website_pageview_id INT PRIMARY KEY,
    created_at DATETIME,
    website_session_id INT,
    pageview_url VARCHAR(100)
);
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    created_at DATETIME,
    website_session_id INT,
    user_id INT,
    primary_product_id INT,
    items_purchased INT,
    price_usd DECIMAL(10,2),
    cogs_usd DECIMAL(10,2)
);
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    created_at datetime,
    order_id INT,
    product_id INT,
    is_primary_item TINYINT,
    price_usd DECIMAL(10,2),
    cogs_usd DECIMAL(10,2)
);
CREATE TABLE order_item_refunds (
    order_item_refund_id INT PRIMARY KEY,
    created_at DATETIME,
    order_item_id INT,
    order_id int,
    refund_amount_usd DECIMAL(10,2)
);
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    created_at DATETIME,
    product_name VARCHAR(50)
);

SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';

LOAD DATA LOCAL INFILE 'F:/Dashboard&Project/Maven+Fuzzy+Factory/website_sessions.csv'
INTO TABLE website_sessions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'F:/Dashboard&Project/Maven+Fuzzy+Factory/website_pageviews.csv'
INTO TABLE website_pageviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'F:/Dashboard&Project/Maven+Fuzzy+Factory/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'F:/Dashboard&Project/Maven+Fuzzy+Factory/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'F:/Dashboard&Project/Maven+Fuzzy+Factory/order_item_refunds.csv'
INTO TABLE order_item_refunds
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'F:/Dashboard&Project/Maven+Fuzzy+Factory/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from fuzzy_factory.website_sessions;
select * from fuzzy_factory.website_pageviews;
select * from fuzzy_factory.products;
select * from fuzzy_factory.orders;
select * from fuzzy_factory.order_items;
select * from fuzzy_factory.order_item_refunds;

-- 🔹 BASIC PERFORMANCE
-- Q1.
-- What is the total number of website sessions?
	select count(website_session_id) from website_sessions;
-- Q2.
-- How does the number of sessions trend over time (monthly)?
	select year(created_at) as Year,
    monthname(created_at) as Month,
    count(website_session_id) as Total_Sessions 
    from website_sessions 
    group by Year,month(created_at),Month
    order by Year,month(created_at);
   
-- 🔹 CONVERSION ANALYSIS
-- Q3.
-- What is the overall conversion rate from sessions to orders?
	select round((count(distinct o.website_session_id) * 100.00)/
    count(distinct ws.website_session_id),2) as Conversion_Rate
    from website_sessions ws 
    left join orders o on ws.website_session_id = o.website_session_id;
-- Q4.
-- How does the conversion rate change over time?
	select year(ws.created_at) as Year,
    monthname(ws.created_at) as Month,
    round((count(distinct o.website_session_id) * 100.00)/
    count(distinct ws.website_session_id),2) as Conversion_Rate
    from website_sessions ws 
    left join orders o on ws.website_session_id = o.website_session_id
    group by Year,month(ws.created_at),Month
    order by Year,month(ws.created_at);
    
-- 🔹 TRAFFIC SOURCE ANALYSIS
-- Q5.
-- Which traffic sources and campaigns drive the most sessions?
	select utm_source, utm_campaign, 
    count(distinct website_session_id) as Total_session 
    from website_sessions 
    group by utm_source, utm_campaign 
    order by Total_session desc 
    limit 1;
-- Q6.
-- Which traffic sources and campaigns generate the highest conversion rates?
	select ws.utm_source,
    ws.utm_campaign,
    COUNT(DISTINCT ws.website_session_id) AS total_sessions,
	COUNT(DISTINCT o.website_session_id) AS converted_sessions,
    round((count(distinct o.website_session_id) * 100.00)/
    count(distinct ws.website_session_id),2) as Conversion_Rate
    from website_sessions ws 
    left join orders o on ws.website_session_id = o.website_session_id
    group by ws.utm_source,ws.utm_campaign
    order by Conversion_Rate desc
    limit 1;
    
-- 🔹 REVENUE ANALYSIS
-- Q7.
-- What is the total revenue and total profit generated?
	select sum(price_usd) as Total_Revenue, 
    sum(price_usd - cogs_usd) as Total_Profit 
    from order_items;
-- Q8.
-- How does revenue trend over time?
	select year(created_at) as Year,
    monthname(created_at) as Month,
    sum(price_usd) as Total_Revenue  
    from order_items 
    group by Year,month(created_at),Month
    order by Year,month(created_at);
    
-- 🔹 PRODUCT PERFORMANCE
-- Q9.
-- Which products generate the highest revenue?
	select p.product_id,p.product_name,sum(oi.price_usd) Total_Revenue 
    from order_items oi 
    join products p on oi.product_id = p.product_id 
    group by p.product_id,p.product_name
    order by Total_Revenue desc
    limit 1;
-- Q10.
-- Which products have the highest number of orders?
	select p.product_id,p.product_name,count(DISTINCT oi.order_id) Total_Orders 
    from order_items oi 
    join products p on oi.product_id = p.product_id 
    group by p.product_id,p.product_name
    order by Total_Orders desc
    limit 1;
    
-- 🔹 FUNNEL ANALYSIS (IMPORTANT)
-- Q11.
-- How many sessions reach each stage of the funnel (homepage, product page, cart, checkout, order)?
	select  ucase(substring(pageview_url,2)) as Funnel, 
	count(distinct website_session_id) as Total_Sessions 
    from website_pageviews 
    WHERE pageview_url IN 
    (
		'/home',
		'/products',
		'/cart',
		'/shipping',
		'/billing'
	)
	group by Funnel 
	order by Total_Sessions desc;
-- Q12.
-- What is the drop-off rate between each stage of the funnel?
	with find_first_page as(
		SELECT *
		FROM (
			SELECT 
			wp.website_session_id,
			wp.pageview_url AS first_page
		FROM website_pageviews wp
		JOIN (
			SELECT 
				website_session_id,
				MIN(created_at) AS first_time
			FROM website_pageviews
			GROUP BY website_session_id
		) t
		ON wp.website_session_id = t.website_session_id
		AND wp.created_at = t.first_time
		) t
		WHERE first_page = '/home'
    ),
	funnel_session as (
		select  ucase(substring(wp.pageview_url,2)) as Funnel, 
		count(distinct wp.website_session_id) as Total_Sessions 
		from website_pageviews wp 
        join find_first_page ffp on wp.website_session_id = ffp.website_session_id
		WHERE pageview_url IN 
		(
			'/home',
			'/products',
			'/cart',
			'/shipping',
			'/billing'
		)
		group by Funnel 
		order by Total_Sessions desc
    )
    select Funnel,Total_Sessions,
    
    ROUND(
		(LAG(Total_Sessions) OVER (ORDER BY Total_Sessions desc) - Total_Sessions) * 100.0 
		/ LAG(Total_Sessions) OVER (ORDER BY Total_Sessions desc),
	2) as Drop_off_Rate 
    from funnel_session;

-- 🔹 REFUND ANALYSIS (UNIQUE)
-- Q13.
-- What is the refund rate for each product?
	select p.product_id, p.product_name,round((count(oir.order_item_id) / count(distinct oi.order_item_id)) * 100,2) as Refund_rate
    from products p 
    join order_items oi on p.product_id=oi.product_id 
    left join order_item_refunds oir on oi.order_item_id = oir.order_item_id
    group by p.product_id,p.product_name
    order by p.product_id;
-- Q14.
-- How much revenue is lost due to refunds?
	SELECT 
    COUNT(*) AS total_refunds,
    round(SUM(refund_amount_usd),2) AS revenue_lost,
    round(AVG(refund_amount_usd),2) AS avg_refund_value
	FROM order_item_refunds; 
    
-- 🔹 DEVICE ANALYSIS
-- Q15.
-- How do sessions and orders differ by device type?
	select ws.device_type, 
    count(distinct ws.website_session_id) as Total_Sessions, 
    count(distinct o.order_id) as Total_Orders
    from website_sessions ws
    left join orders o on ws.website_session_id = o.website_session_id
    group by ws.device_type;
-- Q16.
-- Which device type has the highest conversion rate?
	select ws.device_type, 
    count(distinct ws.website_session_id) as Total_Sessions, 
    count(distinct o.order_id) as Total_Orders,
    ROUND(
    COUNT(DISTINCT o.order_id) * 100.0 
    / COUNT(DISTINCT ws.website_session_id),
	2) AS conversion_rate
    from website_sessions ws
    left join orders o on ws.website_session_id = o.website_session_id
    group by ws.device_type
    order by conversion_rate desc
    limit 1;
    
-- 🔹 USER BEHAVIOR
-- Q17.
-- What is the distribution of new vs repeat sessions?
	select 
    case 
		when is_repeat_session = 0 then 'New'
        else 'Repeat'
        end as new_or_repeat,
        count(distinct website_session_id) as Total_Sessions,
        ROUND(
			COUNT(DISTINCT website_session_id) * 100.0 
			/ SUM(COUNT(DISTINCT website_session_id)) OVER (),
		2) AS percentage_share
        from website_sessions
        group by is_repeat_session;
-- Q18.
-- Do repeat sessions convert better than new sessions?
	select 
    case 
		when ws.is_repeat_session = 0 then 'New'
        else 'Repeat'
        end as new_or_repeat,
        count(distinct ws.website_session_id) as Total_Sessions,
        count(distinct o.order_id) as Total_Orders,
        ROUND(
			COUNT(DISTINCT o.order_id) * 100.0 
			/ COUNT(DISTINCT ws.website_session_id),
		2) AS convertion_rate
        from website_sessions ws 
		left join orders o on ws.website_session_id = o.website_session_id
        group by ws.is_repeat_session;
        
-- 🔹 ADVANCED ANALYSIS (INTERVIEW LEVEL)
-- Q19.
-- What is the average number of pages viewed per session?
	select round(count( website_pageview_id) * 1.0 
    / count(distinct website_session_id),2) as average_pageview_per_session 
    from website_pageviews;
-- Q20.
-- What is the average number of items per order? 
	select round(count(order_item_id) * 1.0 
    / count(distinct order_id),2) as average_items_per_order 
    from order_items;
    