---
title: The novelty effect
version: 1
---

People react to something because it is new: they click the unfamiliar button to see what it does,
or read the redesigned page more carefully than the old one. **The novelty effect is a lift that
fades as visitors get used to the change.** Its mirror image is the **change-aversion** effect, where
returning visitors do worse with a new design for a while, until they learn it. Either way, the first
days of a test describe the reaction to change, and the later ones describe the change.

```schooling-example
{"language": "python", "file": "novelty.py", "parts": [{"code": "import pandas as pd\n\nvisits = pd.read_csv(\"experiment.csv\", parse_dates=[\"day\"])\nvisits[\"week\"] = (visits[\"day\"] - visits[\"day\"].min()).dt.days // 7 + 1", "note": "Number each visitor's day as week 1, 2 or 3 of the test."}, {"code": "rates = visits.pivot_table(index=\"week\", columns=\"group\", values=\"converted\", aggfunc=\"mean\")\nrates[\"lift, points\"] = (rates[\"new\"] - rates[\"old\"]) * 100\nprint((rates[[\"old\", \"new\"]] * 100).round(2).join(rates[\"lift, points\"].round(2)).to_string())", "note": "Conversion in per cent for each group in each week, and the difference between them in percentage points."}], "output": "       old   new  lift, points\nweek                          \n1     4.31  5.35          1.04\n2     4.35  4.25         -0.10\n3     4.17  4.42          0.25"}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 290\" role=\"img\" data-fig=\"l09-daily\" aria-label=\"Daily conversion of the old and new checkout over the 21 days of the test. In the first four days the new line sits well above the old, about 5.4 to 6.8 per cent against 3.2 to 4.5. From the second week the two lines cross and recross around 4 to 5 per cent.\"><path d=\"M60.0 40.0 L60.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M56.0 220.0 L60.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><path d=\"M60.0 160.0 L600.0 160.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 160.0 L60.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M60.0 100.0 L600.0 100.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 100.0 L60.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"100.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M60.0 40.0 L600.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 40.0 L60.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"60.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">conversion, per cent</text><path d=\"M60.0 220.0 L600.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"150.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">week 1</text><text x=\"330.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">week 2</text><path d=\"M240.0 40.0 L240.0 220.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"510.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">week 3</text><path d=\"M420.0 40.0 L420.0 220.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M72.9 145.6 L98.6 184.4 L124.3 176.3 L150.0 144.3 L175.7 145.5 L201.4 118.4 L227.1 139.7 L252.9 155.2 L278.6 140.1 L304.3 156.4 L330.0 153.5 L355.7 167.1 L381.4 153.4 L407.1 122.1 L432.9 134.4 L458.6 176.5 L484.3 161.2 L510.0 134.3 L535.7 135.7 L561.4 153.5 L587.1 188.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M72.9 96.7 L98.6 76.2 L124.3 116.9 L150.0 107.2 L175.7 134.8 L201.4 154.3 L227.1 150.4 L252.9 114.7 L278.6 176.8 L304.3 131.4 L330.0 154.0 L355.7 185.8 L381.4 158.9 L407.1 146.1 L432.9 195.4 L458.6 186.2 L484.3 158.8 L510.0 125.8 L535.7 117.0 L561.4 104.5 L587.1 145.3\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M80.0 262.0 L104.0 262.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"110.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">old checkout</text><path d=\"M280.0 262.0 L304.0 262.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"310.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new checkout</text></svg>", "caption": "The new page's advantage is concentrated in its first days. An average over the three weeks mixes a reaction to novelty with the lasting effect."}
```

**In the first week the new checkout converted 5.35 per cent of visitors against 4.31, a lift of
1.04 points. In the second week the lift was −0.10, and in the third 0.25.** The whole effect of the
test, which lesson 10 computes over three weeks, is an average of a large first week and a small
remainder. Shipped on the strength of the average, the change would deliver much less than the
average promised, because every visitor after launch is past their first week.

## What to do about it

- **Look at the effect over time** as a matter of routine, by week or by day, before reporting the
  total. A lift concentrated at the start is a warning; a lift that holds is reassuring.
- **Separate new and returning visitors** where the test has both. Novelty hits returning visitors,
  who knew the old design; somebody seeing the site for the first time has nothing to be surprised
  by.
- **Run long enough for the effect to settle**, which lesson 8's whole-week rule already helps with.
  When the decision matters and the early weeks look different, the honest estimate is from the later
  weeks, and it comes with fewer visitors and a wider interval.

Panela's test was built with a novelty effect in it: `panela.py` gives the new page an extra lift
that decays day by day, on top of a steady 0.4 points. The weekly lifts above are what that looks
like through three weeks of noise, and lesson 10 asks what it does to the decision.
