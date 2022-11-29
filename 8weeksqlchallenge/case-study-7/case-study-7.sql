/* --------------------
 case-study-7 questions
 --------------------*/
/*
 The following questions can be considered key business questions and metrics that the Balanced Tree team requires for their monthly reports.
 Each question can be answered using a single query - but as you are writing the SQL to solve each individual problem, keep in mind how you would generate all of these metrics in a single SQL script which the Balanced Tree team can run each month.
 */
/* ************************************************* High Level Sales Analysis*/
/*========================================================================*/
-- 1 - What was the total quantity sold for all products?
/*========================================================================*/
-- 2 - What is the total generated revenue for all products before discounts?
/*========================================================================*/
-- 3 - What was the total discount amount for all products?
SELECT
  p.product_name,
  sum([qty]) qty_sold,
  sum(s.price * s.qty) reven,
  sum([discount]) disco
FROM
  [ balanced_tree].[dbo].[sales] s
  join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
group by
  p.product_name
  /* ************************************************* Transaction Analysis*/
  /*========================================================================*/
  -- 1 - How many unique transactions were there?
select
  count(distinct [txn_id]) txn_cnt
FROM
  [ balanced_tree].[dbo].[sales]
  /*======================================================================== */
  -- 2 - What is the average unique products purchased in each transaction?
SELECT
  p.product_name,
  avg(s.[qty]) qty_sold
FROM
  [ balanced_tree].[dbo].[sales] s
  join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
group by
  p.product_name
  /*======================================================================== */
  -- 3 - What are the 25th, 50th and 75th percentile values for the revenue per transaction?
  /*======================================================================== */
  -- 4 - What is the average discount value per transaction?
;

with each_txn as (
  SELECT
    s.txn_id,
    sum(s.price) sm_prc,
    sum(s.[discount]) sm_disco,
    sum(s.price) - sum(s.[discount]) diff_prc_disc
  FROM
    [ balanced_tree].[dbo].[sales] s
  group by
    s.txn_id
)
select
  avg(sm_disco)
from
  each_txn
  /*======================================================================== */
  -- 5 - What is the percentage split of all transactions for members vs non-members?
SELECT
  [member],
  count(distinct ([txn_id])) cnt_txn
FROM
  [ balanced_tree].[dbo].[sales]
group by
  [member]
  /*======================================================================== */
  -- 6 - What is the average revenue for member transactions and non-member transactions?
;

with each_txn as (
  SELECT
    s.txn_id,
    sum(s.price) sm_prc,
    sum(s.[discount]) sm_disco,
    sum(s.price * s.qty) - sum(s.[discount]) diff_prc_disc
  FROM
    [ balanced_tree].[dbo].[sales] s
  group by
    s.txn_id
)
select
  s.[member],
  avg(diff_prc_disc)
from
  [ balanced_tree].[dbo].[sales] s
  join each_txn on s.txn_id = each_txn.txn_id
group by
  [member]
  /*======================================================================== */
  /* ************************************************* Product Analysis*/
  /*======================================================================== */
  -- 1 - What are the top 3 products by total revenue before discount?
SELECT
  top 3 p.product_name,
  sum(s.price * s.qty) reven
FROM
  [ balanced_tree].[dbo].[sales] s
  join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
group by
  p.product_name
order by
  sum(s.price * s.qty) desc
  /*======================================================================== */
  -- 2 - What is the total quantity, revenue and discount for each segment?
SELECT
  p.[segment_name],
  sum(s.qty) gty,
  sum(s.price * s.qty) - sum(s.[discount]) reven,
  sum(s.[discount]) discount
FROM
  [ balanced_tree].[dbo].[sales] s
  join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
group by
  p.[segment_name]
  /*======================================================================== */
  -- 3 - What is the top selling product for each segment?
;

with clc_sm_qty as (
  SELECT
    ROW_NUMBER() over(
      partition by p.segment_name
      order by
        sum([qty]) desc
    ) rn,
    p.segment_name,
    p.product_name,
    sum([qty]) sm_qty
  FROM
    [ balanced_tree].[dbo].[sales] s
    join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
  group by
    p.segment_name,
    p.product_name
)
select
  rn,
  segment_name,
  product_name,
  sm_qty
from
  clc_sm_qty
where
  rn = 1
  /*======================================================================== */
  -- 4 - What is the total quantity, revenue and discount for each category?
SELECT
  p.[category_name],
  sum(s.qty) gty,
  sum(s.price * s.qty) - sum(s.[discount]) reven,
  sum(s.[discount]) discount
FROM
  [ balanced_tree].[dbo].[sales] s
  join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
group by
  p.[category_name]
  /*======================================================================== */
  -- 5 - What is the top selling product for each category?
