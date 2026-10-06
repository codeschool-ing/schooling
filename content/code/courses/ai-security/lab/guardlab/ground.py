"""Whether an answer is grounded in the help centre it cites.

THE ANSWERS IN data/answers.jsonl WERE WRITTEN BY THE COURSE, in place of
what a model would reply; no model wrote them. The help centre in
data/helpdesk/ was written by the course too.

The check is deliberately simple, and it says so: every answer must cite at
least one document or say it does not know; every cited document must exist;
and every number in the answer must appear in a cited document. It catches an
invented source and an invented figure. It does not understand a sentence, so
an answer that cites the right page and draws the wrong conclusion from it
passes, and that is what the lesson says about it.
"""
import os
import re

NUMBER = re.compile(r"\d+(?:[.,]\d+)*%?")
ABSTAIN = re.compile(r"\b(I don't know|I do not know)\b", re.I)


def load_docs(folder):
    docs = {}
    for name in sorted(os.listdir(folder)):
        if name.endswith(".md"):
            with open(os.path.join(folder, name), encoding="utf-8") as fh:
                docs[name[:-3]] = fh.read()
    return docs


def check(answer, docs):
    text, cites = answer["text"], answer.get("cites", [])
    if not cites:
        if ABSTAIN.search(text):
            return ["abstains"], True
        return ["cites nothing"], False
    problems = ["cites %s, which does not exist" % c for c in cites if c not in docs]
    sources = " ".join(docs[c] for c in cites if c in docs)
    for n in NUMBER.findall(text):
        if n not in sources:
            problems.append("the number %s is in no cited document" % n)
    return problems or ["grounded in " + ", ".join(cites)], not problems


def deps(names, registry):
    return [(n, n.lower() in registry) for n in names]
