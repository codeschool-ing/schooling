---
title: Compensation is not rollback
version: 1
---

A rollback makes it as if the change never happened. A compensation cannot. o-3's customer was charged
and then refunded, and **both are facts**: the bank statement shows two lines, an e-mail may have said
"payment received", and for a few seconds the money was gone. A compensation is a new action that
semantically reverses an old one, and it is designed as carefully as the step itself.

Four rules make compensations work:

- **A compensation must not fail for good.** If the refund can fail permanently, the saga can end
  stuck halfway, charged and undelivered. Compensations are retried until they succeed, so they are
  usually operations that can only fail transiently.
- **A compensation must be idempotent**, because it will be retried, as lesson 7 said of every
  repeated step. `release` and `refund` in the lab do nothing the second time, and nothing for an order
  that never reserved or paid.
- **Some steps cannot be compensated**: an e-mail sent, a parcel handed to the carrier, a notification on
  a phone. Put them **last**, after the step that decides the outcome, which the literature calls the
  **pivot**: once it succeeds, the saga only goes forwards. In the lab, scheduling the delivery is the
  pivot, and that is why it has no compensation.
- **Order the steps by how hard they are to undo.** Reserving is cheap to release; charging is less
  cheap to refund (fees, a line on a statement); shipping cannot be undone at all. The checkout runs them
  in that order, so that a failure undoes the cheapest things.

A compensation also has a business meaning that somebody must decide. Refunding is not the only way to
compensate a charge: a voucher, a partial refund, a delivery from another warehouse. That is why sagas
are as much a conversation with the people who run the shop as a technical design.
