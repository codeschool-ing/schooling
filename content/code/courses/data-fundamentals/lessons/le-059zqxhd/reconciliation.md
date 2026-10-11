---
title: Counting against the source
version: 1
---

**The checks at the door judge each row by itself. No row can say whether all the others arrived.**
That question needs a second opinion from outside the copy: the source's own count of what it holds.
Comparing the two is **reconciliation**, and it is how a missing row, which leaves no trace in the
data, becomes something you can see. Section 06 ended on one: the delivery of the 15th had the 200 rows it
promised, passed every check on the file, and did not contain `R000151`.

`compare.py`, in section 05, was one already. It compared the copy with the source key by
key, and found `R000041` missing where both copies looked healthy on their own. That is the most
thorough kind and the most expensive, because it needs every key from both sides.

## Three levels, from cheap to thorough

| level | what is compared | what it costs | what it misses |
|---|---|---|---|
| **counts** | rows per day, here and in the source | one number a day from the source | a row missing and another doubled on the same day |
| **control totals** | the sum of a column per day, such as the amount paid | one more number a day | a row missing and another doubled, when the two amounts are equal |
| **keys** | the identifiers themselves | every key, from both sides | nothing missing or doubled; it does not check the values |

Most pipelines compare counts on every run, totals on every run that carries money, and keys when the
first two disagree, to find out which rows. The 15th's delivery sat exactly in the blind spot of a
count: one ride doubled, one missing, and the total still 200.

## A week of payments

The payments provider sends a statement every day: each payment's id and its amount. Roda Livre's
copy of the same week has two things wrong with it, put there on purpose by the program below, which
plays both sides. On the 17th a payment never arrived. On the 19th one payment arrived twice and
another never did. Amounts are kept in **centavos**, as whole numbers, because a sum of amounts written
as decimal fractions can come out a fraction of a centavo wrong, and a reconciliation that disagrees
for no reason teaches everybody to ignore it. Save it as `collect/reconcile.py`:

```python
# collect/reconcile.py
import random

random.seed(9)
# the payments provider's statement for a week: (payment id, amount in centavos)
provider = {}
for d in range(15, 22):
    n = random.randint(80, 120)
    provider[f"2025-09-{d}"] = [(f"P{d}{i:03d}", random.choice([450, 600, 900, 1200]))
                                for i in range(n)]

# our copy of the same week, with two things gone wrong
ours = {day: list(payments) for day, payments in provider.items()}
ours["2025-09-17"].pop(12)                         # one payment never arrived
ours["2025-09-19"].append(ours["2025-09-19"][5])   # one arrived twice,
ours["2025-09-19"].pop(30)                         # and another never did


def reais(cents):
    return f"{cents // 100}.{cents % 100:02d}"


print("day          provider          ours              check")
for day in provider:
    pn, ps = len(provider[day]), sum(a for _, a in provider[day])
    on, os_ = len(ours[day]), sum(a for _, a in ours[day])
    check = "ok" if (pn, ps) == (on, os_) else "COUNT" if pn != on else "SUM"
    print(f"{day}   {pn:3} {reais(ps):>9}     {on:3} {reais(os_):>9}     {check}")

# where the totals disagree, the ids say which payment
for day in provider:
    p, o = [i for i, _ in provider[day]], [i for i, _ in ours[day]]
    missing = sorted(set(p) - set(o))
    twice = sorted({i for i in o if o.count(i) > 1})
    if missing or twice:
        print(f"{day}: missing {missing}, twice {twice}")
```

```
ana@lab:~/roda/collect$ python reconcile.py
day          provider          ours              check
2025-09-15   109    804.00     109    804.00     ok
2025-09-16    86    643.50      86    643.50     ok
2025-09-17   106    805.50     105    801.00     COUNT
2025-09-18   114    880.50     114    880.50     ok
2025-09-19   105    826.50     105    822.00     SUM
2025-09-20    84    675.00      84    675.00     ok
2025-09-21    92    705.00      92    705.00     ok
2025-09-17: missing ['P17012'], twice []
2025-09-19: missing ['P19030'], twice ['P19005']
```

The 17th fails on the count: 106 payments in the statement, 105 in the copy. **The 19th has the right
count and the wrong money**: 105 payments on both sides, R$ 826.50 against R$ 822.00. A check on
counts alone would have passed it. The keys then say exactly what happened on each day, which the
totals never could: `P19005` twice, `P19030` never.

## Against the source, and on the same clock

Two rules keep a reconciliation honest. **The second number comes from the source**, never from the
pipeline: a count the pipeline computes from its own copy agrees with the copy by construction. Here
it is the provider's statement; for a database it is a count run on a replica; for a delivered file it
is the number the source wrote beside it, as in section 06.

And **both sides must mean the same thing by a day**. A payment made at 23:50 in Curitiba is already
on the next day in UTC. A provider whose statement closes its day in UTC therefore disagrees every
night with a copy that closes it in `America/Sao_Paulo`, by exactly the payments made in the last
three hours of the local day.
Settle the clock before trusting the difference, as lesson 1's 27-hour Wednesday showed.
