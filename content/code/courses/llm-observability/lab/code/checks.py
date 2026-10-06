"""checks.py: rules a reply can be held to without a model, each a function that says pass or fail.

    import checks
    for name, ok, why in checks.run(reply, sources, feature="help"):
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
