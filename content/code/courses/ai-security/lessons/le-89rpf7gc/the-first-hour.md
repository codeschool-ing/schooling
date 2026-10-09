---
title: The first hour of an incident
version: 1
---

An incident, written by the course, that joins five earlier lessons. On Friday 9 October, at 13:52,
the assistant answered account `ac-5F2R` with a reply that quoted its own system prompt. The system
prompt includes `prompts/support.txt`, the file lesson 17 found with the payments key written in it.
At 14:03 the canary rule of lesson 22 paged Ana, who was on call.

## Contain, then understand

The canary runbook's first lines send Ana to `guard trace`, which names the prompt and its version,
and to the prompt itself, which holds the key. **At that point she knows enough to act**, and the
order matters: a leaked credential is revoked first and investigated afterwards. Every minute spent
working out exactly how the prompt leaked is a minute the key still works for whoever has it.

What revoking will break is the question the runbook answers with `guard blast`. It reads lesson 17's
inventory and the payments service's access log. The log is written by the course, with Tarefa's
servers at addresses starting `10.0.4.`; paste it:

```sh
cat > ~/guard/data/access-payments.jsonl <<'EOF'
{"at": "2026-10-09 11:40", "from": "10.0.4.12", "action": "refund", "record": "job 4471", "result": "ok"}
{"at": "2026-10-09 13:20", "from": "10.0.4.12", "action": "refund", "record": "job 3987", "result": "ok"}
{"at": "2026-10-09 14:10", "from": "10.0.4.12", "action": "refund", "record": "job 5120", "result": "ok"}
{"at": "2026-10-09 14:22", "from": "203.0.113.45", "action": "read", "record": "payment 88213", "result": "ok"}
{"at": "2026-10-09 14:25", "from": "203.0.113.45", "action": "read", "record": "payment 88214", "result": "ok"}
{"at": "2026-10-09 14:38", "from": "203.0.113.45", "action": "payout", "record": "payout 1192", "result": "refused, key revoked"}
EOF
```

Save the program as `~/guard/tools/blast.py`:

```python
# blast.py: what a leaked key opens, what revoking it breaks, and who used it.
#
#   guard blast KEY --leaked "YYYY-MM-DD HH:MM" --ours PREFIX
#
# It reads the key from data/keys.json: what it may do, and which components
# use it, which are what stops working the moment it is revoked. Then it reads
# the service's access log, data/access-KEY.jsonl, and lists every use since
# the leak that did not come from an address starting with PREFIX, which is
# where Tarefa's own servers are. Those are the uses somebody else made.
import argparse
import json
import os

p = argparse.ArgumentParser(prog="guard blast")
p.add_argument("key")
p.add_argument("--leaked", required=True)
p.add_argument("--ours", required=True)
a = p.parse_args()

home = os.path.expanduser("~/guard/data")
with open(os.path.join(home, "keys.json"), encoding="utf-8") as f:
    inv = json.load(f)
key = next((k for k in inv["keys"] if k["name"] == a.key), None)
if key is None:
    raise SystemExit("blast: no key named %s in data/keys.json" % a.key)

needed = set()
for user in key["used_by"]:
    needed |= set(inv["needs"].get(user, []))
print("key       %s, kept in %s" % (key["name"], key["kept_in"]))
print("may do    %s" % ", ".join(key["scope"]))
print("needed    %s" % ", ".join(sorted(needed)))
print("revoking  stops %s" % ", ".join(key["used_by"]))

with open(os.path.join(home, "access-%s.jsonl" % a.key), encoding="utf-8") as f:
    uses = [json.loads(line) for line in f]
since = [u for u in uses if u["at"] >= a.leaked]
foreign = [u for u in since if not u["from"].startswith(a.ours)]
print("since     %s: %d use(s), %d from outside %s" % (a.leaked, len(since), len(foreign), a.ours))
for u in foreign:
    print("  %s  %-13s %-7s %-14s %s" % (u["at"], u["from"], u["action"], u["record"], u["result"]))
```

Run now, after the incident, it shows everything:

```
ana@lab:~/guard$ guard blast payments --leaked "2026-10-09 13:52" --ours 10.0.4.
key       payments, kept in source code
may do    refund, payout, read
needed    refund
revoking  stops issue_refund
since     2026-10-09 13:52: 4 use(s), 3 from outside 10.0.4.
  2026-10-09 14:22  203.0.113.45  read    payment 88213  ok
  2026-10-09 14:25  203.0.113.45  read    payment 88214  ok
  2026-10-09 14:38  203.0.113.45  payout  payout 1192    refused, key revoked
```

Four lines decide the next hour:

- **the key may do three things and the assistant needs one.** Lesson 17's SCOPE finding, part of the
  ticket lesson 23's suite reported overdue that same morning, is why a leak that should have exposed
  refunds also exposed payment records and payouts;
- **revoking stops `issue_refund`**, and nothing else. Clients waiting for a refund wait longer while
  a new key is issued. That is a cost the runbook already accepted;
- **two reads from an address that is not Tarefa's**, at 14:22 and 14:25. A `read` returns a payment
  record: a client's name, CPF and the amount. That makes it an incident with personal data in it;
- **the payout at 14:38 was refused**, because the key had been revoked at 14:31. Containment worked,
  and the log is the proof.

## The timeline, written as it happens

Everything Ana and Bruno did went into the incident's own file, one line per step, with the time it
happened rather than the time somebody remembered it. This is their first hour; paste it:

