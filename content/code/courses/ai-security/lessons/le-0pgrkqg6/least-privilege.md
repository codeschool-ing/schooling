---
title: An agent gets the tools its task needs, and no wider
version: 2
---

When a model is given tools, it does not call them. **It writes a proposal for a call**, a tool name
and its arguments, and the application decides whether to run it. That moment is the whole of this
lesson. An application that runs every proposal has handed the model its own permissions; one that
checks every proposal against a written list has kept them.

Tarefa's support assistant is the case. The list of what it may do is `data/tools.json`, written by
the course along with the session it is checked against. Paste it:

```sh
cat > ~/guard/data/tools.json <<'EOF'
{
 "calls_per_conversation": 8,
 "session": {
  "account": "ac-7Q2M",
  "paid_cents": {
   "4471": 120000
  }
 },
 "tools": {
  "lookup_order": {
   "access": "read",
   "scope": "session-account"
  },
  "send_message": {
   "access": "write",
   "recipients": [
    "session-account"
   ]
  },
  "issue_refund": {
   "access": "write",
   "scope": "session-account",
   "max_cents": "what the client paid",
   "confirm": "moves money and cannot be undone"
  }
 }
}
EOF
```

```
ana@lab:~/guard$ cat data/tools.json
{
 "calls_per_conversation": 8,
 "session": {
  "account": "ac-7Q2M",
  "paid_cents": {
   "4471": 120000
  }
 },
 "tools": {
  "lookup_order": {
   "access": "read",
   "scope": "session-account"
  },
  "send_message": {
   "access": "write",
   "recipients": [
    "session-account"
   ]
  },
  "issue_refund": {
   "access": "write",
   "scope": "session-account",
   "max_cents": "what the client paid",
   "confirm": "moves money and cannot be undone"
  }
 }
}
```

Three tools, and the list is short on purpose. **Least privilege** means the agent has the tools its
task needs and nothing else, and each tool reaches only the data of the conversation it is in. A
support conversation needs to read the client's orders, to write to the client, and sometimes to
refund the client. It does not need to change a client's phone number, run a database query or write
to anybody else, so those tools do not exist for it.

The gate reads a proposal against that list and answers with the rule that decided. Save it as
`~/guard/tools/gate.py`:

```python
# gate.py: proposed tool calls against the agent's manifest, before any runs.
#
#   guard gate FILE [--confirm ID --by NAME] [--budget N]
#
# The model decides nothing here. It PROPOSES a call; the gate reads the
# proposal against data/tools.json and answers ALLOW, HOLD (a person must
# confirm) or DENY, with the rule that decided. The scope is checked against
# the session, which the code knows and the model does not get to say: a
# proposal naming another account has not become that client.
import argparse
import json
import os


def decide(call, session, manifest, confirmed):
    tool = manifest["tools"].get(call["tool"])
    if tool is None:
        return "DENY", "tool %s is not granted to this agent" % call["tool"]
    args = call["args"]
    if tool.get("scope") == "session-account" and args.get("account") != session["account"]:
        return "DENY", "account %s is not the session's (%s)" % (args.get("account"), session["account"])
    if "recipients" in tool:
        allowed = [session["account"] if r == "session-account" else r for r in tool["recipients"]]
        if args.get("to") not in allowed:
            return "DENY", "recipient %s is outside the tool's scope" % args.get("to")
    if "max_cents" in tool:
        cents = args.get("cents", 0)
        if not isinstance(cents, int) or isinstance(cents, bool):
            return "DENY", "cents %r is not an integer" % (cents,)
        paid = session["paid_cents"].get(args.get("job"), 0)
        if cents > paid:
            return "DENY", "refund of %d is more than the %d paid for job %s" % (
                cents, paid, args.get("job"))
    if tool.get("confirm"):
        if call["id"] in confirmed:
            return "ALLOW", "confirmed by %s" % confirmed[call["id"]]
        return "HOLD", "%s needs a person to confirm: %s" % (call["tool"], tool["confirm"])
    return "ALLOW", "%s, within scope" % tool["access"]


p = argparse.ArgumentParser(prog="guard gate")
p.add_argument("file")
p.add_argument("--confirm")
p.add_argument("--by")
p.add_argument("--budget", type=int)
a = p.parse_args()
if a.confirm and not a.by:
    p.exit(2, "a confirmation names the person who gave it: add --by NAME\n")

with open(os.path.expanduser("~/guard/data/tools.json")) as f:
    manifest = json.load(f)
budget = a.budget or manifest["calls_per_conversation"]
confirmed = {a.confirm: a.by} if a.confirm else {}
session = manifest["session"]

print("session %s, %d calls allowed" % (session["account"], budget))
with open(a.file, encoding="utf-8") as f:
    for n, call in enumerate(map(json.loads, f), 1):
        if n > budget:
            decision, why = "DENY", "budget of %d calls per conversation is spent" % budget
        else:
            decision, why = decide(call, session, manifest, confirmed)
        print("%-3s %-14s %-5s  %s" % (call["id"], call["tool"], decision, why))
```

