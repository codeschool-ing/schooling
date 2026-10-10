---
title: Telling the customer
version: 1
---

Everything so far happened in the systems. The person in front of the screen sees none of it: they see
a number, a button, and whether the two make sense together. **An eventually consistent system is
judged by its screens**, and a few habits decide whether its windows look like bugs.

- **After a write, show the write's answer.** The checkout returns the order it created; the page that
  follows shows that order, not a list read back from a copy that may not have it yet. This is the
  cheapest read-your-writes there is.
- **Do not put two copies on one screen.** A header that says "3 items in your basket" from one copy
  and a basket page listing two from another is the disagreement made visible. One screen, one source.
- **Say when a number is approximate.** "Only a few left" rather than "1 left" when the number comes from
  a copy, and the exact count at checkout, from the owner. Lesson 8 put the shelf count on the
  available side for this reason.
- **Give work that happens later a state of its own.** An order is "received", then "confirmed" once
  payment and stock have answered. A refund is "requested", then "done". A person who sees "received"
  understands that something is still happening; a person who sees nothing assumes it failed.
- **Say how old a view is, where age matters.** "Updated 2 minutes ago" over a dashboard turns a stale
  number from a lie into a fact.

## What must not be eventual

Some decisions cannot be made from a copy, whatever the screen says. Taking the last bag of coffee,
charging a card and accepting a price all happen **at the owner**, where the order of changes is one
order, as lesson 8's table chose. A copy may say "1 left"; the checkout asks the stock service, which
may say "sold out", and that answer is the one that counts. When the decision spans several services,
each with its own owner, there is no single place to ask, and lesson 14 is about what to do instead.

When you are done with the lesson, stop its servers:

```sh
docker compose down -v
```
