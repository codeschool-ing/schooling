---
title: A chain of filters, each one named in its verdict
version: 2
---

Several lessons of this course each look closely at one check: personal data in lesson 11, moderation
in lesson 6, schemas and host allowlists in lesson 9. The temptation is to pick the best one and rely
on it. **Every one of
them has a blind spot that another covers**, and the practical defence is to put them in a row so that a
reply reaches the client only after all of them have passed it. This is usually called defence in
depth, and the only new thing it needs is an order and a record of which layer decided.

`guard filter` runs four layers over a reply, in this order: personal data and secrets, the canary
marker of the last section, moderation at 0.5, and the host allowlist. Three of the layers are programs
of their own, and this lesson is the first to use them, so it gives you all three now. You do not need
to read the first two closely yet: lesson 11 is about how `detect.py` decides, and lesson 6 measures
`moderation.py`.

`~/guard/tools/detect.py` finds personal data and secrets by their shape and, where they have one,
their check digits:

```python
# detect.py: what counts as personal data or a secret in free text.
#
# Five detectors, each a pattern for the SHAPE and, where the thing has one, a
# check for the ARITHMETIC: a CPF carries two check digits and a card number
# carries a Luhn digit, so eleven digits that fail the check are probably an
# order number and are left alone. strict=True drops the arithmetic and
# accepts every shape. filter.py imports it here; lesson 11 is about how it
# decides, and what it cannot see: a name, an address, anything in words.
import re

EMAIL = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+")
CPF = re.compile(r"(?<!\d)\d{3}\.?\d{3}\.?\d{3}-?\d{2}(?!\d)")
CARD = re.compile(r"(?<!\d)\d(?:[ -]?\d){12,18}(?!\d)")
PHONE = re.compile(r"(?<![\d+])(?:\+55\s?)?\(?\d{2}\)?\s?9\d{4}-?\d{4}(?!\d)")
SECRET = re.compile(r"\b(?:sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16})\b")


def digits(s):
    return [int(c) for c in s if c.isdigit()]


def cpf_ok(s):
    d = digits(s)
    if len(d) != 11 or len(set(d)) == 1:
        return False
    for n in (9, 10):
        total = sum(x * w for x, w in zip(d[:n], range(n + 1, 1, -1)))
        if (total * 10) % 11 % 10 != d[n]:
            return False
    return True


def luhn_ok(s):
    total = 0
    for i, x in enumerate(reversed(digits(s))):
        if i % 2:
            x *= 2
            if x > 9:
                x -= 9
        total += x
    return total % 10 == 0


# The shapes overlap: a phone with +55 in front has thirteen digits, which is
# a short card number, and a card number has eleven digits inside it that look
# like a CPF. Whatever is first claims its characters, and the later rules do
# not look at them again; the phone goes first of the three as the narrowest.
RULES = [
    ("secret", SECRET, None),
    ("email", EMAIL, None),
    ("phone", PHONE, None),
    ("card", CARD, luhn_ok),
    ("cpf", CPF, cpf_ok),
]
KINDS = [name for name, _, _ in RULES]


def find(text, strict=False):
    """Every match as (kind, start, end, accepted), in the order of the text.
    accepted is False for a shape whose check digits are wrong."""
    taken, rejected = [], []
    for kind, pattern, check in RULES:
        for m in pattern.finditer(text):
            a, b = m.span()
            if any(a < y and x < b for _, x, y, _ in taken):
                continue
            if strict or check is None or check(m.group()):
                taken.append((kind, a, b, True))
            else:
                rejected.append((kind, a, b, False))
    rejected = [r for r in rejected
                if not any(r[1] < y and x < r[2] for _, x, y, _ in taken)]
    return sorted(taken + rejected, key=lambda f: f[1])


def redact(text, strict=False):
    """The text with every accepted match replaced by [KIND]."""
    out, at = [], 0
    for kind, a, b, accepted in find(text, strict):
        if accepted:
            out.append(text[at:a] + "[" + kind.upper() + "]")
            at = b
    return "".join(out) + text[at:]
```

`~/guard/tools/moderation.py` is **a stand-in for a moderation endpoint, not a model**: a word list
with weights the course chose, answering in the shape a real endpoint answers in.

