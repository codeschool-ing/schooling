---
title: Three rules for "far"
version: 1
---

**Every outlier rule measures distance from a centre in units of spread**, and the three common ones
differ in which centre and which spread. Run on the 28,526 order totals:

```schooling-example
{
  "language": "python",
  "file": "rules.py",
  "parts": [
    {
      "code": "from orders import orders\n\ntotal = orders[\"total\"]\n",
      "note": "The order totals, without the repeated orders, with each customer's name joined from the CRM by `orders.py`."
    },
    {
      "code": "q1, q3 = total.quantile([0.25, 0.75])\nfence = q3 + 1.5 * (q3 - q1)\n",
      "note": "**The IQR fence**: third quartile plus one and a half interquartile ranges."
    },
    {
      "code": "z = (total - total.mean()) / total.std()\n",
      "note": "**The z-score**: distance from the mean in standard deviations."
    },
    {
      "code": "median = total.median()\nmad = (total - median).abs().median()\nrobust = (total - median) / (1.4826 * mad)\n",
      "note": "**The robust z-score**: distance from the median in units of the median absolute deviation, scaled by 1.4826 to match a standard deviation on normal data."
    },
    {
      "code": "print(f\"IQR fence at R$ {fence:.2f}: {(total > fence).sum()} orders above it\")\nprint(f\"z-score above 3 (mean {total.mean():.2f}, sd {total.std():.2f}): {(z > 3).sum()} orders\")\nprint(f\"robust z above 3.5 (median {median:.2f}, MAD {mad:.2f}): {(robust > 3.5).sum()} orders\")\n",
      "note": "How many orders each rule calls far, with the centre and spread it used."
    }
  ]
}
```

```
ana@lab:~/clean$ python rules.py
IQR fence at R$ 217.29: 2488 orders above it
z-score above 3 (mean 94.14, sd 242.65): 25 orders
robust z above 3.5 (median 57.60, MAD 30.55): 2507 orders
```

The three rules disagree by a factor of a hundred.

**The IQR fence**, `statistics` lesson 6's rule, puts the line at the third quartile plus one and a
half times the interquartile range: R$ 217.29. 2,488 orders cross it — almost one in eleven — because
order totals have a long right tail, and the rule was designed with a symmetric distribution in
mind. Most of the 2,488 are families buying a big basket.

**The z-score** measures distance in standard deviations from the mean, and flags 25 orders. It flags
so few because the outliers inflate the very standard deviation they are measured in: one order of
R$ 26,928.50 pulls the standard deviation to 242.65, more than two and a half times the mean, and a line drawn at
three of those units sits beyond R$ 800. **The z-score is masked by what it is looking for.**

**The robust z-score** replaces the mean with the median and the standard deviation with the median
absolute deviation, the MAD, scaled by 1.4826 so that it matches the standard deviation for normal
data. Neither moves when the extremes do. With the conventional threshold of 3.5 it flags 2,507,
close to the IQR fence and for the same reason: the tail is long.

The same fence in SQL, for anybody working in the database:

