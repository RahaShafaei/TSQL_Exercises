/* --------------------
 case-study-3 questions
 --------------------*/
-- ************************************************* A. Customer Journey
/*========================================================================*/
/* Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description 
 about each customer’s onboarding journey.
 Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
 */
SELECT
    s.[customer_id],
    p.plan_name,
    [start_date]
FROM
    [foodie_fi].[dbo].[subscriptions] s
    join [foodie_fi].[dbo].[plans] p on s.plan_id = p.plan_id
    join (
        select
            [customer_id],
            min([start_date]) min_date
        from
            [foodie_fi].[dbo].[subscriptions]
        group by
            [customer_id]
    ) s_min on s_min.customer_id = s.customer_id
    and s.[start_date] = s_min.min_date -- ************************************************* B. Data Analysis Questions
    /*========================================================================*/
    -- 1 - How many customers has Foodie-Fi ever had?
SELECT
    count(distinct(s.[customer_id])) customer_cnt
FROM
    [foodie_fi].[dbo].[subscriptions] s
    /*========================================================================*/
    -- 2 - What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT
    DATEPART(MONTH, [start_date]) mnt,
    count(*) cnt_dist
FROM
    [foodie_fi].[dbo].[subscriptions] s
where
    plan_id = 0
group by
    DATEPART(MONTH, [start_date])
order by
    DATEPART(MONTH, [start_date])
    /*========================================================================*/
    -- 3 - What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT
    p.plan_name,
    count(*) cnt_pln
FROM
    [foodie_fi].[dbo].[subscriptions] s
    join [foodie_fi].[dbo].plans p on p.plan_id = s.plan_id
where
    [start_date] > cast ('2020-12-31' as date)
group by
    p.plan_name
    /*========================================================================*/
    -- 4 - What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
;

with churned_cnt as (
    SELECT
        count(distinct s.customer_id) cnt_cus,
        count(
            case
                when s.plan_id != 4 then NULL
                else s.plan_id
            end
        ) cnt_churn
    FROM
        [foodie_fi].[dbo].[subscriptions] s
)
select
    cnt_cus,
    cast(
        (
            cast (cnt_churn as decimal) / cast (cnt_cus as decimal)
        ) * 100 as numeric(38, 1)
    ) cnt_churn_prc
from
    churned_cnt
    /*========================================================================*/
    -- 5 - How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
;

with cal_7day as (
    SELECT
        [customer_id],
        [plan_id],
        [start_date],
        DATEADD(DAY, 7, [start_date]) seven_day_after
    FROM
        [foodie_fi].[dbo].[subscriptions]
    where
        [plan_id] = 0
)
select
    count(*) churned
FROM
    [foodie_fi].[dbo].[subscriptions] s
    join cal_7day c on s.customer_id = c.customer_id
    and s.start_date = c.seven_day_after
where
    s.plan_id = 4
    /*========================================================================*/
    -- 6 - What is the number and percentage of customer plans after their initial free trial?
;

with planed_cuso as (
    select
        count(distinct [customer_id]) cnt_planed
    FROM
        [foodie_fi].[dbo].[subscriptions] s
    where
        s.plan_id in(1, 2, 3)
)
select
    (
        cast(max(pc.cnt_planed) as decimal) / cast (count(distinct s.[customer_id]) as decimal) * 100
    ) per_cus_planed
from
    [foodie_fi].[dbo].[subscriptions] s
    cross apply planed_cuso pc
    /*========================================================================*/
    -- 7 - What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
;

with cus_cnt_pln as(
    SELECT
        [customer_id],
        [plan_id],
        [start_date],
        count([customer_id]) over (partition by [start_date]) cnt_cus,
        count([plan_id]) over (partition by [start_date], [plan_id]) cnt_pln
    FROM
        [foodie_fi].[dbo].[subscriptions] s
    where
        s.start_date = cast ('2020-12-31' as date)
)
select
    [plan_id],
    cast (
        (
            cast (cnt_pln as decimal) / cast (cnt_cus as decimal)
        ) * 100 as numeric(38, 2)
    ) pln_prc
from
    cus_cnt_pln
group by
    cnt_cus,
    [plan_id],
    cnt_pln
    /*========================================================================*/
    -- 8 - How many customers have upgraded to an annual plan in 2020?
SELECT
    count(*) cus_upg
FROM
    [foodie_fi].[dbo].[subscriptions]
where
    plan_id = 3
    and datepart(year, [start_date]) = '2020'
    /*========================================================================*/
    -- 9 - How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
;

with tri_anu_dte as(
    SELECT
        [customer_id],
        [plan_id],
        [start_date],
        min(
            case
                when [plan_id] = 0 then [start_date]
                else NULL
            end
        ) over (partition by [customer_id]) trial_date,
        min(
            case
                when [plan_id] = 3 then [start_date]
                else NULL
            end
        ) over (partition by [customer_id]) annual_date
    FROM
        [foodie_fi].[dbo].[subscriptions]
),
date_diff as (
    select
        [customer_id],
        DATEDIFF(day, trial_date, annual_date) avg_anual
    from
        tri_anu_dte
    where
        annual_date is not null
    group by
        [customer_id],
        trial_date,
        annual_date
)
select
    avg(avg_anual) avg_anual
from
    date_diff
    /*========================================================================*/
    -- 10 - Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
;

with cnt_pln_3 as (
    SELECT
        [customer_id],
        [plan_id],
        [start_date],
        sum (
            case
                when plan_id = 3 then 1
                else 0
            end
        ) over(
            order by
                [start_date] ROWS UNBOUNDED PRECEDING
        ) cnt_pln
    FROM
        [foodie_fi].[dbo].[subscriptions]
)
select
    [customer_id],
    [plan_id],
    [start_date],
    avg(cnt_pln) over (
        order by
            [start_date] ROWS BETWEEN 30 PRECEDING
            AND CURRENT ROW
    )
from
    cnt_pln_3
order by
    [start_date]
    /*========================================================================*/
    -- 11 - How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
;

with cus_max as (
    SELECT
        [customer_id],
        [plan_id],
        [start_date],
        LAG([plan_id]) over (
            partition by [customer_id]
            order by
                [customer_id],
                [start_date]
        ) lag_pln,
        max ([start_date]) over (partition by [customer_id]) [max_start_date]
    FROM
        [foodie_fi].[dbo].[subscriptions]
    where
        DATEPART(year, [start_date]) = '2020'
        and [plan_id] in (2, 3)
),
cnt_dwngrd as (
    select
        [customer_id],
        [plan_id],
        lag_pln,
        [start_date]
    from
        cus_max
    where
        [start_date] = [max_start_date]
        and lag_pln > [plan_id]
)
select
    count (*) cnt_dg
from
    cnt_dwngrd -- ************************************************* C. Challenge Payment Question
    /*========================================================================*/
    /*
     The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
     
     monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
     upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
     upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
     once a customer churns they will no longer make payments
     */
    -- ************************************************* D. Outside The Box Questions
    /*========================================================================*/
    -- 1 - How would you calculate the rate of growth for Foodie-Fi?
    /*========================================================================*/
    -- 2 - What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
    /*========================================================================*/
    -- 3 - What are some key customer journeys or experiences that you would analyse further to improve customer retention?
    /*========================================================================*/
    /* 4 - If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
     */
    /*========================================================================*/
    /* 5 - What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?*/
