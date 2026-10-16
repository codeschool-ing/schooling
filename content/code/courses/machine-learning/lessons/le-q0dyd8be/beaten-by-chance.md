---
title: Beaten, or lucky
version: 1
---

The model made R$ 21,672 on the test months and the rule lost R$ 576. That looks decisive, and it
is still one test set: 24,257 rows that happened to be the second half of 2025. **A different six
months, with different subscribers, would have given different numbers**, and the question that
matters is whether the gap would survive that.

`statistics` answered this kind of question with an interval, and the tool that needs no formula
is the **bootstrap**: draw a new test set of the same size from the real one, with replacement,
score both policies on it, and do that a thousand times. The spread of the thousand differences is
how much the gap moves when only luck changes.

One detail separates a correct bootstrap from a reassuring one. The rows of `churn.csv` are not
independent: the same subscriber appears once a month, and their rows rise and fall together. So
this program resamples **subscribers**, carrying all their rows with them. Save it as `beaten.py`;
it reads the scores `first_model.py` saved:

```schooling-example
{
  "language": "python",
  "file": "beaten.py",
  "parts": [
    {
      "code": "# beaten.py\nimport numpy as np\nimport pandas as pd\n\nfrom feira import CREDIT, KEPT, SAVED, net_value\n\ntest = pd.read_csv(\"first_model_scores.csv\")",
      "note": "The scores saved by `first_model.py`, so nothing is fitted again."
    },
    {
      "code": "model = test[\"chance\"] >= CREDIT / (SAVED * KEPT)\nrule = (test[\"skips_90d\"] >= 3) & (test[\"complaints_90d\"] >= 1)\nprint(f\"model R$ {net_value(test['churned'], model):,.0f}, \"\n      f\"rule R$ {net_value(test['churned'], rule):,.0f}\")\n",
      "note": "The two policies being compared, each as a column of yes or no: the model's, at the break-even line, and the rule `rule.py` chose."
    },
    {
      "code": "rng = np.random.default_rng(0)\nrows = test.groupby(\"customer_id\").indices          # each subscriber's rows\npeople = list(rows)\ngaps = []",
      "note": "**Resample people, not rows.** `indices` maps each subscriber to the positions of their rows. A subscriber appears up to six times in the test months, and those rows are not independent draws; resampling rows would pretend they were and make the interval too narrow."
    },
    {
      "code": "for _ in range(1000):\n    drawn = rng.choice(len(people), len(people))      # subscribers, with replacement\n    idx = np.concatenate([rows[people[i]] for i in drawn])\n    t = test.iloc[idx]\n    gaps.append(net_value(t[\"churned\"], model.iloc[idx]) - net_value(t[\"churned\"], rule.iloc[idx]))",
      "note": "A thousand imaginary test sets, each as large as the real one, drawn from it with replacement. On each, the same two policies are scored and the difference kept."
    },
    {
      "code": "low, high = np.percentile(gaps, [2.5, 97.5])\nprint(f\"model minus rule, 95% of resamples between R$ {low:,.0f} and R$ {high:,.0f}\")\nprint(f\"resamples where the rule won: {np.mean(np.array(gaps) < 0):.1%}\")",
      "note": "The middle 95% of those differences is the interval, and the share below zero is how often the rule would have come out ahead."
    }
  ]
}
```

```
ana@lab:~/ml$ python beaten.py
model R$ 21,672, rule R$ -576
model minus rule, 95% of resamples between R$ 18,416 and R$ 25,944
resamples where the rule won: 0.0%
```

**In a thousand resamples, the rule never came out ahead**, and the middle 95% of the differences
runs from about R$ 18,400 to R$ 25,900. The gap is not luck. The resamples land like this:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 250\" role=\"img\" data-fig=\"l02-bootstrap\" aria-label=\"A histogram of 1,000 bootstrap differences between the model and the rule, all of them positive, centred near R$ 22,212, with the zero line well to the left of every bar.\"><path d=\"M60.0 30.0 L60.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M56.0 200.0 L60.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M60.0 165.3 L610.0 165.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 165.3 L60.0 165.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"165.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><path d=\"M60.0 130.6 L610.0 130.6\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 130.6 L60.0 130.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"130.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M60.0 95.9 L610.0 95.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 95.9 L60.0 95.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"95.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">150</text><path d=\"M60.0 61.2 L610.0 61.2\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M56.0 61.2 L60.0 61.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"52.0\" y=\"61.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><text x=\"60.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">resamples</text><path d=\"M335.0 200.0 L335.0 197.2 L352.2 197.2 L352.2 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M352.2 200.0 L352.2 194.4 L369.4 194.4 L369.4 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M369.4 200.0 L369.4 176.4 L386.6 176.4 L386.6 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M386.6 200.0 L386.6 152.1 L403.8 152.1 L403.8 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M403.8 200.0 L403.8 107.7 L420.9 107.7 L420.9 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M420.9 200.0 L420.9 61.9 L438.1 61.9 L438.1 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M438.1 200.0 L438.1 52.2 L455.3 52.2 L455.3 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M455.3 200.0 L455.3 89.0 L472.5 89.0 L472.5 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M472.5 200.0 L472.5 123.0 L489.7 123.0 L489.7 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M489.7 200.0 L489.7 168.8 L506.9 168.8 L506.9 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M506.9 200.0 L506.9 187.5 L524.1 187.5 L524.1 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M524.1 200.0 L524.1 195.8 L541.2 195.8 L541.2 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M60.0 200.0 L610.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 200.0 L60.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 0</text><path d=\"M197.5 200.0 L197.5 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"197.5\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 8,000</text><path d=\"M335.0 200.0 L335.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"335.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 16,000</text><path d=\"M472.5 200.0 L472.5 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"472.5\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 24,000</text><path d=\"M610.0 200.0 L610.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"610.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 32,000</text><text x=\"335.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">model minus rule, in reais</text><path d=\"M60.0 200.0 L60.0 30.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"68.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no difference</text></svg>", "caption": "A thousand resampled test sets. The gap moves by thousands of reais from one to the next, and never reaches zero. The bars in the other colour are the 5% outside the interval."}
```

Reading it the right way round matters. The interval does **not** say the model will make between
those two figures next semester: next semester has its own subscribers and, as lesson 22 shows, its
own surprises. It says that *on data like this*, the difference between these two policies is far
larger than the noise in measuring it. That is all a test set can promise, and it is enough to
decide.

## When the gap is small

The case to watch for is the opposite one: two models a few hundred reais apart, with an interval
that crosses zero. Then the honest report is that **the test cannot tell them apart**, and the
choice between them is made on something else: which is simpler, cheaper to run, easier to
explain. Lessons 8 and 9 meet exactly that, when a tuned model beats an untuned one by less than
this interval is wide.
