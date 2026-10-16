---
title: Listing the suspects
version: 1
---

By now the question is narrow: why were 828 fewer online orders paid in October 2025 than in
October 2024, at the same average ticket? A narrow question still has several possible answers,
and the habit that separates a diagnosis from a story is **writing all of them down before testing
any**. The first explanation somebody likes tends to be the last one anybody checks.

## The checklist: what else changed?

Most changes in a retailer's month come from a short list of places. Lívia's list, with the
evidence that bears on each:

| suspect | what would show it | what Varanda's data said |
|---|---|---|
| the calendar | fewer weekend days or a holiday on a weekday | 8 weekend days in both Octobers; the 12 October holiday fell on a weekend both years |
| prices | a different average ticket | R$ 350 in both Octobers |
| stock | best-sellers out of stock on the site | no product in the online top 20 out of stock for more than a day |
| the data itself | the site's own count of orders disagreeing with the database's | both say 3,086 paid orders |
| campaigns | a campaign in one October and not the other | the yearly online campaign ran 21–31 October 2024, and 3–13 November 2025 |

**The data itself is on the list on purpose.** A pipeline that stops copying orders for three days
produces exactly the shape the tree found, one channel falling with an unchanged ticket, and it is
the cheapest suspect to test. Tiago Ramos, who maintains the pipelines, compared the online shop's
own count of paid orders with the database's for every day of October, and they matched.

## Testing the campaign

One suspect was left standing: the campaign moved. Renata Sá's team had run the online shop's yearly
campaign over the last eleven days of October in 2024. In 2025 they moved it to the first two weeks
of November, to sit closer to the season's biggest shopping days. A suspect left standing is not yet a
cause. Lívia tested it two ways.

**First, by splitting October 2024 at the campaign.** If the campaign explains the fall, October
2025's ordinary days should look like October 2024's ordinary days, a little better, and not like its
campaign days. Type the orders in a small table:

| | A | B | C |
|---|---|---|---|
| 1 | | days | orders |
| 2 | Oct 2024, 1–20, no campaign | 20 | 1760 |
| 3 | Oct 2024, 21–31, campaign | 11 | 2154 |
| 4 | Oct 2025, 1–31, no campaign | 31 | 3086 |

and divide each by its days:

```localised
=ROUND(C2/B2,1)      88
=ROUND(C3/B3,1)      195.8
=ROUND(C4/B4,1)      99.5
```

October 2025's ordinary days averaged 99.5 orders, 13.1% more than the 88 of October 2024's
ordinary days. The campaign days of 2024 averaged 195.8. **October 2025 did not lose customers; it
lost eleven campaign days.**

**Second, by putting October and November together.** If the campaign only moved, what October lost
November should have gained. Online, October and November 2024 sold R$ 3,030 thousand; in 2025 they
sold R$ 3,140 thousand, 3.6% more. November's online shop alone grew 24.1%.

## What is left over

The campaign explains why October fell. It does not explain everything. Taken together, October and
November 2025 grew 3.9% over the same two months of 2024, below the year's 5.7%, and the stores grew
3.9% over the two months as well. **Something kept the end of the year a little under the rest of
it, and the campaign is not that something.** Lívia wrote the leftover into her report as an open
question rather than stretching the campaign to cover it. That is the subject of the next section:
how to say what a diagnosis found, and no more.
