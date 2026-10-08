---
title: An answer has to stand on its source
version: 2
---

The assistant answers clients' questions from Tarefa's help centre. **An answer is grounded when what
it says can be found in the sources it was given**, and the cheapest defence against an invented
answer is to require it to name its sources and then check that they say what it says. The help
centre for this lesson is three short pages, written by the course. Paste them:

```sh
mkdir -p ~/guard/data/helpdesk
cat > ~/guard/data/helpdesk/hc-fees.md <<'EOF'
# Fees

Tarefa keeps 10% of the price of each job as its fee.
The client pays no fee on top of the price.
EOF
cat > ~/guard/data/helpdesk/hc-payouts.md <<'EOF'
# Payouts

Freelancers are paid by Pix 2 business days after the client approves the work.
A payout key can only be changed on the Payouts page.
EOF
cat > ~/guard/data/helpdesk/hc-refunds.md <<'EOF'
# Refunds

A client may ask for a refund of a job up to 14 days after its due date.
If the freelancer delivered nothing, the refund is the full amount paid.
If part of the work was delivered, a person on the support team decides the amount.
Refunds reach the client's card or Pix account in up to 5 business days.
EOF
```

```
ana@lab:~/guard$ ls data/helpdesk
hc-fees.md
hc-payouts.md
hc-refunds.md
ana@lab:~/guard$ cat data/helpdesk/hc-refunds.md
# Refunds

A client may ask for a refund of a job up to 14 days after its due date.
If the freelancer delivered nothing, the refund is the full amount paid.
If part of the work was delivered, a person on the support team decides the amount.
Refunds reach the client's card or Pix account in up to 5 business days.
```

Then six answers, **written by the course in place of what a model would reply**, each with the pages
it cites. They were written so that every rule has something to catch:

```sh
cat > ~/guard/data/answers.jsonl <<'EOF'
{"id": "a1", "question": "How long do I have to ask for a refund?", "text": "You can ask for a refund up to 14 days after the job's due date.", "cites": ["hc-refunds"]}
{"id": "a2", "question": "How long do I have to ask for a refund?", "text": "You can ask for a refund up to 30 days after the job's due date.", "cites": ["hc-refunds"]}
{"id": "a3", "question": "Is my job guaranteed?", "text": "Every job is covered by the Tarefa Guarantee, which pays back twice the price if the work is late.", "cites": ["hc-guarantee"]}
{"id": "a4", "question": "What fee does Tarefa charge?", "text": "Tarefa charges a 15% fee on each job.", "cites": []}
{"id": "a5", "question": "Can I pay in instalments?", "text": "I don't know, and I have passed your question to a colleague.", "cites": []}
{"id": "a6", "question": "When are freelancers paid?", "text": "Freelancers are paid by Pix 2 business days after the job is posted.", "cites": ["hc-payouts"]}
EOF
```

The check applies three rules: an answer cites at least one page or says it does not know; every
cited page exists; every number in the answer appears in a cited page. Save it as
`~/guard/tools/ground.py`:

```python
# ground.py: whether each answer stands on the help centre pages it cites.
#
#   guard ground FILE
#
# FILE has one answer per line, as JSON with "id", "text" and "cites". Three
# rules, deliberately simple: an answer cites at least one page or says it
# does not know; every page it cites exists in data/helpdesk/; and every
# number in it appears in a page it cites. It catches an invented source and
# an invented figure. It does not understand a sentence.
import json
import os
import re
import sys

NUMBER = re.compile(r"\d+(?:[.,]\d+)*%?")
ABSTAIN = re.compile(r"\b(I don't know|I do not know)\b", re.I)

folder = os.path.expanduser("~/guard/data/helpdesk")
docs = {}
for name in sorted(os.listdir(folder)):
    if name.endswith(".md"):
        with open(os.path.join(folder, name), encoding="utf-8") as f:
            docs[name[:-3]] = f.read()


def check(answer):
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


with open(sys.argv[1], encoding="utf-8") as f:
    answers = [json.loads(line) for line in f if line.strip()]
flagged = 0
for a in answers:
    notes, ok = check(a)
    flagged += not ok
    print("%-3s %-5s %s" % (a["id"], "ok" if ok else "FLAG", notes[0]))
    for n in notes[1:]:
        print("%-3s %-5s %s" % ("", "", n))
print("%d of %d answers flagged" % (flagged, len(answers)))
sys.exit(1 if flagged else 0)
```

```
ana@lab:~/guard$ head -2 data/answers.jsonl
{"id": "a1", "question": "How long do I have to ask for a refund?", "text": "You can ask for a refund up to 14 days after the job's due date.", "cites": ["hc-refunds"]}
{"id": "a2", "question": "How long do I have to ask for a refund?", "text": "You can ask for a refund up to 30 days after the job's due date.", "cites": ["hc-refunds"]}
ana@lab:~/guard$ guard ground data/answers.jsonl; echo "exit $?"
a1  ok    grounded in hc-refunds
a2  FLAG  the number 30 is in no cited document
a3  FLAG  cites hc-guarantee, which does not exist
a4  FLAG  cites nothing
a5  ok    abstains
a6  ok    grounded in hc-payouts
3 of 6 answers flagged
exit 1
```