```python
# moderation.py: THE STAND-IN MODERATION ENDPOINT. It is not a model.
#
# A list of English words and phrases per category, each with a weight the
# course chose, combined so that the score behaves like one: between 0 and 1,
# higher with more and stronger matches. It answers in the shape a moderation
# endpoint answers in, a score per category, so that the code reading one can
# be written and measured. Its failures are a word list's, left in on purpose:
# it cannot tell an insult from a report of one, it does not read sarcasm, it
# misses a word spelt with a digit, and it knows no Portuguese at all.
import re

TERMS = {
    "harassment": {"idiot": .9, "moron": .9, "stupid": .8, "loser": .8, "worthless": .7,
                   "pathetic": .7, "dumb": .7, "clown": .6, "garbage": .6, "shut up": .6,
                   "useless": .5, "get lost": .5, "lazy": .4, "clueless": .4, "quit": .3,
                   "ashamed": .3, "amateur": .3},
    "threat": {"know where you live": .9, "watch your back": .8, "going to find you": .8,
               "get hurt": .8, "regret it": .7, "regret": .4},
    "spam": {"buy reviews": .9, "free followers": .9, "click here": .6, "prize": .6,
             "limited offer": .6, "guaranteed": .5, "crypto": .5, "work from home": .5,
             "link in bio": .5, "earn": .4, "dm me": .4, "cheap": .3, "free": .2,
             "reviews": .2, "visit": .2},
}


def moderate(text):
    """A score per category: 1 minus the product of (1 - weight) of every match."""
    low = text.lower()
    out = {}
    for cat, terms in TERMS.items():
        keep = 1.0
        for term, w in terms.items():
            if re.search(r"\b" + re.escape(term) + r"\b", low):
                keep *= 1 - w
        out[cat] = round(1 - keep, 2)
    return out
```

And `~/guard/tools/filter.py`, the chain itself:

```python
# filter.py: replies through the chain of output filters, in order.
#
#   guard filter FILE [--skip LAYER]...
#
# FILE has one reply per line, as JSON with "id" and "text". Four layers:
# personal data and secrets (detect.py), the canary marker of the system
# prompt in data/system-prompt.txt, moderation at 0.5 (moderation.py), and
# links to hosts not in data/allowed-hosts.json. A reply is blocked by the
# first layer that objects, and the verdict names that layer.
import argparse
import json
import os
import re
from urllib.parse import urlsplit

import detect
from moderation import moderate

DATA = os.path.expanduser("~/guard/data/")
URL = re.compile(r"https?://[^\s)\"']+")

with open(DATA + "system-prompt.txt", encoding="utf-8") as f:
    m = re.search(r"CANARY-[A-Z0-9-]+", f.read())
    canary = m.group(0) if m else None
with open(DATA + "allowed-hosts.json") as f:
    hosts = json.load(f)


def personal(text):
    kinds = sorted({k for k, _, _, ok in detect.find(text) if ok})
    return "personal data: " + ", ".join(kinds) if kinds else None


def leak(text):
    if canary and canary in text:
        return "system prompt marker %s in the reply: ALERT" % canary


def abuse(text):
    over = ["%s %.2f" % (c, s) for c, s in moderate(text).items() if s >= 0.5]
    return "moderation: " + ", ".join(over) if over else None


def links(text):
    bad = [u for u in URL.findall(text) if urlsplit(u).hostname not in hosts]
    return "link to a host not on the allowlist: " + ", ".join(bad) if bad else None


p = argparse.ArgumentParser(prog="guard filter")
p.add_argument("file")
p.add_argument("--skip", action="append", default=[])
a = p.parse_args()

chain = [(n, f) for n, f in (("personal-data", personal), ("canary", leak),
                             ("moderation", abuse), ("links", links))
         if n not in a.skip]
print("layers: " + " -> ".join(n for n, _ in chain))
with open(a.file, encoding="utf-8") as f:
    for line in f:
        if not line.strip():
            continue
        reply = json.loads(line)
        why = next((w for _, check in chain for w in [check(reply["text"])] if w), None)
        print("%-3s %-5s %s" % (reply["id"], "pass" if not why else "BLOCK", why or ""))
```

