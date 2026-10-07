---
title: Bias arrives with the data, and leaving out a column does not stop it
version: 2
---

The first fix most teams reach for is to delete the sensitive column: if the system never sees
gender, race or where somebody comes from, the reasoning goes, it cannot discriminate on them.
**A system can use whatever correlates with the deleted column**, and in real data nearly everything
correlates with something. This section shows it happening in three numbers.

Tarefa's shortlist feature ranks the freelancers who apply to a job and puts the best at the top of
what the client sees. The version in this lesson reads four fields from each profile. Sixteen
profiles, written by the course for people it invented:

```sh
cat > ~/guard/data/profiles.jsonl <<'EOF'
{"applicant": "fr-0101", "region": "Sudeste", "cep": "04538-133", "rating": 4.6, "jobs": 22}
{"applicant": "fr-0102", "region": "Sudeste", "cep": "20040-020", "rating": 4.2, "jobs": 10}
{"applicant": "fr-0103", "region": "Sudeste", "cep": "30130-010", "rating": 4.9, "jobs": 5}
{"applicant": "fr-0104", "region": "Sudeste", "cep": "01310-100", "rating": 3.8, "jobs": 30}
{"applicant": "fr-0105", "region": "Sudeste", "cep": "22071-900", "rating": 4.4, "jobs": 2}
{"applicant": "fr-0106", "region": "Sudeste", "cep": "13010-111", "rating": 4.0, "jobs": 12}
{"applicant": "fr-0107", "region": "Sudeste", "cep": "29010-120", "rating": 3.9, "jobs": 8}
{"applicant": "fr-0108", "region": "Sudeste", "cep": "05407-002", "rating": 4.7, "jobs": 40}
{"applicant": "fr-0201", "region": "Nordeste", "cep": "50010-000", "rating": 4.8, "jobs": 15}
{"applicant": "fr-0202", "region": "Nordeste", "cep": "40020-000", "rating": 4.3, "jobs": 12}
{"applicant": "fr-0203", "region": "Nordeste", "cep": "60060-440", "rating": 4.9, "jobs": 25}
{"applicant": "fr-0204", "region": "Nordeste", "cep": "57020-050", "rating": 4.5, "jobs": 20}
{"applicant": "fr-0205", "region": "Nordeste", "cep": "59012-300", "rating": 3.9, "jobs": 6}
{"applicant": "fr-0206", "region": "Nordeste", "cep": "64000-020", "rating": 4.6, "jobs": 9}
{"applicant": "fr-0207", "region": "Nordeste", "cep": "49010-030", "rating": 4.1, "jobs": 30}
{"applicant": "fr-0208", "region": "Nordeste", "cep": "58013-420", "rating": 4.7, "jobs": 44}
EOF
```

```
ana@lab:~/guard$ head -4 data/profiles.jsonl
{"applicant": "fr-0101", "region": "Sudeste", "cep": "04538-133", "rating": 4.6, "jobs": 22}
{"applicant": "fr-0102", "region": "Sudeste", "cep": "20040-020", "rating": 4.2, "jobs": 10}
{"applicant": "fr-0103", "region": "Sudeste", "cep": "30130-010", "rating": 4.9, "jobs": 5}
{"applicant": "fr-0104", "region": "Sudeste", "cep": "01310-100", "rating": 3.8, "jobs": 30}
```

The `region` field is in the file so that this lesson can measure by it. The scorer never reads it.
Save it as `~/guard/tools/standin.py`:

```python
# standin.py: THE STAND-IN SCORER. It is not a model and it learned nothing.
#
# Four lines of arithmetic, written by the course to behave the way a model
# trained on Tarefa's past hires plausibly would: a bonus for a CEP that
# starts with 0, 1, 2 or 3, the postcodes of São Paulo, Rio de Janeiro,
# Espírito Santo and Minas Gerais. It never reads the `region` field. score.py
# and counterfactual.py import it; it prints nothing on its own.
THRESHOLD = 6.0


def score(profile):
    s = 1.0 * profile["rating"] + 0.05 * profile["jobs"]
    if profile["cep"][0] in "0123":
        s += 1.0
    return round(s, 2)
```

