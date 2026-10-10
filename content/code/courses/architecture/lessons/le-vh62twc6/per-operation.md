---
title: Choosing per operation, for Quitanda
version: 1
---

The question CAP leaves, "refuse or risk being wrong?", is answered by the cost of each mistake, and
**the cost differs from one kind of data to the next**, even inside one shop.

| Quitanda's data | if a stale or conflicting answer is given | if the request is refused | choice |
| --- | --- | --- | --- |
| a customer's basket | an item they removed reappears for a minute | they cannot shop at all | availability: keep answering, merge later |
| the catalogue's descriptions and photos | yesterday's photo | the page does not load | availability |
| the units of coffee on the shelf, shown on the product page | "12 left" when there are 11 | no number shown | availability, labelled as approximate |
| taking units out of stock at checkout | two customers buy the last bag | the checkout waits or fails | consistency |
| charging a card | a charge applied twice, or lost | the payment fails, and the customer retries | consistency |
| the price a customer is charged | a price that was already changed | the checkout waits | consistency, at the moment of sale |

Two patterns stand out. **Reads that inform are usually fine stale; writes that commit are usually not.**
The product page can say "12 left" from a standby a second behind, as long as the checkout takes the unit
from the copy that decides. And **"refuse" is often a smaller cost than it sounds**: a failed payment is
retried by a person who sees an error, while a double charge is found weeks later by a person reading a
bank statement.

The rest of the course builds on these choices. Lesson 9 is what the customer sees on the available side,
and how to keep it from being confusing. Lesson 10 is the replication and partitioning underneath. And
lesson 14 shows how a checkout that spans several services keeps the consistent side honest without one
transaction to rely on.

When you are done with the lesson, stop its servers:

```sh
docker compose down -v
```
