---
title: Assigning visitors, and keeping them assigned
version: 1
---

**Randomisation needs two properties, and the obvious implementation has only one.** Flipping a
coin on every page view is random. It is not **sticky**: the same visitor sees the old checkout on
Monday and the new one on Tuesday, belongs to both groups, and makes the comparison meaningless.

The usual implementation is a hash. Take the visitor's identifier and the test's name, run them
through a hash function, and use the result to pick the group:

```schooling-example
{"language": "python", "file": "assign.py", "parts": [{"code": "import hashlib\n\n\ndef group(visitor, test=\"checkout-2025-03\"):\n    digest = hashlib.sha256(f\"{test}:{visitor}\".encode()).hexdigest()\n    return \"new\" if int(digest[:8], 16) % 2 == 0 else \"old\"", "note": "The visitor's identifier and the test's name go through a hash, a function that turns any text into a number that looks random and is always the same for the same text. Even numbers get the new page."}, {"code": "for visitor in [\"v000001\", \"v000002\", \"v000003\", \"v000004\", \"v000001\"]:\n    print(visitor, group(visitor))", "note": "Four visitors, and the first one again: the same visitor gets the same group every time."}, {"code": "print(\"\\nthe same visitors in another test:\")\nfor visitor in [\"v000001\", \"v000002\", \"v000003\", \"v000004\"]:\n    print(visitor, group(visitor, test=\"menu-2025-04\"))", "note": "A different test name reshuffles everybody, so being in the treatment of one test says nothing about the next."}, {"code": "counts = {\"new\": 0, \"old\": 0}\nfor n in range(1, 100001):\n    counts[group(f\"v{n:06d}\")] += 1\nprint(f\"\\n100,000 visitors: {counts}\")", "note": "Over many visitors the split comes out close to half and half, as a coin would."}], "output": "v000001 old\nv000002 old\nv000003 new\nv000004 new\nv000001 old\n\nthe same visitors in another test:\nv000001 new\nv000002 old\nv000003 old\nv000004 old\n\n100,000 visitors: {'new': 50099, 'old': 49901}"}
```

Each property is visible in the output. The first visitor appears twice and gets the same group
both times, so **the assignment is sticky** without storing anything. A different test name gives a
different shuffle, so **tests are independent of each other**: being in the treatment of the
checkout test does not make a visitor more likely to be in the treatment of the menu test. And over
a hundred thousand visitors the split comes out at 50,099 against 49,901, which is what a fair coin
produces.

## The unit decides what "the same visitor" means

The hash is only as sticky as the identifier it is given. A cookie identifies a browser, so the same
person on a phone and a laptop is two visitors, and each device may land in a different group. An
account identifies a person, but only after they log in, and Panela's checkout test is about people
who have not ordered yet. **The randomisation unit is a choice with consequences**: lesson 7 said the
metric must be counted on the same unit, and the section after next says what goes wrong when the
unit is smaller than the person.
