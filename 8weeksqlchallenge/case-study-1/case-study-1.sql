/* --------------------
 case-study-1 questions
 --------------------*/
/*========================================================================*/
-- 1 - What is the total amount each customer spent at the restaurant? 
SELECT
    s.customer_id [customer],
    sum(mu.price) [total amount]
FROM
    [dannys_diner].[dbo].[sales] s
    join [dannys_diner].[dbo].[menu] mu on mu.product_id = s.product_id
group by
    s.customer_id
    /*========================================================================*/
    -- 2 - How many days has each customer visited the restaurant?
;

with visited_times(customer_id, order_date, cnt_visited) as (
    SELECT
        [customer_id],
        [order_date],
        count(distinct [order_date]) cnt_visited
    FROM
        [dannys_diner].[dbo].[sales]
    group by
        [customer_id],
        [order_date]
)
SELECT
    customer_id,
    sum(cnt_visited) sm_visited
FROM
    visited_times
group by
    [customer_id]
    /*========================================================================*/
    -- 3 - What was the first item from the menu purchased by each customer?
;

with first_choose (
    RNum,
    customer_id,
    order_date,
    product_id,
    product_name
) as (
    SELECT
        ROW_NUMBER() over (
            order by
                s.[customer_id],
                s.[order_date],
                s.[product_id]
        ) RNum,
        s.[customer_id],
        s.[order_date],
        s.[product_id],
        mu.product_name
    FROM
        [dannys_diner].[dbo].[sales] s
        join [dannys_diner].[dbo].[menu] mu on s.product_id = mu.product_id
)
select
    fc.[customer_id],
    fc.[product_name]
from
    first_choose fc
group by
    fc.[customer_id],
    fc.[product_name],
    fc.RNum
having
    fc.RNum in (
        select
            min(RNum) over (partition by [customer_id])
        from
            first_choose
    )
    /*========================================================================*/
    -- 4 - What is the most purchased item on the menu and how many times was it purchased by all customers?
;

with most_popular(cnt_product, product_name) as (
    SELECT
        count(s.[product_id]) over(partition by s.[product_id]) cnt_product,
        mu.product_name
    FROM
        [dannys_diner].[dbo].[sales] s
        join [dannys_diner].[dbo].[menu] mu on s.product_id = mu.product_id
)
select
    product_name,
    cnt_product
from
    most_popular
group by
    product_name,
    cnt_product
    /*========================================================================*/
    -- 5 - Which item was the most popular for each customer?
;

with most_popular(
    customer_id,
    cnt_product,
    product_name
) as (
    SELECT
        s.[customer_id],
        count(s.[product_id]) over(partition by s.[customer_id], s.[product_id]) cnt_product,
        mu.product_name
    FROM
        [dannys_diner].[dbo].[sales] s
        join [dannys_diner].[dbo].[menu] mu on s.product_id = mu.product_id
)
select
    mp.customer_id,
    mp.product_name,
    mp.cnt_product
from
    most_popular mp
    join(
        select
            top 100 percent ROW_NUMBER() OVER (
                PARTITION BY customer_id
                ORDER BY
                    cnt_product DESC
            ) AS rn,
            customer_id,
            product_name,
            cnt_product
        from
            most_popular
        group by
            customer_id,
            product_name,
            cnt_product
        order by
            customer_id,
            cnt_product desc,
            product_name
    ) m on mp.customer_id = m.customer_id
    and mp.product_name = m.product_name
    and m.rn = 1
group by
    mp.customer_id,
    mp.product_name,
    mp.cnt_product
    /*========================================================================*/
    -- 6 - Which item was purchased first by the customer after they became a member?
;

with min_ord_dt (
    [customer_id],
    [order_date],
    product_name,
    min_ord_dt
) as(
    SELECT
        s.[customer_id],
        s.[order_date],
        mu.product_name,
        min(s.order_date) over (partition by s.customer_id) min_ord_dt
    FROM
        [dannys_diner].[dbo].[sales] s
        join [dannys_diner].[dbo].[members] mb on mb.customer_id = s.customer_id
        join [dannys_diner].[dbo].menu mu on mu.product_id = s.product_id
    where
        s.[order_date] >= mb.join_date
)
select
    [customer_id],
    product_name
from
    min_ord_dt
where
    [order_date] = min_ord_dt
    /*========================================================================*/
    -- 7 - Which item was purchased just before the customer became a member?
;

with min_ord_dt (
    [customer_id],
    [order_date],
    product_name,
    max_ord_dt
) as(
    SELECT
        s.[customer_id],
        s.[order_date],
        mu.product_name,
        max(s.order_date) over (partition by s.customer_id) max_ord_dt
    FROM
        [dannys_diner].[dbo].[sales] s
        join [dannys_diner].[dbo].[members] mb on mb.customer_id = s.customer_id
        join [dannys_diner].[dbo].menu mu on mu.product_id = s.product_id
    where
        s.[order_date] < mb.join_date
)
select
    [customer_id],
    product_name
from
    min_ord_dt
where
    [order_date] = max_ord_dt
    /*========================================================================*/
    -- 8 - What is the total items and amount spent for each member before they became a member?
;

with calcu_ord ([customer_id], cnt_ord, sm_prc) as(
    SELECT
        s.[customer_id],
        count(s.order_date) over (partition by s.customer_id) cnt_ord,
        sum(mu.price) over (partition by s.customer_id) sm_prc
    FROM
        [dannys_diner].[dbo].[sales] s
        join [dannys_diner].[dbo].[members] mb on mb.customer_id = s.customer_id
        join [dannys_diner].[dbo].menu mu on mu.product_id = s.product_id
    where
        s.[order_date] < mb.join_date
)
select
    [customer_id],
    cnt_ord,
    sm_prc
from
    calcu_ord
group by
    [customer_id],
    cnt_ord,
    sm_prc
    /*========================================================================*/
    -- 9 - If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
;

with cust_point ([customer_id], sm_points) as (
    SELECT
        s.[customer_id],
        sum(
            case
                when mu.[product_name] = 'sushi' then mu.[price] * 20
                else mu.[price] * 10
            end
        ) over (partition by s.customer_id) sm_points
    FROM
        [dannys_diner].[dbo].[sales] s
        join [dannys_diner].[dbo].menu mu on mu.product_id = s.product_id
)
select
    [customer_id],
    sm_points
from
    cust_point
group by
    [customer_id],
    sm_points
    /*========================================================================*/
    /* 10 - In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
     not just sushi - how many points do customer A and B have at the end of January?*/
;

with calcu_points ([customer_id], sm_poin) as(
    SELECT
        s.[customer_id],
        sum(
            case
                when s.order_date >= DATEADD(WEEK, 1, mb.join_date)
                and s.order_date <= cast ('2021-01-31' as Date) then mu.[price] * 20
                when mu.[product_name] = 'sushi' then mu.[price] * 20
                else mu.[price] * 10
            end
        ) over (partition by s.customer_id) sm_poin
    FROM
        [dannys_diner].[dbo].[sales] s
        join [dannys_diner].[dbo].[members] mb on mb.customer_id = s.customer_id
        join [dannys_diner].[dbo].menu mu on mu.product_id = s.product_id
)
select
    [customer_id],
    sm_poin
from
    calcu_points
group by
    [customer_id],
    sm_poin
