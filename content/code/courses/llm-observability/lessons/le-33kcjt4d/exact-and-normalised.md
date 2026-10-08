---
title: Comparing with an expected answer
version: 1
---

An evaluation needs an **answer key**: questions, and for each one what a right reply contains. The
course writes one for the assistant here, twenty-four questions. Nineteen have **facts**, the words a
right reply must contain, one of them at least, and **gold** chunks, the ids of the chunks that hold
the answer, which lesson 11 uses. Five have neither, and their right reply is the refusal: four ask
about things the documents never mention, and `e20` asks about something only an internal document
answers, which the assistant must not show a customer. Save it as `data/eval.jsonl`:

```json
{"id": "e01", "question": "How many days do I have to return a printed book?", "gold": ["returns-policy:the-return-window"], "facts": ["30 days"]}
{"id": "e02", "question": "Who pays for the return postage?", "gold": ["returns-policy:how-to-start-a-return"], "facts": ["are free", "prepaid label"]}
{"id": "e03", "question": "How long after my return arrives will I get the refund?", "gold": ["returns-policy:refunds"], "facts": ["three working days", "3 working days"]}
{"id": "e04", "question": "Can I return a signed copy?", "gold": ["returns-policy:items-that-cannot-be-returned"], "facts": ["signed copies cannot", "cannot be returned", "can't be returned", "not be returned"]}
{"id": "e05", "question": "I downloaded an e-book yesterday. Can I still return it?", "gold": ["returns-policy:items-that-cannot-be-returned"], "facts": ["cannot be returned", "can't be returned", "not be returned", "cannot return"]}
{"id": "e06", "question": "How long does standard delivery take?", "gold": ["shipping-and-delivery:standard-delivery"], "facts": ["three to six working days", "3 to 6 working days"]}
{"id": "e07", "question": "Above what order value is standard delivery free?", "gold": ["shipping-and-delivery:standard-delivery"], "facts": ["R$ 40"]}
{"id": "e08", "question": "How much is express delivery?", "gold": ["shipping-and-delivery:express-delivery"], "facts": ["29.90"]}
{"id": "e09", "question": "When is a standard parcel considered lost?", "gold": ["shipping-and-delivery:lost-parcels"], "facts": ["10 working days", "ten working days"]}
{"id": "e10", "question": "How long does a pickup point keep my parcel?", "gold": ["shipping-and-delivery:pickup-points"], "facts": ["ten days", "10 days"]}
{"id": "e11", "question": "On how many devices can I read my e-books?", "gold": ["ebooks-and-audiobooks:devices"], "facts": ["six devices", "6 devices"]}
{"id": "e12", "question": "Will my e-books open on a Kindle?", "gold": ["ebooks-and-audiobooks:formats"], "facts": ["cannot open", "cannot be opened", "can't open"]}
{"id": "e13", "question": "Can I listen to an audiobook without an internet connection?", "gold": ["ebooks-and-audiobooks:audiobooks"], "facts": ["offline"]}
{"id": "e14", "question": "Can I pay in instalments?", "gold": ["payments-and-invoices:instalments"], "facts": ["three instalments", "3 instalments"]}
{"id": "e15", "question": "When does an order paid by bank slip ship?", "gold": ["payments-and-invoices:how-you-can-pay"], "facts": ["two working days", "2 working days"]}
{"id": "e16", "question": "When do I get the invoice for my order?", "gold": ["payments-and-invoices:invoices"], "facts": ["when the order ships", "when your order ships", "when it ships"]}
{"id": "e17", "question": "How long is a gift card valid?", "gold": ["gift-cards:validity"], "facts": ["two years", "2 years"]}
{"id": "e18", "question": "What happens if my order costs more than my gift card holds?", "gold": ["gift-cards:using-a-gift-card"], "facts": ["the rest"]}
{"id": "e19", "question": "How long is the statutory right of withdrawal?", "gold": ["returns-policy:the-right-of-withdrawal"], "facts": ["seven days", "7 days"]}
{"id": "e20", "question": "What is the largest refund that can be paid without anybody approving it?", "gold": [], "facts": []}
{"id": "e21", "question": "Do you have a shop in Porto Alegre where I can pick up books?", "gold": [], "facts": []}
{"id": "e22", "question": "Can I place an order by phone?", "gold": [], "facts": []}
{"id": "e23", "question": "Which carrier do you use in Portugal?", "gold": [], "facts": []}
{"id": "e24", "question": "Is there a student discount?", "gold": [], "facts": []}
```

Grading needs replies to grade. `evalrun.py` sends every question of the set through the assistant and
keeps what came back as a **run**, with the sources each reply was given:

```python
"""evalrun.py: every question of an evaluation set through the assistant, kept as a run.

    python evalrun.py NAME [--set data/eval.jsonl] [--at 2026-10-05T12:00:00] [--release R]

A run is runs/NAME.jsonl: one line per question with its id, the question, the
reply, the release that answered, the sources the model was shown (their ids
and their text) and the trace id. Later lessons grade runs and compare them;
they never call the assistant themselves, so a run can be graded again, by
another method, without asking the model twice.
"""
import argparse
import json
import os

import assistant
import telemetry

p = argparse.ArgumentParser()
p.add_argument("name")
p.add_argument("--set", default="data/eval.jsonl")
p.add_argument("--at", default="2026-10-05T12:00:00", help="the moment whose release answers")
p.add_argument("--release", help="answer with this release, whatever the moment")
a = p.parse_args()

if a.release:   # a release not yet in force: answer as if it were
    assistant.RELEASES = {a.release: dict(assistant.RELEASES[a.release], **{"from": "0000"})}
telemetry.setup("eval-spans.jsonl", service="evalrun")
os.makedirs("runs", exist_ok=True)
release, _ = assistant.release_at(a.at)
n = 0
with open(f"runs/{a.name}.jsonl", "w") as out:
    for case in map(json.loads, open(a.set)):
        reply, sources, trace = assistant.ask(case["question"], user="evalrun", feature="help", at=a.at)
        out.write(json.dumps({"id": case["id"], "question": case["question"], "reply": reply, "release": release,
                              "sources": [{"id": c["id"], "text": c["text"]} for c, _ in sources],
                              "trace": trace}, ensure_ascii=False) + "\n")
        n += 1
print(f"runs/{a.name}.jsonl: {n} questions, release {release}")
```