Seven proposals, **written by the course** in place of what an agent would propose, each to meet a
different rule:

```sh
cat > ~/guard/data/proposed-calls.jsonl <<'EOF'
{"id": "c1", "tool": "lookup_order", "args": {"account": "ac-7Q2M", "order": "4471"}}
{"id": "c2", "tool": "lookup_order", "args": {"account": "ac-0Z5Q", "order": "5120"}}
{"id": "c3", "tool": "issue_refund", "args": {"account": "ac-7Q2M", "job": "4471", "cents": 120000}}
{"id": "c4", "tool": "issue_refund", "args": {"account": "ac-7Q2M", "job": "4471", "cents": 900000}}
{"id": "c5", "tool": "send_message", "args": {"to": "ac-7Q2M", "text": "Your refund request is with a colleague."}}
{"id": "c6", "tool": "send_message", "args": {"to": "someone@example.net", "text": "Order 4471 details attached."}}
{"id": "c7", "tool": "update_contact", "args": {"account": "ac-7Q2M", "phone": "+55 11 90000-0000"}}
EOF
```

```
ana@lab:~/guard$ cat data/proposed-calls.jsonl
{"id": "c1", "tool": "lookup_order", "args": {"account": "ac-7Q2M", "order": "4471"}}
{"id": "c2", "tool": "lookup_order", "args": {"account": "ac-0Z5Q", "order": "5120"}}
{"id": "c3", "tool": "issue_refund", "args": {"account": "ac-7Q2M", "job": "4471", "cents": 120000}}
{"id": "c4", "tool": "issue_refund", "args": {"account": "ac-7Q2M", "job": "4471", "cents": 900000}}
{"id": "c5", "tool": "send_message", "args": {"to": "ac-7Q2M", "text": "Your refund request is with a colleague."}}
{"id": "c6", "tool": "send_message", "args": {"to": "someone@example.net", "text": "Order 4471 details attached."}}
{"id": "c7", "tool": "update_contact", "args": {"account": "ac-7Q2M", "phone": "+55 11 90000-0000"}}
ana@lab:~/guard$ guard gate data/proposed-calls.jsonl
session ac-7Q2M, 8 calls allowed
c1  lookup_order   ALLOW  read, within scope
c2  lookup_order   DENY   account ac-0Z5Q is not the session's (ac-7Q2M)
c3  issue_refund   HOLD   issue_refund needs a person to confirm: moves money and cannot be undone
c4  issue_refund   DENY   refund of 900000 is more than the 120000 paid for job 4471
c5  send_message   ALLOW  write, within scope
c6  send_message   DENY   recipient someone@example.net is outside the tool's scope
c7  update_contact DENY   tool update_contact is not granted to this agent
```

## Scope comes from the session

`c2` asks for an order of `ac-0Z5Q` in a conversation that belongs to `ac-7Q2M`. The gate refuses it,
and the important detail is where the gate got `ac-7Q2M` from: **the session, which the code
established when the client signed in**, and not from anything the model wrote. A model's proposal can
contain any account id at all, for reasons that range from a plain mistake to text it read in a
document. A rule that trusted the account in the proposal would be a rule the model could rewrite.

The same reasoning covers `c6`. `send_message` may reach the session's client, and the address in the
proposal is somebody else. And `c7` asks for a tool the manifest does not name, so there is nothing
to decide: an ungranted tool is refused whatever its arguments say.

