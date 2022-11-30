/* --------------------
 case-study-8 questions
 --------------------*/
/* ************************************************* Data Exploration and Cleansing*/
/*========================================================================*/
-- 1 - Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
UPDATE
    [dbo].[interest_metrics]
SET
    [month_year] = cast (STUFF([month_year1], 3, 1, '-01-') as date)
    /*========================================================================*/
    -- 2 - What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT
    [month_year],
    count(*)
FROM
    [fresh_segments].[dbo].[interest_metrics]
group by
    [month_year]
order by
    [month_year]
    /*========================================================================*/
    -- 3 - What do you think we should do with these null values in the fresh_segments.interest_metrics
    /*========================================================================*/
    -- 4 - How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
SELECT
    count(*) ant_inter
FROM
    [fresh_segments].[dbo].[interest_metrics] i
    left join [fresh_segments].[dbo].[interest_map] im on i.interest_id = im.id
where
    im.id is null
    /*========================================================================*/
    -- 5 - Summarise the id values in the fresh_segments.interest_map by its total record count in this table
update
    im
set
    im.[id] = im_tem.rn
from
    [fresh_segments].[dbo].[interest_map] im
    join (
        SELECT
            [id],
            ROW_NUMBER() over(
                order by
                    id
            ) rn
        FROM
            [fresh_segments].[dbo].[interest_map]
    ) im_tem on im_tem.id = im.id
    /*========================================================================*/
    -- 6 - What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
    /*Answer: left join to interest_metrics, because there aren't the same row for eache row of [interest_map] in [interest_metrics]*/
SELECT
    [id],
    [interest_name],
    [interest_summary],
    [created_at],
    [last_modified],
    [_month],
    [_year],
    [month_year1],
    [month_year],
    [interest_id],
    [composition],
    [index_value],
    [ranking],
    [percentile_ranking]
FROM
    [fresh_segments].[dbo].[interest_metrics] me
    left join [fresh_segments].[dbo].[interest_map] ma on me.interest_id = ma.id
where
    interest_id = 21246
    /*========================================================================*/
    -- 7 - Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
    /*Answer: these values are valid,because there isn't any interest_metrics before interest_map*/
SELECT
    count(*)
FROM
    [fresh_segments].[dbo].[interest_metrics] me
    left join [fresh_segments].[dbo].[interest_map] ma on me.interest_id = ma.id
where
    me.month_year < ma.created_at
    /* ************************************************* Interest Analysis */
    /*========================================================================*/
    -- 1 - Which interests have been present in all month_year dates in our dataset?
    --Which interests have been present in all month_year dates in our dataset?
;

with cnt_mt_yr as (
    SELECT
        count(distinct [month_year]) cnt_mt
    FROM
        [fresh_segments].[dbo].[interest_metrics]
    where
        [month_year] is not null
),
cnt_interest as(
    select
        [interest_id],
        [month_year],
        sum(1) over (partition by [interest_id]) sm_int
    FROM
        [fresh_segments].[dbo].[interest_metrics]
    where
        [month_year] is not null
    group by
        [interest_id],
        [month_year]
)
select
    [interest_id],
    sm_int
from
    cnt_interest
    join cnt_mt_yr on cnt_interest.sm_int >= cnt_mt_yr.cnt_mt
group by
    [interest_id],
    sm_int
    /*======================================================================== */
    -- 2 - Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
    /*Answer: None of them*/
;

with cnt_interest as(
    select
        [interest_id],
        [month_year],
        sum(1) over (partition by [interest_id]) sm_int
    FROM
        [fresh_segments].[dbo].[interest_metrics]
    where
        [month_year] is not null
    group by
        [interest_id],
        [month_year]
),
gg as (
    select
        [interest_id],
        [month_year],
        sm_int,
        count(*) over (
            partition by [month_year],
            sm_int
            order by
                [month_year],
                sm_int ROWS BETWEEN UNBOUNDED PRECEDING
                AND CURRENT ROW
        ) * 100.0 / count(*) over (partition by [month_year]) cnt_prc
    from
        cnt_interest
)
select
    *
from
    gg
where
    cnt_prc >= 90.0
    /*======================================================================== */
    -- 3 - If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
;

with cnt_interest as(
    select
        [interest_id],
        [month_year],
        sum(1) over (partition by [interest_id]) sm_int
    FROM
        [fresh_segments].[dbo].[interest_metrics]
    where
        [month_year] is not null
    group by
        [interest_id],
        [month_year]
)
select
    count(*) cnt_rm
from
    cnt_interest
where
    sm_int < 14
    /*======================================================================== */
    -- 4 - Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
    /*======================================================================== */
    -- 5 - After removing these interests - how many unique interests are there for each month?
DELETE FROM
    [fresh_segments].[dbo].[interest_metrics]
