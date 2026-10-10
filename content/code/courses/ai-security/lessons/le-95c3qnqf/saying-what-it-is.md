---
title: The screen is a security control too
version: 1
---

Every defence so far ran on Tarefa's servers. The client never saw `guard gate` or `memory.py`; they
saw a chat window, a reply, a refusal, a confirmation. **What those screens say decides what the
client believes and what the client does next.** A client who believes the wrong thing is a
failure of the system as real as a leaked key: a reply taken as a promise from Tarefa's staff, a
refusal retried forty times, a refund confirmed without reading it.

So the screens get rules too, written down and checked like everything else. Tarefa's assistant has
six screens, each with its text and the actions it offers; the course wrote them as a first draft
would be written. Paste them:

```sh
cat > ~/guard/data/ui-copy.json <<'EOF'
[
 {"id": "chat-welcome", "kind": "chat",
  "text": "Hi! I'm here to help with your jobs, payments and account.",
  "actions": ["talk-to-a-person"]},
 {"id": "reply", "kind": "reply",
  "text": "{reply}",
  "actions": ["copy"]},
 {"id": "refusal-budget", "kind": "refusal",
  "text": "Something went wrong. Please try again.",
  "actions": ["retry"]},
 {"id": "refusal-scope", "kind": "refusal",
  "text": "I can only help with jobs, payments and accounts on Tarefa. For anything else, a person on our team can help: they reply within one business day.",
  "actions": ["talk-to-a-person"]},
 {"id": "confirm-refund", "kind": "confirm", "tool": "issue_refund",
  "text": "The assistant wants to issue a refund. Allow?",
  "shows": [],
  "actions": ["allow", "cancel"]},
 {"id": "memory-panel", "kind": "memory",
  "text": "What the assistant remembers about you, and until when.",
  "actions": ["delete-one", "delete-all"]}
]
EOF
```

The checker knows what each kind of screen owes the client. Save it as `~/guard/tools/uxcheck.py`:

```python
# uxcheck.py: what the assistant's screens say, against rules a person sets.
#
#   guard uxcheck FILE
#
# FILE lists every screen of the assistant with its text and the actions it
# offers. Each kind of screen has rules of its own:
#
#   chat     says the client is talking to an automated assistant, and
#            offers a person
#   reply    can be reported
#   refusal  says why, names the next step, and offers a person; never only
#            "try again", which turns a limit into a loop
#   confirm  shows every argument of the tool call, as lesson 10 asked
#   memory   lets the client delete what is remembered
#
# The arguments a confirmation must show, per tool, are TOOL_ARGS below; they
# are the arguments of the proposals in lesson 10. The exit status is 1 while
# any screen breaks a rule.
import argparse
import json
import os
import re

AUTOMATED = re.compile(r"\b(automated|AI|artificial intelligence|language model)\b", re.I)
WHY = re.compile(r"\b(can only|cannot|because|limit|today)\b", re.I)
TOOL_ARGS = {"issue_refund": ["account", "job", "cents"]}

p = argparse.ArgumentParser(prog="guard uxcheck")
p.add_argument("file")
a = p.parse_args()
with open(a.file, encoding="utf-8") as f:
    screens = json.load(f)


def problems(s):
    out = []
    acts = s.get("actions", [])
    if s["kind"] == "chat":
        if not AUTOMATED.search(s["text"]):
            out.append("does not say the assistant is automated")
        if "talk-to-a-person" not in acts:
            out.append("offers no person")
    if s["kind"] == "reply" and "report" not in acts:
        out.append("a reply cannot be reported")
    if s["kind"] == "refusal":
        if not WHY.search(s["text"]):
            out.append("does not say why")
        if "talk-to-a-person" not in acts:
            out.append("offers no person")
        if acts == ["retry"]:
            out.append("only offers to try again")
    if s["kind"] == "confirm":
        missing = [x for x in TOOL_ARGS[s["tool"]] if x not in s.get("shows", [])]
        if missing:
            out.append("does not show " + ", ".join(missing))
    if s["kind"] == "memory" and not {"delete-one", "delete-all"} & set(acts):
        out.append("nothing can be deleted")
    return out


bad = 0
for s in screens:
    found = problems(s)
    bad += bool(found)
    print("%-15s %-8s %s" % (s["id"], s["kind"], "ok" if not found else found[0]))
    for f in found[1:]:
        print("%-15s %-8s %s" % ("", "", f))
print("%d screens, %d breaking a rule" % (len(screens), bad))
raise SystemExit(1 if bad else 0)
```

```
ana@lab:~/guard$ guard uxcheck data/ui-copy.json; echo "exit status $?"
chat-welcome    chat     does not say the assistant is automated
reply           reply    a reply cannot be reported
refusal-budget  refusal  does not say why
                         offers no person
                         only offers to try again
refusal-scope   refusal  ok
confirm-refund  confirm  does not show account, job, cents
memory-panel    memory   ok
6 screens, 4 breaking a rule
exit status 1
```

Four of six break a rule. This section is about the first two; the next one is about the other two.

## Say it is a model

`chat-welcome` greets the client warmly and never says what is answering. **A client who does not
know they are talking to a model reads its replies as Tarefa's word**: a price it invents becomes a
quote, a date it guesses becomes a promise, and the client acts on both. Lesson 2 measured how often
a model states what nobody wrote. The welcome is where the client learns to check, and it costs one
sentence: *Tarefa's automated assistant*. The rule looks for the words that say so and refuses a
welcome without them.

The same screen offers a person, and keeps offering one. An automated assistant with no way past it
is a wall, and a client who needs a person and cannot find one tries to make the assistant do what a
person would, which is exactly the use nobody designed for.

## Every reply can be reported

`reply` offers to copy the text and nothing else. **The client is the one who sees every reply**,
including the ones no check caught: the wrong queue of lesson 14, the confident error of lesson 15's
`q1`. A report button on every reply is the cheapest monitoring there is, and lesson 22 builds on
it. It costs nothing to show and very little to read, provided each report arrives with what lesson
20 logged for the call, so that somebody can find the reply, the prompt version and the model,
rather than a screenshot and a guess.