- `a2` cites the right page and says 30 days where the page says 14. The number is the invention, and
  the number is what a client acts on.
- `a3` cites `hc-guarantee`, a page that does not exist, for a guarantee that does not exist either.
  An invented source is the most common shape of an invented answer, and the easiest to catch.
- `a4` cites nothing and states a 15% fee, against the 10% the fee page gives.
- `a5` says it does not know and passes the question to a person. **Abstaining is a correct answer**,
  and a system that punishes it teaches the model, through the prompt and the evaluation, to guess.

What happens to a flagged answer follows lesson 9: it is not shown, and the question goes back to the
model once with the problem, or to a person.

## What this check cannot see

`a6` passed. Read it against its source:

```
ana@lab:~/guard$ grep a6 data/answers.jsonl
{"id": "a6", "question": "When are freelancers paid?", "text": "Freelancers are paid by Pix 2 business days after the job is posted.", "cites": ["hc-payouts"]}
ana@lab:~/guard$ cat data/helpdesk/hc-payouts.md
# Payouts

Freelancers are paid by Pix 2 business days after the client approves the work.
A payout key can only be changed on the Payouts page.
```

The answer cites the right page and every number in it is on that page. It is still wrong: payment
follows the client's approval, not the posting of the job. The check compares numbers and names,
**and it does not understand a sentence**, so a wrong conclusion drawn from the right page passes.

Stronger checks exist and cost more: comparing each claim with the passage it came from using a
second model, or showing the client the passage beside the answer so that they can see it. Each one
catches some of what the cheap check misses, and none catches everything, which is why the documents
the assistant answers from are kept short, current and unambiguous. A help centre that contradicts
itself produces grounded answers that contradict each other.

## The same check on a real reply

The six answers above were written to exercise the check. A real model's replies go through the same check, and
this program produces one: it sends the three pages to `llama3.2:3b` with the question, asks for JSON
naming the pages it used, and prints a line in the shape of `answers.jsonl`. It uses `ask()` from the
program lesson 1 gave you. Save it as `~/guard/tools/answer.py`:

```python
# answer.py: the assistant's answer to one client question, from the help centre.
#
#   guard answer ID QUESTION
#
# It sends every page of data/helpdesk/ to the model with the question, asks
# for JSON naming the pages it used, and prints one line in the shape of
# data/answers.jsonl, so that `guard ground` can check a real reply.
import json
import os
import sys

from ask import ask

ID, QUESTION = sys.argv[1], sys.argv[2]
folder = os.path.expanduser("~/guard/data/helpdesk")
pages = ""
for name in sorted(os.listdir(folder)):
    with open(os.path.join(folder, name), encoding="utf-8") as f:
        pages += "<page id=\"%s\">\n%s</page>\n" % (name[:-3], f.read())

SYSTEM = """You answer clients of Tarefa, a freelance marketplace, using only
the help centre pages below. Reply with a JSON object with two keys: "text",
your answer in one or two sentences, and "cites", a list of the ids of the
pages you used. If the pages do not answer the question, say "I don't know"
in "text" and leave "cites" empty.

""" + pages

reply = json.loads(ask(QUESTION, system=SYSTEM, json_only=True))
print(json.dumps({"id": ID, "question": QUESTION, "text": reply.get("text", ""),
                  "cites": reply.get("cites", [])}, ensure_ascii=False))
```

```
ana@lab:~/guard$ guard answer r1 "How long do I have to ask for a refund?" > data/live.jsonl
ana@lab:~/guard$ guard answer r2 "What fee does Tarefa charge?" >> data/live.jsonl
ana@lab:~/guard$ guard answer r3 "Can I pay in instalments?" >> data/live.jsonl
ana@lab:~/guard$ guard answer r4 "When are freelancers paid?" >> data/live.jsonl
ana@lab:~/guard$ cat data/live.jsonl
{"id": "r1", "question": "How long do I have to ask for a refund?", "text": "You have up to 14 days after the job's due date to ask for a refund.", "cites": ["hc-refunds", "hc-fees", "hc-payouts"]}
{"id": "r2", "question": "What fee does Tarefa charge?", "text": "Tarefa charges a 10% fee on the price of each job", "cites": ["hc-fees"]}
{"id": "r3", "question": "Can I pay in instalments?", "text": "I don't know", "cites": []}
{"id": "r4", "question": "When are freelancers paid?", "text": "Freelancers are paid by Pix 2 business days after the client approves the work.", "cites": ["hc-payouts"]}
ana@lab:~/guard$ guard ground data/live.jsonl; echo "exit $?"
r1  ok    grounded in hc-refunds, hc-fees, hc-payouts
r2  ok    grounded in hc-fees
r3  ok    abstains
r4  ok    grounded in hc-payouts
0 of 4 answers flagged
exit 0
```

All four passed, and that is worth reading rather than skipping. With three short pages in front of it
and the temperature at 0, the model kept to the pages, and it said it did not know about instalments
rather than guess, which is the behaviour `a5` stands for. Your replies may be worded differently.

Two things in those lines are still worth a second look. `r1` cites all three pages for an answer that
came from one: the check passes it, because a citation it cannot use is not a citation it can refuse.
And every reply passed **on this run**. The check is there for the run when a reply says 30 days, and
nothing in a run that passes says when that will be.
