/* --------------------
 case-study-6 questions
 --------------------*/
/* ************************************************* 2. Digital Analysis*/
/*========================================================================*/
-- 1 - How many users are there?
SELECT
  count(distinct [user_id]) cnt_usr
FROM
  [clique_bait].[dbo].[users]
  /*========================================================================*/
  -- 2 - How many cookies does each user have on average?
;

with cnt_cookies as(
  SELECT
    [user_id],
    count(*) cnt_cok
  FROM
    [clique_bait].[dbo].[users]
  group by
    [user_id]
)
select
  avg(cnt_cok) avg_cook
from
  cnt_cookies
  /*========================================================================*/
  -- 3 - What is the unique number of visits by all users per month?
SELECT
  datepart(month, [event_time]) mnt,
  count(distinct [visit_id]) cnt_vst
FROM
  [clique_bait].[dbo].[events]
group by
  datepart(month, [event_time])
order by
  datepart(month, [event_time])
  /*========================================================================*/
  -- 4 - What is the number of events for each event type?
SELECT
  ei.event_name,
  count(*) cnt_evn
FROM
  [clique_bait].[dbo].[events] e
  join [clique_bait].[dbo].event_identifier ei on e.event_type = ei.event_type
group by
  ei.event_name,
  ei.event_type
order by
  ei.event_type
  /*======================================================================== */
  -- 5 - What is the percentage of visits which have a purchase event?
SELECT
  (
    cast(
      count(
        case
          when ei.event_name = 'Purchase' then ei.event_name
          else NULL
        end
      ) as decimal(38, 2)
    ) / cast(count(*) as decimal(38, 2))
  ) * 100 cnt_purch
FROM
  [clique_bait].[dbo].[events] e
  join [clique_bait].[dbo].event_identifier ei on e.event_type = ei.event_type
  /*======================================================================== */
  -- 6 - What is the percentage of visits which view the checkout page but do not have a purchase event?
;

with calc_cnts as (
  SELECT
    count(distinct e.visit_id) cnt_vst,
    case
      when count(
        case
          when ph.page_name = 'Checkout' then ph.page_name
          else NULL
        end
      ) > 0 then 1
      else 0
    end cnt_check,
    count(
      case
        when ei.event_name = 'Purchase' then ph.page_name
        else NULL
      end
    ) cnt_purch
  FROM
    [clique_bait].[dbo].[events] e
    join [clique_bait].[dbo].event_identifier ei on e.event_type = ei.event_type
    join [clique_bait].[dbo].page_hierarchy ph on e.page_id = ph.page_id
  group by
    e.visit_id
)
select
  (
    cast(
      sum(
        case
          when cnt_check > 0
          and cnt_purch = 0 then cnt_check
          else 0
        end
      ) as decimal(38, 2)
    ) / cast (sum(cnt_vst) as decimal(38, 2))
  ) * 100 as avg_chk
from
  calc_cnts
  /*======================================================================== */
  -- 7 - What are the top 3 pages by number of views?
SELECT
  top 3 page_name,
  count(*) cnt_page
FROM
  [clique_bait].[dbo].[events] e
  join [clique_bait].[dbo].[page_hierarchy] ph on ph.page_id = e.page_id
group by
  page_name
order by
  count(*) desc
  /*======================================================================== */
  -- 8 - What is the number of views and cart adds for each product category?
SELECT
  ph.product_category,
  count([visit_id]) cnt_vst,
  count(
    case
      when [event_type] = 2 then [event_type]
      else NULL
    end
  ) cnt_cart_add
FROM
  [clique_bait].[dbo].[events] e
  join [clique_bait].[dbo].[page_hierarchy] ph on e.page_id = ph.page_id
  and [product_category] is not null
group by
  ph.product_category
  /*======================================================================== */
  -- 9 - What are the top 3 products by purchases?
SELECT
  top 3 ph.page_name,
  count(*) cnt_product
FROM
  [clique_bait].[dbo].[events] e
  join [clique_bait].[dbo].[events] e_purch on e.visit_id = e_purch.visit_id
  and e_purch.[event_type] = 3
  join [clique_bait].[dbo].[page_hierarchy] ph on e.page_id = ph.page_id
where
  e.[event_type] = 2
group by
  ph.page_name
