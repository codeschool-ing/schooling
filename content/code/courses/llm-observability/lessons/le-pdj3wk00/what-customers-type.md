---
title: What customers type
version: 1
---

Before deciding what to remove, count what arrives. `scan.py` runs every request of the week through
`redact.found()`, the counting half of the redaction this lesson builds, and reports how many in each
feature carry something it would take out:

```python
"""scan.py: a week of what customers typed, and how much of it redact() would take out."""
import json
from collections import Counter

import redact

rows = [json.loads(line) for line in open("data/traffic.jsonl")]
total, hit, found = Counter(), Counter(), Counter()
for r in rows:
    total[r["feature"]] += 1
    f = redact.found(r["text"])
    hit[r["feature"]] += bool(f)
    found.update(f)
print("feature  requests  with something to redact")
for feature in total:
    print(f"{feature:8} {total[feature]:9} {hit[feature]:9}")
print("found:", dict(found))
```

```
ana@lab:~/obs$ python scan.py
feature  requests  with something to redact
help           786         0
summary        124       124
order          217       217
found: {'order': 341, 'email': 107, 'phone': 110}
```

Three features, three different answers. **None of the 786 `help` requests** carries an address, a
number or an order: they are questions about policy, the same few dozen phrasings over and over.
**Every one of the 217 `order` requests** does, because a customer asking about their own order
identifies the order and very often themselves. And **every one of the 124 `summary` requests**
does, because a support conversation being summarised is full of order numbers.

The traffic is generated, and real proportions will differ. The shape will not: personal data is
not spread evenly over a product. It concentrates in the features that are about a particular
person, and a policy that treats every trace the same either over-protects the questions about gift
cards or under-protects the questions about somebody's lost parcel.

```
ana@lab:~/obs$ grep -m 3 "\"order\"" data/traffic.jsonl
{"id": "r0007", "at": "2026-09-28T03:55:08", "user": "u023", "session": "s0007", "feature": "order", "topic": 1, "text": "This is Marta Seixas, order MG-80660491: can I still return a book I got 3 weeks ago? My email is marta.s@example.org."}
{"id": "r0008", "at": "2026-09-28T04:34:28", "user": "u087", "session": "s0008", "feature": "order", "topic": 9, "text": "Hi, I'm Joana Prado (joana.prado@example.com). My order MG-16887804 has not arrived after 12 working days. Is it lost?"}
{"id": "r0009", "at": "2026-09-28T05:00:13", "user": "u062", "session": "s0009", "feature": "order", "topic": 9, "text": "My parcel MG-63273039 still hasn't arrived, two weeks now. You can call me on +55 21 5550-0187. When is it considered lost?"}
```

Read the second and the third. A name and an e-mail address in one, a telephone number in the other,
each beside an order number, and each in a sentence that a model, and therefore a trace, receives
whole. Count once more in that output what `scan.py` cannot: **the names**. Marta Seixas, Joana Prado.
A pattern finds an address because addresses have a shape. A name has none, and the section on what
patterns miss comes back to it.

## Where the text is, once it arrives

Following one order question through the assistant, its words reach:

- the `app.question` attribute on the root span, which the assistant writes;
- the prompt sent to the provider, which the provider's own terms then govern;
- any span an instrumentation library writes for the call, which lesson 1 showed keeps the whole
  prompt by default;
- the reply, if the model repeats any of it, and then the `app.reply` attribute;
- and wherever the spans go next: the file, a tracing service, its backups.

The next two sections deal with the first and the third. The provider's side is a question of contract, which `ai-dev`
lesson 11 and `ai-models` lesson 2 take up, and no trace can fix it.
