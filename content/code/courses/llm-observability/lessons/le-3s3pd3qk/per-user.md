---
title: Cost per user
version: 2
---

The same bill, by the pseudonym lesson 2 put on every root span:

```
ana@dev:~/obs$ python bill.py --by user --top 6
user               requests    input  output  cost US$  per 1k  share  features
f71cf97066359de1         14     1256     589    0.0061    0.43   4.2%  summary
1c6130a39563f0ad         13     1281     573    0.0058    0.44   4.0%  summary
e01da6591c8e42f4         10     1896     371    0.0054    0.54   3.7%  help/order
71a47489cab1d256          9     1826     301    0.0050    0.56   3.5%  help/order
2b86d5011760317d         11     1739     271    0.0049    0.44   3.4%  help/order
91aa3bdfe71fb999          7     1453     222    0.0045    0.65   3.2%  help/order
total                   311    53240    8005    0.1434    0.46
```

**The two heaviest users are not customers.** Their only feature is `summary`: they are two of the
support team's three people, summarising conversations all week, 36 requests between the three. The pseudonym hides
who they are, which is its job, and the feature column says what they are, which is enough. A view of
cost per user that does not also show what each user did would have sent somebody to investigate two
customers who do not exist.

After them, the customers. No customer reaches 4% of the week, and the six heaviest users, staff
included, add up to 22%.
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
