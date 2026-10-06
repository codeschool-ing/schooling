---
title: An agent gets the tools its task needs, and no wider
version: 1
---

When a model is given tools, it does not call them. **It writes a proposal for a call**, a tool name
and its arguments, and the application decides whether to run it. That moment is the whole of this
lesson. An application that runs every proposal has handed the model its own permissions; one that
checks every proposal against a written list has kept them.

Tarefa's support assistant is the case. The list of what it may do is `data/tools.json`:

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

The calls in `data/proposed-calls.jsonl` **were written by the course** in place of what an agent
would propose; no model proposed them. Each meets a different rule:

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
left out. Lesson 7 looks at what goes wrong when an agent's permissions are wider than its task; this
lesson is the shape of the fix.
