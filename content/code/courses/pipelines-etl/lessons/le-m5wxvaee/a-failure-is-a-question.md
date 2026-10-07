---
title: A failure is a question, with two answers
version: 1
---

A failed test says that the data and the rule disagree. It does not say which one is wrong, and
**deciding that is the work**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l12-two-answers\" aria-label=\"A failed test leads to one question: is the rule wrong or the data? If the rule is wrong, correct the test so that it says what is actually true, and keep it. If the data is wrong, keep the test as it is and fix the data where it comes from. Deleting the test is drawn crossed out, as the move that is never right.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270.0\" y=\"16.0\" width=\"180.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">a test fails</text><rect x=\"270.0\" y=\"86.0\" width=\"180.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the rule or the data?</text><path d=\"M360.0 56.0 L360.0 84.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"150.0\" width=\"230.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"155.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the rule is wrong</text><rect x=\"450.0\" y=\"150.0\" width=\"230.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the data is wrong</text><path d=\"M300.0 126.0 L200.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M420.0 126.0 L520.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"155.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">narrow the test until it is true</text><text x=\"565.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fix it upstream; the test stays</text><path d=\"M155.0 190.0 L155.0 202.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M565.0 190.0 L565.0 202.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">delete the test</text><path d=\"M300.0 244.0 L420.0 244.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path></svg>", "caption": "Both answers keep a test. The only wrong move is the one that keeps none."}
```

Ana takes the 5,809 orders with no customer first, and counts them by shop:

```
ana@vm:~/etl$ psql -d wh -c "SELECT s.name, s.channel, count(*) FILTER (WHERE o.customer_id IS NULL) AS no_customer, count(*) AS orders FROM dbt_staging.stg_orders o JOIN raw.shops s USING (shop_id) GROUP BY 1, 2 ORDER BY 2, 1"
   name    | channel | no_customer | orders 
-----------+---------+-------------+--------
 Online    | online  |           7 |   6757
 Batel     | store   |         652 |   1440
 Cambuí    | store   |         752 |   1704
 Moinhos   | store   |         596 |   1320
 Paulista  | store   |        1618 |   3593
 Pinheiros | store   |        1273 |   2801
 Savassi   | store   |         911 |   2085
(7 rows)
```

The six bookshops have thousands each, and the website seven. Of course they do: **a till sells to
whoever walks in**, and most people buy a book without giving their name. The shop has never
promised a customer on every order; Ana believed it because the website does. The rule was wrong,
not the data.

The order lines are the same kind of mistake from the other side. `order_id` is not unique in
`stg_order_lines` because an order has several lines: lesson 6 established the grain as *one row
per order line*, and the key of that grain is the order **and** the line number. The test checked
the wrong key.

Neither of those tests should be deleted, though. Each held a real belief that was stated too
broadly, and the narrower version is still worth checking every night. A test that is simply
removed when it fails stops protecting anything; **a test that is corrected says, in the project,
what the data is actually like** — which is what the next reader of the model needs to know.

And when the answer is the other one — the rule is right and the data broke it — the test stays as
it is, and the fix goes upstream, where the bad rows come from. Silencing a true test so that the
build goes green is the one move that is never right.
