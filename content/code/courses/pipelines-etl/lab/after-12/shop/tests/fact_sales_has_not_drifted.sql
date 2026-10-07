-- Days on which the incremental fact table and a rebuild from staging disagree:
-- lesson 11's drift.sql, made into a test. Every row it returns is a failure.
select order_date, t.lines as in_table, s.lines as in_source
  from (select order_date, count(*) as lines from {{ ref('fact_sales') }} group by 1) as t
  full join (select order_date, count(*) as lines from {{ ref('int_sales') }} group by 1) as s
       using (order_date)
 where t.lines is distinct from s.lines
