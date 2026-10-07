---
title: Least privilege for an agent
version: 2
---

An agent can do whatever its tools can do, and a model's choice of tool and arguments is the output
of the loop of lesson 1 section 06: likely, not guaranteed. Lesson 11 adds a worse case, text inside
a tool result written to steer the model. **So every limit is enforced below the model, in the host
or in the tool, where the model's choices cannot reach.**

## The tool refuses what it should not do

A model that asks for a handbook page named `../../.env` is asking the tool to read a file outside
the handbook. The tool does not trust the argument:

```
ana@dev:~/shop$ python scratch/tools.py read_handbook shipping
is_error: False | # Shipping

Orders ship within two working days from the warehouse in Campinas. Delivery
i
ana@dev:~/shop$ python scratch/tools.py read_handbook ../../.env
Tool 'read_handbook' failed: "Error executing tool read_handbook: '../../.env' is not a page of the handbook; the pages are: account, contact, coupons, payment-errors, products, returns, shipping, warranty"
is_error: True | Error executing tool read_handbook: '../../.env' is not a page of the handbook; the pages 
```

The first call reads the page. The second is refused by the tool, with a message the model can act
on, and the server logs it on its own error output, the first line. **The check is about what the
argument resolves to**, not what it looks like: `resolve()` turns `../../.env` into a real path, and
the path is compared with the handbook's folder.

## A person approves what changes things

`issue_refund` is the one tool that is not read-only, so the host asks before calling it. Here the
operator says no:

```
ana@dev:~/shop$ echo n | python agent.py "Refund order 1042, the customer changed their mind."
[1] call:   issue_refund({"cents": "0", "order_id": "1042"})
allow issue_refund({"cents": "0", "order_id": "1042"})? [y/N] n
[1] result: refused by the operator
[2] model:  Unfortunately, the refund for order 1042 has been refused by the operator. Can I assist you with anything else?
host: 2 requests, 398 input tokens: [290, 108]
ana@dev:~/shop$ cat data/refunds.log
cat: data/refunds.log: No such file or directory
```

The host returned *refused by the operator* to the model as an error result, the model reported it,
and the refunds log does not exist: **nothing was paid.** The same request with a yes:

```
ana@dev:~/shop$ echo y | python agent.py "Refund order 1042, the customer changed their mind."
[1] call:   issue_refund({"cents": "0", "order_id": "1042"})
allow issue_refund({"cents": "0", "order_id": "1042"})? [y/N] y
[1] result: refunded 0 cents on order 1042
[2] model:  Refund of 0 cents has been processed for order 1042.
host: 2 requests, 403 input tokens: [290, 113]
ana@dev:~/shop$ cat data/refunds.log
1042 0
```

**A refund of zero, approved, paid and logged.** The model asked for `"cents": "0"`, a string, for
an order of 79.80 in mugs. The server's schema says `cents` is an integer and quietly turned `"0"`
into `0`, the tool has no rule against refunding nothing, and the operator answered `y` to a prompt
that showed the zero in plain sight. Every layer did what it was built to do, and none of them was
built to refuse this.

That is the case for the approval showing the exact arguments, and for reading them: a person
approving "a refund" is not approving "a refund of 0 cents on order 1042". And it is the case for
the second rule below. `issue_refund` should refuse an amount below one cent or above what the order
cost, whoever asked and whoever approved, because the tool is the one place every call passes
through.

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
