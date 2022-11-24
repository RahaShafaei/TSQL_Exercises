/* --------------------
 case-study-5 questions
 --------------------*/
/* ************************************************* 1. Data Cleansing Steps*/
/*========================================================================*/
/*
 In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
 Convert the week_date to a DATE format
 Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
 Add a month_number with the calendar month for each week_date value as the 3rd column
 Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
 Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
 segment	age_band
 1	Young Adults
 2	Middle Aged
 3 or 4	Retirees
 
 Add a new demographic column using the following mapping for the first letter in the segment values:
 segment	demographic
 C	Couples
 F	Families
 
 Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
 Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
 */
;

with date_conv as(
  SELECT
    [week_date],
    CONVERT(
      DATE,
      '20' + RIGHT([week_date], 2) + '.' +case
        when len(
          substring(
            [week_date],
            (CHARINDEX('/', [week_date]) + 1),
            len([week_date]) -(CHARINDEX('/', [week_date]) + 1) -2
          )
        ) < 2 then '0' + substring(
          [week_date],
          (CHARINDEX('/', [week_date]) + 1),
          len([week_date]) -(CHARINDEX('/', [week_date]) + 1) -2
        )
        else substring(
          [week_date],
          (CHARINDEX('/', [week_date]) + 1),
          len([week_date]) -(CHARINDEX('/', [week_date]) + 1) -2
        )
      end + '.' +case
        when len(
          SUBSTRING([week_date], 1, (CHARINDEX('/', [week_date]) -1))
        ) < 2 then '0' + SUBSTRING([week_date], 1, (CHARINDEX('/', [week_date]) -1))
        else SUBSTRING([week_date], 1, (CHARINDEX('/', [week_date]) -1))
      end,
      102
    ) w_date
  FROM
    [data_mart].[dbo].[weekly_sales]
  group by
    [week_date]
)
select
  distinct dc.w_date [week_date],
  datepart(WEEK, dc.w_date) as [week_number],
  datepart(MONTH, dc.w_date) as [month_number],
  datepart(YEAR, dc.w_date) as [calendar_year],
  [region],
  [platform],
  case
    when [segment] = 'null' then 'unknown'
    else [segment]
  end [segment],
  case
    when [segment] = 'null' then 'unknown'
    when CHARINDEX('1', [segment]) > 0 then 'Young Adults'
    when CHARINDEX('2', [segment]) > 0 then 'Middle Aged'
    when (
      CHARINDEX('3', [segment]) > 0
      OR CHARINDEX('4', [segment]) > 0
    ) then 'Retirees'
  end [age_band],
  case
    when [segment] = 'null' then 'unknown'
    when CHARINDEX('F', [segment]) > 0 then 'Families'
    when CHARINDEX('C', [segment]) > 0 then 'Couples'
  end [demographic],
  [sales],
  [transactions],
  cast (([sales] / [transactions]) as decimal(38, 2)) [avg_transaction ] into [data_mart].[dbo].[clean_weekly_sales]
from
  [data_mart].[dbo].[weekly_sales] ws
  join date_conv dc on ws.week_date = dc.week_date
  /* ************************************************* 2. Data Exploration*/
  /*========================================================================*/
  -- 1 - What day of the week is used for each week_date value?
SELECT
  [week_date],
  DATEPART(dw, [week_date]) day_num,
  DATENAME(dw, GETDATE()) day_name,
  [week_number],
  [month_number],
  [calendar_year],
  [region],
  [platform],
  [segment],
  [age_band],
  [demographic],
  [avg_transaction ]
FROM
  [data_mart].[dbo].[clean_weekly_sales]
  /*========================================================================*/
  -- 2 - What range of week numbers are missing from the dataset?
select
  dm_num
from
  (
    values
      (1),
      (2),
      (3),
      (4),
      (5),
      (6),
      (7)
  ) as tem(dm_num)
except
SELECT
  DATEPART(dw, [week_date]) day_num
