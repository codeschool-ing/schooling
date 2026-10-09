---
title: Change one thing and count what moves
version: 2
---

Group rates say that something is uneven. They do not say what causes it, and they need hundreds of
decisions before they say anything. **A counterfactual test asks a narrower question about each
decision**: if this person were the same in every way except one, would the system decide
differently? Change the one field, keep everything else, run the system again, and count the
decisions that flip.

`guard counterfactual` does that to the profiles from the first section. It moves every Southeastern
CEP to Recife, `50010-000`, and every Northeastern one to São Paulo, `01310-100`. The rating and the
number of jobs stay as they were. Save it as `~/guard/tools/counterfactual.py`:

```python
# counterfactual.py: score every profile again with only its CEP moved.
#
#   guard counterfactual FILE
#
# A Southeastern CEP becomes Recife's, 50010-000, and any other becomes São
# Paulo's, 01310-100. Nothing else in the profile changes, so a decision that
# flips was decided by the CEP alone.
import json
import sys

from standin import THRESHOLD, score

with open(sys.argv[1], encoding="utf-8") as f:
    profiles = [json.loads(line) for line in f if line.strip()]

flips = {}
print("%-8s %-9s %-10s %5s   %-10s %5s" % ("who", "region", "cep", "score", "swapped", "score"))
for p in profiles:
    other = dict(p, cep="50010-000" if p["cep"][0] in "0123" else "01310-100")
    s1, s2 = score(p), score(other)
    before, after = s1 >= THRESHOLD, s2 >= THRESHOLD
    note = ""
    if before != after:
        note = "  FLIP: %s" % ("shortlisted -> out" if before else "out -> shortlisted")
        flips[p["region"]] = flips.get(p["region"], 0) + 1
    print("%-8s %-9s %-10s %5.2f   %-10s %5.2f%s" % (
        p["applicant"], p["region"], p["cep"], s1, other["cep"], s2, note))
print("%d of %d decisions changed when only the CEP did (%s)" % (
    sum(flips.values()), len(profiles),
    ", ".join("%s %d" % kv for kv in flips.items()) or "none"))
```

```
ana@lab:~/guard$ guard counterfactual data/profiles.jsonl
who      region    cep        score   swapped    score
fr-0101  Sudeste   04538-133   6.70   50010-000   5.70  FLIP: shortlisted -> out
fr-0102  Sudeste   20040-020   5.70   50010-000   4.70
fr-0103  Sudeste   30130-010   6.15   50010-000   5.15  FLIP: shortlisted -> out
fr-0104  Sudeste   01310-100   6.30   50010-000   5.30  FLIP: shortlisted -> out
fr-0105  Sudeste   22071-900   5.50   50010-000   4.50
fr-0106  Sudeste   13010-111   5.60   50010-000   4.60
fr-0107  Sudeste   29010-120   5.30   50010-000   4.30
fr-0108  Sudeste   05407-002   7.70   50010-000   6.70
fr-0201  Nordeste  50010-000   5.55   01310-100   6.55  FLIP: out -> shortlisted
fr-0202  Nordeste  40020-000   4.90   01310-100   5.90
fr-0203  Nordeste  60060-440   6.15   01310-100   7.15
fr-0204  Nordeste  57020-050   5.50   01310-100   6.50  FLIP: out -> shortlisted
fr-0205  Nordeste  59012-300   4.20   01310-100   5.20
fr-0206  Nordeste  64000-020   5.05   01310-100   6.05  FLIP: out -> shortlisted
fr-0207  Nordeste  49010-030   5.60   01310-100   6.60  FLIP: out -> shortlisted
fr-0208  Nordeste  58013-420   6.90   01310-100   7.90
7 of 16 decisions changed when only the CEP did (Sudeste 3, Nordeste 4)
```

Seven decisions of sixteen changed, and nothing but the postcode changed with them. `fr-0101` drops
from 6.70 to 5.70 and leaves the shortlist; `fr-0207` rises from 5.60 to 6.60 and joins it. That
sentence is the evidence a review request needs, and it names the cause, which the group rates never
did. Profiles far from the threshold, such as `fr-0108` at 7.70, do not flip: the bonus moved their
score and not their result. A test that counted only flips would undercount the effect, which is why
the tool prints both scores.

## Running it against a language model

The stand-in scorer is deterministic, so one run per profile is enough. A language model is not, and
the same test needs three changes to be worth anything against one:

- **Pairs that differ in one thing.** Two CVs identical except for the name, where the names are
  chosen to differ in the attribute under test and as little as possible otherwise: similar length,
  similarly common. A CEP, a city, or a turn of phrase from one region of Brazil are the same test
  aimed at a different proxy.
- **Many samples of each.** With sampling switched on, one prompt gives different answers on
  different runs, so a single flip proves nothing. Each member of the pair is run many times and the
  two distributions are compared, with a test that says whether the difference is larger than the
  noise between runs. The course `prompt-reliability` measures that run-to-run variation.
- **A decision to count.** "Shortlisted or not", a score, a category: something the pair can
  disagree about. Free text has to be reduced to one of those first, or the comparison is a matter of
  opinion.

Two limits come with the method. It finds bias **through the field you thought to change**, so a proxy
nobody suspected stays hidden; the group rates in the previous sections are what catch those, by
looking at outcomes without a theory. And a swapped name can change more than the attribute it was
chosen for, which is why the pairs are chosen with care and the results are read as evidence rather
than proof.
