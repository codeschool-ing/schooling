---
title: The costs, and when to pay them
version: 1
---

Event sourcing is one of the patterns most often regretted, and the regret is rarely about the idea.
It is about costs that only arrive later:

| cost | why it arrives | what people do |
| --- | --- | --- |
| **events are forever** | an event written in 2024 with a field called `units` must still be read in 2030, after the code has renamed it three times | version the event types, and **upcast** old versions to new ones as they are read |
| **replays get slow** | an order with 5,000 events is 5,000 rows to read on every command | save a **snapshot** every few hundred events and replay only what comes after it |
| **erasing a person** | an append-only store cannot delete what the LGPD says must be deleted | keep personal data outside the events, or encrypt it per person and delete the key (**crypto-shredding**) |
| **every read model lags** | projections are copies, lesson 9 applies everywhere | read-your-writes from the command's answer; show staleness where it matters |
| **a different way of thinking** | the team has to model changes as facts, and most code and tools assume tables of current state | start with one part of the system that clearly benefits, not all of it |

## When it is worth it

CQRS without event sourcing is a modest step, and often a good one: a read model kept by a projection
or an outbox, where one query has outgrown the write model. **Event sourcing is a bigger commitment**,
and earns it where the history is itself the product: money, stock movements, anything audited, anything
where "what did it look like on the 3rd" is a question somebody asks.

For Quitanda, that points at the **payments and the stock ledger**, which are already append-only in
spirit. It does not point at the catalogue, where nobody will ever ask what a product's description
said in March, and an ordinary table with a read replica is all the design needs.

When you are done, stop the lab:

```sh
docker compose down -v
```
