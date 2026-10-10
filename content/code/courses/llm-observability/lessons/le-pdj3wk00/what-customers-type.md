---
title: What customers type
version: 2
---

Before deciding what to remove, count what arrives, and for that the course needs a week of it.
Marginalia does not exist, so neither do its customers: their week is written by `traffic.py`, from
phrasings the course chose, with a fixed seed so that your week is the same as the lesson's. Save it
in `~/obs`:

```python
"""traffic.py: writes data/traffic.jsonl, a week of people using Marginalia's help assistant.

THE TRAFFIC IS GENERATED, NOT RECORDED, and nothing about it is measured from a
real shop. It is drawn with a fixed seed from the phrasings below, which were
written by the course: twelve topics the documents answer, with the facts a
right answer to each contains, four questions the documents do not answer,
messages about an order that carry a name, an e-mail address or a telephone
number, and requests from the support team to summarise a conversation. The
names, addresses and numbers are invented, the domains are reserved for
examples, and the telephone numbers are not in use.

Each line is one request as it ARRIVES: when, who, in which session, through
which feature, and the words. What the assistant answered, and what the
person did next, are not in this file: replay.py produces them by running
the assistant, and the simulated person's reaction is decided there.

    python traffic.py data/traffic.jsonl

It also writes data/topics.json beside it: each topic's phrasings and facts,
which replay.py reads to decide whether a reply was right.
"""
import json
import os
import random
import sys
from datetime import datetime, timedelta

# (phrasings, facts): a right answer contains one of the facts, in any case;
# [] means the documents do not answer it, and the right answer is the refusal.
TOPICS = [
    (["How many days do I have to return a printed book?", "how long do I have to return a book",
      "return window for books", "Can I still return a book I got 3 weeks ago?"], ["30 days"]),
    (["How much is express delivery?", "express shipping price", "what does next day delivery cost"],
     ["29.90"]),
    (["How long after my return arrives will I get the refund?", "when do I get my refund",
      "how long does a refund take"], ["three working days", "3 working days"]),
    (["Above what order value is standard delivery free?", "free delivery threshold", "when is shipping free"],
     ["R$ 40"]),
    (["On how many devices can I read my e-books?", "how many devices for ebooks", "ebook device limit"],
     ["six devices", "6 devices"]),
    (["How long is a gift card valid?", "gift card expiry", "do gift cards expire"], ["two years", "2 years"]),
    (["Will my e-books open on a Kindle?", "kindle ebooks", "can I read on kindle"],
     ["cannot open", "cannot be opened", "can't open"]),
    (["Can I pay in instalments?", "pay in instalments", "split payment in three"], ["three instalments", "3 instalments"]),
    (["When is a standard parcel considered lost?", "my parcel is lost", "parcel not arrived after two weeks"],
     ["10 working days", "ten working days"]),
    (["Who pays for the return postage?", "is returning free", "return shipping cost"], ["are free", "prepaid label"]),
    (["How long is the statutory right of withdrawal?", "right of withdrawal days"],
     ["seven days", "7 days"]),
    (["How long does a pickup point keep my parcel?", "pickup point how many days"], ["ten days", "10 days"]),
    (["Can I place an order by phone?", "order by telephone"], []),
    (["Is there a student discount?", "student discount"], []),
    (["Which carrier do you use in Portugal?", "carrier portugal"], []),
    (["Do you have a shop in Porto Alegre where I can pick up books?", "physical shop porto alegre"], []),
]

PEOPLE = [("Joana Prado", "joana.prado@example.com", "+55 11 5550-0142"),
          ("Rafael Lima", "rafael.lima@example.org", "+55 21 5550-0187"),
          ("Beatriz Costa", "bia.costa@example.net", "+55 51 5550-0119"),
          ("Tiago Moura", "tiago.moura@example.com", "+55 31 5550-0163"),
          ("Marta Seixas", "marta.s@example.org", "+351 21 555 0174")]
ORDER = [
    "Hi, I'm {name} ({email}). My order {order} has not arrived after 12 working days. Is it lost?",
    "My parcel {order} still hasn't arrived, two weeks now. You can call me on {phone}. When is it considered lost?",
    "This is {name}, order {order}: can I still return a book I got 3 weeks ago? My email is {email}.",
    "Order {order} - I want to return it. Who pays for the return postage? {name}, {phone}",
]
ORDER_TOPIC = [8, 8, 0, 9]

CONVERSATIONS = [
    ["Hi, my name is Beatriz Costa and I have a problem with order MG-20481937.",
     "The order had two books. Persuasion arrived with water damage on the cover.",
     "The other one, Middlemarch, is fine and I want to keep it.",
     "Can you send a new copy of Persuasion instead of a refund?"],
    ["Hello, this is Rafael Lima. My order MG-31770254 has not arrived.",
     "It was sent by standard delivery and the tracking has not changed for twelve working days.",
     "I would prefer a refund rather than waiting for a new parcel."],
]

# How many requests arrive in each hour of the day, relative to the busiest.
HOURLY = [1, 1, 1, 1, 1, 2, 3, 6, 9, 10, 10, 9, 8, 9, 10, 10, 9, 8, 8, 9, 9, 7, 4, 2]


def main(out, seed=21):
    rng = random.Random(seed)
    users = [f"u{i:03d}" for i in range(1, 61)]
    start = datetime(2026, 9, 28, 0, 0)
    rows = []
    for day in range(7):
        weekend = day >= 5
        for hour in range(24):
            n = (HOURLY[hour] * (2 if weekend else 3) + rng.randrange(0, 10)) // 10
            for _ in range(n):
                at = start + timedelta(days=day, hours=hour, seconds=rng.randrange(0, 3600))
                rows.append(at)
    rows.sort()
    with open(os.path.join(os.path.dirname(out), "topics.json"), "w") as f:
        json.dump([{"topic": i + 1, "phrasings": p, "facts": facts} for i, (p, facts) in enumerate(TOPICS)],
                  f, indent=1)
    sessions = 0
    with open(out, "w") as f:
        for i, at in enumerate(rows, 1):
            sessions += 1
            r = rng.random()
            row = {"id": f"r{i:03d}", "at": at.strftime("%Y-%m-%dT%H:%M:%S"), "user": rng.choice(users),
                   "session": f"s{sessions:03d}"}
            if r < 0.72:
                weights = [1 / (k + 1) ** 0.8 for k in range(len(TOPICS))]
                t = rng.choices(range(len(TOPICS)), weights)[0]
                row.update(feature="help", topic=t + 1, text=rng.choice(TOPICS[t][0]))
            elif r < 0.90:
                k = rng.randrange(len(ORDER))
                name, email, phone = rng.choice(PEOPLE)
                order = f"MG-{rng.randrange(10000000, 99999999)}"
                row.update(feature="order", topic=ORDER_TOPIC[k] + 1,
                           text=ORDER[k].format(name=name, email=email, phone=phone, order=order))
            else:
                c = rng.choice(CONVERSATIONS)
                row.update(feature="summary", topic=None, user="staff-" + rng.choice(["ana", "caio", "lia"]),
                           text="Summarise this conversation in at most 40 words.\n" + "\n".join(c))
            f.write(json.dumps(row, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main(sys.argv[1])
```

