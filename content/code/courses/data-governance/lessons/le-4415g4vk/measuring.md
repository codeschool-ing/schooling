---
title: Measuring, before deciding
version: 1
---

Every dimension of the last section becomes a question with a number for an answer. Six of them, over
Ipê's data, in one query:

```sql
-- Six questions about the data, each answered with a count.
SET ROLE ipe_owner;
SELECT 'e-mail with no valid shape' AS question, count(*) AS answer
  FROM sales.customers
  WHERE email !~* '^[^@ ]+@[^@ ]+\.[a-z]{2,}$' AND email NOT LIKE 'erased-%@invalid'
UNION ALL
SELECT 'e-mail held by two customers', count(*)
  FROM (SELECT lower(email) FROM sales.customers GROUP BY 1 HAVING count(*) > 1) d
UNION ALL
SELECT 'order dated after today', count(*)
  FROM sales.orders WHERE ordered_at > timestamptz '2026-07-01'
UNION ALL
SELECT 'order with no customer', count(*)
  FROM sales.orders WHERE customer_id IS NULL
UNION ALL
SELECT 'consent before sign-up', count(*)
  FROM sales.customers WHERE consent_at < created_at
UNION ALL
SELECT 'payment different from its order', count(*)
  FROM sales.orders o JOIN sales.payments p USING (order_id)
  WHERE p.amount_cents <> o.total_cents;
```

```
ana@lab:~/gov$ psql -f measure.sql
SET
             question             | answer 
----------------------------------+--------
 order with no customer           |     14
 order dated after today          |      3
 consent before sign-up           |   1324
 e-mail with no valid shape       |     23
 e-mail held by two customers     |     12
 payment different from its order |      0
(6 rows)
```

Five defects and one rule that holds. Before anybody fixes anything, it is worth looking at a few of
the rows each count is made of — a number tells you how much, and only the rows tell you what:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT email FROM sales.customers WHERE email !~* '^[^@ ]+@[^@ ]+\.[a-z]{2,}\$' AND email NOT LIKE 'erased-%@invalid' ORDER BY customer_id LIMIT 4" -c "SELECT ordered_at FROM sales.orders WHERE ordered_at > timestamptz '2026-07-01' ORDER BY 1" -c "SELECT min(ordered_at)::date AS first, max(ordered_at)::date AS last FROM sales.orders WHERE customer_id IS NULL" -c "SELECT count(*) AS ends_in_dot_con FROM sales.customers WHERE email LIKE '%.con'"
SET
            email             
------------------------------
 samuel.cardosoexample.net
 isabela.carvalho2example.net
 eduardo.araujoexample.net
 luana.pintoexample.com
(4 rows)

       ordered_at       
------------------------
 2027-02-10 10:00:00-03
 2027-03-11 10:00:00-03
 2027-04-12 10:00:00-03
(3 rows)

   first    |    last    
------------+------------
 2019-05-16 | 2019-12-26
(1 row)

 ends_in_dot_con 
-----------------
               7
(1 row)
```

- **23 malformed e-mails**, and every one of them has lost its `@`. These customers signed up and have
  never received an e-mail from Ipê; the site accepted the address without checking its shape. The
  last query finds **7 more** that the shape check passes: addresses ending in `.con`. They have a
  perfectly valid shape and point at a domain that does not exist. Validity is not accuracy, and a
  rule about shape will never see them.
- **12 duplicate e-mails.** Lesson 5 met these when a unique index on the keyed hash of the CPF failed.
  The same twelve people signed up twice, the second time with the address in capitals.
- **3 orders in the future**, all at exactly 10:00 on dates in 2027. Round times and a regular pattern
  are what a test record or a broken import looks like, not what customers do.
- **14 orders with no customer**, every one of them between May and December 2019. That matches what
  Ipê's old site allowed: guest checkout, ended in 2020. **This is not a defect**, and the rule in
  section 7 says so.
- **1,324 consents before sign-up.** The next section is about this one.
- **0 payments that differ from their order.** A rule that holds is worth keeping: it is the one that
  will notice the day it stops holding.

## Measuring is not judging

The count of guest orders shows why a number on its own decides nothing. Fourteen nulls in
`customer_id` look like a completeness defect, and they are a record of how the business worked in
2019. The person who can say so is the **owner** of the table, not the person who wrote the query.
Measurement produces questions; the owner answers them; and only then does anybody change data.
