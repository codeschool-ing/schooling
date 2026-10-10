---
title: Cases from the traffic
version: 2
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
ana@dev:~/obs$ python harvest.py
56 different questions after redaction; doubted, of asked:
   8 of   8  Can I place an order by phone?
   7 of   7  right of withdrawal days
   6 of   6  can I read on kindle
   6 of   6  kindle ebooks
   6 of   6  This is Marta Seixas, order [order]: can I still return a book I got 3 weeks ago? My email is [email].
   5 of   8  How long is the statutory right of withdrawal?
   4 of   4  split payment in three
   4 of   4  pickup point how many days
   4 of   4  Hi, I'm Beatriz Costa ([email]). My order [order] has not arrived after 12 working days. Is it lost?
   4 of   4  Is there a student discount?
   4 of   5  Order [order] - I want to return it. Who pays for the return postage? Tiago Moura, [phone]
   3 of   7  when is shipping free
   3 of   3  This is Beatriz Costa, order [order]: can I still return a book I got 3 weeks ago? My email is [email].
   3 of   5  This is Joana Prado, order [order]: can I still return a book I got 3 weeks ago? My email is [email].
   3 of   3  physical shop porto alegre
   3 of   3  Do you have a shop in Porto Alegre where I can pick up books?
```

Three findings in sixteen lines, none of which the twenty-four cases could have shown:

- **The right of withdrawal and the Kindle are doubted every time they are asked**, in every wording:
  "right of withdrawal days" seven times of seven, "can I read on kindle" and "kindle ebooks" six of
  six. Lesson 11 found why for the Kindle: the model is given the right chunk and refuses. The set asks
  each once, in a full sentence.
- **Customers write in keywords.** "split payment in three", "pickup point how many days", "when is
  shipping free": short, lower-case, no verb. The set's questions are full sentences, and an assistant
  tuned on them is tuned on a way of asking customers mostly do not use.
- **The order messages are doubted more than the same question asked bare.** "Can I still return a
  book I got 3 weeks ago", wrapped in a name, an order number and an address, is doubted in all six of
  Marta's and three of Beatriz's. The set has no case with personal data in it, so it cannot see this
  failure at all.

And one warning, in the lines themselves: **the names survive.** Redaction by pattern takes out e-mail
addresses, telephone numbers and order numbers, and "Marta Seixas" has none of those shapes. Lesson 2
showed Presidio finding names with a language model; `harvest.py` does not use it, and a list of
candidates like this one is customers' data until somebody has gone through it.

## From candidate to case

A candidate becomes a case when a person writes what the right answer is. The course wrote eight from
the list above, keeping each question's wording and its shape. Save them as `data/eval-additions.jsonl`:

```json
{"id": "e25", "question": "right of withdrawal days", "gold": ["returns-policy:the-right-of-withdrawal"], "facts": ["seven days", "7 days"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08"}
{"id": "e26", "question": "can I read on kindle", "gold": ["ebooks-and-audiobooks:formats"], "facts": ["cannot open", "cannot be opened", "can't open"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08"}
{"id": "e27", "question": "split payment in three", "gold": ["payments-and-invoices:instalments"], "facts": ["three instalments", "3 instalments"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08"}
{"id": "e28", "question": "pickup point how many days", "gold": ["shipping-and-delivery:pickup-points"], "facts": ["ten days", "10 days"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08"}
{"id": "e29", "question": "This is Ana Teste, order MG-00000001: can I still return a book I got 3 weeks ago? My email is ana.teste@example.com.", "gold": ["returns-policy:the-return-window"], "facts": ["30 days"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08", "synthetic": ["Ana Teste", "MG-00000001", "ana.teste@example.com"]}
{"id": "e30", "question": "Hi, I'm Ana Teste (ana.teste@example.com). My order MG-00000002 has not arrived after 12 working days. Is it lost?", "gold": ["shipping-and-delivery:lost-parcels"], "facts": ["10 working days", "ten working days"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08", "synthetic": ["Ana Teste", "ana.teste@example.com", "MG-00000002"]}
{"id": "e31", "question": "Order MG-00000003 - I want to return it. Who pays for the return postage? Ana Teste, +55 11 5550-0101", "gold": ["returns-policy:how-to-start-a-return"], "facts": ["are free", "prepaid label"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08", "synthetic": ["MG-00000003", "Ana Teste", "+55 11 5550-0101"]}
{"id": "e32", "question": "when is shipping free", "gold": ["shipping-and-delivery:standard-delivery"], "facts": ["R$ 40"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08"}
```

```
ana@dev:~/obs$ wc -l data/eval.jsonl data/eval-additions.jsonl
  24 data/eval.jsonl
   8 data/eval-additions.jsonl
  32 total
ana@dev:~/obs$ grep e31 data/eval-additions.jsonl
{"id": "e31", "question": "Order MG-00000003 - I want to return it. Who pays for the return postage? Ana Teste, +55 11 5550-0101", "gold": ["returns-policy:how-to-start-a-return"], "facts": ["are free", "prepaid label"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08", "synthetic": ["MG-00000003", "Ana Teste", "+55 11 5550-0101"]}
```

**The wording is the customer's, and the data is not.** e29, e30 and e31 keep the shape that made the
order messages fail: a name, an order number, an address or a telephone around the question. That
shape is the point of those cases. Every value in them is invented for the test, and each case says so
in `synthetic`, so that the check in the section after next can tell a declared test value from a
customer's. The order numbers are all zeros and the telephone number is in a range kept for fiction.

**The facts and the gold come from the documents**, exactly as for the first twenty-four, and **each
case records where it came from** (`source`) and when it was added. A set grows for years, and "why is
this case here" is a question somebody will ask about every one of them.