```
ana@dev:~/obs$ python traffic.py data/traffic.jsonl
ana@dev:~/obs$ wc -l data/traffic.jsonl
284 data/traffic.jsonl
```

284 requests, one per line, each with when it arrived, who sent it, in which session, through which
feature and the words. `data/topics.json` beside it keeps each topic's phrasings and the facts a
right answer contains, which lesson 3 needs. Every name, address and number in the file is invented,
under domains reserved for examples.

Now count. `scan.py` runs every request of the week through
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
ana@dev:~/obs$ python scan.py
feature  requests  with something to redact
summary         36        36
order           56        56
help           192         0
found: {'order': 92, 'phone': 26, 'email': 30}
```

Three features, three different answers. **None of the 192 `help` requests** carries an address, a
number or an order: they are questions about policy, the same few dozen phrasings over and over.
**Every one of the 56 `order` requests** does, because a customer asking about their own order
identifies the order and very often themselves. And **every one of the 36 `summary` requests**
does, because a support conversation being summarised is full of order numbers.

The traffic is generated, and real proportions will differ. The shape will not: personal data is
not spread evenly over a product. It concentrates in the features that are about a particular
person, and a policy that treats every trace the same either over-protects the questions about gift
cards or under-protects the questions about somebody's lost parcel.

```
ana@dev:~/obs$ grep -m 3 "\"order\"" data/traffic.jsonl
{"id": "r002", "at": "2026-09-28T06:55:08", "user": "u024", "session": "s002", "feature": "order", "topic": 9, "text": "My parcel MG-86609249 still hasn't arrived, two weeks now. You can call me on +55 21 5550-0187. When is it considered lost?"}
{"id": "r003", "at": "2026-09-28T07:12:31", "user": "u053", "session": "s003", "feature": "order", "topic": 10, "text": "Order MG-16598027 - I want to return it. Who pays for the return postage? Marta Seixas, +351 21 555 0174"}
{"id": "r014", "at": "2026-09-28T11:02:53", "user": "u024", "session": "s014", "feature": "order", "topic": 1, "text": "This is Beatriz Costa, order MG-17886675: can I still return a book I got 3 weeks ago? My email is bia.costa@example.net."}
```

Read them. A telephone number in the first, a name and a telephone number in the second, a name and
an e-mail address in the third, each beside an order number, and each in a sentence that a model,
and therefore a trace, receives whole. Count once more in that output what `scan.py` cannot: **the
names**. Marta Seixas, Beatriz Costa.
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
