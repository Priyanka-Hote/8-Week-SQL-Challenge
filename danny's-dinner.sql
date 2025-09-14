-- Database: dannys_diner

-- DROP DATABASE IF EXISTS dannys_diner;

CREATE DATABASE dannys_diner
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id,concat(sum(m.price),'$')
FROM sales s 
inner JOIN menu m ON s.product_id = m.product_id 
group by s.customer_id 
order by customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id,count(order_date) as total_visited 
from sales 
group by customer_id 
order by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
select s.*,m.* from sales s inner join menu m on s.product_id = m.product_id;
select * from sales;
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select customer_id,count(product_id) 
from sales 
where product_id =(
			select product_id  
			from sales 
			group by product_id 
			order by count(product_id) desc limit 1) 
group by customer_id;

select m.product_name,count(s.product_id) as total 
from sales s 
inner join menu m 
on s.product_id = m.product_id 
group by m.product_name 
order by total desc limit 1 ;

-- 5. Which item was the most popular for each customer?
select  t.customer_id, m.product_name from 
(select customer_id,product_id,count(product_id) as fre,
dense_rank() over(partition by customer_id order by count(product_id) desc) as rnk
from sales group by customer_id,product_id order by customer_id) t
inner join menu m
on t.product_id = m.product_id
where t.rnk = 1
order by customer_id;


WITH product_counts AS (
    SELECT 
        customer_id,
        product_id,
        COUNT(*) AS freq,
        DENSE_RANK() OVER (
            PARTITION BY customer_id 
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM sales
    GROUP BY customer_id, product_id
)
SELECT customer_id, product_id, freq
FROM product_counts
WHERE rnk = 1
ORDER BY customer_id;

-- 6. Which item was purchased first by the customer after they became a member?


select t.customer_id,m.product_name from
	(select s.customer_id,s.product_id,s.order_date,m.join_date , 
		dense_rank() over(partition by s.customer_id order by s.order_date) as rnk
		from sales s 
		inner join members m on s.customer_id = m.customer_id 
		where s.order_date > m.join_date 
		order by s.order_date) t
inner join menu m
on t.product_id = m.product_id
where t.rnk=1;



-- 7. Which item was purchased just before the customer became a member?

select t.customer_id,m.product_name from
	(select s.customer_id,s.product_id,s.order_date,m.join_date , 
		dense_rank() over(partition by s.customer_id order by s.order_date desc) as rnk
		from sales s 
		inner join members m on s.customer_id = m.customer_id 
		where s.order_date < m.join_date 
		) t
inner join menu m
on t.product_id = m.product_id
where t.rnk=1
order by t.customer_id ;



-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id, count(s.product_id), sum(mu.price)
from sales s 
inner join members m 
on s.customer_id = m.customer_id 
inner join menu mu 
on s.product_id = mu.product_id
where s.order_date < m.join_date 
group by s.customer_id;

-- window function
select distinct s.customer_id,
count(s.product_id) over(partition by s.customer_id) as total_products,
sum(mu.price) over(partition by s.customer_id) as total_amount
from sales s 
inner  join members m 
on s.customer_id = m.customer_id
inner join menu mu 
on s.product_id = mu.product_id
where s.order_date < m.join_date
order by s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
-- how many points would each customer have?
select s.customer_id, 
sum(
	case
		when m.product_name ='sushi' then 20*m.price
		else 10*m.price
	end) 
as points
from sales s
inner join menu m
on s.product_id =m.product_id
group by s.customer_id
order by s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?


with cte as (select s.customer_id,s.order_date as date,m.join_date,m1.price,
		s.order_date,s.order_date::date + interval '7 days' AS new_date
		from sales s
		inner join members m on s.customer_id = m.customer_id
		inner join menu m1 on s.product_id = m1.product_id )
select customer_id,sum(20*price) as points
from cte
where date between join_date and new_date
group by customer_id

with cte_p as (
			select s.customer_id,s.order_date as order_dt,m.join_date as join_dt,m1.product_name,m1.price,
			s.order_date,s.order_date::date + interval '7 days' AS new_date,
			case
				when s.order_date between m.join_date and m.join_date+ interval '7 days' then 20*price
				when product_name ='sushi' then 20* price
				else 10*price 
				end as points
			from sales s
			inner join members m on s.customer_id = m.customer_id
			inner join menu m1 on s.product_id = m1.product_id
			where s.order_date <'2021-01-31')
select cte_p.customer_id,sum(points) as amount_spent from cte_p group by cte_p.customer_id;






















	