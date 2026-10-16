---
title: Segment's other half: events and identity
version: 1
---

Everything so far started from a table. Segment's original job starts from a person clicking: the shop's
website and app call Segment's library, which sends one message per thing that happened, and Segment
forwards it to the warehouse and to any tool connected to it. Its specification has a few kinds of call,
and three carry most of the traffic:

| call | what it says | Lantern's example |
|---|---|---|
| `page` (or `screen` in an app) | somebody is looking at this page | the product page for a lamp |
| `track` | somebody did this, with these properties | *add_to_cart*, product 4, quantity 1 |
| `identify` | this visitor is this person | the visitor signed in as customer 1500 |

Lantern's `web_events` is the warehouse end of exactly this: one row per event, in a session. What it
lacks is the link to a customer, and that is the hard part every event collector has to solve.

## Two ids for one person

Before somebody signs in, the library gives the browser a random **anonymous id** and sends it with every
event. When they sign in, `identify` sends the anonymous id together with the **user id**, which is the
shop's customer id, and from then on both are known to belong to one person. The events from before
sign-in can then be counted as that customer's.

What goes wrong is predictable:

- **The same person on two devices** has two anonymous ids, joined only if they sign in on both.
- **Somebody who clears cookies** comes back as a new anonymous id, and is a new visitor in every count.
- **The user id has to be the shop's id**, never an e-mail address, for lesson 7's reason: it is the one
  key that does not change.

This is also how Segment bills its event collection, which the last section returns to: by **monthly
tracked users**, people seen in a month, and an anonymous visitor who never signs in counts as one of
them.
