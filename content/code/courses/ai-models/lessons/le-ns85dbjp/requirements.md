---
title: Writing the thresholds down
version: 1
---

Before looking at a single model, ana writes down what any model has to do. It is a short file in
the project, and it is the only defence against choosing by whichever table she happens to read
first:

| requirement | why | kind |
|---|---|---|
| returns valid JSON matching a schema | the extraction task feeds another program | threshold |
| window of at least 32,000 tokens | the drafting task sends the shop's policy, about 5,000 tokens, and long threads | threshold |
| processing allowed for customer e-mail under the shop's terms | lesson 2 section 07 | threshold |
| reads and writes Portuguese well | the customers write in it | threshold, measured in lesson 5 |
| sorts at least 35 of 40 cases as a person would | below that, a person has to check everything anyway | threshold, measured in lesson 5 |
| costs as little as possible | the shop is small | rank |
| replies quickly enough that an agent waiting on a draft does not give up | it sits in front of a person | rank, with a ceiling |

Some of those can be checked against the sheet at once. `sheet.py pick` filters every chat entry
with a price; `--needs` and `--min-window` apply two of her thresholds:

```
ana@desk:~/desk$ python sheet.py pick | sed -n 2p
2990 entries pass
ana@desk:~/desk$ python sheet.py pick --needs response_schema --min-window 32000 | sed -n 2p
1617 entries pass
ana@desk:~/desk$ python sheet.py pick --needs response_schema --min-window 32000 --max-in 1 | sed -n 2p
893 entries pass
```

From 2,990 priced chat entries, the two thresholds leave **1,617**: structured output and a window
of 32,000 rule out almost half. The third command adds a ceiling of $1 a million input tokens,
which is not one of her thresholds and is there to show what happens when a preference is used as
a filter: **893**, and the cheapest on that list are entries she has never heard of, at prices that
look like mistakes.

## What the sheet cannot filter

Three of the seven rows above are not in any sheet: whether the terms allow her use, whether the
Portuguese is good, and the accuracy on her cases. The first is a document to read for each
provider (lesson 2). The other two are measurements, and the sheet's 1,617 entries are far too many
to measure.

So ana narrows by hand to a **short list**: a handful of models from providers whose terms she has
read, at least one open-weight model for the option lesson 3 asked her to keep, spread across
price levels. Section 08 shows hers. The short list is a judgement, and it is the one place in this
method where judgement is right: the measuring that follows will correct a bad choice of
candidates, as long as there are several.
