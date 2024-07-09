select * from sales;
select * from menu;
select * from members;

--1. What is the total amount each customer spent at the restaurant?

select customer_id, sum(price) as total_amount
from sales s
join menu m on s.product_id = m.product_id
group by customer_id
order by total_amount desc 

--2. How many days has each customer visited the restaurant?

select customer_id, count(distinct order_date) days_visited
from sales
group by customer_id
	
--3. What was the first item from the menu purchased by each customer?

with cte as
			(select customer_id, min( order_date) as mins,m.product_name,
				row_number() over(partition by customer_id order by customer_id, min(order_date)) as num
			from sales s
			join menu m on s.product_id = m.product_id
			group by customer_id, m.product_name)
select customer_id, product_name
from cte
where num = 1
	
	
--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

with cte as
			(select product_name as Most_purchased_Item, count(1) as No_of_orders,
				rank() over(order by count(1) desc)
			from sales s
			join menu m on s.product_id = m.product_id
			group by product_name)
select Most_purchased_Item, No_of_orders
from cte
where rank = 1

--5. Which item was the most popular for each customer?

with cte as
			(select customer_id, product_name, count(product_name),
				rank() over(partition by customer_id order by count(product_name) desc)
			from sales s
			join menu m on s.product_id = m.product_id
			group by customer_id, product_name)
select customer_id, product_name
from cte
where rank = 1
	
--6. Which item was purchased first by the customer after they became a member?

with cte as	
			(select s.customer_id as cust_id, order_date, join_date, product_name,
				rank() over(partition by s.customer_id order by order_date)
			from sales s
			join members ms on s.customer_id = ms.customer_id
			join menu m on s.product_id = m.product_id
			where order_date > join_date
			group by s.customer_id, order_date, join_date, product_name)
select cust_id, product_name
from cte
where rank = 1
	
--7. Which item was purchased just before the customer became a member?

with cte as	
			(select s.customer_id as cust_id, order_date, join_date, product_name,
				rank() over(partition by s.customer_id order by order_date)
			from sales s
			join members ms on s.customer_id = ms.customer_id
			join menu m on s.product_id = m.product_id
			where order_date < join_date
			group by s.customer_id, order_date, join_date, product_name)
select cust_id, product_name
from cte
where rank = 1

--8. What is the total items and amount spent for each member before they became a member?

select s.customer_id, count(product_name) as total_items, sum(price) as amount_spent
from sales s
join members ms on s.customer_id = ms.customer_id
join menu m on s.product_id = m.product_id
where order_date < join_date
group by s.customer_id

	
--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
	how many points would each customer have?

with cte as	
			(select *,
				case
					when product_name = 'sushi' then price*20
					else price*10
				end as points
			from sales s
			join menu m on s.product_id = m.product_id
			order by s.customer_id)
select customer_id, sum(points) as total_points
from cte
group by customer_id
	
--10. In the first week after a customer joins the program (including their join date) 
--	they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

with cte as
			(select customer_id, sum(points) as points
			from (select s.customer_id as customer_id,
					case when price >= 1 then price*20
					end as points
				from sales s
				join menu m on s.product_id = m.product_id
				join members ms on s.customer_id = ms.customer_id
				where order_date between join_date and (join_date + 6))
			group by customer_id
				
			union
			
			select customer_id, sum(points) as points
			from (select s.customer_id as customer_id,
				case when price >= 1 then price*10
				end as points
			from sales s
			join menu m on s.product_id = m.product_id
			join members ms on s.customer_id = ms.customer_id
			where order_date between (join_date + 6) and to_date('31-01-2021','dd-mm-yyyy'))	
			group by customer_id)
select customer_id, sum(points) as points
from cte
group by customer_id
order by points desc;
