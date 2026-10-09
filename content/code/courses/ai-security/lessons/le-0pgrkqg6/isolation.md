---
title: Tools that run apart from the model, with limits of their own
version: 2
---

The gate decides which calls run. **Isolation decides what a call can reach when it does run**, and
it is the layer that still holds when the gate has a bug.

## The tool's credentials are the tool's

A tool that refunds a job needs a credential for the payments system. That credential lives with the
tool, on the server, and the model never sees it: not in the system prompt, not in a tool result,
not in an error message. A model that never held a key cannot leak it, whatever ends up in its
context. The same goes for scope: `lookup_order` runs with a database user that can read orders and
nothing else, so a query it was never meant to make fails at the database too.

## A budget per conversation

An agent works in a loop: propose a call, read the result, propose the next. A loop with no end costs
money at best and repeats a harmful action at worst, and the cheapest guard is a count:

```
ana@lab:~/guard$ guard gate data/proposed-calls.jsonl --budget 4
session ac-7Q2M, 4 calls allowed
c1  lookup_order   ALLOW  read, within scope
c2  lookup_order   DENY   account ac-0Z5Q is not the session's (ac-7Q2M)
c3  issue_refund   HOLD   issue_refund needs a person to confirm: moves money and cannot be undone
c4  issue_refund   DENY   refund of 900000 is more than the 120000 paid for job 4471
c5  send_message   DENY   budget of 4 calls per conversation is spent
c6  send_message   DENY   budget of 4 calls per conversation is spent
c7  update_contact DENY   budget of 4 calls per conversation is spent
```

With a budget of four, the fifth proposal is refused whatever it is. Tarefa's manifest allows eight,
which is enough for a support conversation and too few for a runaway one. When the budget is spent,
the conversation goes to a person, the same fallback as the retry loop of lesson 9.

## Everything leaves a record

Every proposal, every decision and its reason, every confirmation and its author goes to the log,
under the request id and the end-user identifier from lesson 7. The logs of lesson 11 apply: the
arguments of a call are personal data when they name a person, and are redacted and expire like the
rest.

Three layers, then, and an action has to pass all of them: the manifest and its scope, the person who
confirms what matters, and the credentials and budget that bound what a call can do once it runs.
