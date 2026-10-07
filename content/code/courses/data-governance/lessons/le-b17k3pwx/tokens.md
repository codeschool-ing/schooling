---
title: Tokens
version: 1
---

Ipê's database has held tokens since the first lesson, and they are the clearest example of the
idea. Customers pay by card, and the payments table has never seen a card number:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT method, card_token, card_last4, amount_cents FROM sales.payments WHERE method = 'card' ORDER BY order_id LIMIT 3"
SET
 method |      card_token      | card_last4 | amount_cents 
--------+----------------------+------------+--------------
 card   | tok_bbc2f3feed7b87e2 | 1195       |         7970
 card   | tok_7047e508b313e1b0 | 5129       |         1590
 card   | tok_9945210f5943d04f | 4814       |        12730
(3 rows)
```

**`card_token` is a stand-in.** The payment provider received the card number from the customer's
browser, stored it in its own vault, and gave Ipê back a random reference: `tok_` followed by
sixteen hexadecimal characters. Ipê can charge that card again by sending the token to the provider,
refund it, and show the customer "the card ending in 1195" — and never holds a number anybody could
use at a shop.

That is **tokenisation**, and it has three parts:

- **the token** — a value with no relation to the original that could be computed: random, or drawn
  from a counter. Nothing about `tok_bbc2f3feed7b87e2` says which card it is;
- **the vault** — the one place that maps tokens back to values, run by somebody else or by a small,
  separate, heavily guarded system;
- **detokenisation** — the operation of asking the vault for the original, granted to almost
  nobody, and logged.

The arrangement moves risk, deliberately. Card numbers are governed by the payment card industry's
standard, PCI DSS, and every system that stores, processes or transmits one is in its scope, with
the audits that come with it. **By never receiving a card number, Ipê's database, its backups and
its analysts are out of that scope.** The provider's vault is in it, and that is the provider's
business.

`card_last4` is a different thing: a **truncated** value, kept because the customer needs to
recognise their card. Four digits of sixteen identify a card to its owner and to nobody else.

## A vault Ipê would run itself

The same pattern works for any value: a table in a schema of its own, holding token and value,
readable by one function that only a few roles may execute, writing a line to an audit table on
every call. It is the right design when the original has to come back in clear somewhere — a
document sent to a court, a report to a tax authority — and the people who need it are few.

For the CPF, Ipê does not need a vault of that kind. Support needs two things from a CPF: to
**read it** to the customer, which lesson 4's encrypted column already does through OpenBao, and to
**find a customer by it** when they read it out. Finding needs a stand-in that is *the same every
time for the same CPF*, which a random token is not — and the next section builds one.
