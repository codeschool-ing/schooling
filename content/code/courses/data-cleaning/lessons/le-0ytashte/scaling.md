---
title: Putting columns on one scale
version: 1
---

**Normalisation** is a word with three meanings in this course. Lesson 6 normalised Unicode, and
databases have normal forms, which is a third thing again. Here it means **rescaling a number** so
that columns measured in different units can be compared or combined: revenue in reais and number
of orders, for instance, which differ by a factor of a hundred.

The two common rescalings, and a third that behaves differently:

```schooling-example
{
  "language": "python",
  "file": "scale.py",
  "parts": [
    {
      "code": "from per_customer import per\n\n"
    },
    {
      "code": "r = per[\"revenue\"]\n",
      "note": "Each customer's revenue for the year."
    },
    {
      "code": "per[\"minmax\"] = (r - r.min()) / (r.max() - r.min())\n",
      "note": "**Min-max**: 0 for the smallest, 1 for the largest."
    },
    {
      "code": "per[\"z\"] = (r - r.mean()) / r.std()\n",
      "note": "**z-score**: distance from the mean in standard deviations."
    },
    {
      "code": "per[\"pct\"] = r.rank(pct=True)\n\n",
      "note": "**Percentile rank**: the share of customers at or below this one."
    },
    {
      "code": "if __name__ == \"__main__\":\n    print(per[[\"revenue\", \"minmax\", \"z\", \"pct\"]].describe().round(3).to_string())\n    print(per.nlargest(2, \"revenue\")[[\"revenue\", \"minmax\", \"z\", \"pct\"]].round(3).to_string())\n",
      "note": "The summary of all four columns, and the two largest customers."
    }
  ]
}
```

```
ana@lab:~/clean$ python scale.py
         revenue    minmax         z       pct
count   2273.000  2273.000  2273.000  2273.000
mean    1178.038     0.033    -0.000     0.500
std     1408.926     0.040     1.000     0.289
min        0.000     0.000    -0.836     0.000
25%      424.750     0.012    -0.535     0.250
50%      892.100     0.025    -0.203     0.500
75%     1568.800     0.044     0.277     0.750
max    35522.500     1.000    24.376     1.000
             revenue  minmax       z  pct
customer_id                              
C01115       35522.5   1.000  24.376  1.0
C01114       28682.5   0.807  19.522  1.0
```

- **Min-max** maps the smallest value to 0 and the largest to 1. The largest is the Clínica Bem
  Viver, R$ 35,522.50 in two December orders. Every household is measured against a clinic, and
  **three customers in four end up below 0.05**: the scale exists, and almost nobody uses it.
- **The z-score** subtracts the mean and divides by the standard deviation. The median customer is
  at −0.20, and the clinic at 24.4. Lesson 9 showed why: the extremes inflate the standard
  deviation that is supposed to measure them.
- **The percentile rank** replaces each value by the share of customers at or below it. It cannot
  be dragged by an extreme, because it only knows the order, and the clinic and the accounting
  office both show as 1.0. **What it throws away is distance**: R$ 1,000 and R$ 35,000 can be
  neighbours.

None of the three is right in general. A scale is chosen for what it feeds. When an extreme is real
and belongs in the data, as these companies do, a rescaling it cannot dominate serves the households
better: the rank, or the logarithm of the next section. The corporate flag from the first section
can also keep them out of the fit altogether.

::: track data-science
The rescaling is a model of the data, and like any model it has parameters: the minimum and
maximum, or the mean and standard deviation. **Compute them on the training data only**, then apply
them unchanged to the test data and to everything that arrives later. Computing them on the whole
data set lets the test rows shape the scale they are measured on, a quiet form of leakage that
makes a model look better on paper than it will be in use. scikit-learn's scalers, `fit` on one
set and `transform` on another, exist to make that separation hard to forget.
:::

::: track bi
In a dashboard, rescaled values are rarely what people should read: nobody acts on a revenue of
0.025. Rescaling earns its place behind the scenes, in a ranking, a combined score or a colour
scale, and the number on the screen stays in reais. When a combined score is shown, show its
recipe beside it.
:::

::: track *
Wherever a rescaled column ends up, the values it was computed from belong in the same table, and
the formula, with the numbers it used, belongs in the code that made it.
:::
