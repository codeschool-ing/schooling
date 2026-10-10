---
title: The model proposes a memory, the code decides
version: 1
---

An assistant that remembers is more useful: a client who asked for replies in Portuguese should not
have to ask in every conversation, and one who always pays by Pix should not be asked how they will
pay. **Memory is also a store of personal data that the model writes for itself**, from whatever the
client happened to say, kept for longer than any one conversation and read back into every prompt
after it. Lesson 13 would draw it as two flows: client text into the store, and the store back into
the prompt.

The design question is the one lesson 10 answered for tools. **The model proposes; the code decides.**
The model is good at spotting that a sentence is about the client. It has no idea what Tarefa's
privacy policy allows it to keep, and nothing in its reply can be trusted to have checked.

Three messages from one client, written by the course, the kind a support chat collects in a month.
The CPF has valid check digits on purpose, as in lesson 11, and belongs to nobody. Paste them:

```sh
cat > ~/guard/data/conversations.jsonl <<'EOF'
{"id": "k1", "account": "ac-7Q2M", "date": "2026-03-02", "text": "Hi, it's Marcos again. Please answer me in Portuguese from now on, my English is not great. The logo for job 4471 should use dark blue, like my shop's sign."}
{"id": "k2", "account": "ac-7Q2M", "date": "2026-03-09", "text": "Sorry for the delay in approving the draft, I was in hospital for a surgery last week. For the invoice my CPF is 111.444.777-35. I always pay by Pix."}
{"id": "k3", "account": "ac-7Q2M", "date": "2026-03-20", "text": "My new phone is (11) 98765-4321, please call me there. Also, I prefer to get updates once a week rather than every day."}
EOF
```

The program asks the model for memories in a schema the server enforces, which lesson 14 showed
closes the shape of the reply: at most five, each a kind and one sentence of at most 120 characters.
Then each proposal meets three rules written in code. It imports `ask.py` from lesson 1, `detect.py`
from lesson 11 and the sensitive-word list of `minimise.py` from lesson 12. Save it as
`~/guard/tools/memory.py`:

