---
title: The timer that stops at two hours
version: 1
---

**456 own-fleet deliveries have no time, and nothing in their rows explains it.** This section
follows them the way an analyst would, with only the files, and then — because this is a lab —
checks the conclusion against the answer.

## What the recorded times say

```schooling-example
{
  "language": "python",
  "file": "own_fleet.py",
  "parts": [
    {
      "code": "import pandas as pd\n\norders = pd.read_csv(\"raw/orders.csv\", dtype=str, keep_default_na=False,\n                     na_values=[\"\"]).drop_duplicates()\n"
    },
    {
      "code": "own = orders[(orders[\"courier\"] == \"propria\") & (orders[\"status\"] != \"cancelled\")].copy()\n",
      "note": "The company's own couriers, without the cancelled orders: nothing was delivered there, so nothing should have been timed."
    },
    {
      "code": "own[\"missing\"] = own[\"delivery_minutes\"].isna()\nown[\"minutes\"] = pd.to_numeric(own[\"delivery_minutes\"])\n",
      "note": "A flag for the blank and the time as a number. `to_numeric` leaves a blank as `NaN`, which `describe()` skips."
    },
    {
      "code": "print(f\"own-fleet deliveries: {len(own)}, without a time: {own['missing'].sum()}\")\nprint(own[\"minutes\"].describe().round(1).to_string())\n",
      "note": "How many, how many without a time, and the summary of the times that exist."
    }
  ]
}
```

```
ana@lab:~/clean$ python own_fleet.py
own-fleet deliveries: 15314, without a time: 456
count    14858.0
mean        59.4
std         21.1
min         12.0
25%         44.0
50%         56.0
75%         72.0
max        119.0
```

The middle of this distribution is ordinary: half the deliveries take under 56 minutes, three
quarters under 72. The end is not. **The longest recorded delivery is 119 minutes, in 14,858
deliveries**, and the column of times has a right tail — lesson 2 showed the same shape in the order
totals — that should thin out gradually, not stop one minute short of a round number. Counting the
deliveries near the top:

```
ana@lab:~/clean$ psql -c "SELECT delivery_minutes::int / 10 * 10 AS from_minute, count(*) FROM raw.orders WHERE courier = 'propria' AND delivery_minutes IS NOT NULL GROUP BY 1 ORDER BY 1 DESC LIMIT 4"
 from_minute | count 
-------------+-------
         110 |   309
         100 |   471
          90 |   784
          80 |  1092
(4 rows)
```

309 deliveries between 110 and 119 minutes, and then nothing at all from 120. A tail that is still
three hundred deliveries thick one band before it ends was cut, not thinned.

## What the blanks line up with