FROM
  [data_mart].[dbo].[clean_weekly_sales]
group by
  [week_date]
  /*========================================================================*/
  -- 3 - How many total transactions were there for each year in the dataset?
SELECT
  DATEPART(year, [week_date]) d_year,
  sum([transactions]) tot_trans
FROM
  [data_mart].[dbo].[clean_weekly_sales]
group by
  DATEPART(year, [week_date])
  /*========================================================================*/
  -- 4 - What is the total sales for each region for each month?
SELECT
  [region],
  DATEPART(MONTH, [week_date]) mnt,
  SUM(sales) tot_trans
FROM
  [data_mart].[dbo].[clean_weekly_sales]
group by
  [region],
  DATEPART(MONTH, [week_date])
order by
  [region],
  DATEPART(MONTH, [week_date])
  /*======================================================================== */
  -- 5 - What is the total count of transactions for each platform
SELECT
  [platform],
  sum([transactions]) tot_trans
FROM
  [data_mart].[dbo].[clean_weekly_sales]
group by
  [platform]
  /*======================================================================== */
  -- 6 - What is the percentage of sales for Retail vs Shopify for each month?
;

with sm_sale as(
  SELECT
    DATEPART(MONTH, [week_date]) mnt,
    [platform],
    SUM(cast(sales as decimal(38, 2))) sum_sale
  FROM
    [data_mart].[dbo].[clean_weekly_sales]
  group by
    DATEPART(MONTH, [week_date]),
    [platform]
)
select
  mnt,
  [platform],
  sum_sale,
  cast(
    (
      cast (
        case
          when [platform] = 'Retail' then sum_sale
          else NULL
        end as decimal
      ) / (
        SUM(cast(sum_sale as decimal(38, 2))) over (partition by [platform])
      )
    ) * 100 as numeric(38, 1)
  ) prc_Retail,
  cast(
    (
      cast (
        case
          when [platform] = 'Shopify' then sum_sale
          else NULL
        end as decimal
      ) / (
        SUM(cast(sum_sale as decimal(38, 2))) over (partition by [platform])
      )
    ) * 100 as numeric(38, 1)
  ) prc_Shopify
from
  sm_sale
order by
  mnt,
  [platform]
  /*======================================================================== */
  -- 7 - What is the percentage of sales by demographic for each year in the dataset?
;

with sm_sale as(
  SELECT
    DATEPART(YEAR, [week_date]) yr,
    [demographic],
    SUM(cast(sales as decimal(38, 2))) sum_sale
  FROM
    [data_mart].[dbo].[clean_weekly_sales]
  group by
    DATEPART(YEAR, [week_date]),
    [demographic]
)
select
  yr,
  [demographic],
  sum_sale,
  cast(
    (
      cast (
        case
          when [demographic] = 'Couples' then sum_sale
          else NULL
        end as decimal
      ) / (
        SUM(cast(sum_sale as decimal(38, 2))) over (partition by [demographic])
      )
    ) * 100 as numeric(38, 1)
  ) prc_Couples,
  cast(
    (
      cast (
        case
          when [demographic] = 'Families' then sum_sale
          else NULL
        end as decimal
      ) / (
        SUM(cast(sum_sale as decimal(38, 2))) over (partition by [demographic])
      )
    ) * 100 as numeric(38, 1)
  ) prc_Families,
  cast(
    (
      cast (
        case
          when [demographic] = 'unknown' then sum_sale
          else NULL
        end as decimal
      ) / (
        SUM(cast(sum_sale as decimal(38, 2))) over (partition by [demographic])
      )
    ) * 100 as numeric(38, 1)
  ) prc_unknown
from
  sm_sale
order by
  yr,
  [demographic]
  /*======================================================================== */
  -- 8 - Which age_band and demographic values contribute the most to Retail sales?
  /*  Which age_band and demographic values contribute the most to Retail sales? */
;

