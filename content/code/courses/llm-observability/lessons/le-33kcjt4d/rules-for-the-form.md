---
title: Rules for the form of a reply
version: 2
---

A fact needs an expected answer. A **rule** does not: it is a property every good reply has, whatever
the question. That makes rules the cheapest evaluation there is, and the only one that can look at a
reply nobody wrote an answer key for.

`checks.py` has six:

```python
"""checks.py: rules a reply can be held to without a model, each a function that says pass or fail.

    import checks
    for name, ok, why in checks.run(reply, sources):
        ...

Every check is deterministic: the same reply and sources give the same verdict
on every run, in microseconds, at no cost. Which is why they can run on every
reply in production, and why lesson 15 can make a build fail on them.
"""
import re

import redact

REFUSAL = "I could not find that in our documents."
CITE = re.compile(r"\[(\d+)\]")
NUMBER = re.compile(r"\d+(?:[.,]\d+)?")


def sentences(reply):
    return [s for s in re.split(r"(?<=[.!?\]])\s+(?=[A-Z])", reply.strip()) if s]


def is_refusal(reply):
    return reply.strip() == REFUSAL


def cites_every_sentence(reply, sources):
    """Every sentence of an answer ends with a citation like [1]."""
    if is_refusal(reply):
        return True, "a refusal cites nothing"
    bare = [s for s in sentences(reply) if not CITE.search(s)]
    return not bare, f"{len(bare)} sentence(s) with no citation" if bare else "every sentence cited"


def citations_exist(reply, sources):
    """Every [n] points at a source the model was given."""
    bad = sorted({int(n) for n in CITE.findall(reply) if not 0 < int(n) <= len(sources)})
    return not bad, f"no source {bad}" if bad else "every citation has a source"


def numbers_in_sources(reply, sources):
    """Every number in the reply appears in the text of the sources: no figure comes from nowhere."""
    text = " ".join(s["text"] for s in sources)
    found = set(NUMBER.findall(text))
    stray = [n for n in NUMBER.findall(CITE.sub("", reply)) if n not in found]
    return not stray, f"not in any source: {stray}" if stray else "every number is in a source"


def no_personal_data(reply, sources):
    """The reply repeats no address, telephone, card or order number."""
    f = redact.found(reply)
    return not f, f"repeats {f}" if f else "nothing personal"


def refusal_is_exact(reply, sources):
    """A reply that says it cannot answer says so in the agreed words, so that it can be counted."""
    looks = re.search(r"\b(could not find|do not say|cannot answer|no information)\b", reply, re.I)
    return (not looks or is_refusal(reply)), "not the agreed refusal" if looks and not is_refusal(reply) else "ok"


def short_enough(reply, sources, words=80):
    """An answer to a customer stays under a word limit."""
    n = len(CITE.sub("", reply).split())
    return n <= words, f"{n} words"


CHECKS = [cites_every_sentence, citations_exist, numbers_in_sources, no_personal_data, refusal_is_exact,
          short_enough]


def run(reply, sources):
    """[(name, passed, detail)] for every check."""
    return [(c.__name__, *c(reply, sources)) for c in CHECKS]
```

Each is a function that takes a reply and the sources it was given, and answers pass or fail and why.
They encode what Marginalia's system prompt asks for and what the support team cares about:

- **every sentence cites a source**, which the prompt demands;
- **every citation points at a source the model was given**, so that a `[4]` among three sources is
  caught;
- **every number appears in the sources**, a narrow, deterministic check of faithfulness: a price, a
  number of days or a percentage that is in no source came from nowhere;
- **no personal data comes back**, lesson 2's patterns applied to the output;
- **a refusal uses the agreed words**, so that refusals can be counted and nothing that looks like one
  slips past as an answer;
- **an answer stays under 80 words**.

To see each one fire on demand, `broken.py` puts five replies **written by the course** through all
six, against the chunk about standard delivery, which says it costs R$ 12.90 and is free over R$ 40:

```python
"""broken.py: five replies the course wrote, each breaking one rule, through every check."""
import json

import checks

source = [c for c in json.load(open("data/index.json"))["chunks"] if c["id"] == "shipping-and-delivery:standard-delivery"]
for reply in ["Standard delivery is free on orders over R$ 40.",
              "Standard delivery is free on orders over R$ 40. [2]",
              "Standard delivery costs R$ 9.90. [1]",
              "Joana, we sent the details to joana.prado@example.com. [1]",
              "Sorry, I could not find anything about that."]:
    failed = [f"{name}: {why}" for name, ok, why in checks.run(reply, source) if not ok]
    print(f"{reply}\n    {'; '.join(failed) or 'passes every check'}")
```

```
ana@dev:~/obs$ python broken.py
Standard delivery is free on orders over R$ 40.
    cites_every_sentence: 1 sentence(s) with no citation
Standard delivery is free on orders over R$ 40. [2]
    citations_exist: no source [2]
Standard delivery costs R$ 9.90. [1]
    numbers_in_sources: not in any source: ['9.90']
Joana, we sent the details to joana.prado@example.com. [1]
    no_personal_data: repeats {'email': 1}
Sorry, I could not find anything about that.
    cites_every_sentence: 1 sentence(s) with no citation; refusal_is_exact: not the agreed refusal
```

Each reply breaks the rule it was written to break, and the last breaks two: a refusal in its own words
cites nothing and is not the agreed sentence, so it would be missed by every count of refusals in
lesson 5.

Notice what the number rule caught: **R$ 9.90 is a price the source does not contain**. A model that
"remembers" a price from somewhere else, or works out a number it should have copied, produces
exactly that, and no customer can tell. The next section finds `llama3.2:3b` doing the second. It is
the one kind of faithfulness a program can check with certainty, and for a shop whose answers are
mostly prices, days and thresholds, it covers a large share of what matters.