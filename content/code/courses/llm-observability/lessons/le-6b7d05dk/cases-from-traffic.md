---
title: Cases from the traffic
version: 1
---

The best source of new cases is the replies somebody already doubted, lesson 9's targeted sample.
`harvest.py` goes through the replayed week, redacts each question with lesson 2's patterns, groups the
ones that are now identical, and counts how many times each was asked and how many of those got a thumb
down or a refusal:

```python
"""harvest.py: candidate cases for the evaluation set: every question of the week somebody doubted,
redacted, grouped and counted. Doubted means a thumb down, or a refusal."""
import json
from collections import Counter

import checks
import redact

thumbs = {f["trace"]: f["value"] for f in map(json.loads, open("feedback.jsonl")) if f["kind"] == "thumbs"}
asked, doubted = Counter(), Counter()
for s in map(json.loads, open("spans.jsonl")):
    a = s["attributes"]
    if s["name"] != "ask" or a["app.feature"] == "summary":
        continue
    text = redact.redact(a["app.question"])
    asked[text] += 1
    doubted[text] += thumbs.get(s["trace"]) == "down" or checks.is_refusal(a["app.reply"])
print(f"{len(asked)} different questions after redaction; doubted, of asked:")
for text, n in doubted.most_common(16):
    print(f"{n:4} of {asked[text]:3}  {text}")
```

```
ana@lab:~/obs$ python harvest.py
59 different questions after redaction; doubted, of asked:
  53 of  53  what does next day delivery cost
  20 of  55  My parcel [order] still hasn't arrived, two weeks now. You can call me on [phone]. When is it considered lost?
  18 of  18  Order [order] - I want to return it. Who pays for the return postage? Tiago Moura, [phone]
  17 of  31  when is shipping free
  15 of  47  express shipping price
  15 of  15  Which carrier do you use in Portugal?
  14 of  14  Can I place an order by phone?
  14 of  14  Hi, I'm Joana Prado ([email]). My order [order] has not arrived after 12 working days. Is it lost?
  14 of  14  carrier portugal
  14 of  14  Order [order] - I want to return it. Who pays for the return postage? Joana Prado, [phone]
  13 of  13  pay in instalments
  12 of  12  Order [order] - I want to return it. Who pays for the return postage? Rafael Lima, [phone]
  12 of  12  order by telephone
  11 of  11  Hi, I'm Tiago Moura ([email]). My order [order] has not arrived after 12 working days. Is it lost?
  11 of  11  physical shop porto alegre
  11 of  60  return window for books
```

Three findings in sixteen lines, none of which the thirty cases could have shown:

- **"what does next day delivery cost" was doubted every one of its 53 times.** The set asks "How much
  is express delivery?", which gets an answer, if a wrong one (lesson 10 read it). Customers also say
  "next day", and the assistant does not connect the two. It is the most doubted question of the week.
- **Customers write in keywords.** "express shipping price", "when is shipping free", "carrier
  portugal": short, lower-case, no verb. The set's questions are full sentences, and an assistant tuned
  on them is tuned on a way of asking customers mostly do not use.
- **The order messages fail far more than the same question asked bare**, as lesson 5 traced: the name,
  the address and the order number pull the search away from the documents. The set has no case with
  personal data in it, so it cannot see this failure at all.

And one warning, in the lines themselves: **the names survive.** Redaction by pattern takes out e-mail
addresses, telephone numbers and order numbers, and "Tiago Moura" has none of those shapes. Lesson 2
showed Presidio finding names with a language model; harvest.py did not use it, and a list of candidates
like this one is customers' data until somebody has gone through it.

## From candidate to case

A candidate becomes a case when a person writes what the right answer is. The course wrote twelve, in
`data/eval-additions.jsonl`, keeping each question's wording and its shape:

```
ana@lab:~/obs$ wc -l data/eval.jsonl data/eval-additions.jsonl
  30 data/eval.jsonl
  12 data/eval-additions.jsonl
  42 total
ana@lab:~/obs$ grep e39 data/eval-additions.jsonl
{"id": "e39", "question": "Order MG-00000002 - I want to return it. Who pays for the return postage? Ana Teste, +55 11 5550-0101", "gold": [["returns-policy", "How to start a return"]], "facts": ["Returns are free"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-06", "synthetic": ["MG-00000002", "Ana Teste", "+55 11 5550-0101"]}
```

**The wording is the customer's, and the data is not.** e39 keeps the shape that made the order messages
fail, an order number, a name and a telephone number around the question, because that shape is the
point of the case. Every value in it is invented for the test, and the case says so in `synthetic`, so
that the check in the section after next can tell a declared test value from a customer's.

**The facts and the gold come from the documents**, exactly as for the first thirty, and **each case
records where it came from** (`source`) and when it was added. A set grows for years, and "why is this
case here" is a question somebody will ask about every one of them.