```sh
mkdir -p ~/guard/data/incidents
cat > ~/guard/data/incidents/INC-7.jsonl <<'EOF'
{"at": "2026-10-09 14:03", "kind": "detected", "by": "ana.lima", "text": "canary alert paged: the canary is in reply rq-5530"}
{"at": "2026-10-09 13:52", "kind": "started", "by": "ana.lima", "text": "rq-5530 to account ac-5F2R quoted the system prompt"}
{"at": "2026-10-09 14:12", "kind": "note", "by": "ana.lima", "text": "trace: the prompt includes prompts/support.txt, with the payments key"}
{"at": "2026-10-09 14:19", "kind": "note", "by": "ana.lima", "text": "blast: two reads from 203.0.113.45 since 13:52"}
{"at": "2026-10-09 14:31", "kind": "contained", "by": "bruno.alves", "text": "payments key revoked; issue_refund down"}
{"at": "2026-10-09 14:44", "kind": "note", "by": "bruno.alves", "text": "new key, refund only, in the secret store; issue_refund back"}
{"at": "2026-10-09 15:10", "kind": "note", "by": "bruno.alves", "text": "key removed from support.txt; approved by ana.lima"}
EOF
```

The first line in the file is the page. The second was added once the trace showed which reply
leaked, and says the incident *started* at 13:52, eleven minutes earlier. The file is only ever
appended to: a mistake is corrected by a later note, never by editing an earlier line. Save the
program as `~/guard/tools/incident.py`:

```python
# incident.py: one incident's timeline, written as it happens.
#
#   guard incident add ID --at "YYYY-MM-DD HH:MM" --kind KIND --by NAME TEXT
#   guard incident show ID
#
# KIND is one of started, detected, note, contained, resolved. Entries are
# appended to data/incidents/ID.jsonl and never changed: a correction is a
# new note. show prints them in time order, each with the minutes since
# detection, and how long detecting and containing took.
import argparse
import datetime as dt
import json
import os

KINDS = ["started", "detected", "note", "contained", "resolved"]
FMT = "%Y-%m-%d %H:%M"

p = argparse.ArgumentParser(prog="guard incident")
sub = p.add_subparsers(dest="cmd", required=True)
add = sub.add_parser("add")
add.add_argument("id")
add.add_argument("--at", required=True)
add.add_argument("--kind", required=True, choices=KINDS)
add.add_argument("--by", required=True)
add.add_argument("text")
show = sub.add_parser("show")
show.add_argument("id")
a = p.parse_args()

path = os.path.expanduser("~/guard/data/incidents/%s.jsonl" % a.id)
if a.cmd == "add":
    dt.datetime.strptime(a.at, FMT)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps({"at": a.at, "kind": a.kind, "by": a.by, "text": a.text}) + "\n")
    raise SystemExit(0)

with open(path, encoding="utf-8") as f:
    entries = sorted((json.loads(line) for line in f), key=lambda e: e["at"])
first = {}
for e in entries:
    first.setdefault(e["kind"], dt.datetime.strptime(e["at"], FMT))
zero = first.get("detected")
for e in entries:
    t = dt.datetime.strptime(e["at"], FMT)
    rel = "" if zero is None else "%+5dm" % ((t - zero).total_seconds() // 60)
    print("%s %6s  %-9s %-11s %s" % (e["at"], rel, e["kind"], e["by"], e["text"]))
for start, end in [("started", "detected"), ("detected", "contained"), ("detected", "resolved")]:
    if start in first and end in first:
        print("%-9s %d minutes after it %s" % (end, (first[end] - first[start]).total_seconds() // 60,
                                               "started" if start == "started" else "was detected"))
    elif start in first:
        print("%-9s not yet" % end)
```

At 15:30, with the blast output read, Ana records what changes everything that follows:

```
ana@lab:~/guard$ guard incident add INC-7 --at "2026-10-09 15:30" --kind note --by ana.lima "personal data affected: two payment records read; encarregado told"
ana@lab:~/guard$ guard incident show INC-7
2026-10-09 13:52   -11m  started   ana.lima    rq-5530 to account ac-5F2R quoted the system prompt
2026-10-09 14:03    +0m  detected  ana.lima    canary alert paged: the canary is in reply rq-5530
2026-10-09 14:12    +9m  note      ana.lima    trace: the prompt includes prompts/support.txt, with the payments key
2026-10-09 14:19   +16m  note      ana.lima    blast: two reads from 203.0.113.45 since 13:52
2026-10-09 14:31   +28m  contained bruno.alves payments key revoked; issue_refund down
2026-10-09 14:44   +41m  note      bruno.alves new key, refund only, in the secret store; issue_refund back
2026-10-09 15:10   +67m  note      bruno.alves key removed from support.txt; approved by ana.lima
2026-10-09 15:30   +87m  note      ana.lima    personal data affected: two payment records read; encarregado told
detected  11 minutes after it started
contained 28 minutes after it was detected
resolved  not yet
```

**Eleven minutes to detect, twenty-eight to contain.** Those two numbers are what the review after the
incident tries to shrink, and they only exist because each step was written down with its time. The
incident is not resolved: the key is revoked and replaced, the prompt is fixed, and two people whose
payment records were read do not know yet. The next section is about telling them, and telling the
ANPD.

## What not to do in the first hour

- **delete the evidence.** The call log holds the reply that leaked, and lesson 11's sweep deletes raw
  text after 30 days. The runbook says to pause it; the incident's calls are kept for as long as the
  incident is open, and the reason goes in the timeline;
- **fix it quietly.** Removing the key from `support.txt` without revoking it leaves a working key in
  the hands of whoever read the reply;
- **guess in the timeline.** "Probably leaked around lunchtime" is useless to the review. A time the
  log can confirm, or a note saying it is not known yet.
