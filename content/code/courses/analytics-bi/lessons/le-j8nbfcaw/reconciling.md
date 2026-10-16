---
title: Reconciling two numbers that disagree
version: 1
---

Even with written definitions, two numbers will disagree, because somebody will use the other
one. Marketing's quarterly report says R$ 329,036.20 and finance's says R$ 294,209.60, and the
question in the meeting is whether one of them is wrong. **The answer is a bridge**: a list of steps
that walks from one number to the other, each step one difference in definition, each with its
own amount. If the steps add up, both numbers are right and the meeting is over; if they do not,
the step that is missing is the bug.

The bridge from gross to net, for the first quarter of 2026:

```sql
SELECT 1 AS step, 'gross, every order placed' AS line, round(sum(gross_cents) / 100.0, 2) AS brl
FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
UNION ALL
SELECT 2, 'minus discounts', round(-sum(discount_cents) / 100.0, 2)
FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
UNION ALL
SELECT 3, 'minus refunded orders', round(-sum(net_cents) FILTER (WHERE status = 'refunded') / 100.0, 2)
FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
UNION ALL
SELECT 4, 'minus the test account', round(-coalesce(sum(net_cents) FILTER (WHERE customer_id = 1 AND status = 'paid'), 0) / 100.0, 2)
FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
UNION ALL
SELECT 5, 'net revenue', round(sum(net_cents) FILTER (WHERE status = 'paid' AND customer_id <> 1) / 100.0, 2)
FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
ORDER BY step;
```

```
lantern=# SELECT 1 AS step, 'gross, every order placed' AS line, round(sum(gross_cents) / 100.0, 2) AS brl
lantern-# FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
lantern-# UNION ALL
lantern-# SELECT 2, 'minus discounts', round(-sum(discount_cents) / 100.0, 2)
lantern-# FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
lantern-# UNION ALL
lantern-# SELECT 3, 'minus refunded orders', round(-sum(net_cents) FILTER (WHERE status = 'refunded') / 100.0, 2)
lantern-# FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
lantern-# UNION ALL
lantern-# SELECT 4, 'minus the test account', round(-coalesce(sum(net_cents) FILTER (WHERE customer_id = 1 AND status = 'paid'), 0) / 100.0, 2)
lantern-# FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
lantern-# UNION ALL
lantern-# SELECT 5, 'net revenue', round(sum(net_cents) FILTER (WHERE status = 'paid' AND customer_id <> 1) / 100.0, 2)
lantern-# FROM order_revenue WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01'
lantern-# ORDER BY step;
 step |           line            |    brl    
------+---------------------------+-----------
    1 | gross, every order placed | 329036.20
    2 | minus discounts           | -23768.58
    3 | minus refunded orders     | -11058.02
    4 | minus the test account    |      0.00
    5 | net revenue               | 294209.60
(5 rows)
```

Read it as arithmetic: R$ 329,036.20, minus R$ 23,768.58 of discounts, minus R$ 11,058.02 of
orders that were refunded, minus nothing for the test account, which placed no order this quarter,
is R$ 294,209.60. Every row is one cell of the anatomy table earlier in this lesson — a different
measure, a different filter — turned into money.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"bridge\" aria-label=\"A bridge from gross to net revenue for the first quarter of 2026, drawn as five columns. Gross revenue is a full column of 329,036.20 reais. Discounts hang from its top as a drop of 23,768.58. Refunds hang below that as a drop of 11,058.02. The test account is a drop of zero, drawn as a flat line. Net revenue is a full column of 294,209.60, whose top is level with the bottom of the last drop.\"><rect x=\"60\" y=\"65.58219999999997\" width=\"100\" height=\"184.41780000000003\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"53.58219999999997\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">R$ 329,036.20</text><text x=\"110.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">gross</text><rect x=\"190\" y=\"65.58219999999997\" width=\"100\" height=\"55.46002000000004\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"240.0\" y=\"135.04222000000001\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">−R$ 23,768.58</text><text x=\"240.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">discounts</text><rect x=\"320\" y=\"121.04222000000001\" width=\"100\" height=\"25.802046666666712\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"370.0\" y=\"160.84426666666673\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">−R$ 11,058.02</text><text x=\"370.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">refunds</text><line x1=\"450\" y1=\"146.84426666666673\" x2=\"550\" y2=\"146.84426666666673\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"500.0\" y=\"160.84426666666673\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">R$ 0.00</text><text x=\"500.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">test account</text><rect x=\"580\" y=\"146.84426666666673\" width=\"100\" height=\"103.15573333333327\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"134.84426666666673\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">R$ 294,209.60</text><text x=\"630.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">net</text><line x1=\"50\" y1=\"250\" x2=\"690\" y2=\"250\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"50\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-style=\"italic\">the scale starts at R$ 250,000, not at zero</text></svg>", "caption": "Each drop is one difference between the two definitions, and they close: the last drop ends exactly where net revenue begins."}
```

Three things make a bridge trustworthy:

- **It closes.** The last line is computed independently, not as the sum of the lines above it; if
  it were, the bridge would close by construction and could hide anything.
- **The order of the steps is stated.** Refunds here are taken at their net value, after the
  discount, because step 2 has already removed the discount. Take them at gross and the discount
  on refunded orders is removed twice.
- **A step of zero stays in.** "Minus the test account: 0.00" says the exclusion was checked this
  quarter. Leaving the row out says nothing, and next quarter, when the team tests a new checkout
  on the live shop, the row will matter.

The same technique reconciles any two numbers, not only revenue: active customers by two windows,
a dashboard against an export, this month's figure against what was reported last month before a
late load arrived. Find the definitions' differences, compute each one, and check that they close.
