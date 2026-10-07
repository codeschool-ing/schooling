---
title: Least privilege for an agent
version: 1
---

An agent can do whatever its tools can do, and a model's choice of tool and arguments is the output
of the loop of lesson 1 section 06: likely, not guaranteed. Lesson 11 adds a worse case, text inside
a tool result written to steer the model. **So every limit is enforced below the model, in the host
or in the tool, where the model's choices cannot reach.**

## The tool refuses what it should not do

A model that asks for a handbook page named `../../.env` is asking the tool to read a file outside
the handbook. The tool does not trust the argument:

```
ana@dev:~/shop$ python lab/tools.py read_handbook shipping
is_error: False | # Shipping

Orders ship within two working days from the warehouse in Campinas. Delivery
i
ana@dev:~/shop$ python lab/tools.py read_handbook ../../.env
Tool 'read_handbook' failed: "Error executing tool read_handbook: '../../.env' is not a page of the handbook"
is_error: True | Error executing tool read_handbook: '../../.env' is not a page of the handbook
```

The first call reads the page. The second is refused by the tool, with a message the model can act
on, and the server logs it. **The check is about what the argument resolves to**, not what it looks
like: `resolve()` turns `../../.env` into a real path, and the path is compared with the handbook's
folder.

## A person approves what changes things

`issue_refund` is the one tool that is not read-only, so the host asks before calling it. Here the
operator says no:

```
ana@dev:~/shop$ echo n | python agent.py "Refund order 1042, the customer changed their mind."
[1] call:   issue_refund({"order_id": "1042", "cents": 7980})
allow issue_refund({"order_id": "1042", "cents": 7980})? [y/N] n
[1] result: refused by the operator
[2] model:  The refund was not issued: the operator declined it.
ana@dev:~/shop$ cat data/refunds.log 2>&1
cat: data/refunds.log: No such file or directory
```

The host returned *refused by the operator* to the model as an error result, the model reported that
the refund was not issued, and the refunds log does not exist: **nothing was paid.** The same request
with a yes:

```
ana@dev:~/shop$ echo y | python agent.py "Refund order 1042, the customer changed their mind."
[1] call:   issue_refund({"order_id": "1042", "cents": 7980})
allow issue_refund({"order_id": "1042", "cents": 7980})? [y/N] y
[1] result: refunded 7980 cents on order 1042
[2] model:  Refunded 79.80 on order 1042, the two mugs. Shipping was not refunded, since the handbook refunds it only when the whole order is returned.
ana@dev:~/shop$ cat data/refunds.log
1042 7980
```

One refund, logged, for the 79.80 the model asked for. The approval showed the exact arguments before
anything happened, which is the point: a person approving "a refund" is not approving "a refund of
7980 cents on order 1042".

## The rules

- **Read-only by default.** Give an agent tools that only read until it has a reason to change
  something, and then one narrow tool for that change.
- **Check arguments in the tool.** Paths, amounts, ids that must belong to the current customer. The
  schema checks types; the tool checks meaning.
- **Ask a person before anything that costs money, sends a message, deletes or publishes**, and show
  them the arguments, not a summary.
- **Run the agent with the least access that works**: its own credentials, scoped to what its tools
  need, never the developer's own.
- **Log every call and every result**, with who approved what. When an agent does something
  surprising, the log is the only account of why.