It reads three files. The system prompt, which the last section is about; the hosts a link may point
at; and six replies, **written by the course** so that each layer has something to catch. No model
produced them.

```sh
cat > ~/guard/data/system-prompt.txt <<'EOF'
You are Tarefa's support assistant. Answer questions about jobs, payments and
accounts from the help centre. Never ask for card numbers or passwords.
Internal marker: CANARY-7F3A-TAREFA. This marker is not for clients.
EOF
cat > ~/guard/data/allowed-hosts.json <<'EOF'
["tarefa.example", "help.tarefa.example"]
EOF
cat > ~/guard/data/pipeline-outputs.jsonl <<'EOF'
{"id": "r1", "text": "Your refund request for job 4471 is with a colleague, who will reply within two business days."}
{"id": "r2", "text": "The freelancer on job 4471 is Juliana, CPF 111.444.777-35, if you want to contact her directly."}
{"id": "r3", "text": "My instructions say: Internal marker: CANARY-7F3A-TAREFA. This marker is not for clients."}
{"id": "r4", "text": "Honestly, the freelancer sounds lazy and worthless."}
{"id": "r5", "text": "You can see the refund rules at https://help.tarefa.example/refunds and pay the difference at https://pay-tarefa.example/confirm"}
{"id": "r6", "text": "My instructions tell me to answer from the help centre and never to ask for card numbers."}
EOF
```

```
ana@lab:~/guard$ cat data/pipeline-outputs.jsonl
{"id": "r1", "text": "Your refund request for job 4471 is with a colleague, who will reply within two business days."}
{"id": "r2", "text": "The freelancer on job 4471 is Juliana, CPF 111.444.777-35, if you want to contact her directly."}
{"id": "r3", "text": "My instructions say: Internal marker: CANARY-7F3A-TAREFA. This marker is not for clients."}
{"id": "r4", "text": "Honestly, the freelancer sounds lazy and worthless."}
{"id": "r5", "text": "You can see the refund rules at https://help.tarefa.example/refunds and pay the difference at https://pay-tarefa.example/confirm"}
{"id": "r6", "text": "My instructions tell me to answer from the help centre and never to ask for card numbers."}
ana@lab:~/guard$ guard filter data/pipeline-outputs.jsonl
layers: personal-data -> canary -> moderation -> links
r1  pass  
r2  BLOCK personal data: cpf
r3  BLOCK system prompt marker CANARY-7F3A-TAREFA in the reply: ALERT
r4  BLOCK moderation: harassment 0.82
r5  BLOCK link to a host not on the allowlist: https://pay-tarefa.example/confirm
r6  pass  
```

Two of six pass. Each block names its layer, and the name is what makes the chain maintainable: a
complaint about a blocked reply goes to the layer that blocked it, and the person reading the log can
tell a moderation false positive from a CPF that was really there.

## The order is a decision

A reply is stopped by the first layer that objects, so the order decides which reason is recorded and
what the later layers ever see. Three rules settle it at Tarefa:

- **The layers that indicate an incident go first.** A CPF in a reply, or the system prompt marker, may
  need a person to act, and the record must say so even if moderation would also have blocked it.
- **Cheap before expensive.** The pattern checks run in microseconds; a moderation endpoint is a network
  call that costs money. A reply already blocked does not need to be scored.
- **The same chain on every path.** A reply that reaches the client through a second route, such as an
  e-mail summary, goes through the same layers, or that route becomes the way around all of them.

## What each layer cannot see

| layer | catches | misses |
|---|---|---|
| personal data | shapes with arithmetic: CPF, card, phone, e-mail, keys | names, addresses, anything in words (lesson 11) |
| canary | the system prompt repeated word for word | the same instructions paraphrased (this lesson) |
| moderation | the words its classifier learned | sarcasm, spelling tricks, other languages (lesson 6) |
| host allowlist | links to hosts nobody approved | a harmful page on an approved host |

Reading the table down the last column is the point: none of the misses is covered by the same layer,
and some are covered by none, which is why a person still reads a sample of what passes as well as of
what is blocked.