order by
  count(*) desc
  /*======================================================================== */
  /* ************************************************* 3. Product Funnel Analysis*/
  /* Using a single SQL query - create a new output table which has the following details:
   How many times was each product viewed?
   How many times was each product added to cart?
   How many times was each product added to a cart but not purchased (abandoned)?
   How many times was each product purchased?
   Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.*/
  /*++++Create [clique_bait].[dbo].[product_counts] table ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
;

with vis_not_purch as(
  select
    distinct e.visit_id
  from
    [clique_bait].[dbo].[events] e
  where
    e.[event_type] != 3
    and not EXISTS (
      select
        distinct visit_id
      from
        [clique_bait].[dbo].[events] e1
      where
        e1.[event_type] = 3
        and e1.visit_id = e.visit_id
    )
)
select
  page_name,
  [Page_View],
  [Add_to_Cart],
  [Add_to_Cart_not_Purchased],
  [Purchased] into [clique_bait].[dbo].product_counts
from
  (
    select
      *
    from
      (
        SELECT
          'Page_View' event_name,
          ph.page_name,
          count(*) cnt
        FROM
          [clique_bait].[dbo].[events] e
          join [clique_bait].[dbo].[page_hierarchy] ph on e.page_id = ph.page_id
          and ph.product_category is not null
        where
          e.[event_type] = 1
        group by
          ph.page_name
        union
        SELECT
          'Add_to_Cart' event_name,
          ph.page_name,
          count(*) cnt_add_cart
        FROM
          [clique_bait].[dbo].[events] e
          join [clique_bait].[dbo].[page_hierarchy] ph on e.page_id = ph.page_id
          and ph.product_category is not null
        where
          e.[event_type] = 2
        group by
          ph.page_name
        union
        SELECT
          'Add_to_Cart_not_Purchased' event_name,
          ph.page_name,
          count(*) cnt_not_purch
        FROM
          [clique_bait].[dbo].[events] e
          join vis_not_purch on vis_not_purch.visit_id = e.visit_id
          join [clique_bait].[dbo].[page_hierarchy] ph on e.page_id = ph.page_id
          and ph.product_category is not null
        where
          e.[event_type] = 2
        group by
          ph.page_name
        union
        SELECT
          'Purchased' event_name,
          ph.page_name,
          count(*) cnt_product
        FROM
          [clique_bait].[dbo].[events] e
          join [clique_bait].[dbo].[events] e_purch on e.visit_id = e_purch.visit_id
          and e_purch.[event_type] = 3
          join [clique_bait].[dbo].[page_hierarchy] ph on e.page_id = ph.page_id
          and ph.product_category is not null
        where
          e.[event_type] = 2
        group by
          ph.page_name
      ) as tb1 PIVOT(
        sum(cnt) FOR event_name IN (
          [Page_View],
          [Add_to_Cart],
          [Add_to_Cart_not_Purchased],
          [Purchased]
        )
      ) AS pivot_table
  ) as tb2
  /*+++++++Create [clique_bait].[dbo].[product_category_counts] table +++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
;

with vis_not_purch as(
  select
    distinct e.visit_id
  from
    [clique_bait].[dbo].[events] e
  where
    e.[event_type] != 3
    and not EXISTS (
      select
        distinct visit_id
      from
        [clique_bait].[dbo].[events] e1
      where
        e1.[event_type] = 3
        and e1.visit_id = e.visit_id
    )
)
select
  product_category,
  [Page_View],
  [Add_to_Cart],
  [Add_to_Cart_not_Purchased],
  [Purchased] into [clique_bait].[dbo].[product_category_counts]
from
  (
    select
      *
    from
      (
        SELECT
          'Page_View' event_name,
          ph.[product_category],
          count(*) cnt
        FROM
          [clique_bait].[dbo].[events] e
          join [clique_bait].[dbo].[page_hierarchy] ph on e.page_id = ph.page_id
          and ph.product_category is not null
        where
          e.[event_type] = 1
        group by
          ph.[product_category]
        union
        SELECT
          'Add_to_Cart' event_name,
          ph.[product_category],
          count(*) cnt_add_cart
        FROM
          [clique_bait].[dbo].[events] e
          join [clique_bait].[dbo].[page_hierarchy] ph on e.page_id = ph.page_id
          and ph.product_category is not null
        where
          e.[event_type] = 2
        group by
          ph.[product_category]
        union
        SELECT
          'Add_to_Cart_not_Purchased' event_name,
          ph.[product_category],
          count(*) cnt_not_purch
        FROM
          [clique_bait].[dbo].[events] e
          join vis_not_purch on vis_not_purch.visit_id = e.visit_id
          join [clique_bait].[dbo].[page_hierarchy] ph on e.page_id = ph.page_id
          and ph.product_category is not null
        where
          e.[event_type] = 2
        group by
          ph.[product_category]
        union
        SELECT
          'Purchased' event_name,
          ph.[product_category],
          count(*) cnt_product
        FROM
          [clique_bait].[dbo].[events] e
          join [clique_bait].[dbo].[events] e_purch on e.visit_id = e_purch.visit_id
          and e_purch.[event_type] = 3
          join [clique_bait].[dbo].[page_hierarchy] ph on e.page_id = ph.page_id
          and ph.product_category is not null
        where
          e.[event_type] = 2
        group by
          ph.[product_category]
      ) as tb1 PIVOT(
        sum(cnt) FOR event_name IN (
          [Page_View],
          [Add_to_Cart],
          [Add_to_Cart_not_Purchased],
          [Purchased]
        )
      ) AS pivot_table
  ) as tb2
  /*======================================================================== */
  -- 1 - Which product had the most views, cart adds and purchases?
SELECT
  top 1 [page_name],
  [Page_View],
  [Add_to_Cart],
  [Purchased]
FROM
  [clique_bait].[dbo].[product_counts]