WHERE
    exists (
        select
            [interest_id],
            [month_year]
        from
            (
                select
                    [interest_id],
                    [month_year],
                    sum(1) over (partition by [interest_id]) sm_int
                FROM
                    [fresh_segments].[dbo].[interest_metrics]
                where
                    [month_year] is not null
                group by
                    [interest_id],
                    [month_year]
            ) cnt_interest
        where
            sm_int < 14
            and cnt_interest.interest_id = [fresh_segments].[dbo].[interest_metrics].interest_id
            and cnt_interest.[month_year] = [fresh_segments].[dbo].[interest_metrics].[month_year]
    ) --+++++++++++++++++++++++++++++++++++++++++++++++
    /*Answer: 480*/
SELECT
    [month_year],
    count(distinct [interest_id]) cnt_int
FROM
    [fresh_segments].[dbo].[interest_metrics]
group by
    [month_year]
    /*======================================================================== */
    /* ************************************************* Segment Analysis*/
    /*======================================================================== */
    -- 1 - Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
DELETE FROM
    [fresh_segments].[dbo].[interest_metrics]
WHERE
    exists (
        select
            [interest_id],
            [month_year]
        from
            (
                select
                    [interest_id],
                    [month_year],
                    sum(1) over (partition by [interest_id]) sm_int
                FROM
                    [fresh_segments].[dbo].[interest_metrics]
                where
                    [month_year] is not null
                group by
                    [interest_id],
                    [month_year]
            ) cnt_interest
        where
            sm_int < 6
            and cnt_interest.interest_id = [fresh_segments].[dbo].[interest_metrics].interest_id
            and cnt_interest.[month_year] = [fresh_segments].[dbo].[interest_metrics].[month_year]
    )
    /*--+++++++++++++++++++++++++++++++++++++++++++++++*/
;

with clc_rnk as (
    SELECT
        ROW_NUMBER() over(
            partition by [interest_id]
            order by
                [composition] desc
        ) rn,
        [month_year],
        [interest_id],
        [composition]
    FROM
        [fresh_segments].[dbo].[interest_metrics]
    where
        interest_id is not null
)
select
    top 10 [month_year],
    [interest_id],
    [composition]
from
    clc_rnk
where
    rn = 1
order by
    [composition] desc
    /* --+++++++++++++++++++++++++++++++++++++++++++++++*/
;

with clc_rnk as (
    SELECT
        ROW_NUMBER() over(
            partition by [interest_id]
            order by
                [composition] desc
        ) rn,
        [month_year],
        [interest_id],
        [composition]
    FROM
        [fresh_segments].[dbo].[interest_metrics]
    where
        interest_id is not null
)
select
    top 10 [month_year],
    [interest_id],
    [composition]
from
    clc_rnk
where
    rn = 1
order by
    [composition]
    /*======================================================================== */
    -- 2 - Which 5 interests had the lowest average ranking value?
SELECT
    top 5 [interest_id],
    avg([ranking]) avg_rnk
FROM
    [fresh_segments].[dbo].[interest_metrics]
group by
    [interest_id]
order by
    avg([ranking])
    /*======================================================================== */
    -- 3 - Which 5 interests had the largest standard deviation in their percentile_ranking value?
SELECT
    top 5 [interest_id],
    STDEV([percentile_ranking]) avg_rnk
FROM
    [fresh_segments].[dbo].[interest_metrics]
where
    interest_id is not null
group by
    [interest_id]
order by
    STDEV([percentile_ranking]) desc
    /*======================================================================== */
    -- 4 - For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
    /* For the 5 interests found in the previous question - 
     what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? 
     Can you describe what is happening for these 5 interests?*/
;

with std_int as (
    SELECT
        top 5 [interest_id],
        STDEV([percentile_ranking]) avg_rnk,
        min([percentile_ranking]) min_percentile,
        max([percentile_ranking]) max_percentile
    FROM
        [fresh_segments].[dbo].[interest_metrics]
    where
        interest_id is not null
    group by
        [interest_id]
    order by
        STDEV([percentile_ranking]) desc
)
select
    'min_percentile_ranking' [min_percentile],
    im.[interest_id],
    im.month_year,
    im.[percentile_ranking]
from
    [fresh_segments].[dbo].[interest_metrics] im
    join std_int on im.interest_id = std_int.interest_id
    and im.[percentile_ranking] = std_int.min_percentile
UNION
select
    'max_percentile_ranking' [max_percentile],
    im.[interest_id],
    im.month_year,
    im.[percentile_ranking]
from
    [fresh_segments].[dbo].[interest_metrics] im
    join std_int on im.interest_id = std_int.interest_id
    and im.[percentile_ranking] = std_int.max_percentile
order by
    im.[interest_id]
    /*======================================================================== */
    -- 5 - How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?
    /* ************************************************* Index Analysis*/
    /* The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.
     Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.*/
    /*======================================================================== */
    -- 1 - What is the top 10 interests by the average composition for each month?
    /*======================================================================== */
    -- 2 - For all of these top 10 interests - which interest appears the most often?
    /*======================================================================== */
    -- 3 - What is the average of the average composition for the top 10 interests for each month?
    /*======================================================================== */
    -- 4 - What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
    /*======================================================================== */
    -- 5 - Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?
