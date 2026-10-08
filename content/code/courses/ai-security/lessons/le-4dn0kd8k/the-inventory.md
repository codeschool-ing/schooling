---
title: An inventory of the entry points
version: 2
---

A threat model starts as a list. For Tarefa's assistant it is `data/surface.json`, written by the
course for a company it invented: one entry per place where text comes in or goes out, with three
facts about each, and the lessons of this course that build its controls. Paste it:

```sh
cat > ~/guard/data/surface.json <<'EOF'
[
{"id": "client-chat", "what": "a client's message in the chat", "enters": "prompt", "trusted": false, "controls": ["guard check-in", "guard moderate"], "lessons": [9, 6]},
{"id": "helpdesk", "what": "help centre pages retrieved for an answer", "enters": "prompt", "trusted": "written by Tarefa", "controls": ["guard ground"], "lessons": [2]},
{"id": "ticket-text", "what": "messages inside a support ticket", "enters": "prompt", "trusted": false, "controls": ["guard minimise"], "lessons": [12]},
{"id": "uploaded-files", "what": "briefs and files clients attach to a job", "enters": "prompt", "trusted": false, "controls": [], "lessons": []},
{"id": "system-prompt", "what": "the assistant's instructions", "enters": "prompt", "trusted": "written by Tarefa", "controls": ["canary in guard filter"], "lessons": [5]},
{"id": "model-reply", "what": "the model's reply, before a client reads it", "enters": "screen", "trusted": false, "controls": ["guard check-out", "guard filter"], "lessons": [9, 5]},
{"id": "tool-calls", "what": "tool calls the model proposes", "enters": "tools", "trusted": false, "controls": ["guard gate"], "lessons": [10]},
{"id": "partner-api", "what": "requests from companies using Tarefa's API", "enters": "prompt", "trusted": false, "controls": ["guard onboard", "guard drift", "guard ratelimit"], "lessons": [8, 7]},
{"id": "call-log", "what": "the log of every prompt and reply", "enters": "storage", "trusted": "Tarefa's own", "controls": ["guard redact", "guard sweep"], "lessons": [11]},
{"id": "provider", "what": "the third-party model and its records of the calls", "enters": "outside", "trusted": "by contract", "controls": ["guard minimise", "guard enduser"], "lessons": [12, 7]}
]
EOF
```

The program that reads it prints one row per entry point. Save it as `~/guard/tools/surface.py`:

```python
# surface.py: the assistant's entry points, and which control covers each.
#
#   guard surface [--gaps]
#
# It reads data/surface.json and prints one row per entry point. --gaps
# prints only the rows with no control, which are the ones to act on.
import argparse
import json
import os

p = argparse.ArgumentParser(prog="guard surface")
p.add_argument("--gaps", action="store_true")
a = p.parse_args()

with open(os.path.expanduser("~/guard/data/surface.json"), encoding="utf-8") as f:
    rows = json.load(f)

print("%-15s %-8s %-18s %s" % ("entry point", "goes to", "trusted?", "controls"))
gaps = 0
for r in rows:
    trusted = "no" if r["trusted"] is False else r["trusted"]
    gaps += not r["controls"]
    if a.gaps and r["controls"]:
        continue
    print("%-15s %-8s %-18s %s" % (r["id"], r["enters"], trusted,
                                   ", ".join(r["controls"]) or "NONE"))
print("%d entry points, %d with no control" % (len(rows), gaps))
```

```
ana@lab:~/guard$ head -3 data/surface.json
[
{"id": "client-chat", "what": "a client's message in the chat", "enters": "prompt", "trusted": false, "controls": ["guard check-in", "guard moderate"], "lessons": [9, 6]},
{"id": "helpdesk", "what": "help centre pages retrieved for an answer", "enters": "prompt", "trusted": "written by Tarefa", "controls": ["guard ground"], "lessons": [2]},
ana@lab:~/guard$ guard surface
entry point     goes to  trusted?           controls
client-chat     prompt   no                 guard check-in, guard moderate
helpdesk        prompt   written by Tarefa  guard ground
ticket-text     prompt   no                 guard minimise
uploaded-files  prompt   no                 NONE
system-prompt   prompt   written by Tarefa  canary in guard filter
model-reply     screen   no                 guard check-out, guard filter
tool-calls      tools    no                 guard gate
partner-api     prompt   no                 guard onboard, guard drift, guard ratelimit
call-log        storage  Tarefa's own       guard redact, guard sweep
provider        outside  by contract        guard minimise, guard enduser
10 entry points, 1 with no control
```

Read the columns as three questions:

- **goes to** is what the text reaches: the prompt, the screen, the tools, storage, or outside Tarefa
  altogether. Text that goes to the tools is the most dangerous, because it becomes an action.
- **trusted?** is who wrote it. Only two entries are trusted outright, the system prompt and the help
  centre, both written by Tarefa. The log is Tarefa's own and the provider is trusted by contract,
  which lesson 12 shows is a trust with conditions.
- **controls** names the commands from this course that cover the entry. None of them exists on your
  machine yet: each is a program a later lesson prints, and the lesson numbers are in the file.

The list is short because Tarefa's assistant is small. A larger application has more rows, not more
columns: each new feature adds an entry point, and **a feature is not finished until its row is
written**, with its trust and its control. A row added after an incident is a row somebody found the
hard way.

## Two rows worth reading closely

`model-reply` is marked untrusted, though Tarefa runs the model. The model's output is shaped by every
untrusted input that reached it, so it inherits their trust level. That is why lesson 9 checks every
reply against a schema and lesson 5 filters it before a client sees it.

`tool-calls` are untrusted for the same reason, and they go to the tools. A proposal is text the model
wrote after reading things nobody at Tarefa wrote, so it is checked like any other untrusted input,
by the gate of lesson 10, before it becomes an effect.
