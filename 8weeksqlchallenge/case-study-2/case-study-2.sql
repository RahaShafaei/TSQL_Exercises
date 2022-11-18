/* --------------------
 case-study-2 questions
 --------------------*/
/*----------------------------- Data Cleansing*/
update
    [pizza_runner].[dbo].[customer_orders]
set
    [extras] = NULL
where
    [extras] IN ('', 'null')
    /* ---------------------*/
update
    [pizza_runner].[dbo].[customer_orders]
set
    [exclusions] = NULL
where
    [exclusions] IN ('', 'null')
    /* ---------------------*/
update
    [pizza_runner].[dbo].[runner_orders]
set
    [pickup_time] = NULL
where
    [pickup_time] IN ('', 'null')
    /* ---------------------*/
update
    [pizza_runner].[dbo].[runner_orders]
set
    [distance] = NULL
where
    [distance] IN ('', 'null')
    /* ---------------------*/
update
    [pizza_runner].[dbo].[runner_orders]
set
    [duration] = NULL
where
    [duration] IN ('', 'null')
    /* ---------------------*/
update
    [pizza_runner].[dbo].[runner_orders]
set
    [cancellation] = NULL
where
    [cancellation] IN ('', 'null')
    /* ---------------------*/
update
    [pizza_runner].[dbo].[runner_orders]
set
    [distance] = REPLACE(REPLACE([distance], N'km', ''), ' ', ''),
    [duration] = replace (
        LEFT(
            SUBSTRING(
                [duration],
                PATINDEX('%[0-9]%', [duration]),
                LEN([duration])
            ),
            PATINDEX(
                '%[^0-9]%',
                SUBSTRING(
                    [duration],
                    PATINDEX('%[0-9]%', [duration]),
                    LEN([duration])
                ) + 't'
            ) - 1
        ),
        ' ',
        ''
    ) -- ************************************************* A. Pizza Metrics
    /*========================================================================*/
    -- 1 - How many pizzas were ordered?
select
    count(*) cnt
from
    [pizza_runner].[dbo].[runner_orders]
where
    pickup_time is not null
    /*========================================================================*/
    -- 2 - How many unique customer orders were made?
select
    co.customer_id,
    count(distinct co.order_id) [tot_ord_num],
    count (distinct ro.order_id) [tot_ord_num_acpt]
from
    [pizza_runner].[dbo].[runner_orders] ro
    right join [pizza_runner].[dbo].[customer_orders] co on co.order_id = ro.order_id
    and ro.pickup_time is not null
group by
    co.customer_id
order by
    co.customer_id
    /*========================================================================*/
    -- 3 - How many successful orders were delivered by each runner?
SELECT
    [runner_id],
    count(*) cnt_deliv
FROM
    [pizza_runner].[dbo].[runner_orders]
where
    pickup_time is not null
group by
    [runner_id]
    /*========================================================================*/
    -- 4 - How many of each type of pizza was delivered?
SELECT
    [pizza_id],
    count([pizza_id])
FROM
    [pizza_runner].[dbo].[runner_orders] ro
    join [pizza_runner].[dbo].[customer_orders] co on co.order_id = ro.order_id
    and ro.pickup_time is not null
group by
    [pizza_id]
    /*========================================================================*/
    -- 5 - How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
    co.[customer_id],
    CAST(pn.pizza_name AS NVARCHAR(MAX)) pizza_name,
    count(co.[pizza_id]) cnt_typ
FROM
    [pizza_runner].[dbo].[customer_orders] co
    join [pizza_runner].[dbo].[pizza_names] pn on pn.pizza_id = co.pizza_id
group by
    co.[customer_id],
    CAST(pn.pizza_name AS NVARCHAR(MAX))
order by
    co.[customer_id]
    /*========================================================================*/
    -- 6 - What was the maximum number of pizzas delivered in a single order?
;

with mx_ord as(
    SELECT
        co.order_id,
        count(co.order_id) cnt_ord
    FROM
        [pizza_runner].[dbo].[runner_orders] ro
        join [pizza_runner].[dbo].[customer_orders] co on co.order_id = ro.order_id
        and ro.pickup_time is not null
    group by
        co.order_id
)
select
    max(cnt_ord) max_ord
from
    mx_ord
    /*========================================================================*/
    -- 7 - For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select
    co.customer_id,
    count(co.[exclusions]) cnt_exc,
    count(co.[extras]) cnt_ext
FROM
    [pizza_runner].[dbo].[runner_orders] ro
    join [pizza_runner].[dbo].[customer_orders] co on co.order_id = ro.order_id
    and ro.pickup_time is not null
group by
    co.customer_id
    /*========================================================================*/
    -- 8 - How many pizzas were delivered that had both exclusions and extras?
select
    co.customer_id,
    count(co.[exclusions]) cnt_exc,
    count(co.[extras]) cnt_ext
FROM
    [pizza_runner].[dbo].[runner_orders] ro
    join [pizza_runner].[dbo].[customer_orders] co on co.order_id = ro.order_id
    and ro.pickup_time is not null
group by
    co.customer_id
having
    count(co.[exclusions]) != 0
    and count(co.[extras]) != 0
    /*========================================================================*/
    -- 9 - What was the total volume of pizzas ordered for each hour of the day?
