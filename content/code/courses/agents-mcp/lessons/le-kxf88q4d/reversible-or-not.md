---
title: Can the action be undone?
version: 1
---

The question that decides how much freedom an agent gets is not how clever its model is. It is what the worst wrong step costs, and whether it can be taken back. Sort every tool an agent might have by that, before writing any of them:

| kind of action | Marginalia's example | undone by |
|---|---|---|
| **reads** | `get_order`, `search_help`, `get_book` | nothing needed: reading again is free |
| **drafts** | write a reply for a person to send | the person not sending it |
| **reversible writes** | add a note to an order, put a hold on it | removing the note, lifting the hold |
| **writes with a cost to reverse** | issue a refund, cancel an order | another transaction, and an apology |
| **irreversible or external** | send an email, post publicly, delete a customer's data | nothing: it has happened |

An agent whose tools are all in the first two rows can be wrong freely, because nothing it does reaches the world before a person does. **The design question starts at the third row**, and the answer gets stricter row by row: the refund tool in lesson 17 checks its own limits, records who approved it, and asks a person before it runs.

## The direction of the error matters

Two mistakes are possible with any risky tool, and they do not cost the same. Refusing a refund that was due costs a customer a second message and costs the shop some goodwill. Issuing a refund that was not due costs money that rarely comes back. A design that leans one way on purpose is better than one that pretends both mistakes are equally bad: **for writes with a cost, an agent that stops and asks is the cheaper failure.**

## Undo is a feature you build

"Reversible" is not a property of an action in the abstract. Deleting a file is reversible on a system that keeps a trash folder and irreversible on one that does not. A refund is reversible only if the payment system supports charging back. So part of making an agent safe is building undo into the tools it calls: soft deletes, holds instead of cancellations, drafts instead of sends. **Moving a tool up the table is often cheaper than guarding it where it is.**