;

with clc_sm_qty as (
  SELECT
    ROW_NUMBER() over(
      partition by p.[category_name]
      order by
        sum([qty]) desc
    ) rn,
    p.[category_name],
    p.product_name,
    sum([qty]) sm_qty
  FROM
    [ balanced_tree].[dbo].[sales] s
    join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
  group by
    p.[category_name],
    p.product_name
)
select
  rn,
  [category_name],
  product_name,
  sm_qty
from
  clc_sm_qty
where
  rn = 1
  /*======================================================================== */
  -- 6 - What is the percentage split of revenue by product for each segment?
;

with sm_reven as (
  SELECT
    p.segment_name,
    p.product_name,
    sum(s.price * s.qty) - sum(s.[discount]) reven
  FROM
    [ balanced_tree].[dbo].[sales] s
    join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
  group by
    p.segment_name,
    p.product_name
)
select
  segment_name,
  product_name,
  cast(reven as decimal(38, 2)) / cast(
    sum(reven) over (partition by segment_name) as decimal(38, 2)
  ) * 100 prc_produc,
  reven,
  sum(reven) over (partition by segment_name) sm_seg
from
  sm_reven
  /*======================================================================== */
  -- 7 - What is the percentage split of revenue by segment for each category?
;

with sm_reven as (
  SELECT
    p.category_name,
    p.segment_name,
    sum(s.price * s.qty) - sum(s.[discount]) reven
  FROM
    [ balanced_tree].[dbo].[sales] s
    join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
  group by
    p.category_name,
    p.segment_name
)
select
  category_name,
  segment_name,
  cast(reven as decimal(38, 2)) / cast(
    sum(reven) over (partition by category_name) as decimal(38, 2)
  ) * 100 prc_produc,
  reven,
  sum(reven) over (partition by category_name) sm_seg
from
  sm_reven
  /*======================================================================== */
  -- 8 - What is the percentage split of total revenue by category?
;

with sm_reven as (
  SELECT
    p.category_name,
    sum(s.price * s.qty) - sum(s.[discount]) reven
  FROM
    [ balanced_tree].[dbo].[sales] s
    join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
  group by
    p.category_name
)
select
  category_name,
  cast(reven as decimal(38, 2)) / cast(sum(reven) over () as decimal(38, 2)) * 100 prc_produc,
  reven,
  sum(reven) over () sm_seg
from
  sm_reven
  /*======================================================================== */
  -- 9 - What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
;

with pr_txn as (
  select
    p.product_name,
    count(s.txn_id) cnt_txn
  FROM
    [ balanced_tree].[dbo].[sales] s
    join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
  group by
    p.product_name
)
select
  product_name,
  cast(cnt_txn as decimal(38, 2)) cnt_txn_prc,
  cast(SUM(cnt_txn) over() as decimal(38, 2)) cnt_txn_tot,
  cast(cnt_txn as decimal(38, 2)) / cast(SUM(cnt_txn) over() as decimal(38, 2)) * 100 [penetration]
from
  pr_txn
order by
  cnt_txn desc
  /*======================================================================== */
  -- 10 - What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
  /* ************************************************* Reporting Challenge*/
  /* Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.
   Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.
   He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).
   Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)
   */
  -- 1 - What are the top 3 products by total revenue before discount?
  -- 1 - What are the top 3 products by total revenue before discount?
  -- 1 - What are the top 3 products by total revenue before discount?
;

with top_3_products as (
  SELECT
    top 3 p.product_name,
    sum(s.price * s.qty) reven
  FROM
    [ balanced_tree].[dbo].[sales] s
    join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
  group by
    p.product_name
  order by
    sum(s.price * s.qty) desc
),
pr_txn as (
  select
    p.product_name,
    count(s.txn_id) cnt_txn
  FROM
    [ balanced_tree].[dbo].[sales] s
    join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
  group by
    p.product_name
),
clc_sm_qty_cat as (
  SELECT
    ROW_NUMBER() over(
      partition by p.[category_name]
      order by
        sum([qty]) desc
    ) rn,
    p.[category_name],
    p.product_name,
    sum([qty]) sm_qty
  FROM
    [ balanced_tree].[dbo].[sales] s
    join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
  group by
    p.[category_name],
    p.product_name
),
clc_sm_qty_seg as (
  SELECT
    ROW_NUMBER() over(
      partition by p.segment_name
      order by
        sum([qty]) desc
    ) rn,
    p.segment_name,
    p.product_name,
    sum([qty]) sm_qty
  FROM
    [ balanced_tree].[dbo].[sales] s
    join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
  group by
    p.segment_name,
    p.product_name
),
sm_reven_cat as (
  SELECT
    p.category_name,
    p.segment_name,
    sum(s.price * s.qty) - sum(s.[discount]) reven
  FROM
    [ balanced_tree].[dbo].[sales] s
    join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
  group by
    p.category_name,
    p.segment_name
),
sm_reven_seg as (
  SELECT
    p.segment_name,
    p.product_name,
    sum(s.price * s.qty) - sum(s.[discount]) reven
  FROM
    [ balanced_tree].[dbo].[sales] s
    join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
  group by
    p.segment_name,
    p.product_name
),
sm_reven_tot as (
  SELECT
    p.category_name,
    sum(s.price * s.qty) - sum(s.[discount]) reven
  FROM
    [ balanced_tree].[dbo].[sales] s
    join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
  group by
    p.category_name
)
SELECT
  '1_ category_1 _total quantity, revenue and discount' as group_name,
  p.[category_name] as [category_name],
  NULL as [segment_name],
  NULL as [product_name],
  NULL as [value],
  sum(s.qty) [total_quantity],
  sum(s.price * s.qty) - sum(s.[discount]) [total revenue],
  sum(s.[discount]) [total_discount]
