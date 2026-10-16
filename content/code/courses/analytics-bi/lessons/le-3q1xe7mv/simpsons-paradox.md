---
title: Better on every device, worse overall
version: 1
---

The percentage section ended with a question: did Lantern's conversion fall at all? Split the same
sessions by device:

```
lantern=# SELECT extract(year FROM started_at)::int AS year,
lantern-#        coalesce(device, 'all') AS device,
lantern-#        count(*) AS sessions,
lantern-#        round(100.0 * count(*) FILTER (WHERE steps >= 5) / count(*), 2) AS conversion_pct
lantern-# FROM shop.web_sessions
lantern-# GROUP BY 1, ROLLUP (device) ORDER BY 1, 2;
 year | device  | sessions | conversion_pct 
------+---------+----------+----------------
 2025 | all     |    28194 |           7.37
 2025 | desktop |    13180 |          11.14
 2025 | mobile  |    15014 |           4.06
 2026 | all     |    31806 |           6.77
 2026 | desktop |    10141 |          12.04
 2026 | mobile  |    21665 |           4.30
(6 rows)
```

Desktop conversion rose from 11.14% to 12.04%. Mobile rose from 4.06% to 4.30%. **Both groups improved,
and the total fell**, from 7.37% to 6.77%. No number is wrong.

This is **Simpson's paradox**: a trend that holds within every group reverses when the groups are
combined. It is not rare and not a trick of the data. It happens whenever two things are true at once:
the groups have very different rates, and their sizes change between the two periods.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"simpson\" aria-label=\"Conversion in 2025 and 2026 for three groups, as pairs of dots joined by a line. Desktop rises from 11.14 to 12.04 percent. Mobile rises from 4.06 to 4.30 percent. All sessions together fall from 7.37 to 6.77 percent. Below, the share of sessions on mobile rises from 53.3 percent in 2025 to 68.1 percent in 2026.\"><text x=\"200.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0%</text><line x1=\"200.0\" y1=\"40\" x2=\"200.0\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"262.85714285714283\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2%</text><line x1=\"262.85714285714283\" y1=\"40\" x2=\"262.85714285714283\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"325.7142857142857\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4%</text><line x1=\"325.7142857142857\" y1=\"40\" x2=\"325.7142857142857\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"388.57142857142856\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6%</text><line x1=\"388.57142857142856\" y1=\"40\" x2=\"388.57142857142856\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"451.42857142857144\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8%</text><line x1=\"451.42857142857144\" y1=\"40\" x2=\"451.42857142857144\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"514.2857142857142\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10%</text><line x1=\"514.2857142857142\" y1=\"40\" x2=\"514.2857142857142\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"577.1428571428571\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12%</text><line x1=\"577.1428571428571\" y1=\"40\" x2=\"577.1428571428571\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"640.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14%</text><line x1=\"640.0\" y1=\"40\" x2=\"640.0\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"0.5\" stroke-dasharray=\"2 3\"></line><text x=\"30\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">desktop</text><line x1=\"550.1142857142858\" y1=\"70\" x2=\"578.4\" y2=\"70\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><circle cx=\"550.1142857142858\" cy=\"70\" r=\"4.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.5\"></circle><circle cx=\"578.4\" cy=\"70\" r=\"5.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"542.1142857142858\" y=\"56\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11.14%</text><text x=\"586.4\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">12.04%</text><text x=\"30\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mobile</text><line x1=\"327.6\" y1=\"120\" x2=\"335.1428571428571\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><circle cx=\"327.6\" cy=\"120\" r=\"4.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.5\"></circle><circle cx=\"335.1428571428571\" cy=\"120\" r=\"5.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"319.6\" y=\"106\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4.06%</text><text x=\"343.1428571428571\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">4.30%</text><text x=\"30\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">all sessions</text><line x1=\"431.62857142857143\" y1=\"170\" x2=\"412.77142857142854\" y2=\"170\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><circle cx=\"431.62857142857143\" cy=\"170\" r=\"4.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.5\"></circle><circle cx=\"412.77142857142854\" cy=\"170\" r=\"5.5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"439.62857142857143\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7.37%</text><text x=\"404.77142857142854\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">6.77%</text><text x=\"30\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">share of sessions on mobile</text><text x=\"200.0\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2025: 53.3%</text><text x=\"420.0\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2026: 68.1%</text><text x=\"640\" y=\"270\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" font-style=\"italic\">grey: 2025 · coloured: 2026</text></svg>", "caption": "Each device converts better in 2026; the total converts worse, because it is now mostly made of the device that always converted worse."}
```

Both are true here. Desktop converts about three times as well as mobile. And the mix moved:

```
lantern=# SELECT extract(year FROM started_at)::int AS year, device, count(*) AS sessions,
lantern-#        round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY extract(year FROM started_at)), 1) AS share_pct
lantern-# FROM shop.web_sessions
lantern-# GROUP BY extract(year FROM started_at), device ORDER BY 1, 2;
 year | device  | sessions | share_pct 
------+---------+----------+-----------
 2025 | desktop |    13180 |      46.7
 2025 | mobile  |    15014 |      53.3
 2026 | desktop |    10141 |      31.9
 2026 | mobile  |    21665 |      68.1
(4 rows)
```

In 2025 a little over half of the sessions came from phones; in 2026, more than two thirds. Lantern's
growth in 2026 came largely from social media, and social media visits arrive on phones. So the total of
2026 is an average weighted much more heavily towards the low-converting group. Each group got better;
the average got worse because it is now mostly made of the group that was always worse.

Which number is right? **Both, for different questions.** "Is the website converting visitors better
than last year?" — yes, on each device, by about a point on desktop. "Out of every hundred sessions, how
many buy?" — fewer than last year, because the visitors are different. A report that gives only the
total answers the second question while everyone reads it as the first.

The question that catches it: **did the mix of what is being counted change between the two periods?**