A run is kept so that it can be graded again, by another method, without asking the model twice;
lessons 9 to 12 grade this same file. `--at` picks which release answers, by the moment it would have
been in force, and the default is Monday 5 October, under the release that raised the floor:

```
ana@lab:~/obs$ python evalrun.py current
runs/current.jsonl: 30 questions, release 2026.10.1
ana@lab:~/obs$ head -c 600 runs/current.jsonl; echo
{"id": "e01", "question": "How many days do I have to return a printed book?", "reply": "You have 30 days from delivery to return a printed book in the condition you received it. [1] Our returns and refunds policy extends this period to 30 days for printed books. [3] A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return. [2]", "release": "2026.10.1", "sources": [{"id": "returns-policy:fbe325d9ffef", "text": "You have 30 days from delivery to return a printed book in the condi
```

## The comparison, and how loose it is

`facts.py` grades a run two ways: **exact**, where a fact must appear in the reply as it was written,
and **normalised**, where case, punctuation and runs of spaces are ignored on both sides first.

```python
"""facts.py: a run graded against the facts of the evaluation set, two ways."""
import json
import re
import sys

REFUSAL = "I could not find that in our documents."
cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}


def exact(reply, facts):
    return reply == REFUSAL if not facts else any(f in reply for f in facts)


def normalised(reply, facts):
    squash = lambda t: re.sub(r"\s+", " ", re.sub(r"[^\w\s.]", " ", t.lower())).strip()
    return reply == REFUSAL if not facts else any(squash(f) in squash(reply) for f in facts)


if __name__ == "__main__":
    run = [json.loads(line) for line in open(f"runs/{sys.argv[1]}.jsonl")]
    for name, grade in (("exact", exact), ("normalised", normalised)):
        right = [r["id"] for r in run if grade(r["reply"], cases[r["id"]]["facts"])]
        print(f"{name:10} {len(right)}/{len(run)} right")
    wrong = [r for r in run if not normalised(r["reply"], cases[r["id"]]["facts"])]
    for r in wrong:
        print(f"  {r['id']}  {r['question'][:52]:52}  {r['reply'][:60]}")
```

```
ana@lab:~/obs$ python facts.py current
exact      16/30 right
normalised 16/30 right
  e02  Who pays for the return postage?                      I could not find that in our documents.
  e04  Can I return a signed copy?                           I could not find that in our documents.
  e05  My e-book was downloaded yesterday, can I still get   An e-book can be refunded within 14 days of purchase if you 
  e06  How much is express delivery?                         Express delivery is not free at any order value. [1]
  e07  Above what order value is standard delivery free?     Express delivery is not free at any order value. [1]
  e14  Can I pay in instalments?                             I could not find that in our documents.
  e17  When is the contract of sale formed?                  I could not find that in our documents.
  e19  What commission does Marginalia take from a marketpl  Marginalia is an online bookshop operated at marginalia.exam
  e20  How often are sellers paid?                           I could not find that in our documents.
  e21  What does error E-4102 mean in the affiliate API?     I could not find that in our documents.
  e22  What commission do affiliates earn on e-books?        I could not find that in our documents.
  e24  Do you store my IP address?                           I could not find that in our documents.
  e25  What is the most a support agent can refund without   I could not find that in our documents.
  e26  What must I check before changing a customer's order  I could not find that in our documents.
```

**Sixteen of thirty**, either way. Under this release, ten of the fourteen wrong replies are the refusal
to a question the documents answer, which lesson 5 would have predicted. Two are the express delivery sentence from lesson 1, now answering the question about the price of express delivery too.

The two comparisons agree here because extract-1 copies sentences, so a right reply contains the fact
as the document wrote it. The difference shows on replies that are worded differently. `normalise.py`
takes three, **written by the course for this purpose**, against the fact *30 days from delivery*:

```python
"""normalise.py: three replies the course wrote, against one fact, compared two ways."""
from facts import exact, normalised

fact = ["30 days from delivery"]
for reply in ["You have 30 days from delivery to return a printed book. [1]",
              "You have 30 days  from Delivery to return it. [1]",
              "You have thirty days after delivery to return it. [1]"]:
    print(f"exact {exact(reply, fact)!s:5}  normalised {normalised(reply, fact)!s:5}  {reply}")
```

```
ana@lab:~/obs$ python normalise.py
exact True   normalised True   You have 30 days from delivery to return a printed book. [1]
exact False  normalised True   You have 30 days  from Delivery to return it. [1]
exact False  normalised False  You have thirty days after delivery to return it. [1]
```

The second reply, with a double space and a capital, fails the exact comparison and passes the
normalised one. The third says the same thing in other words and fails both. **No normalisation
reaches a paraphrase.** A comparison can be loosened only by things that do not change the meaning:
case, spacing, punctuation, perhaps number words. Each loosening is a decision, made for this set and
written in the code where a reviewer can see it, exactly as a cloze declares `ignore_case`.

That makes deterministic comparison right for the facts that have one form: a price, a number of days,
an error code, an order status, a word from a fixed list. And wrong for anything a person would say
in their own words, which is most of what an assistant says. Lesson 9 is about the rest.
