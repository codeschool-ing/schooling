---
title: First hypotheses
version: 1
---

Exploration ends with hypotheses, not conclusions. A **hypothesis** is a statement precise enough
to be wrong, written down together with what would show it is wrong. The findings of this lesson
give three, and each is written in that form:

| Hypothesis | Comes from | Would be refuted by |
|---|---|---|
| December's household growth is Christmas shopping, not new customers | December households a third above November | December's growth coming from customers whose first order is in December |
| The evening wave is people ordering after work, for the next day | orders peaking at 19 o'clock | evening orders whose deliveries are scheduled for the same night |
| Bigger orders cost more mostly through more items, not dearer ones | Spearman 0.644, Pearson 0.427 without companies | the median price per line rising as strongly with the number of lines |

Three habits make a list like this useful rather than decorative.

- **Each one names the data that could refute it.** The first can be checked today, with lesson 12's
  `per_customer` table and its `first` column. The second cannot: the files have no scheduled
  delivery time, so the hypothesis also says what data would have to be collected.
- **None of them is reported as a finding.** "December is Christmas shopping" may well be true, and
  until the check is run, a report says that December was a third higher and that Christmas is the
  leading explanation, not that Christmas caused it.
- **The surprises go on the list first.** The sugar price and the corporate orders looked like
  business facts at first sight and were data defects. A hypothesis list that only contains what
  everybody expected has not explored anything.

Lesson 3 is worth remembering here as well. The survey's NPS looked like a measurement of
satisfaction, and it was a measurement of who chose to answer. **Any hypothesis built on a column
with a known gap carries the gap with it**, and saying so belongs in the same row of the table.
