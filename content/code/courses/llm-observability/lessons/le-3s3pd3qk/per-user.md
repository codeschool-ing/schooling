---
title: Cost per user
version: 1
---

The same bill, by the pseudonym lesson 2 put on every root span:

```
ana@lab:~/obs$ python bill.py --by user --top 6
user               requests    input  output  cost US$  per 1k  share  features
a1461432bd4296ff         51     3807    2583    0.0251    0.49   3.0%  summary
3bfa9e105a50c997         38     2812    1919    0.0185    0.49   2.2%  summary
3baf8d13359269fa         35     2469    1740    0.0166    0.47   2.0%  summary
6a49ed68660c8f52         23     4583     752    0.0132    0.58   1.6%  help/order
d36cba1f26b7cec0         21     4611     731    0.0132    0.63   1.6%  help/order
78ec3ac003d867c4         23     4342     554    0.0126    0.55   1.5%  help/order
total                  1345   281072   46663    0.8228    0.61
```

**The three heaviest users are not customers.** Their only feature is `summary`: they are the support
team, three people summarising conversations all week, 124 requests between them. The pseudonym hides
who they are, which is its job, and the feature column says what they are, which is enough. A view of
cost per user that does not also show what each user did would have sent somebody to investigate three
customers who do not exist.

After them, the customers. No customer reaches 2% of the week, and the six heaviest users, staff included, add up to 11.9%.
That is a flat curve, and it is a property of the simulated traffic, which picks a user at random for
every request. Real usage is rarely flat. A handful of users, or one integration somebody wrote against
the API, is usually a visible share of the bill, and that is the reason to look per user at all:

- **one account using far more than anyone else** is either the best customer or somebody scripting
  the assistant, and the difference matters;
- **a per-user limit** (the last section) needs the per-user number first;
- **an outlier in cost is often an outlier in behaviour**: the same question asked forty times, a
  conversation that never ends, a prompt somebody is probing.

## Why a pseudonym is enough

None of this needed the user's identity. The counting works on any stable value, which is what lesson
2's HMAC provides. When the number on a row does need a person, a support case or an account to
suspend, the person who holds the key can resolve that one row, and nobody else has to see the rest.
