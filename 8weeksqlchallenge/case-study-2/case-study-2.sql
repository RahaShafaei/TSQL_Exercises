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
    /*========================================================================*/
    -- 7 - For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
    /*========================================================================*/
    -- 8 - How many pizzas were delivered that had both exclusions and extras?
    /*========================================================================*/
    -- 9 - What was the total volume of pizzas ordered for each hour of the day?
    /*========================================================================*/
    -- 10 - What was the volume of orders for each day of the week?
    -- ************************************************* B. Runner and Customer Experience
    /*========================================================================*/
    -- 1 - How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
    /*========================================================================*/
    -- 2 - What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
    /*========================================================================*/
    -- 3 - Is there any relationship between the number of pizzas and how long the order takes to prepare?
    /*========================================================================*/
    -- 4 - What was the average distance travelled for each customer?
    /*========================================================================*/
    -- 5 - What was the difference between the longest and shortest delivery times for all orders?
    /*========================================================================*/
    -- 6 - What was the average speed for each runner for each delivery and do you notice any trend for these values?
    /*========================================================================*/
    -- 7 - What is the successful delivery percentage for each runner?
    -- ************************************************* C. Ingredient Optimisation
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