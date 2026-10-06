---
title: Investigating a candidate
version: 1
---

A rule produces a list. What turns the list into knowledge is going back to each candidate and asking where it came from. This is the step that is most often skipped, because it is the one that cannot be automated.

## Questions to ask of each candidate

**Is it possible?** A delivery of −5 minutes, a basket of R$ 0.00 for twelve items, a customer aged 212: impossible values are errors, full stop. Lesson 5's advice to look at the range of a column before anything else catches most of them.

**Does the record agree with itself?** A R$ 2,126.00 basket with three items in it is suspicious. A R$ 421.78 basket with 43 items is not. Other columns in the same row are the cheapest evidence there is.

**Does the source agree?** The original receipt, the payment record, the courier's log. If the payment processor charged R$ 212.60, the table's R$ 2,126.00 is a typo, and the fix is to correct it.

**Does it belong to the population?** A restaurant's order, a staff test, an order placed through a partner company that resells: real records, but not the households the analysis is about.

**Is there a pattern?** Several candidates from the same day, the same courier or the same version of the app point at a common cause: a broken scanner, a training day for a new employee, a bug introduced in one release. A pattern is usually a more valuable finding than any one outlier.

## The rainy evening

Lesson 6's boxplots flagged one delivery in Centro: 45.5 minutes, where the median was 30.5. Horta's records answer the first three questions at once. The order held fourteen items, it was a rainy evening, and the courier's log shows the time. It is possible, consistent and confirmed, and it belongs to the population of Centro deliveries. It stays.

That answer is also information. If rainy evenings regularly produce deliveries like this one, a promise of "30 minutes in Centro" needs a footnote for rain, and lesson 19 can put rain into a model of delivery times.

## Who checks

Analysts often cannot check sources themselves: they do not have the receipts, or the system that produced them. The practical step is to **send the list to whoever owns the data**, with the reason each value was flagged. "These 17 baskets are above R$ 202; are any of them test orders or business customers?" is a question a sales manager can answer in an afternoon, and one no rule can.
