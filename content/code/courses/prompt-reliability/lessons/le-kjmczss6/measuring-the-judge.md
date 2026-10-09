---
title: Measuring the judge
version: 2
---

A judge is a classifier. It reads two replies and outputs a label, `a` or `b`, so **it is measured
the way the triage prompt was: against labels a person wrote down first.** This program asks the
judge about every pair, reads the first letter of its answer, and compares the verdicts with the
person's. With `--swap` it asks a second time with the replies the other way round, which the next
section needs. Save it as `judge.py`:

```python
"""judge: ask the model which of two replies is better, and measure it
against the verdicts a person wrote down."""
import argparse

from pl import DEFAULTS, call, read_jsonl, read_prompt, render


def ask(template, params, pair, first, second):
    """The judge's verdict, as "first", "second" or "?" if it said neither."""
    prompt = render(template, {"message": pair["message"],
                               "reply_a": pair[first], "reply_b": pair[second]})
    said = call(prompt, params)["text"].strip().upper()[:1]
    return {"A": first, "B": second}.get(said, "?")


def kappa(human, judge):
    """Cohen's kappa: agreement beyond what the two raters' rates give by chance."""
    n = len(human)
    observed = sum(h == j for h, j in zip(human, judge)) / n
    chance = sum(human.count(x) / n * judge.count(x) / n for x in ("a", "b"))
    return observed, (observed - chance) / (1 - chance) if chance < 1 else 1.0


p = argparse.ArgumentParser(prog="judge")
p.add_argument("pairs")
p.add_argument("--swap", action="store_true")
a = p.parse_args()

params, template = read_prompt("prompts/judge.txt")
params = {**DEFAULTS, **params}
pairs = read_jsonl(a.pairs)
human, judge, flips, stable = [], [], 0, 0
for pair in pairs:
    v = ask(template, params, pair, "a", "b")
    human.append(pair["human"])
    judge.append(v)
    line = "%s  human %s  judge %s" % (pair["id"], pair["human"], v)
    if a.swap:
        w = ask(template, params, pair, "b", "a")
        line += "  swapped %s%s" % (w, "  FLIP" if w != v else "")
        flips += w != v
        stable += w == v == pair["human"]
    print(line)
observed, k = kappa(human, judge)
print("\nagrees with the human on %d of %d" % (round(observed * len(pairs)), len(pairs)))
print("Cohen's kappa %.2f" % k)
if a.swap:
    print("changes its mind when the order is swapped: %d of %d" % (flips, len(pairs)))
    print("agrees AND keeps its verdict: %d of %d" % (stable, len(pairs)))
```

`ask()` turns the answer into the letter of a reply. An answer that does not start with `A` or `B`
is a `?`: no verdict, which counts as a disagreement, the way `pl check` counts a reply that does
not parse.

```
ana@lab:~/triage$ python3 judge.py cases/pairs.jsonl
j01  human b  judge b
j02  human b  judge b
j03  human a  judge b
j04  human a  judge a
j05  human b  judge ?
j06  human a  judge b
j07  human b  judge b
j08  human a  judge b
j09  human b  judge b
j10  human a  judge b
j11  human b  judge b
j12  human a  judge ?
j13  human b  judge b
j14  human b  judge b
j15  human a  judge b
j16  human a  judge b

agrees with the human on 8 of 16
Cohen's kappa 0.11
```

Eight of sixteen agree with the person, 50%, and two answers began with neither letter. That reads
like a coin. It is a little better than one, and the reason is in which letters it used.

## Agreement beyond chance

With two possible answers, a judge that tossed a coin would agree with the person about half the
time. Raw agreement does not say how much of the 50% is that half. **Cohen's kappa measures
agreement beyond chance**, a statistic Jacob Cohen published in 1960 for exactly this: two raters
sorting the same items into categories.

It needs two numbers. The observed agreement is 8 of 16, 0.5. The agreement expected by chance
comes from how often each rater uses each answer:

```
ana@lab:~/triage$ grep -c '"human": "a"' cases/pairs.jsonl
8
```

The person chose `a` in 8 pairs of 16. The judge chose `a` once, `b` thirteen times, and nothing
twice. If the two answered independently at those rates, they would both say `a` with probability
8/16 × 1/16 = 0.03125, and both say `b` with probability 8/16 × 13/16 = 0.40625. So they would agree
0.4375 of the time by chance.

Kappa is how far the observed agreement got from chance, as a share of how far it could have got:
(0.5 − 0.4375) / (1 − 0.4375) = 0.11. **A kappa of 0 is a judge that agrees with people exactly as
often as chance would, and 1 is perfect agreement.** The scale most often quoted, from Landis and
Koch in 1977, calls anything from 0 to 0.20 slight. A judge that says `b` thirteen times in
sixteen is right about the eight `b` pairs by habit, and kappa takes that habit out.

## Calibrate before you trust

That number is what a judge has to show before anybody relies on it: a sample of the real task,
labelled by people who did not see the judge's answer, and the judge's agreement with them corrected
for chance. Sixteen pairs is the smallest set that makes the arithmetic visible, and lesson 11's
warning applies in full: one pair moves the agreement by six points. A judge you plan to use on
thousands of replies deserves a few hundred labelled pairs first.
