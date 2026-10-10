---
title: Showback: each team's share, and the part with no name
version: 1
---

The second translation divides the bill by team. Two wrong ideas get in the way of starting. One is
that the split has to be exact before anybody sees it, so the work waits for perfect labelling that
never arrives. The other is to divide the bill evenly, which is quick and tells every team the same
useless number. **A first showback is approximate, published, and corrected in public**, and that
is enough to change what teams do.

## Tags, and what has none

A tag is a label on a cloud resource naming who owns it. Rafaela's Platform team asked every team
to tag its resources with its name, and after a month the bill split like this:

| team | tagged cost, one month |
|---|---|
| Checkout | R$ 58,000 |
| Catalogue | R$ 41,000 |
| Box Office | R$ 27,000 |
| Data | R$ 35,000 |
| Platform | R$ 22,000 |
| no tag | R$ 29,000 |
| **total** | **R$ 212,000** |

Payments and Mobile have no line of their own. Mobile runs no servers, and Payments' services are
among the untagged resources, which is part of why that line exists: **the untagged money is
money somebody owns and nobody has claimed.**

Put it in a sheet. Rows 2 to 6 are the teams, row 7 is left empty, and row 8 holds the untagged
amount:

| | A | B | C |
|---|---|---|---|
| 1 | Team | Tagged | With share |
| 2 | Checkout | 58000 | |
| 3 | Catalogue | 41000 | |
| 4 | Box Office | 27000 | |
| 5 | Data | 35000 | |
| 6 | Platform | 22000 | |
| 7 | | | |
| 8 | Untagged | 29000 | |

The untagged share of the bill, in an empty cell:

```localised
=ROUND(B8/SUM(B2:B8)*100,1)      13.7
```

**13.7% of the bill has no owner.** That number goes at the top of every showback report, because
it says how far to trust everything below it.

## Sharing out what has no tag

Coreto shares the untagged R$ 29,000 in proportion to what each team already has tagged: a team
with a larger tagged bill gets a larger part of the unclaimed one. In C2:

```localised
=ROUND(B2+$B$8*B2/SUM($B$2:$B$6),0)      67191
```

Copied down to C6, the column reads 47497, 31279, 40546 and 25486. Checkout's R$ 58,000 becomes
R$ 67,191 once its share is added.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l12-showback\" aria-label=\"Five horizontal bars, one per team. Each bar has a solid part for the cost tagged to the team and an outlined part for its share of the untagged R$ 29,000. Checkout R$ 58,000 becomes R$ 67,191; Catalogue R$ 41,000 becomes R$ 47,497; Box Office R$ 27,000 becomes R$ 31,279; Data R$ 35,000 becomes R$ 40,546; Platform R$ 22,000 becomes R$ 25,486.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">A month of showback: R$ 212,000, of which R$ 29,000 (13.7%) carries no tag</text><text x=\"20.0\" y=\"58.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Checkout</text><rect x=\"130.0\" y=\"40.0\" width=\"293.5\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"423.5\" y=\"40.0\" width=\"46.5\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"58.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 58,000 → R$ 67,191</text><text x=\"20.0\" y=\"96.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Catalogue</text><rect x=\"130.0\" y=\"78.0\" width=\"207.5\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"337.5\" y=\"78.0\" width=\"32.9\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380.3\" y=\"96.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 41,000 → R$ 47,497</text><text x=\"20.0\" y=\"134.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Box Office</text><rect x=\"130.0\" y=\"116.0\" width=\"136.6\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"266.6\" y=\"116.0\" width=\"21.7\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"298.3\" y=\"134.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 27,000 → R$ 31,279</text><text x=\"20.0\" y=\"172.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Data</text><rect x=\"130.0\" y=\"154.0\" width=\"177.1\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"307.1\" y=\"154.0\" width=\"28.1\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"345.2\" y=\"172.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 35,000 → R$ 40,546</text><text x=\"20.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Platform</text><rect x=\"130.0\" y=\"192.0\" width=\"111.3\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"241.3\" y=\"192.0\" width=\"17.6\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"269.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 22,000 → R$ 25,486</text><rect x=\"20.0\" y=\"235.0\" width=\"14.0\" height=\"14.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"42.0\" y=\"246.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">tagged to the team</text><rect x=\"250.0\" y=\"235.0\" width=\"14.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"272.0\" y=\"246.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">its share of the untagged R$ 29,000</text></svg>", "caption": "Proportional allocation. Each team's share of the untagged cost is in proportion to what it already has tagged, so the outlined part grows with the solid part. A team that leaves its own resources untagged pays less than it spends, and the teams that tag well make up the difference."}
```

Now add the column up:

```localised
=SUM(C2:C6)      211999
```

**One real is missing.** Each team's share was rounded to whole reais, and five roundings did not
cancel out: the shares add to R$ 28,999 instead of R$ 29,000. Nothing is wrong with the method,
and a real is not worth a meeting. The report is another matter. A total that does not match the
bill is the first thing a sceptical reader finds, and once they have found it they argue about the
arithmetic instead of reading their team's line. Either say it on the report — a row that reads
"rounding: R$ 1" — or give the missing real to the largest share so the column adds up. Whichever
you choose, decide it before the report goes out rather than after somebody asks.

## What proportional sharing gets wrong

Proportional sharing is simple and it is defensible, and it has one bad property: **it rewards
nobody for tagging.** A team that tags every resource still pays its share of the resources other
teams left untagged, and a team that leaves its own resources untagged pays less than it spends,
because the untagged part is shared out by what each team has tagged. The untagged line never
shrinks on its own.

So Davi publishes both numbers every month: each team's total with its share, and the untagged
percentage, which he and Rafaela own until it falls. A team can see what its decisions cost, and
everybody can see whether the unclaimed part is getting smaller.

## Showback, not chargeback

Showback shows each team its cost. **Chargeback goes further and moves the money**: the cost is
charged to the team's own budget, which shrinks when its cloud bill grows.

Chargeback sounds more serious, and at most companies it is premature. It needs an allocation every
team accepts, because now a rounding rule or a share of the untagged pool is money out of somebody's
budget. It turns every shared cost into a negotiation, and it gives teams a reason to avoid shared
services — including the Platform team's — whenever running their own looks cheaper on their own
line. And it needs teams to have budgets in the first place. Coreto's teams do not: lesson 11's
budget is four company-wide lines, so chargeback there would move money between budgets that do
not exist.

Showback gets most of the effect for little of the cost. Teams change behaviour when they see their
number next to their name; they do not need the number to be deducted from anything. The next section
is what they find once they look.