SELECT
    DATEPART(HOUR, [order_time]) hr,
    count(*) cnt
FROM
    [pizza_runner].[dbo].[customer_orders]
group by
    DATEPART(HOUR, [order_time])
order by
    DATEPART(HOUR, [order_time])
    /*========================================================================*/
    -- 10 - What was the volume of orders for each day of the week?
SELECT
    cast([order_time] as Date) dt,
    count(*) cnt
FROM
    [pizza_runner].[dbo].[customer_orders]
group by
    cast([order_time] as Date)
order by
    cast([order_time] as Date) -- ************************************************* B. Runner and Customer Experience
    /*========================================================================*/
    -- 1 - How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
    DATEPART(week, [registration_date]) we_num,
    count(*) cnt_rn
FROM
    [pizza_runner].[dbo].[runners]
group by
    DATEPART(week, [registration_date])
    /*========================================================================*/
    -- 2 - What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT
    ro.runner_id,
    avg(datediff(minute, [order_time], pickup_time))
FROM
    [pizza_runner].[dbo].[runner_orders] ro
    join [pizza_runner].[dbo].[customer_orders] co on co.order_id = ro.order_id
    and ro.pickup_time is not null
group by
    ro.runner_id
    /*========================================================================*/
    -- 3 - Is there any relationship between the number of pizzas and how long the order takes to prepare?
    -- Answer: Accordin to result of guery "No there isn't"
select
    ro.order_id,
    count(*) cnt,
    ro.duration,
    ro.duration / count(*) each_piz
FROM
    [pizza_runner].[dbo].[runner_orders] ro
    join [pizza_runner].[dbo].[customer_orders] co on co.order_id = ro.order_id
    and ro.pickup_time is not null
group by
    ro.order_id,
    ro.duration
    /*========================================================================*/
    -- 4 - What was the average distance travelled for each customer?
;

with avg_dis as (
    select
        co.customer_id,
        ro.distance,
        avg(cast(ro.distance as float)) over (partition by co.customer_id) as avf_dist
    FROM
        [pizza_runner].[dbo].[runner_orders] ro
        join [pizza_runner].[dbo].[customer_orders] co on co.order_id = ro.order_id
        and ro.pickup_time is not null
    group by
        ro.order_id,
        co.customer_id,
        ro.distance
)
select
    customer_id,
    avf_dist
from
    avg_dis
group by
    customer_id,
    avf_dist
    /*========================================================================*/
    -- 5 - What was the difference between the longest and shortest delivery times for all orders?
SELECT
    co.order_id,
    datediff(minute, [order_time], pickup_time) min_dur,
    datediff(minute, [order_time], pickup_time) + duration man_dur
FROM
    [pizza_runner].[dbo].[runner_orders] ro
    join [pizza_runner].[dbo].[customer_orders] co on co.order_id = ro.order_id
    and ro.pickup_time is not null
group by
    co.order_id,
    [order_time],
    pickup_time,
    duration
    /*========================================================================*/
    -- 6 - What was the average speed for each runner for each delivery and do you notice any trend for these values?
    -- Answer: Accordin to result of guery "Runner 1 is activer that the others"
SELECT
    [runner_id],
    count(order_id) ord_mun,
    avg(cast ([duration] as int)) avg_dur
FROM
    [pizza_runner].[dbo].[runner_orders]
where
    duration is not null
group by
    [runner_id]
    /*========================================================================*/
    -- 7 - What is the successful delivery percentage for each runner?
SELECT
    [runner_id],
    cast (
        (COUNT(pickup_time) /(COUNT(order_id) * 1.0)) * 100 as int
    ) percent_suc
FROM
    [pizza_runner].[dbo].[runner_orders]
group by
    [runner_id] -- ************************************************* C. Ingredient Optimisation
    /*========================================================================*/
    -- 1 - What are the standard ingredients for each pizza?
    /*========================================================================*/
    -- 2 - What was the most commonly added extra?
    /*========================================================================*/
    -- 3 - What was the most common exclusion?
    /*========================================================================*/
    /* 4 - Generate an order item for each record in the customers_orders table in the format of one of the following:
     Meat Lovers
     Meat Lovers - Exclude Beef
     Meat Lovers - Extra Bacon
     Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
     */
    /*========================================================================*/
    /* 5 - Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
     For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"*/
    /*========================================================================*/
    -- 6 - What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
    -- ************************************************* D. Pricing and Ratings
    /*========================================================================*/
    /* 1 - If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
     how much money has Pizza Runner made so far if there are no delivery fees?*/
    /*========================================================================*/
    -- 2 - What was the most commonly added extra?
    /*========================================================================*/
    /* 3 - The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
     how would you design an additional table for this new dataset - 
     generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
     */
    /*========================================================================*/
    /* 4 - Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
     customer_id
     order_id
     runner_id
     rating
     order_time
     pickup_time
     Time between order and pickup
     Delivery duration
     Average speed
     Total number of pizzas
     */
    /*========================================================================*/
    /* 5 - If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras 
     and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
     */
    /*
     ==================================== Bonus Questions ====================================
     If Danny wants to expand his range of pizzas - how would this impact the existing data design? 
     Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the 
     toppings was added to the Pizza Runner menu?
     */
