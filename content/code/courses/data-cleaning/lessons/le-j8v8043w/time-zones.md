---
title: Time zones: the same instant, two clocks
version: 1
---

**A timestamp without a time zone is a reading on an unnamed clock.** The app writes
`2025-01-01 07:00:30` and means São Paulo. The website writes `2025-01-01T11:24:01Z`, and the `Z` —
for "Zulu", the military name for UTC — says the clock is UTC. São Paulo has been three hours
behind UTC all year round since Brazil abolished daylight saving in 2019, so 11:24 UTC is 08:24 in
the shop.

Converting each source to one clock:

```schooling-example
{
  "language": "python",
  "file": "when.py",
  "parts": [
    {
      "code": "import pandas as pd\n\norders = pd.read_csv(\"raw/orders.csv\", dtype=str).drop_duplicates()\nsite = orders[\"channel\"] == \"site\"\n",
      "note": "The orders without their repeats, and a mask for the website's."
    },
    {
      "code": "utc = pd.to_datetime(orders.loc[site, \"ordered_at\"], format=\"%Y-%m-%dT%H:%M:%SZ\", utc=True)\n",
      "note": "The website's timestamps, read as UTC: the format includes the literal `Z`, and `utc=True` says what it means."
    },
    {
      "code": "local = pd.to_datetime(orders.loc[~site, \"ordered_at\"], format=\"%Y-%m-%d %H:%M:%S\")\n",
      "note": "The app's, with no zone: local time as written."
    },
    {
      "code": "orders.loc[site, \"placed\"] = utc.dt.tz_convert(\"America/Sao_Paulo\").dt.tz_localize(None)\n",
      "note": "**One clock for both.** UTC converted to São Paulo, then the zone label dropped so the column holds plain local times."
    },
    {
      "code": "orders.loc[~site, \"placed\"] = local\n"
    },
    {
      "code": "orders[\"placed\"] = pd.to_datetime(orders[\"placed\"])\n",
      "note": "One column of local times for every order."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from when import orders as o; s = o[o['channel'] == 'site']; print(s[['ordered_at', 'placed']].head(3).to_string(index=False)); print((s['ordered_at'].str[:10] != s['placed'].dt.strftime('%Y-%m-%d')).sum())"
          ordered_at              placed
2025-01-01T11:24:01Z 2025-01-01 08:24:01
2025-01-01T12:53:12Z 2025-01-01 09:53:12
2025-01-01T13:59:17Z 2025-01-01 10:59:17
1335
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l07-two-clocks\" aria-label=\"Two time lines, one above the other, for the same stretch of time. The upper one is UTC and the lower one São Paulo, three hours behind. An order stamped 02:00 on 2 January in UTC sits at 23:00 on 1 January in São Paulo: the same instant, on the previous day.\"><text x=\"60.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">UTC, as the website writes it</text><path d=\"M60.0 70.0 L680.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 66.0 L60.0 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15:00</text><path d=\"M163.3 66.0 L163.3 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"163.3\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18:00</text><path d=\"M266.7 66.0 L266.7 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"266.7\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">21:00</text><path d=\"M370.0 66.0 L370.0 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"370.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">00:00</text><path d=\"M473.3 66.0 L473.3 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"473.3\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">03:00</text><path d=\"M576.7 66.0 L576.7 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"576.7\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">06:00</text><path d=\"M680.0 66.0 L680.0 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"680.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">09:00</text><path d=\"M370.0 94.0 L370.0 110.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 2\"></path><text x=\"364.0\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 January</text><text x=\"376.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 January</text><text x=\"60.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">São Paulo, as the customer saw it</text><path d=\"M60.0 170.0 L680.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 166.0 L60.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12:00</text><path d=\"M163.3 166.0 L163.3 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"163.3\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15:00</text><path d=\"M266.7 166.0 L266.7 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"266.7\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18:00</text><path d=\"M370.0 166.0 L370.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"370.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">21:00</text><path d=\"M473.3 166.0 L473.3 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"473.3\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">00:00</text><path d=\"M576.7 166.0 L576.7 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"576.7\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">03:00</text><path d=\"M680.0 166.0 L680.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"680.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">06:00</text><path d=\"M473.3 194.0 L473.3 210.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 2\"></path><text x=\"467.3\" y=\"204.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 January</text><text x=\"479.3\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 January</text><path d=\"M438.9 70.0 L438.9 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"438.9\" cy=\"70.0\" r=\"5\" fill=\"var(--amber)\"></circle><circle cx=\"438.9\" cy=\"170.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"448.9\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">02:00</text><text x=\"448.9\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">23:00</text><text x=\"492.9\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">same instant, previous day</text><text x=\"492.9\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one order</text></svg>", "caption": "Every website order stamped between 00:00 and 02:59 UTC belongs to the evening before on the clock its customer used: 1,335 of them in 2025."}
```

The website's first three orders move three hours earlier, to the times a customer in São Paulo
saw on the screen. **1,335 website orders also move to a different day**: anything stamped from
00:00 to 02:59 UTC was placed the evening before, between 21:00 and 23:59 local time.

That is not a rounding error. A report of orders per day built on the raw text would put every late
evening order on the wrong date, inflating Mondays with Sunday nights and pushing New Year's Eve
orders into 2026. A report by hour would show the website's customers shopping at two in the
morning. Lesson 3 avoided both by using only the app's orders for the hour of the day, and said it
would come back to this.

## In SQL

PostgreSQL reads the `Z` itself when the text is cast to `timestamptz`, and `AT TIME ZONE` gives the
local clock time:

```
ana@lab:~/clean$ psql -c "SELECT ordered_at, (ordered_at::timestamptz AT TIME ZONE 'America/Sao_Paulo') AS placed FROM raw.orders WHERE channel = 'site' LIMIT 3"
      ordered_at      |       placed        
----------------------+---------------------
 2025-01-01T11:24:01Z | 2025-01-01 08:24:01
 2025-01-01T12:53:12Z | 2025-01-01 09:53:12
 2025-01-01T13:59:17Z | 2025-01-01 10:59:17
(3 rows)
```

Two rules carry over to any data with times in it:

- **store instants in UTC, or with their offset, and convert at the edge**, for display and for
  anything grouped by local day or hour;
- **name time zones by region, `America/Sao_Paulo`, never by offset, `-03:00`**. The region knows its
  own history, including the daylight saving São Paulo had before 2019; an offset is right only for
  the dates it happened to be measured on.
