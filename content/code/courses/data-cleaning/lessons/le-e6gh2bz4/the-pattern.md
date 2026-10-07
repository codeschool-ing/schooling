---
title: The pattern of the blanks
version: 1
---

**Blanks are rarely scattered. They line up with something, and what they line up with is the
first clue to their mechanism.** The technique is the one lesson 2 used for formats: split the
missingness of each column by the columns that might explain it, and look for the cells that are
all or nothing.

For the orders, the candidates are the channel, how the order was fulfilled and by whom:

```schooling-example
{
  "language": "python",
  "file": "pattern.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "orders = pd.read_csv(\"raw/orders.csv\", dtype=str, keep_default_na=False,\n                     na_values=[\"\"]).drop_duplicates()\n",
      "note": "`drop_duplicates()` removes the 25 repeated orders, so no order counts twice in a share."
    },
    {
      "code": "orders[\"segment\"] = orders[\"fulfilment\"] + \" / \" + orders[\"courier\"].fillna(\"-\")\n",
      "note": "A segment is how the order was fulfilled and by whom. A pickup has no courier, so `-` stands in for it in the label; the column itself is left alone."
    },
    {
      "code": "share = (orders[[\"courier\", \"delivery_minutes\", \"discount\"]].isna()\n         .groupby([orders[\"channel\"], orders[\"segment\"]]).mean() * 100)\n",
      "note": "`isna()` turns each column into true and false, and the mean of true and false within a group is the share that is blank."
    },
    {
      "code": "print(share.round(1))\n",
      "note": "Shares as percentages, one row per channel and segment."
    }
  ]
}
```

```
ana@lab:~/clean$ python pattern.py
                            courier  delivery_minutes  discount
channel segment                                                
app     delivery / Rapidex      0.0             100.0       0.0
        delivery / propria      0.0               6.9       0.0
        pickup / -            100.0             100.0       0.0
site    delivery / Rapidex      0.0             100.0      88.8
        delivery / propria      0.0               6.8      87.9
        pickup / -            100.0             100.0      87.8
```

Read it as a map.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-pattern-map\" aria-label=\"A grid of the share of empty cells in three columns of the orders file, for six groups of orders. Courier is empty in every pickup and nowhere else. Delivery minutes is empty in every pickup and every Rapidex delivery, and in about seven per cent of the own fleet's. Discount is empty in almost nine of ten website orders and in no app order.\"><text x=\"320.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">courier</text><text x=\"460.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">delivery_minutes</text><text x=\"600.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">discount</text><text x=\"238.0\" y=\"68.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app · Rapidex</text><rect x=\"252.0\" y=\"52.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0%</text><rect x=\"392.0\" y=\"52.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">100.0%</text><rect x=\"532.0\" y=\"52.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0%</text><text x=\"238.0\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app · propria</text><rect x=\"252.0\" y=\"88.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0%</text><rect x=\"392.0\" y=\"88.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6.9%</text><rect x=\"532.0\" y=\"88.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0%</text><text x=\"238.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">app · pickup</text><rect x=\"252.0\" y=\"124.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">100.0%</text><rect x=\"392.0\" y=\"124.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">100.0%</text><rect x=\"532.0\" y=\"124.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0%</text><text x=\"238.0\" y=\"176.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">site · Rapidex</text><rect x=\"252.0\" y=\"160.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0%</text><rect x=\"392.0\" y=\"160.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">100.0%</text><rect x=\"532.0\" y=\"160.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">88.8%</text><text x=\"238.0\" y=\"212.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">site · propria</text><rect x=\"252.0\" y=\"196.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0%</text><rect x=\"392.0\" y=\"196.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6.8%</text><rect x=\"532.0\" y=\"196.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">87.9%</text><text x=\"238.0\" y=\"248.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">site · pickup</text><rect x=\"252.0\" y=\"232.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">100.0%</text><rect x=\"392.0\" y=\"232.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">100.0%</text><rect x=\"532.0\" y=\"232.0\" width=\"136.0\" height=\"32.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">87.8%</text></svg>", "caption": "Read down a column and across a row: each blank lines up with something you can see, except the 7% of own-fleet times."}
```

- **`courier`** is empty in 100% of pickups and 0% of everything else. Fully explained by
  `fulfilment`: not applicable.
- **`discount`** is empty in about 88% of website orders, in every segment alike, and in no app
  order. Explained by `channel`, and the rate is the share of website orders without a coupon,
  which lesson 2 already established.
- **`delivery_minutes`** is empty in 100% of pickups and 100% of Rapidex deliveries — both explained
  — and in about 7% of the own fleet's, in both channels.

**Cells at 0% and 100% are explanations; the cells in between are questions.** Everything here is
explained except one cell in each channel, and the two agree with each other, which is itself
information: whatever empties the own fleet's times does not care which system took the order.

## Following the one that is left

Splitting the own fleet by the order's status takes the next step:

```
ana@lab:~/clean$ psql -c "SELECT status, count(*) AS orders, count(delivery_minutes) AS timed FROM (SELECT DISTINCT * FROM raw.orders) o WHERE courier = 'propria' GROUP BY status ORDER BY orders DESC"
  status   | orders | timed 
-----------+--------+-------
 delivered |  14835 | 14394
 cancelled |    643 |     0
 refunded  |    479 |   464
(3 rows)
```

The 643 cancelled orders have no time and need none; nobody delivered them, so they join the
not-applicable pile. That leaves 441 delivered and 15 refunded orders: **456 blanks beside 14,858
timed deliveries, about 3%**, with nothing in `channel`, `fulfilment`, `courier` or `status` to
explain them.

Three per cent sounds small enough to ignore, and that is the instinct this lesson exists to
interrupt. A small rate of missingness does little harm if it is MCAR. If it is MNAR, a small rate
can hide exactly the cases a report is about. The next section finds out which this is.