FROM
  [ balanced_tree].[dbo].[sales] s
  join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
group by
  p.[category_name]
UNION
select
  '2_ category_2 _top selling product for each category' as group_name,
  [category_name] as [category_name],
  NULL [segment_name],
  product_name [product_name],
  sm_qty as [value],
  NULL [total_quantity],
  NULL [total revenue],
  NULL [total_discount]
from
  clc_sm_qty_cat
where
  rn = 1
UNION
SELECT
  '3_ segment_1 _total quantity, revenue and discount' as group_name,
  NULL as [category_name],
  p.[segment_name] as [segment_name],
  NULL as [product_name],
  NULL as [value],
  sum(s.qty) [total_quantity],
  sum(s.price * s.qty) - sum(s.[discount]) [total revenue],
  sum(s.[discount]) [total_discount]
FROM
  [ balanced_tree].[dbo].[sales] s
  join [ balanced_tree].[dbo].[product_details] p on p.product_id = s.prod_id
group by
  p.[segment_name]
UNION
select
  '4_ segment_2 _top selling product for each segment' as group_name,
  NULL as [category_name],
  segment_name [segment_name],
  product_name [product_name],
  sm_qty as [value],
  NULL [total_quantity],
  NULL [total revenue],
  NULL [total_discount]
from
  clc_sm_qty_seg
where
  rn = 1
UNION
select
  '5_ product_1 _Top 3 Product revenue' as group_name,
  NULL as [category_name],
  NULL as [segment_name],
  product_name as [product_name],
  reven [value],
  NULL [total_quantity],
  NULL [total revenue],
  NULL [total_discount]
from
  top_3_products
union
select
  '6_ product_2 _penetration' as group_name,
  NULL as [category_name],
  NULL as [segment_name],
  product_name as [product_name],
  cast(cnt_txn as decimal(38, 2)) / cast(SUM(cnt_txn) over() as decimal(38, 2)) * 100 [value],
  NULL [total_quantity],
  NULL [total revenue],
  NULL [total_discount]
from
  pr_txn
UNION
select
  '7_ category _the percentage split of revenue by segment for each category' as group_name,
  category_name as [category_name],
  segment_name as [segment_name],
  NULL as [product_name],
  cast(reven as decimal(38, 2)) / cast(
    sum(reven) over (partition by category_name) as decimal(38, 2)
  ) * 100 [value],
  NULL [total_quantity],
  NULL [total revenue],
  NULL [total_discount]
from
  sm_reven_cat
UNION
select
  '8_ segment _the percentage split of revenue by product for each segment' as group_name,
  NULL as [category_name],
  segment_name as [segment_name],
  product_name as [product_name],
  cast(reven as decimal(38, 2)) / cast(
    sum(reven) over (partition by segment_name) as decimal(38, 2)
  ) * 100 [value],
  NULL [total_quantity],
  NULL [total revenue],
  NULL [total_discount]
from
  sm_reven_seg
UNION
select
  '9_ total _the percentage split of total revenue by category' as group_name,
  category_name as [category_name],
  NULL as [segment_name],
  NULL as [product_name],
  cast(reven as decimal(38, 2)) / cast(sum(reven) over () as decimal(38, 2)) * 100 [value],
  NULL [total_quantity],
  NULL [total revenue],
  NULL [total_discount]
from
  sm_reven_tot
order by
  group_name,
  [category_name],
  [segment_name],
  [product_name],
  [value] desc,
  [total_quantity],
  [total revenue],
  [total_discount]
  /* ************************************************* Bonus Challenge*/
  /* Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.
   Hint: you may want to consider using a recursive CTE to solve this problem!*/
