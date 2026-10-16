---
title: A funnel counts how far people got
version: 1
---

A **funnel** is a path with steps in a fixed order, and a count of how many reached each one. Lantern's
path is the five events of lesson 8's tracking plan, and `web_sessions` records how many steps each
visit got through, so the funnel is one join: every session against every step it reached.

```
lantern=# SELECT step, event,
lantern-#        desktop, round(100.0 * desktop / lag(desktop) OVER (ORDER BY step), 1) AS desktop_pct,
lantern-#        mobile, round(100.0 * mobile / lag(mobile) OVER (ORDER BY step), 1) AS mobile_pct
lantern-# FROM (SELECT p.step, p.event,
lantern(#              count(*) FILTER (WHERE s.device = 'desktop') AS desktop,
lantern(#              count(*) FILTER (WHERE s.device = 'mobile') AS mobile
lantern(#       FROM tracking.plan p JOIN shop.web_sessions s ON s.steps >= p.step
lantern(#       GROUP BY p.step, p.event) f
lantern-# ORDER BY step;
 step |    event     | desktop | desktop_pct | mobile | mobile_pct 
------+--------------+---------+-------------+--------+------------
    1 | visit        |   23321 |             |  36679 |           
    2 | product_view |   13504 |        57.9 |  15382 |       41.9
    3 | add_to_cart  |    5361 |        39.7 |   4654 |       30.3
    4 | checkout     |    3431 |        64.0 |   2425 |       52.1
    5 | purchase     |    2689 |        78.4 |   1541 |       63.5
(5 rows)
```

Each step has two numbers worth reading. The count is how many sessions got that far; the percentage is
the share of the previous step that went on. On desktop, 57.9% of visits looked at a product, 39.7% of
those added something to the cart, 64.0% of those reached checkout and 78.4% of those paid. Mobile loses
more at every step, and the biggest gap is at the very first one: 41.9% of mobile visits look at a
product, against 57.9% on desktop.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"funnel\" aria-label=\"Two funnels side by side, desktop and mobile, five steps each: visit, product view, add to cart, checkout and purchase. Each bar is the share of visits that reached the step. Desktop: 100, 57.9, 23.0, 14.7 and 11.5 percent. Mobile: 100, 41.9, 12.7, 6.6 and 4.2 percent. Mobile is narrower at every step, and the largest single loss on both is between product view and add to cart.\"><text x=\"200\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">desktop</text><rect x=\"50.0\" y=\"44\" width=\"300.0\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"200\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">visit  ·  100.0%</text><rect x=\"113.14266112087816\" y=\"92\" width=\"173.71467775824368\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"200\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">product_view  ·  57.9%</text><rect x=\"165.5182024784529\" y=\"140\" width=\"68.96359504309422\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"200\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">add_to_cart  ·  23.0%</text><rect x=\"177.93190686505724\" y=\"188\" width=\"44.13618626988551\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"200\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">checkout  ·  14.7%</text><rect x=\"182.70442948415592\" y=\"236\" width=\"34.591141031688174\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"200\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">purchase  ·  11.5%</text><text x=\"540\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">mobile</text><rect x=\"390.0\" y=\"44\" width=\"300.0\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"540\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">visit  ·  100.0%</text><rect x=\"477.0947953870062\" y=\"92\" width=\"125.81040922598763\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"540\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">product_view  ·  41.9%</text><rect x=\"520.9673109953925\" y=\"140\" width=\"38.06537800921508\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"540\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">add_to_cart  ·  12.7%</text><rect x=\"530.082881212683\" y=\"188\" width=\"19.83423757463399\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"540\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">checkout  ·  6.6%</text><rect x=\"533.6980288448431\" y=\"236\" width=\"12.603942310313803\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"540\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">purchase  ·  4.2%</text></svg>", "caption": "Each bar is the share of all visits that got that far. Mobile starts with more visits and ends with fewer purchases."}
```

The step-to-step percentage is the one to act on, because it says **where** people leave. The overall
conversion — purchases over visits, 2,689 of 23,321 on desktop, 11.5% — is the product of all four, and
improving any one of them moves it. A team that only watches the overall number knows that something
changed and not where.

The largest loss in both funnels is between viewing a product and adding it to the cart: six in ten
desktop sessions and seven in ten mobile ones stop there. That is normal for a shop, where most visits
are browsing; the useful question is not why it is large but whether it moved.