```python
# memory.py: what the assistant remembers about a client between conversations.
#
#   guard memory learn CONVERSATIONS --as ACCOUNT
#   guard memory show --as ACCOUNT --now DATE
#   guard memory forget ID --as ACCOUNT
#   guard memory sweep --now DATE
#
# The model PROPOSES memories from a client's messages, in a JSON Schema the
# server enforces: at most five, each a kind and one sentence of at most 120
# characters. The code DECIDES. A proposal is refused when it holds personal
# data detect.py finds (lesson 11), words from the sensitive list of
# minimise.py (lesson 12), or a kind with no retention here; contact details
# belong in the account record, where the client edits them. What is kept is
# written to data/memory/ACCOUNT.jsonl with the date it stops being used.
#
# show lists what the assistant may use on a date, and never another
# account's file. forget deletes one entry. sweep deletes every entry past its
# date from the disk: an expired memory that is still in the file is still
# personal data Tarefa holds.
import argparse
import datetime as dt
import json
import os
import sys
import urllib.error
import urllib.request

import ask
from detect import find
from minimise import sensitive_terms

KEEP_DAYS = {"preference": 365, "job": 90}
FOLDER = os.path.expanduser("~/guard/data/memory")
SYSTEM = ("You maintain the memory of Tarefa's support assistant. From the client's message, "
          "list the facts worth remembering for future conversations with this client, each "
          "as one short sentence about the client, with a kind: preference, job, contact or other.")
SCHEMA = {"type": "object", "required": ["memories"], "additionalProperties": False,
          "properties": {"memories": {"type": "array", "maxItems": 5, "items": {
              "type": "object", "required": ["kind", "text"], "additionalProperties": False,
              "properties": {"kind": {"type": "string",
                                      "enum": ["preference", "job", "contact", "other"]},
                             "text": {"type": "string", "maxLength": 120}}}}}}


def propose(message):
    body = {"model": ask.MODEL, "temperature": 0, "seed": 1,
            "messages": [{"role": "system", "content": SYSTEM},
                         {"role": "user", "content": message}],
            "response_format": {"type": "json_schema", "json_schema": {
                "name": "memories", "schema": SCHEMA, "strict": True}}}
    req = urllib.request.Request(ask.URL + "/chat/completions", json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    if ask.KEY:
        req.add_header("Authorization", "Bearer " + ask.KEY)
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            return json.loads(json.load(r)["choices"][0]["message"]["content"])["memories"]
    except urllib.error.HTTPError as e:
        sys.exit("memory: %s answered %d: %s" % (ask.URL, e.code, e.read().decode().strip()))
    except urllib.error.URLError as e:
        sys.exit("memory: cannot reach %s (%s). Is Ollama running?" % (ask.URL, e.reason))


def refuse(m):
    """Why a proposed memory may not be kept, or None."""
    found = sorted({kind for kind, _, _, ok in find(m["text"]) if ok})
    if found:
        return "personal data: " + ", ".join(found)
    words = sensitive_terms(m["text"])
    if words:
        return "sensitive (%s)" % ", ".join(words)
    if m["kind"] not in KEEP_DAYS:
        return "kind %s is not kept" % m["kind"]
    return None


def path(account):
    return os.path.join(FOLDER, account + ".jsonl")


def read(account):
    if not os.path.exists(path(account)):
        return []
    with open(path(account), encoding="utf-8") as f:
        return [json.loads(line) for line in f]


def write(account, rows):
    os.makedirs(FOLDER, exist_ok=True)
    with open(path(account), "w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")


p = argparse.ArgumentParser(prog="guard memory")
p.add_argument("action", choices=["learn", "show", "forget", "sweep"])
p.add_argument("target", nargs="?")
p.add_argument("--as", dest="account")
p.add_argument("--now")
a = p.parse_args()

if a.action == "learn":
    rows = read(a.account)
    with open(a.target, encoding="utf-8") as f:
        conversations = [json.loads(line) for line in f]
    for c in conversations:
        if c["account"] != a.account:
            continue
        for m in propose(c["text"]):
            why = refuse(m)
            if why:
                print("%s  REFUSE %-10s %-40s %s" % (c["id"], m["kind"], m["text"][:40], why))
                continue
            day = dt.date.fromisoformat(c["date"])
            n = max([int(r["id"][1:]) for r in rows] + [0]) + 1
            rows.append({"id": "m%d" % n, "kind": m["kind"], "text": m["text"],
                         "from": c["id"], "kept": c["date"],
                         "until": str(day + dt.timedelta(days=KEEP_DAYS[m["kind"]]))})
            print("%s  KEEP   %-10s %-40s until %s" % (c["id"], m["kind"], m["text"][:40], rows[-1]["until"]))
    write(a.account, rows)
elif a.action == "show":
    now = dt.date.fromisoformat(a.now)
    rows = [r for r in read(a.account) if dt.date.fromisoformat(r["until"]) >= now]
    print("%s on %s, memories in use: %d" % (a.account, a.now, len(rows)))
    for r in rows:
        print("  %-3s %-10s until %s  %s" % (r["id"], r["kind"], r["until"], r["text"]))
elif a.action == "forget":
    rows = read(a.account)
    left = [r for r in rows if r["id"] != a.target]
    if len(left) == len(rows):
        p.exit(1, "memory: %s has no memory %s\n" % (a.account, a.target))
    write(a.account, left)
    print("forgot %s for %s" % (a.target, a.account))
elif a.action == "sweep":
    now = dt.date.fromisoformat(a.now)
    for name in sorted(os.listdir(FOLDER)) if os.path.isdir(FOLDER) else []:
        account = name[:-len(".jsonl")]
        rows = read(account)
        left = [r for r in rows if dt.date.fromisoformat(r["until"]) >= now]
        write(account, left)
        print("%s: %d deleted, %d kept" % (account, len(rows) - len(left), len(left)))
```

What the model proposed, and what the code did with each proposal:

```
ana@lab:~/guard$ guard memory learn data/conversations.jsonl --as ac-7Q2M
k1  REFUSE contact    Marcos                                   kind contact is not kept
k1  KEEP   job        4471                                     until 2026-05-31
k1  KEEP   preference dark blue logo color                     until 2027-03-02
k2  REFUSE contact    CPF: 111.444.777-35                      personal data: cpf
k2  KEEP   job        always pays by Pix                       until 2026-06-07
k2  REFUSE preference was in hospital for a surgery last week  sensitive (health)
k3  REFUSE contact    (11) 98765-4321                          personal data: phone
k3  KEEP   preference weekly updates preferred                 until 2027-03-20
```

**The model proposed a CPF, a phone number and a surgery as things to remember**, and filed the
surgery under `preference`. The code refused all three, each with its reason: `detect.py` found the
CPF and the phone, and the sensitive list found the health words. It also refused the client's name,
filed as `contact`, because contact details live in the account record, where the client can see and
change them, and a second copy in a memory goes stale the day they change.

## What the rules cannot see

Two things in the capture are the rules working as written and still not what a person would want.

- **The most useful fact was never proposed.** Marcos asked for replies in Portuguese, and no memory
  says so. The code can only refuse what the model offers. Missing a good memory costs a client one
  repeated request; keeping a bad one costs a privacy incident, which is why the rules lean the way
  they do.
- **The kind decides the retention, and the model chose the kind.** "Always pays by Pix" is a
  preference, filed as `job`, so it will be kept 90 days instead of 365. That error shortens a
  memory, which is the safe direction. An error that lengthened one would not be, and that is a reason
  to keep the longest retention for the narrowest kind.

**A list of refused things is never complete.** `detect.py` sees five shapes of personal data and the
sensitive list sees some words in English. A memory that said "her daughter's school is in Moema"
would pass both. The rules lower the risk; the next section limits what is left of it by deciding
whose memory it is and how long it lives.
