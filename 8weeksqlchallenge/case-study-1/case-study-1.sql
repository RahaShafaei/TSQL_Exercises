/* --------------------
 Case Study Questions
 --------------------*/

---========================================================================
-- 1 - What is the total amount each customer spent at the restaurant? 
SELECT s.customer_id [customer],
    sum(mu.price) [total amount]
FROM [dannys_diner].[dbo].[sales] s
    join [dannys_diner].[dbo].[menu] mu on mu.product_id = s.product_id
group by s.customer_id 

---========================================================================
-- 2 - How many days has each customer visited the restaurant?
;with visited_times(customer_id, order_date, cnt_visited) as (
    SELECT [customer_id],
        [order_date],
        count(distinct [order_date]) cnt_visited
    FROM [dannys_diner].[dbo].[sales]
    group by [customer_id],
        [order_date]
)
SELECT customer_id,
    sum(cnt_visited) sm_visited
FROM visited_times
group by [customer_id] 

---========================================================================
-- 3 - What was the first item from the menu purchased by each customer?
;with first_choose (
    RNum,
    customer_id,
    order_date,
    product_id,
    product_name
) as (
    SELECT ROW_NUMBER() over (
            order by s.[customer_id],
                s.[order_date],
                s.[product_id]
        ) RNum,
        s.[customer_id],
        s.[order_date],
        s.[product_id],
        mu.product_name
    FROM [dannys_diner].[dbo].[sales] s
        join [dannys_diner].[dbo].[menu] mu on s.product_id = mu.product_id
)
select fc.[customer_id],
    fc.[product_name]
from first_choose fc
group by fc.[customer_id],
    fc.[product_name],
    fc.RNum
having fc.RNum in (
        select min(RNum) over (partition by [customer_id])
        from first_choose
    ) 

---========================================================================
-- 4 - What is the most purchased item on the menu and how many times was it purchased by all customers?
;with most_popular(cnt_product, product_name) as (
    SELECT count(s.[product_id]) over(partition by s.[product_id]) cnt_product,
        mu.product_name
    FROM [dannys_diner].[dbo].[sales] s
        join [dannys_diner].[dbo].[menu] mu on s.product_id = mu.product_id
)
select product_name,
    cnt_product
from most_popular
group by product_name,
    cnt_product 

---========================================================================
-- 5 - Which item was the most popular for each customer?
;with most_popular(
    customer_id,
    cnt_product,
    product_name
    /*, rn*/
) as (
    SELECT s.[customer_id],
        count(s.[product_id]) over(partition by s.[customer_id], s.[product_id]) cnt_product,
        mu.product_name
    FROM [dannys_diner].[dbo].[sales] s
        join [dannys_diner].[dbo].[menu] mu on s.product_id = mu.product_id
)
select mp.customer_id,
    mp.product_name,
    mp.cnt_product
from most_popular mp
    join(
        select top 100 percent ROW_NUMBER() OVER (
                PARTITION BY customer_id
                ORDER BY cnt_product DESC
            ) AS rn,
            customer_id,
            product_name,
            cnt_product
        from most_popular
        group by customer_id,
            product_name,
            cnt_product
        order by customer_id,
            cnt_product desc,
            product_name
    ) m on mp.customer_id = m.customer_id
    and mp.product_name = m.product_name
    and m.rn = 1
group by mp.customer_id,
    mp.product_name,
    mp.cnt_product