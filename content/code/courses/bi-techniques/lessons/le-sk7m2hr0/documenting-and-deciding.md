---
title: Writing it down, and deciding not to
version: 1
---

A model outlives the analyst who built it, and is used by people who never read its code. **What it is
for, and what it is not for, has to travel with it.** The usual form is a short document, often called
a **model card**. For Panela's churn model it would say:

| | |
|---|---|
| **purpose** | rank customers active in the last 60 days by their chance of no order in the next 90, to choose who receives a retention offer |
| **not for** | any decision that withholds something from a customer, such as the loyalty club; credit; pricing |
| **data** | orders and customers to 30 June 2025; trained on 31 December 2024, tested on 30 June 2025 |
| **inputs** | overdue, relative order count, tenure, channel, plan; region is not an input |
| **performance** | at a threshold of 0.2: precision 59.2%, recall 67.9% |
| **by group** | false alarms among stayers by region, 6.2% to 10.3%; the North's recall rests on 17 people |
| **known limits** | the save rate of the offer is assumed, not measured; the North is 4% of the data |
| **owner** | who retrains it, who audits it, and who answers questions about it |

The "not for" line is the one that would have stopped the club. It is the deployment bias of lesson
18, prevented in one sentence.

## The person on the other side

**In Brazil the LGPD gives people a right about decisions like these.** Article 20 says a person may
ask for a review of decisions taken solely by automated processing of their data that affect their
interests, including decisions that define their profile as a consumer. They are also entitled to
clear information about the criteria and procedures used, with room left for the company's trade
secrets. A churn score that kept somebody out of a club would be such a decision, and Panela would
have to be able to explain it and to review it. The text once required that review to be made by a
person; that requirement was removed in 2019, so whether a person looks is now the company's choice.

There is still an argument for keeping a person in the loop wherever a model's decision closes a door: not
reviewing every flag, which nobody would do for long, but **a route by which a customer, or an
employee who sees something odd, can ask for a human look**.

## Deciding not to

**Sometimes the right outcome of an audit is that the model is not used.** The club is a good example.
A loyalty club rewards customers for being loyal, and the customer's own order history says that
directly: a customer who has ordered every fortnight for a year is loyal. Predicting loyalty with a
churn model adds a step that can only add errors. The better design is no model at all.

Three questions are worth asking before any model goes into a decision that affects people.

1. **Is a prediction needed**, or is the fact already in the data?
2. **Who is hurt by each kind of error**, and has the audit been run for that error?
3. **Could this decision be explained** to the person it affects, in a sentence they would accept?

A model that fails the first question is unnecessary. One that fails the second is not ready. One that
fails the third should not be making the decision on its own.
