/* --------------------
 case-study-4 questions
 --------------------*/
/* ************************************************* A. Customer Nodes Exploration*/
/*========================================================================*/
-- 1 - How many unique nodes are there on the Data Bank system?
SELECT
  count(distinct c.node_id) cnt_node
FROM
  [data_bank].[dbo].[customer_nodes] c
  /*========================================================================*/
  -- 2 - What is the number of nodes per region?
SELECT
  r.region_name,
  count(distinct c.node_id) cnt_node
FROM
  [data_bank].[dbo].[customer_nodes] c
  join [data_bank].[dbo].[regions] r on c.region_id = r.region_id
group by
  r.region_name
  /*========================================================================*/
  -- 3 - How many customers are allocated to each region?
SELECT
  r.region_name,
  count(distinct c.customer_id) cnt_node
FROM
  [data_bank].[dbo].[customer_nodes] c
  join [data_bank].[dbo].[regions] r on c.region_id = r.region_id
group by
  r.region_name
  /*========================================================================*/
  -- 4 - How many days on average are customers reallocated to a different node?
SELECT
  avg (
    case
      when DATEPART(year, [end_date]) != 9999 then DATEDIFF(day, [start_date], [end_date])
      else NULL
    end
  ) avg_dat_diff
FROM
  [data_bank].[dbo].[customer_nodes] c
  /*======================================================================== ++++++++++++++++++++++++ */
  -- 5 - What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
  /* ************************************************* B. Customer Transactions*/
  /*========================================================================*/
  -- 1 - What is the unique count and total amount for each transaction type?
SELECT
  [txn_type],
  count([txn_type]) [cnt_txn_type],
  sum([txn_amount]) [sum_txn_amount]
FROM
  [data_bank].[dbo].[customer_transactions]
group by
  [txn_type]
  /*========================================================================*/
  -- 2 - What is the average total historical deposit counts and amounts for all customers?
;

with sum_cnt as (
  SELECT
    customer_id,
    count([txn_type]) [cnt_txn_type],
    sum([txn_amount]) [sum_txn_amount]
  FROM
    [data_bank].[dbo].[customer_transactions]
  where
    [txn_type] = 'deposit'
  group by
    customer_id
)
select
  avg(cnt_txn_type) avg_cnt,
  avg(sum_txn_amount) avg_sum
from
  sum_cnt
  /*========================================================================*/
  -- 3 - For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
;

with cnt_txt_typ as(
  SELECT
    [customer_id],
    DATEPART(MONTH, [txn_date]) mnt,
    sum(
      case
        when [txn_type] = 'deposit' then 1
        else 0
      end
    ) cnt_deposit,
    sum(
      case
        when [txn_type] = 'purchase' then 1
        else 0
      end
    ) cnt_purchase,
    sum(
      case
        when [txn_type] = 'withdrawal' then 1
        else 0
      end
    ) cnt_withdrawal
  FROM
    [data_bank].[dbo].[customer_transactions]
  group by
    [customer_id],
    DATEPART(MONTH, [txn_date])
  having
    sum(
      case
        when [txn_type] = 'deposit' then 1
        else 0
      end
    ) > 0
    OR sum(
      case
        when [txn_type] = 'purchase' then 1
        else 0
      end
    ) > 0
    OR sum(
      case
        when [txn_type] = 'withdrawal' then 1
        else 0
      end
    ) > 0
)
select
  count(distinct [customer_id]) cnt_cust
from
  cnt_txt_typ
  /*======================================================================== ++++++++++++++++++++++++ */
  -- 4 - What is the closing balance for each customer at the end of the month?
  /*========================================================================*/
  -- 5 - What is the percentage of customers who increase their closing balance by more than 5%? ++++++++++++++++++++++++ */
  /* ************************************************* C. Data Allocation Challenge*/
  /* To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:
   Option 1: data is allocated based off the amount of money at the end of the previous month
   Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
   Option 3: data is updated real-time
   For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
   running customer balance column that includes the impact each transaction
   customer balance at the end of each month
   minimum, average and maximum values of the running balance for each customer
   Using all of the data available - how much data would have been required for each option on a monthly basis?  */
  /* ************************************************* D. Extra Challenge*/
  /*Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.
   If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?
   Special notes:
   Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!*/
  /* ************************************************* Extension Request*/
  /*The Data Bank team wants you to use the outputs generated from the above sections to create a quick Powerpoint presentation which will be used as marketing materials for both external investors who might want to buy Data Bank shares and new prospective customers who might want to bank with Data Bank.
   Using the outputs generated from the customer node questions, generate a few headline insights which Data Bank might use to market it’s world-leading security features to potential investors and customers.
   With the transaction analysis - prepare a 1 page presentation slide which contains all the relevant information about the various options for the data provisioning so the Data Bank management team can make an informed decision.*/
