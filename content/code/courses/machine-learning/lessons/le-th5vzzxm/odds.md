---
title: What a logistic weight means
version: 1
---

A weight in logistic regression does not move the chance by a fixed amount, because the bend makes
the same push worth more in the middle than near 0 or 1. What it moves by a fixed amount is the
**odds**: the chance of leaving divided by the chance of staying. A chance of 0.2 is odds of 0.25,
one to four; a chance of 0.5 is odds of 1.

**Each weight, raised as a power of e, is the factor the odds are multiplied by** when that column
goes up by one unit. `logistic.py` printed that factor beside each weight, and since the columns
were scaled, one unit is one standard deviation of the column:

| column | odds × | read out loud |
|---|---|---|
| `rating_90d` | 0.45 | one standard deviation higher in rating, about half a star here, and the odds of leaving fall by more than half |
| `tenure_months` | 0.62 | one standard deviation longer as a subscriber, about eight months, and the odds fall by a third |
| `skips_90d` | 1.41 | one standard deviation more skips, about one box, and the odds rise by 41% |
| `late_90d` | 1.30 | one more late delivery or so, and the odds rise by 30% |

To turn one of these into a factor per original unit, divide the weight by the column's standard
deviation before taking the power; the fitted scaler keeps them in `scale.scale_`. The ranking
above is the more useful reading, because it is in comparable units: **rating and tenure move
the odds more than anything else in the model.**

## The baseline in a category

`payment_card` and `payment_pix` both have weights of about −0.24, and there is no
`payment_boleto`. That is `drop_first=True` at work: `boleto` came first alphabetically, so it was
dropped and became the baseline that the other two are compared with. **Both weights say the same
thing: paying by card or Pix carries lower odds of leaving than paying by boleto.** Had the baseline
been `card`, the model would have printed a positive weight for `boleto` and an almost-zero one for
`pix`, with exactly the same predictions. A category's weights only make sense next to the name of
the category that was left out.

## What a weight does not mean

The same warning as for a line, louder. **Raising a subscriber's rating would not halve their odds
of leaving**, because nobody can raise a rating; the rating is a symptom of how much they like the
boxes, and the weight says how strongly that symptom goes with leaving. The weights describe the
data, holding fixed the other columns in the model, and nothing more. Lesson 19 takes the question
of what a model's weights can and cannot say a good deal further.
