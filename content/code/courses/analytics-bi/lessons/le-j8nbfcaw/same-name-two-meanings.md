---
title: The same column name, meaning two things
version: 1
---

Two tables in Lantern have a column called `channel`, with the same four values:

```
lantern=# SELECT channel, count(*) AS customers FROM customers GROUP BY 1 ORDER BY 1;
 channel  | customers 
----------+-----------
 email    |       361
 referral |       493
 search   |       951
 social   |       845
(4 rows)

lantern=# SELECT channel, count(*) AS sessions FROM web_sessions GROUP BY 1 ORDER BY 1;
 channel  | sessions 
----------+----------
 email    |     9278
 referral |    10183
 search   |    18887
 social   |    21652
(4 rows)
```

They are not the same dimension. In `customers`, `channel` is how the customer **first arrived**,
recorded once at signup and never changed: the 845 customers whose value is `social` came to the
shop through social media the first time. In `web_sessions`, `channel` is where **this one visit**
came from, and the same person can arrive from search on Monday and from an e-mail on Friday.

A dashboard that puts "orders by channel" next to "visits by channel" invites the reader to divide
one by the other and compute a conversion rate per channel. The result is meaningless: the
numerator is grouped by where customers first came from and the denominator by where visits came
from, and nothing joins the two. **A dimension is defined by what it describes and when it was
recorded, not by its column name.** Marketing calls the first one *acquisition channel* and the
second *session source*, and that is exactly the distinction a shared definition has to make
before anybody builds a chart on it.

The general rule has a name in data modelling: a **conformed dimension** is one that means the same
thing in every table that carries it, so that two measures grouped by it can be put side by side.
`state` would be conformed if two tables carried it with the same meaning. `channel`, here, is
not, and the fix is the name: two columns, two names.