order by
  [Page_View] desc,
  [Add_to_Cart] desc,
  [Purchased] desc
  /*======================================================================== */
  -- 2 - Which product was most likely to be abandoned?
SELECT
  top 1 [page_name],
  [Page_View],
  [Add_to_Cart],
  [Purchased]
FROM
  [clique_bait].[dbo].[product_counts]
order by
  [Purchased]
  /*======================================================================== */
  -- 3 - Which product had the highest view to purchase percentage?
SELECT
  top 1 [page_name],
  [Page_View],
  [Add_to_Cart],
  [Add_to_Cart_not_Purchased],
  [Purchased],
  (
    cast ([Purchased] as decimal(38, 2)) / sum(cast([Purchased] as decimal(38, 2))) over()
  ) * 100 tot_purch
FROM
  [clique_bait].[dbo].[product_counts]
order by
  (
    cast ([Purchased] as decimal(38, 2)) / sum(cast([Purchased] as decimal(38, 2))) over()
  ) * 100 desc
  /*======================================================================== */
  -- 4 - What is the average conversion rate from view to cart add?
SELECT
  top 1 avg(
    cast([Add_to_Cart] as decimal(38, 2)) / cast([Page_View] as decimal(38, 2)) * 100
  ) over() prc_viw_cart
FROM
  [clique_bait].[dbo].[product_counts]
  /*======================================================================== */
  -- 5 - What is the average conversion rate from cart add to purchase?
SELECT
  top 1 avg(
    cast([Purchased] as decimal(38, 2)) / cast([Add_to_Cart] as decimal(38, 2)) * 100
  ) over() prc_viw_cart
FROM
  [clique_bait].[dbo].[product_counts]
  /* ************************************************* 3. Campaigns Analysis*/
  /* Generate a table that has 1 single row for every unique visit_id record and has the following columns:
   user_id
   visit_id
   visit_start_time: the earliest event_time for each visit
   page_views: count of page views for each visit
   cart_adds: count of product cart add events for each visit
   purchase: 1/0 flag if a purchase event exists for each visit
   campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
   impression: count of ad impressions for each visit
   click: count of ad clicks for each visit
   (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)
   Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.
   Some ideas you might want to investigate further include:
   Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
   Does clicking on an impression lead to higher purchase rates?
   What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
   What metrics can you use to quantify the success or failure of each campaign compared to eachother?
   */
;

with visivt_calc as (
  SELECT
    e.[visit_id],
    u.[user_id],
    min(e.[event_time]) over(partition by e.[visit_id]) as [visit_start_time],
    count(
      case
        when ei.event_name = 'Page View' then ei.event_name
        else NULL
      end
    ) over(partition by e.[visit_id]) as [page_views],
    count(
      case
        when ei.event_name = 'Add to Cart' then ei.event_name
        else NULL
      end
    ) over(partition by e.[visit_id]) as [cart_adds],
case
      when e_purch.visit_id is not null then 1
      else 0
    end [purchase],
    count(
      case
        when ei.event_name = 'Ad Impression' then ei.event_name
        else NULL
      end
    ) over(partition by e.[visit_id]) as [impression],
    max(e.[sequence_number]) over(partition by e.[visit_id]) as [click],
(
      SELECT
        LEFT(p_name, LEN(p_name) - 1)
      FROM
        (
          SELECT
            ph1.page_name + ', '
          FROM
            [clique_bait].[dbo].[events] e1
            join [clique_bait].[dbo].[page_hierarchy] ph1 on ph1.page_id = e1.page_id
            and ph1.product_id is not null
            and e1.event_type = 2
          where
            e1.[visit_id] = e.[visit_id]
          order by
            e1.[visit_id],
            e1.sequence_number FOR XML PATH ('')
        ) c (p_name)
    ) as [cart_products]
  FROM
    [clique_bait].[dbo].[events] e
    join [clique_bait].[dbo].[users] u on e.cookie_id = u.cookie_id
    join [clique_bait].[dbo].event_identifier ei on ei.event_type = e.event_type
    left join [clique_bait].[dbo].[events] e_purch on e.visit_id = e_purch.visit_id
    and e_purch.event_type = 3
    left join [clique_bait].[dbo].[page_hierarchy] ph on ph.page_id = e.page_id
    and ph.product_id is not null
    and e.event_type = 2
)
select
  ROW_NUMBER() over(
    order by
      [visit_id]
  ) id,
  [visit_id],
  [user_id],
  [visit_start_time],
  [page_views],
  [cart_adds],
  [purchase],
  [campaign_name],
  [impression],
  [click],
  [cart_products] into [clique_bait].[dbo].[campaigns_analysis]
from
  visivt_calc v
  left join [clique_bait].[dbo].[campaign_identifier] c on v.visit_start_time >= c.start_date
  and v.visit_start_time <= c.end_date
group by
  [visit_id],
  [user_id],
  [visit_start_time],
  [page_views],
  [cart_adds],
  [purchase],
  [impression],
  [click],
  c.campaign_name,
  [cart_products]
order by
  [visit_id]
