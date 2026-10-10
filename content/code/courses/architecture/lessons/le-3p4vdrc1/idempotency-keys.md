---
title: Idempotency keys, and the payment that was sent twice
version: 1
---

The same problem exists without any broker. A shopper presses "pay", the request reaches the payments
API and the card is charged, and then the connection drops before the response arrives. The browser,
or the shop's server, cannot tell whether the charge happened, lesson 2's uncertainty exactly. Retrying
might charge twice; not retrying might leave the order unpaid.

**The fix is a key chosen by the caller, sent with every attempt of the same request.** The caller
generates a unique value once, for this payment, and sends it with the first attempt and with every
retry, commonly in a header called `Idempotency-Key`. The server stores each key with the response it
produced:

| the server sees a key that is… | it does |
| --- | --- |
| new | the work, then stores the key and the response together |
| already stored with a response | nothing new: it returns the stored response |
| stored and still in progress | answers `409 Conflict`, so the caller waits and asks again |

Stripe's API made this pattern widely known, and an IETF draft describes the `Idempotency-Key` header
for HTTP in general. Two rules make it work:

- **The caller creates the key, not the server**, because the point is to identify the attempt across
  a failure the server may never have seen.
- **The key is created once per intended operation, before the first attempt**, and stored by the
  caller, so that a retry after the caller itself restarts still sends the same one. A key generated
  fresh for each retry identifies nothing.

The server's storage of keys is the `processed` table of the previous section, with the response kept
beside it. The broker's message id and the HTTP key are the same idea in two places: **a stable name
for one intended effect, so that every repeat can be matched to it.**

## Where Quitanda needs one

Wherever an effect is not naturally idempotent and a retry is possible: charging a card, creating an
order from a checkout form that a nervous customer submits twice, sending a refund, decrementing stock.
In each case the identifier already exists or is cheap to create, the order id, the checkout session,
and the expensive version is the one discovered after a customer's bank statement shows it twice.