**This is not a model, and the course wrote it on purpose.** It stands in for a model trained on
Tarefa's past hires. Most of Tarefa's clients are in the Southeast and have mostly hired people near
them, so a model fitted to who was hired learns that a Southeastern postcode goes with being hired.
The stand-in states the result in one line: a bonus for a CEP that starts with 0, 1, 2 or 3, which
covers São Paulo, Rio de Janeiro, Espírito Santo and Minas Gerais. A real model would not write it
down where anybody could read it, which is why the rest of this lesson measures instead of reading
code.

The program that runs it over a file of profiles is `~/guard/tools/score.py`:

```python
# score.py: the stand-in scorer over a file of profiles.
#
#   guard score FILE
#
# FILE has one profile per line, as JSON. Every profile scoring at least the
# threshold is shortlisted.
import json
import sys

from standin import THRESHOLD, score

with open(sys.argv[1], encoding="utf-8") as f:
    profiles = [json.loads(line) for line in f if line.strip()]

print("%-8s %-9s %-10s %6s %4s  %5s  %s" % (
    "who", "region", "cep", "rating", "jobs", "score", "shortlisted"))
for p in profiles:
    s = score(p)
    print("%-8s %-9s %-10s %6.1f %4d  %5.2f  %s" % (
        p["applicant"], p["region"], p["cep"], p["rating"], p["jobs"], s,
        "yes" if s >= THRESHOLD else "no"))
print("threshold %.1f" % THRESHOLD)
```

```
ana@lab:~/guard$ guard score data/profiles.jsonl
who      region    cep        rating jobs  score  shortlisted
fr-0101  Sudeste   04538-133     4.6   22   6.70  yes
fr-0102  Sudeste   20040-020     4.2   10   5.70  no
fr-0103  Sudeste   30130-010     4.9    5   6.15  yes
fr-0104  Sudeste   01310-100     3.8   30   6.30  yes
fr-0105  Sudeste   22071-900     4.4    2   5.50  no
fr-0106  Sudeste   13010-111     4.0   12   5.60  no
fr-0107  Sudeste   29010-120     3.9    8   5.30  no
fr-0108  Sudeste   05407-002     4.7   40   7.70  yes
fr-0201  Nordeste  50010-000     4.8   15   5.55  no
fr-0202  Nordeste  40020-000     4.3   12   4.90  no
fr-0203  Nordeste  60060-440     4.9   25   6.15  yes
fr-0204  Nordeste  57020-050     4.5   20   5.50  no
fr-0205  Nordeste  59012-300     3.9    6   4.20  no
fr-0206  Nordeste  64000-020     4.6    9   5.05  no
fr-0207  Nordeste  49010-030     4.1   30   5.60  no
fr-0208  Nordeste  58013-420     4.7   44   6.90  yes
threshold 6.0
```

The bonus is worth a full point, and the threshold is 6.0. `fr-0201`, in Recife, has a 4.8 rating
and 15 jobs and scores 5.55. `fr-0103`, in Belo Horizonte, has 4.9 and 5 jobs and scores 6.15. Four
Southeastern profiles of eight are shortlisted, and two Northeastern ones of eight.

## Four ways it gets in

The CEP is one route. A model meets four, and most real cases involve more than one:

| source | what it means | at Tarefa |
|---|---|---|
| **historical** | the labels record past decisions, including their prejudice | "was hired" is what the past clients chose, near them |
| **proxy** | a field that stands in for a protected one | the CEP carries the region; a name carries gender, often region and race |
| **representation** | a group with few examples is learned badly and measured worse | 12 applicants from the North, against 200 from the Southeast |
| **measurement** | the label itself is unevenly accurate across groups | client ratings, which feed `rating`, can carry the client's prejudice too |

A language model brings all four with it before anybody fine-tunes it: it learned from text written
by people, with their associations, and it reads names, dialects and addresses in every prompt. When
a prompt asks a model to rank CVs or to summarise a complaint, those associations are in play
whether or not anybody asked for them.

## Why this belongs in a security course

A biased decision harms people in the same way a breach does, and it carries legal exposure the same
way. In Brazil, the Constitution makes promoting the good of all *without prejudice of origin, race,
sex, colour or age* a fundamental objective (art. 3, IV). The LGPD lists **non-discrimination** among
its principles (art. 6, IX), and art. 20 gives anybody affected by a decision made solely by automated
processing the right to ask for it to be reviewed and to be told the criteria it used. A shortlist
that decides who a client sees is that kind of decision. *"We never gave it the region"* is not an
answer to a review request when the CEP did the work, and the next sections are how you find that
out before somebody asks.