with dem_max as (
  SELECT
    top 1 'demographic' [type],
    [demographic],
    SUM(cast(sales as decimal(38, 2))) sum_sale
  FROM
    [data_mart].[dbo].[clean_weekly_sales]
  where
    [demographic] != 'unknown'
  group by
    [demographic]
  order by
    SUM(cast(sales as decimal(38, 2))) DESC
),
age_max as(
  SELECT
    top 1 'age_band' [type],
    [age_band],
    SUM(cast(sales as decimal(38, 2))) sum_sale
  FROM
    [data_mart].[dbo].[clean_weekly_sales]
  where
    [age_band] != 'unknown'
  group by
    [age_band]
  order by
    SUM(cast(sales as decimal(38, 2))) DESC
)
select
  *
from
  dem_max
union
select
  *
from
  age_max
  /*======================================================================== */
  -- 9 - Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
  /*Answer: This file cannot be considered as an average, because it is calculating the amount of sales based on the number of transactions, and it is not related to the average transaction at all, and of course it is based on toltal of dataset and not by year.*/
SELECT
  DATEPART(YEAR, [week_date]) yr,
  [platform],
  AVG(cast([transactions] as decimal(38, 2))) trans_Retail
FROM
  [data_mart].[dbo].[clean_weekly_sales]
group by
  DATEPART(YEAR, [week_date]),
  [platform]
  /* ************************************************* 3. Before & After Analysis*/
  /* This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
   Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
   We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
   Using this analysis approach - answer the following questions:*/
  /*======================================================================== */
  -- 1 - What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
SELECT
  sum(cast([sales] as decimal(38, 2))) tot_sale
FROM
  [data_mart].[dbo].[clean_weekly_sales]
where
  [week_date] > DATEADD(WEEK, -4, cast('2020-06-15' as DATE))
  and [week_date] < DATEADD(WEEK, 4, cast('2020-06-15' as DATE))
  and [week_date] != cast('2020-06-15' as DATE)
  /*======================================================================== */
  -- 2 - What about the entire 12 weeks before and after?
SELECT
  sum(cast([sales] as decimal(38, 2))) tot_sale
FROM
  [data_mart].[dbo].[clean_weekly_sales]
where
  [week_date] > DATEADD(WEEK, -12, cast('2020-06-15' as DATE))
  and [week_date] < DATEADD(WEEK, 12, cast('2020-06-15' as DATE))
  and [week_date] != cast('2020-06-15' as DATE)
  /*======================================================================== */
  -- 3 - How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
SELECT
  '2020-06-15' as yr,
  sum(cast([sales] as decimal(38, 2))) tot_sale
FROM
  [data_mart].[dbo].[clean_weekly_sales]
where
  [week_date] > DATEADD(WEEK, -4, cast('2020-06-15' as DATE))
  and [week_date] < DATEADD(WEEK, 4, cast('2020-06-15' as DATE))
  and [week_date] != cast('2020-06-15' as DATE)
UNION
SELECT
  '2019-06-15' as yr,
  sum(cast([sales] as decimal(38, 2))) tot_sale
FROM
  [data_mart].[dbo].[clean_weekly_sales]
where
  [week_date] > DATEADD(WEEK, -4, cast('2019-06-15' as DATE))
  and [week_date] < DATEADD(WEEK, 4, cast('2019-06-15' as DATE))
  and [week_date] != cast('2019-06-15' as DATE)
UNION
SELECT
  '2018-06-15' as yr,
  sum(cast([sales] as decimal(38, 2))) tot_sale
FROM
  [data_mart].[dbo].[clean_weekly_sales]
where
  [week_date] > DATEADD(WEEK, -4, cast('2018-06-15' as DATE))
  and [week_date] < DATEADD(WEEK, 4, cast('2018-06-15' as DATE))
  and [week_date] != cast('2018-06-15' as DATE)
  /* ************************************************* 4. Bonus Question*/
  /* Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
   
   region
   platform
   age_band
   demographic
   customer_type
   Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?*/