```
ana@lab:~/clean$ psql -c "WITH t AS (SELECT DISTINCT order_id, total::numeric AS total FROM raw.orders), q AS (SELECT percentile_cont(0.25) WITHIN GROUP (ORDER BY total) AS q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY total) AS q3 FROM t) SELECT round((q3 + 1.5 * (q3 - q1))::numeric, 2) AS fence, (SELECT count(*) FROM t WHERE total > q3 + 1.5 * (q3 - q1)) AS above FROM q"
 fence  | above 
--------+-------
 217.29 |  2488
(1 row)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l09-rules-and-truth\" aria-label=\"A histogram of order totals on a logarithmic scale from R$ 10 to R$ 100,000, most of them between R$ 20 and R$ 300. Two vertical lines mark where the IQR fence (217.29) and the z-score of 3 (822.08) begin. Below the axis, the seven typed totals and the sixteen corporate orders are marked: the corporate orders sit far right, beyond both lines, and the typos are scattered, some beyond the lines and some well inside them.\"><path d=\"M200.0 40.0 L200.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M196.0 220.0 L200.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"192.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M200.0 167.7 L690.0 167.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M196.0 167.7 L200.0 167.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"192.0\" y=\"167.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1000</text><path d=\"M200.0 115.3 L690.0 115.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M196.0 115.3 L200.0 115.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"192.0\" y=\"115.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2000</text><path d=\"M200.0 63.0 L690.0 63.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M196.0 63.0 L200.0 63.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"192.0\" y=\"63.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3000</text><text x=\"200.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><rect x=\"200.0\" y=\"208.8\" width=\"12.2\" height=\"11.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"212.2\" y=\"171.4\" width=\"12.2\" height=\"48.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"224.5\" y=\"154.9\" width=\"12.2\" height=\"65.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"236.8\" y=\"137.9\" width=\"12.2\" height=\"82.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"249.0\" y=\"111.8\" width=\"12.2\" height=\"108.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"261.2\" y=\"83.6\" width=\"12.2\" height=\"136.4\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"273.5\" y=\"64.5\" width=\"12.2\" height=\"155.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"285.8\" y=\"56.4\" width=\"12.2\" height=\"163.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"298.0\" y=\"64.5\" width=\"12.2\" height=\"155.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"310.2\" y=\"98.5\" width=\"12.2\" height=\"121.5\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"322.5\" y=\"119.6\" width=\"12.2\" height=\"100.4\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"334.8\" y=\"141.3\" width=\"12.2\" height=\"78.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"347.0\" y=\"154.6\" width=\"12.2\" height=\"65.4\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"359.2\" y=\"165.7\" width=\"12.2\" height=\"54.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"371.5\" y=\"177.4\" width=\"12.2\" height=\"42.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"383.8\" y=\"186.4\" width=\"12.2\" height=\"33.6\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"396.0\" y=\"201.9\" width=\"12.2\" height=\"18.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"408.2\" y=\"211.1\" width=\"12.2\" height=\"8.9\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"420.5\" y=\"218.3\" width=\"12.2\" height=\"1.7\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"432.8\" y=\"219.7\" width=\"12.2\" height=\"0.3\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"445.0\" y=\"219.9\" width=\"12.2\" height=\"0.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"457.2\" y=\"219.9\" width=\"12.2\" height=\"0.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"469.5\" y=\"219.8\" width=\"12.2\" height=\"0.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"494.0\" y=\"219.8\" width=\"12.2\" height=\"0.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"506.2\" y=\"219.8\" width=\"12.2\" height=\"0.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"518.5\" y=\"219.8\" width=\"12.2\" height=\"0.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"555.2\" y=\"219.9\" width=\"12.2\" height=\"0.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"567.5\" y=\"219.8\" width=\"12.2\" height=\"0.2\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><rect x=\"616.5\" y=\"219.9\" width=\"12.2\" height=\"0.1\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></rect><path d=\"M200.0 220.0 L690.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M200.0 220.0 L200.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"200.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 10</text><path d=\"M322.5 220.0 L322.5 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"322.5\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 100</text><path d=\"M445.0 220.0 L445.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"445.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 1,000</text><path d=\"M567.5 220.0 L567.5 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"567.5\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 10,000</text><path d=\"M690.0 220.0 L690.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"690.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 100,000</text><path d=\"M363.8 242.0 L363.8 292.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"359.8\" y=\"302.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">IQR fence</text><path d=\"M434.6 242.0 L434.6 292.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"438.6\" y=\"302.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">z = 3</text><circle cx=\"494.1\" cy=\"258.0\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"403.5\" cy=\"258.0\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"498.3\" cy=\"258.0\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"476.5\" cy=\"258.0\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"387.1\" cy=\"258.0\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"331.5\" cy=\"258.0\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"461.7\" cy=\"258.0\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"558.8\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"517.3\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"559.4\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"504.2\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"529.1\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"577.7\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"577.9\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"478.3\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"620.2\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"519.5\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"455.1\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"523.8\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"576.4\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"515.6\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"472.1\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"517.7\" cy=\"280.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"190.0\" y=\"258.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">typed with a zero too many</text><text x=\"190.0\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">corporate orders</text><text x=\"445.0\" y=\"326.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">order total, logarithmic scale</text></svg>", "caption": "Marked from the lab's truth file. Both rules flag every corporate order, which is real, and miss some of the typos, which are not."}
```

The figure shows what none of the three rules can say. **Every corporate order is beyond both
lines, and every corporate order is real.** Of the seven typed totals, some are far out and some sit
in the thick of the distribution, where no distance rule will ever look. A rule decides what to look
at; it never decides what is true.
