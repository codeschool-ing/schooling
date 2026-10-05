"""THE STAND-IN MODERATION ENDPOINT, and the measurements made of it.

It is NOT a moderation model. It is a list of English words and phrases per
category, each with a weight the course chose, combined so that the score
behaves like one: between 0 and 1, higher with more and stronger matches
(1 minus the product of 1 minus each weight). It answers in the shape a
moderation endpoint answers in, a score per category, so that the code that
reads one can be written and measured.

Its failures are the ones a word list has, and they were left in on purpose
because real classifiers have milder versions of the same ones: it cannot
tell somebody insulting a person from somebody reporting an insult, it does
not read sarcasm, it misses a word spelt with a digit in it, and it knows no
Portuguese at all.
"""
import json
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
CATEGORIES = list(TERMS)


def moderate(text):
    low = text.lower()
    out = {}
    for cat, terms in TERMS.items():
        keep = 1.0
        for term, w in terms.items():
            if re.search(r"\b" + re.escape(term) + r"\b", low):
                keep *= 1 - w
        out[cat] = round(1 - keep, 2)
    return out


def load(path):
    with open(path, encoding="utf-8") as fh:
        return [json.loads(line) for line in fh if line.strip()]


def confusion(rows, cat, threshold):
    tp = fp = fn = tn = 0
    for r in rows:
        flagged = moderate(r["text"])[cat] >= threshold
        labelled = cat in r["labels"]
        if flagged and labelled:
            tp += 1
        elif flagged:
            fp += 1
        elif labelled:
            fn += 1
        else:
            tn += 1
    return tp, fp, fn, tn
