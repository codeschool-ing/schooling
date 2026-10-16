---
title: Where the model was wrong
version: 1
---

A model that is too pessimistic overall can still be wrong in different directions for different
people, and the overall figure hides that. The question is the one lesson 20 asked about age, asked now of
every group: for each value of a column, what did the model say and what happened? The ratio of the two
is the useful number. Below 1, fewer left than the model said; above 1, more did. Save this as
`where.py`:

```python
# where.py
import pandas as pd

from feira import load_churn

scores = pd.concat(pd.read_csv(f"scores/2026-0{m}.csv", parse_dates=["snapshot"]) for m in [1, 2, 3])
labels = pd.read_csv("data/churn_2026_labels.csv", parse_dates=["snapshot"])
rows = scores.merge(labels, on=["customer_id", "snapshot"]).merge(
    load_churn("data/churn_2026.csv"), on=["customer_id", "snapshot"])

for col in ["plan", "city"]:
    g = rows.groupby(col, observed=True)
    table = pd.DataFrame({"subscribers": g.size(), "chance": g["chance"].mean(),
                          "left": g["churned"].mean()})
    table["left / chance"] = table["left"] / table["chance"]
    print(table.round(3).sort_values("left / chance").to_string(), end="\n\n")
```

```
ana@lab:~/ml$ python where.py
             subscribers  chance   left  left / chance
plan                                                  
monthly              496   0.108  0.058          0.541
fortnightly         5714   0.053  0.041          0.776
weekly              6944   0.070  0.058          0.831

                subscribers  chance   left  left / chance
city                                                     
Rio de Janeiro         2497   0.089  0.056          0.631
Campinas               1890   0.056  0.039          0.694
São Paulo              5292   0.059  0.043          0.727
Belo Horizonte         1776   0.059  0.066          1.124
Curitiba               1699   0.057  0.064          1.124
```

Most groups sit between 0.6 and 0.8, the overall pessimism of the last section spread fairly evenly.
Two kinds of row stand out.

**The monthly plan, at 0.541.** The model gave these 496 subscribers a mean chance of 0.108, and 5.8%
left: the model said nearly twice what happened. This is the artefact lesson 19 found, now with its price
attached. Every plan column is zero for them, so the model reads them as a plan it has no weight for,
and a short tenure on top makes them look like the newest, flightiest subscribers on any plan. **The
inputs warned about this one on the first of February**, when `inputs.py` showed a value never seen in
training.

**Curitiba and Belo Horizonte, at 1.124.** Every other city came in well under its chance; these two came
in over. More of their subscribers left than the model said, in a quarter when the model was
over-estimating everybody else. That is not noise in one month. Their monthly rate, set against the
other three cities over the whole history, looks like this:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 340\" role=\"img\" data-fig=\"l22-cities\" aria-label=\"Monthly share of subscribers who left, July 2024 to March 2026, in two lines: Curitiba and Belo Horizonte together, and the other three cities. Through 2025 the two lines cross back and forth between about 0.03 and 0.08, rising together after the September price rise. From January 2026, to the right of a dashed line where the model's data ends, the two cities sit above the others every month: 0.058 against 0.045, 0.064 against 0.041, and 0.073 against 0.050.\"><path d=\"M70.0 280.0 L560.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 280.0 L70.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jul 2024</text><path d=\"M217.0 280.0 L217.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"217.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jan 2025</text><path d=\"M364.0 280.0 L364.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"364.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jul 2025</text><path d=\"M511.0 280.0 L511.0 284.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"511.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jan 2026</text><path d=\"M70.0 30.0 L70.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 280.0 L70.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.02</text><path d=\"M70.0 208.6 L560.0 208.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 208.6 L70.0 208.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"208.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.04</text><path d=\"M70.0 137.1 L560.0 137.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 137.1 L70.0 137.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"137.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.06</text><path d=\"M70.0 65.7 L560.0 65.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 65.7 L70.0 65.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"65.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.08</text><text x=\"70.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">share who left that month</text><path d=\"M70.0 46.6 L94.5 91.5 L119.0 136.1 L143.5 151.0 L168.0 166.0 L192.5 152.0 L217.0 152.7 L241.5 157.7 L266.0 159.4 L290.5 148.4 L315.0 154.4 L339.5 183.1 L364.0 172.2 L388.5 163.8 L413.0 105.7 L437.5 95.5 L462.0 95.7 L486.5 120.9 L511.0 190.8 L535.5 205.3 L560.0 173.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M70.0 114.9 L94.5 167.9 L119.0 188.1 L143.5 182.0 L168.0 127.7 L192.5 130.0 L217.0 125.9 L241.5 152.1 L266.0 182.5 L290.5 235.1 L315.0 150.6 L339.5 156.2 L364.0 208.3 L388.5 200.9 L413.0 69.5 L437.5 137.3 L462.0 135.8 L486.5 184.0 L511.0 143.9 L535.5 124.0 L560.0 90.5\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M498.8 280.0 L498.8 37.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"498.8\" y=\"29.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the model's data ends</text><text x=\"525.7\" y=\"80.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Curitiba + BH</text><text x=\"525.7\" y=\"223.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the other three</text></svg>", "caption": "Two cities move away from the rest in January, and nothing the model reads moved with them."}
```

Through 2025 the two lines take turns on top. From January they separate, and stay apart. Asked about
it, the retention team knew at once: **a competitor started delivering in Curitiba and Belo Horizonte in
January**, with an introductory price. It was in the local news. It is in no column of `churn.csv`.

And that is why `inputs.py` saw nothing. The city column sat at 0.001: the same share of subscribers
lived in each city as always. **What changed was what living there meant for whether somebody stays.**
The inputs were the same; the answer to the same inputs was different. No check on the inputs can
see that, because there is nothing in the inputs to see. Only the labels show it, a month late, and only
if somebody breaks the error down by group.
