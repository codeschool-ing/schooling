---
title: The shard key, which you choose once
version: 1
---

Every sharded table has a **shard key**: the column whose value decides which server a row lives
on. Every other decision in this lesson can be revised later at some cost. This one is close to
permanent, because changing it means moving almost every row to a different server, while the
application keeps running.

The tempting way to pick it is to look at the data and ask which column splits it evenly. That is
half the question. The other half is **which column the queries ask by**, and when the two halves
disagree, the queries win.

## What a good key does

A query that names one value of the shard key goes to **one** server. A query that does not name it
goes to **all** of them, waits for the slowest and merges the answers. So the key should be the
column most of the traffic already filters by, and it should split both the rows and the work
evenly, with no single value large enough to fill a server by itself.

In `market` there are two candidates. A seller's screens read by `seller_id`. A customer's screens
read by `customer_id`. Both are plausible, both are foreign keys every order carries, and they
behave very differently.

## Seller 1 is a quarter of everything

Ask how the orders are spread over sellers, and then what four shards split by seller would hold.
The `% 4` stands in for whatever the real routing function is; a hash would scatter the other
sellers differently, and no function can split one seller across two shards:

```
market=# SELECT seller_id, count(*), round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct FROM orders GROUP BY seller_id ORDER BY count(*) DESC LIMIT 3;
 seller_id | count  | pct  
-----------+--------+------
         1 | 500114 | 25.0
       178 |   1648 |  0.1
       480 |   1630 |  0.1
(3 rows)

Time: 100.275 ms

market=# SELECT seller_id % 4 AS shard, count(*), round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct FROM orders GROUP BY 1 ORDER BY 1;
 shard | count  | pct  
-------+--------+------
     0 | 374915 | 18.7
     1 | 873427 | 43.7
     2 | 375683 | 18.8
     3 | 375975 | 18.8
(4 rows)

Time: 150.905 ms
```

**Seller 1 has 500114 orders, exactly 25.0% of the table**, and the next largest seller has 1648.
That is the marketplace's own store, and every marketplace has one: the big brand, the house label,
the account that is a third of the revenue. Split by seller, the shard holding seller 1 gets
**43.7%** of all orders, the 25% that is seller 1 plus its quarter of everybody else, against 18.7%
on each of the others. That shard is the **hot shard**: it receives more than twice the writes of
any other, its disk fills first, and it is the one that wakes somebody at night. Adding shards does
not help, because seller 1 stays on one of them however many there are. With a hundred shards, one
of them still holds a quarter of the orders.

Now the same split by customer:

```
market=# SELECT customer_id % 4 AS shard, count(*), round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct FROM orders GROUP BY 1 ORDER BY 1;
 shard | count  | pct  
-------+--------+------
     0 | 500615 | 25.0
     1 | 498862 | 24.9
     2 | 500759 | 25.0
     3 | 499764 | 25.0
(4 rows)

Time: 193.114 ms

market=# SELECT max(n) AS busiest_customer FROM (SELECT count(*) AS n FROM orders GROUP BY customer_id) AS per_customer;
 busiest_customer 
------------------
               27
(1 row)

Time: 219.365 ms
```

**25.0, 24.9, 25.0 and 25.0 percent.** Two hundred thousand customers, and the busiest has 27
orders. No customer is big enough to unbalance anything, and none will be: a person can only buy so
much.

## Which queries stay on one shard

Even distribution is necessary, not sufficient. Lesson 2's workload says what the application asks,
and how often:

| script | share | filters by | split by customer | split by seller |
|---|---|---|---|---|
| `customer-orders.sql` | 50% | `customer_id` | one shard | every shard |
| `order-page.sql` | 25% | `order_id` | see below | see below |
| `place-order.sql` | 10% | writes one order | one shard | one shard |
| `seller-dashboard.sql` | 4% | `seller_id` | every shard | one shard |
| `pending-count.sql` | 1% | nothing | every shard | every shard |

Split by customer, half the traffic plus every write stays on one shard. Split by seller, the
dashboard does, at 4%, and the customer's order list fans out to every server on every page view.
**`customer_id` is the key**, by the data and by the queries both. The seller's dashboard becomes
the query that pays: section 04 measures what it costs.

The order page is the instructive row. It reads `order_lines` by `order_id`, and `order_id` is not
the shard key. To keep it on one shard, `order_lines` has to live on the same shard as its order,
which means `order_lines` is sharded by **the order's customer** too: the column has to be in the
table, or the router has to look the order up first. This is called **co-location**: tables that
are joined together are sharded by the same key, so that the join happens inside one server.
`products` and `sellers` are the opposite case, small and read by everybody, and the usual answer
is to copy them whole to every shard, a **reference table**, accepting that a change to a product
is now a write to every server.

## Three ways to route

Something has to turn a key into a server. **Hash** routing, used in section 04, computes a hash of
the key and takes it modulo the number of shards: even, and blind to what the values mean. **Range**
routing gives each shard a band of keys, customers 1 to 100000 here and the rest there, which keeps
neighbours together and lets one band grow hot when new customers all get high ids. A **directory**
is a table that says, per key, which shard holds it. It is the most flexible, since a single
customer can be moved by updating one row, and it costs one more lookup on every request, from a
table that is now the most important thing in the system.

None of them rescues a bad key. If the key is `seller_id`, the hot shard exists under all three,
because the problem is one value and not the function.