Splitting the blanks by time of day, using the app's orders because their timestamps are local
(the website's are in UTC, and lesson 7 converts them):

```schooling-example
{
  "language": "python",
  "file": "by_hour.py",
  "parts": [
    {
      "code": "import pandas as pd\n\norders = pd.read_csv(\"raw/orders.csv\", dtype=str, keep_default_na=False,\n                     na_values=[\"\"]).drop_duplicates()\n"
    },
    {
      "code": "app = orders[(orders[\"channel\"] == \"app\") & (orders[\"courier\"] == \"propria\")\n             & (orders[\"status\"] != \"cancelled\")].copy()\n",
      "note": "Only the app's own-fleet deliveries: the app writes local time, so the hour can be read straight from the text."
    },
    {
      "code": "app[\"hour\"] = app[\"ordered_at\"].str[11:13]\napp[\"evening\"] = app[\"hour\"].isin([\"18\", \"19\", \"20\"])\n",
      "note": "Characters 11 and 12 of `2025-01-01 07:00:30` are the hour. Six to nine in the evening is the rush."
    },
    {
      "code": "rate = app.groupby(\"evening\")[\"delivery_minutes\"].apply(lambda m: m.isna().mean() * 100)\n",
      "note": "The share without a time, in each of the two groups."
    },
    {
      "code": "rate.index = [\"other hours\", \"18:00 to 20:59\"]\nprint(\"% without a time\")\nprint(rate.round(1).to_string())\n",
      "note": "Labels a reader understands, and the result."
    }
  ]
}
```

```
ana@lab:~/clean$ python by_hour.py
% without a time
other hours       1.5
18:00 to 20:59    6.0
```

Four times the rate in the evening. **Read on its own, that looks like MAR**: the blanks depend on
the hour, the hour is in the file, so fill the evening's blanks from other evening deliveries and
the problem is handled. And it would be the wrong conclusion. Evening deliveries are slower — the
traffic is worse — so more of them cross whatever line empties the field. The hour does not cause
the blank; it predicts the value that does.

**The two readings cannot be told apart from inside the data.** A blank that depends on the hour and
a blank that depends on a slow delivery that the hour makes more likely produce the same table. The
clue that separates them is the ceiling: a maximum of 119 and a tail cut flat. Ana takes it to the
operations team, who know the couriers' app: **the timer stops at two hours and saves nothing**,
by design, so that a courier who forgets to close a delivery does not record one of nine hours.

That is MNAR in its purest form: every value of 120 or more is missing, and only those.

## Checking against the answer

No real data set comes with the values it lost. This lab does, because its generator wrote every
real delivery time to `truth/` before emptying the field. Reading it is what you can never do at
work, and it shows what the blanks were hiding:

```python
import pandas as pd

truth = pd.read_csv("~/clean-data/truth/orders.csv")
real = truth.loc[truth["what"] == "minutes", "value"]
unseen = real[real >= 120]
print(f"deliveries the timer never recorded: {len(unseen)}")
print(f"their real times: {unseen.min()} to {unseen.max()} minutes")
print(f"mean of the recorded times: {real[real < 120].mean():.1f}")
print(f"mean of all the real times: {real.mean():.1f}")
seen = real[real < 120]
print(f"late (90 minutes or more), as recorded: {(seen >= 90).mean() * 100:.1f}%")
print(f"late (90 minutes or more), really:      {(real >= 90).mean() * 100:.1f}%")
```

```
ana@lab:~/clean$ python truth_minutes.py
deliveries the timer never recorded: 456
their real times: 120 to 223 minutes
mean of the recorded times: 59.4
mean of all the real times: 61.9
late (90 minutes or more), as recorded: 10.5%
late (90 minutes or more), really:      13.2%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l03-ceiling\" aria-label=\"A histogram of the real delivery times of 15314 own-fleet deliveries, in ten-minute bins from 0 to 230 minutes, as the lab's generator knows them. Every bar below 120 minutes was recorded. The 456 deliveries of 120 minutes or more, a thin tail out to 223, were never recorded, because the timer stops at two hours.\"><path d=\"M70.0 50.0 L70.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 250.0 L70.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 187.6 L690.0 187.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 187.6 L70.0 187.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"187.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1000</text><path d=\"M70.0 125.2 L690.0 125.2\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 125.2 L70.0 125.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"125.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2000</text><path d=\"M70.0 62.8 L690.0 62.8\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 62.8 L70.0 62.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"62.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3000</text><text x=\"70.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">deliveries</text><path d=\"M70.0 250.0 L690.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 250.0 L70.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M150.9 250.0 L150.9 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"150.9\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M231.7 250.0 L231.7 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"231.7\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M312.6 250.0 L312.6 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"312.6\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">90</text><path d=\"M393.5 250.0 L393.5 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"393.5\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">120</text><path d=\"M474.3 250.0 L474.3 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"474.3\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">150</text><path d=\"M555.2 250.0 L555.2 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"555.2\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">180</text><path d=\"M636.1 250.0 L636.1 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"636.1\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">210</text><text x=\"380.0\" y=\"281.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">real delivery time, minutes</text><rect x=\"97.0\" y=\"247.4\" width=\"27.0\" height=\"2.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"123.9\" y=\"207.9\" width=\"27.0\" height=\"42.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"150.9\" y=\"131.4\" width=\"27.0\" height=\"118.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"177.8\" y=\"71.4\" width=\"27.0\" height=\"178.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"204.8\" y=\"80.0\" width=\"27.0\" height=\"170.0\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"231.7\" y=\"102.7\" width=\"27.0\" height=\"147.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"258.7\" y=\"147.5\" width=\"27.0\" height=\"102.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"285.7\" y=\"181.8\" width=\"27.0\" height=\"68.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"312.6\" y=\"201.1\" width=\"27.0\" height=\"48.9\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"339.6\" y=\"220.7\" width=\"27.0\" height=\"29.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"366.5\" y=\"230.7\" width=\"27.0\" height=\"19.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"393.5\" y=\"240.0\" width=\"27.0\" height=\"10.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"420.4\" y=\"243.3\" width=\"27.0\" height=\"6.7\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"447.4\" y=\"245.3\" width=\"27.0\" height=\"4.7\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"474.3\" y=\"247.8\" width=\"27.0\" height=\"2.2\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"501.3\" y=\"248.1\" width=\"27.0\" height=\"1.9\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"528.3\" y=\"248.7\" width=\"27.0\" height=\"1.3\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"555.2\" y=\"248.8\" width=\"27.0\" height=\"1.2\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"582.2\" y=\"248.8\" width=\"27.0\" height=\"1.2\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"609.1\" y=\"248.8\" width=\"27.0\" height=\"1.2\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"636.1\" y=\"248.8\" width=\"27.0\" height=\"1.2\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"663.0\" y=\"248.8\" width=\"27.0\" height=\"1.2\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><path d=\"M393.5 250.0 L393.5 70.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"393.5\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the timer stops</text><text x=\"541.7\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">456 never recorded</text></svg>", "caption": "Drawn from the lab's truth file, which no real data set has. In the orders file, everything right of the line is simply a blank."}
```

The mean moves only from 59.4 to 61.9 minutes, because 456 deliveries are 3% of the total. **The
share of late deliveries moves from 10.5% to 13.2%**: a quarter more late deliveries than the
recorded times show, and a report on late deliveries is precisely the report somebody reads to
decide whether the fleet needs more couriers. An analyst who filled the blanks with the average,
or dropped them, would have reported the fleet as faster than it is, with a straight face and a
correct query.
