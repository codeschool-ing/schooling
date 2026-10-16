---
title: The rule a person would write
version: 1
---

A constant is the floor. The bar a model has to clear to be worth building is higher: **the best
rule somebody who knows the business could write in one line.** If a subscriber who skips three
boxes in a quarter is very likely to leave, the retention team does not need a model, it needs that
sentence.

The first step is to look at one column against the target, on the training months only. Then
write a handful of candidate rules, score each on the training months, keep the best, and only
then look at the test. Save this as `rule.py`:

```python
# rule.py
from feira import by_time, load_churn, net_value

train, test = by_time(load_churn())

RULES = {
    "skips_90d >= 3": lambda d: d["skips_90d"] >= 3,
    "complaints_90d >= 2": lambda d: d["complaints_90d"] >= 2,
    "rating_90d < 3.6": lambda d: d["rating_90d"] < 3.6,
    "skips >= 3 and complaints >= 1": lambda d: (d["skips_90d"] >= 3) & (d["complaints_90d"] >= 1),
    "tenure_months <= 2": lambda d: d["tenure_months"] <= 2,
}
print("on the months it may learn from:")
for name, rule in RULES.items():
    send = rule(train)
    print(f"  {name:32} {send.sum():5,} credits  R$ {net_value(train['churned'], send):>8,.0f}")

best = max(RULES, key=lambda name: net_value(train["churned"], RULES[name](train)))
send = RULES[best](test)
print(f"best rule: {best}")
print(f"on the test months: {send.sum():,} credits, "
      f"{(send & (test['churned'] == 1)).sum()} to leavers, "
      f"net value R$ {net_value(test['churned'], send):,.0f}")
```

```
ana@lab:~/ml$ python rule.py
on the months it may learn from:
  skips_90d >= 3                   2,355 credits  R$  -32,280
  complaints_90d >= 2              1,848 credits  R$  -33,024
  rating_90d < 3.6                 3,172 credits  R$   -2,896
  skips >= 3 and complaints >= 1     468 credits  R$    2,448
  tenure_months <= 2               5,852 credits  R$ -166,400
best rule: skips >= 3 and complaints >= 1
on the test months: 270 credits, 71 to leavers, net value R$ -576
```

Four of the five rules **lose money on the months they were chosen from**. Each one picks out
people who leave more often than average, and that is not enough: a credit pays for itself only
when more than 40 ÷ 144, about 28%, of the people who receive it were about to leave. `skips_90d
>= 3` finds a group whose rate is several times the average and still sends most of its credits to
people who were staying.

The one rule that made a little money on the training months, **R$ 2,448**, combines two
conditions and sends only 468 credits. On the six months it never saw, it sends 270 and loses
**R$ 576**. That is the rule a person would have written, chosen honestly, and it is worth nothing.

Two things to take from that, and both outlast this lesson:

- **A rule chosen on data is fitted to it.** The best of five is partly the best and partly the
  luckiest, and the luck does not travel. The same happens to a model with a thousand parameters,
  only more so, and lesson 3 is how to keep it honest.
- **The bar is now clear.** *Send nobody* is R$ 0, and the best rule anybody wrote is about R$ 0.
  Anything a model makes on the test months is money a sentence could not find.
