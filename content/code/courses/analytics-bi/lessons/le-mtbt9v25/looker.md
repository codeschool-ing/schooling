---
title: Looker
version: 1
---

**Looker** is Google Cloud's enterprise BI platform, and it is the tool most built around lesson 3's
idea: nothing is explored that a modeller has not first described.

The description is written in **LookML**, a language of text files kept in git. A **view** describes
one table: its dimensions and its measures. An **explore** says which views may be joined to which,
and how. A **model** groups explores and names the database connection. People who are not
modellers never write SQL: they pick dimensions and measures from an explore, and Looker writes the
query from the LookML.

Lantern's orders, described as a LookML view, might read like this. **It was not run**: it is written
from Looker's documentation to show the shape, and a real project would be checked by Looker's own
validator.

```
view: orders {
  sql_table_name: semantic.orders ;;

  dimension: order_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.order_id ;;
  }

  dimension_group: order {
    type: time
    datatype: date
    timeframes: [date, month, quarter, year]
    sql: ${TABLE}.order_date ;;
  }

  measure: net_revenue {
    type: sum
    sql: ${TABLE}.net_revenue ;;
    value_format_name: decimal_2
    description: "Gross minus discount for paid orders. Refunded orders count zero."
  }
}
```

Two things in it are lessons of this course written as syntax. The `primary_key` tells Looker the
view's grain, which it uses to detect lesson 3's fan-out and compute sums correctly when a join would
otherwise repeat rows. And the measure's `type: sum` is chosen once, by the modeller, so nobody
exploring it picks an average by accident — the implicit-measure problem of lesson 4, closed by the
language.

## Not to be confused with Looker Studio

Google also has **Looker Studio**, formerly Google Data Studio: a free, browser-based dashboard tool
with no LookML and no central model, closer in spirit to a spreadsheet chart. The shared name sends
many people to the wrong one. If a job advertisement asks for LookML, it means Looker.
