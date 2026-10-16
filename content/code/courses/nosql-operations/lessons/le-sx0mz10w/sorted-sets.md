---
title: Sorted sets, a ranking the server keeps
version: 1
---

The shop wants a best-seller box: the three products sold most this month. The relational answer is
a `GROUP BY` over the month's order lines, run on every page view or cached and run again later.
**A sorted set keeps the ranking up to date on every sale instead**: each member is a set member with
a number beside it, the score, and Redis keeps the members ordered by score at all times.

## A leaderboard, one sale at a time

Each sale adds the quantity sold to the product's score with `ZINCRBY`. The month is in the key, so
October's ranking is a key of its own and November starts from nothing:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> ZINCRBY bestsellers:2026-10 2 KB-101
"2"
127.0.0.1:6379> ZINCRBY bestsellers:2026-10 5 CB-012
"5"
127.0.0.1:6379> ZINCRBY bestsellers:2026-10 1 MN-330
"1"
127.0.0.1:6379> ZINCRBY bestsellers:2026-10 3 MS-204
"3"
127.0.0.1:6379> ZINCRBY bestsellers:2026-10 3 KB-101
"5"
```

`ZINCRBY` creates the member the first time and adds to it afterwards: the keyboard sold 2 and then
3, and its score is 5. There is no table to scan and no query to run; the ranking already exists when
the page asks for it:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> ZREVRANGE bestsellers:2026-10 0 2 WITHSCORES
1) "KB-101"
2) "5"
3) "CB-012"
4) "5"
5) "MS-204"
6) "3"
127.0.0.1:6379> ZREVRANK bestsellers:2026-10 MS-204
(integer) 2
127.0.0.1:6379> ZRANGE bestsellers:2026-10 3 +inf BYSCORE WITHSCORES
1) "MS-204"
2) "3"
3) "CB-012"
4) "5"
5) "KB-101"
6) "5"
```

`ZREVRANGE … 0 2 WITHSCORES` read the top three, highest score first. Three details in that answer
are worth knowing before a page depends on them:

- **A tie is broken by the member's name**, byte by byte. `KB-101` and `CB-012` both scored 5, and in
  reverse order `K` comes before `C`. If the shop wants ties broken by something else, such as the
  product that reached the score first, that has to be folded into the score.
- **Ranks count from zero.** `ZREVRANK` answered `2` for the mouse, which the page shows as third.
- **A range can be by score as well as by position.** `ZRANGE … 3 +inf BYSCORE` returned every
  product that sold at least three, lowest first.

The scores came back in quotes because a score is a floating-point number, stored as a 64-bit double.
Whole numbers are exact up to 2⁵³, about nine thousand trillion, so counting units sold is safe.

## The same shape, other questions

A sorted set is a ranking by any number the shop can attach to a member, and a few of the common ones
look nothing like a leaderboard:

| question | member | score |
| --- | --- | --- |
| best sellers this month | product code | units sold, added with `ZINCRBY` |
| "recently viewed", without the duplicates the list needed `LREM` for | product code | the time of the view; a second view just moves the score |
| orders to cancel if unpaid after 30 minutes | order number | the deadline as a Unix time; `ZRANGE … BYSCORE` with `-inf` and now finds those due |
| requests per customer in the last minute | a request id | the time of the request; `ZREMRANGEBYSCORE` drops the old ones |

The cost is the same in every case. A sorted set keeps two structures for each member, one to find
it by name and one to keep the order. So it uses more memory per member than a set or a list, and
adding a member costs O(log N) instead of O(1). For a ranking that is read on every page, that is
almost always the cheaper side of the trade.