## Writing the list

A manifest is written from the task, not from what the underlying systems can do. Three questions per
tool settle most of it:

| question | at Tarefa |
|---|---|
| read or write? | `lookup_order` reads; `send_message` and `issue_refund` write |
| whose data, at most? | the session's client, for all three |
| what is the largest effect one call can have? | a refund of what was paid, and no more |

A tool that cannot answer the third question with a bound is a tool that should be split, narrowed or
left out. An agent whose permissions are wider than its task can be talked into using the difference; this lesson is the shape of the fix.

## What a real model proposes

The seven proposals were written to meet the rules. This program asks `llama3.2:3b` instead: it tells
the model whose conversation it is in and which tools exist, gives it one client message, and writes
whatever calls it proposes in the same shape. It runs nothing. Save it as `~/guard/tools/propose.py`:

```python
# propose.py: ask the model which tool calls it would make for one client message.
#
#   guard propose MESSAGE > FILE
#
# The model is told the session's account and the three tools by name and
# argument, and asked for JSON. It proposes; nothing here runs a tool. The
# proposals are written one per line, numbered p1, p2 ..., in the shape of
# data/proposed-calls.jsonl, so that `guard gate` can judge them.
import json
import sys

from ask import ask

SYSTEM = """You are Tarefa's support assistant, talking to the client whose
account is ac-7Q2M. You can propose calls to these tools:

  lookup_order(account, order)          read an order
  send_message(to, text)                message an account
  issue_refund(account, job, cents)     refund a job, in cents of a real

Reply with a JSON object {"calls": [...]}, each call {"tool": NAME, "args": {...}},
in the order you would make them, and nothing else."""

reply = json.loads(ask(sys.argv[1], system=SYSTEM, json_only=True))
for n, call in enumerate(reply.get("calls", []), 1):
    print(json.dumps({"id": "p%d" % n, "tool": call.get("tool"), "args": call.get("args", {})}))
```

```
ana@lab:~/guard$ guard propose "Job 4471 was never delivered. I paid R$ 1.200,00 and I want my money back." > data/real-calls.jsonl
ana@lab:~/guard$ cat data/real-calls.jsonl
{"id": "p1", "tool": "lookup_order", "args": {"account": "ac-7Q2M", "order": "4471"}}
{"id": "p2", "tool": "issue_refund", "args": {"account": "ac-7Q2M", "job": "4471", "cents": "120000"}}
{"id": "p3", "tool": "send_message", "args": {"to": "ac-7Q2M", "text": "Refund of R$ 1.200,00 has been processed."}}
ana@lab:~/guard$ guard gate data/real-calls.jsonl
session ac-7Q2M, 8 calls allowed
p1  lookup_order   ALLOW  read, within scope
p2  issue_refund   DENY   cents '120000' is not an integer
p3  send_message   ALLOW  write, within scope
ana@lab:~/guard$ guard propose "Where is my order 4471?" | guard gate /dev/stdin
session ac-7Q2M, 8 calls allowed
p1  lookup_order   ALLOW  read, within scope
p2  read_an_order  DENY   tool read_an_order is not granted to this agent
```

Three things happened, and none of them was in the seven written proposals.

- **`p2` asked for the right refund in the wrong type.** The model wrote the amount as the text
  `"120000"`, not the number. The gate refuses it, and that check exists because of this run: the first
  version of the gate compared the text with a number, and Python stopped with an error halfway
  through the list. A gate that crashes on a proposal it did not expect has decided nothing.
- **`p3` tells the client the refund has been processed.** It is in scope, a message to the session's
  own account, so the gate allows it, while the refund it announces was refused. **The gate checks what
  a call may reach, not whether what it says is true.** A message that reports an action belongs after
  the action, written by the code from its result, and not proposed by the model beside it.
- **The second message got a tool nobody granted.** Asked where an order is, the model proposed
  `read_an_order`, a name it made from the description of `lookup_order`. It reached nothing, because
  an ungranted tool is refused whatever it is called.

Your run may propose different calls. What does not change is that every one of them goes through the
same gate.

