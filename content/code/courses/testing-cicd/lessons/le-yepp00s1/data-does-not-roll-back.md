---
title: What a rollback cannot undo
version: 1
---

`rollback.sh` moves a link. It returns the **code** to its previous state, and nothing else. Anything
the bad release did to the world outside its own directory stays done.

## Data

A release that ran a migration changed the database. Rolling back the code leaves the new schema in
place, and the old code now meets a database it was not written for. If the migration renamed a
column, the old code asks for a column that no longer exists, and the rollback fails in a new way.

This is why lesson 7's **expand and contract** matters here. A change to the schema is split into
releases that each work with both the old shape and the new: add the new column, write to both, copy
the old rows across, move the readers, then stop writing the old column and drop it. At every step the release before can still run against
the database as it is, so at every step a rollback is safe. The destructive part, dropping the old
column, comes last, in a release of its own, once nobody needs to go back past it.

## Everything else that left the building

- **Messages and e-mails sent.** A release that e-mailed every customer the wrong delivery date has
  sent those e-mails. Rolling back stops the next ones.
- **Payments taken, orders placed, labels printed with the carrier.** These are facts in somebody
  else's system now, and undoing them is a business process, not a deploy.
- **Caches and queues.** A release that wrote a new format into a shared cache, or published messages
  the old consumers cannot parse, has left them for whoever runs next.

## So, before a release that touches state

Ask one question at review time: **if we roll this back an hour after it ships, what is left
behind?** If the answer is "nothing", rollback is a full undo. If the answer is a schema, a message
format or a sent e-mail, the release needs either an expand-and-contract plan, or a flag that lets
the new behaviour be turned off without moving the code, or both.
