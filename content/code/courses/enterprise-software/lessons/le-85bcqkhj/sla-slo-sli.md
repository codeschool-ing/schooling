---
title: A measurement, a target and a contract
version: 1
---

At the fintech, Joana's team called every reliability target an SLA. "The payments API has an SLA
of 200 milliseconds" meant that somebody had written 200 on a wiki page. Nobody outside the team
had agreed to it and nothing happened when it was missed. **Using one word for three things hides
the question that matters most: what happens when the number is not met?**

The vocabulary that separates them comes from Google's *Site Reliability Engineering* (Beyer,
Jones, Petoff and Murphy, eds., 2016), whose fourth chapter defines all three, and it is now
ordinary in the trade.

| term | what it is | at Serra Alta, for the Portal B2B |
|---|---|---|
| SLI, service level indicator | a measurement of some aspect of the service, usually a ratio | the share of order submissions that got a confirmation within 5 seconds |
| SLO, service level objective | a target for an SLI over a stated window | 99.5% of submissions, over a rolling 30 days |
| SLA, service level agreement | a contract with the users that says what happens if the objectives are missed | none: the bakeries have no contract that pays them for a failed order |

The book offers a test that settles most arguments: ask what happens if the objective is missed. If
the answer is a consequence somebody can collect, a credit, a penalty, a right to end the contract,
it is an SLA. If the answer is that the team will look into it, it is an SLO, and calling it an SLA
only makes it sound enforceable.

## The indicator: what is counted, and where

An SLI is easiest to reason about written as a ratio: good events divided by valid events. Both
halves need a definition, and both hide decisions.

*Good* has to be what the user would call good. A submission that the portal accepted after 40
seconds is not good to a bakery owner standing at the counter at 05:30, so Joana's indicator counts
a submission as good only if the confirmation came within 5 seconds.

*Valid* excludes what was never the system's to get right. A bakery over its credit limit whose
order is refused got a correct answer, and counting it as a failure would punish the portal for
enforcing a rule. A test order from the portal team's own monitoring is not a bakery at all.

Then there is the question of where the counting happens. **A service measured only from its own
logs cannot see the requests that never reached it.** If the portal's address fails to resolve, or
the load balancer in front of it is refusing connections, the portal's log shows a quiet evening and
a perfect SLI. Joana's indicator is taken from the load balancer's log, which is as close to the
bakeries as Serra Alta's own equipment goes, and a probe outside Serra Alta's network places a test
order every five minutes to catch what even the load balancer cannot see.

## The objective, and why it is not 100%

An objective of 100% is never met, and a target that is never met stops being read. It is also the
wrong goal: the bakeries' own phones, networks and browsers fail more often than that, and money
spent beyond what users can notice is money taken from something they would notice.

**An objective has to be one the architecture can reach.** The previous section put the stock
check at 98.41% over a year. An objective of 99.9% on submissions that need that check is a wish,
and either the objective comes down or the design changes so that a submission no longer waits on
SAP. Joana chose 99.5% and the design change both, and wrote the reason beside the number.

## The error budget

The part of the window that the objective leaves over is the **error budget**. At 99.5% it is 0.5%
of valid submissions. The portal receives about 24,000 order submissions in 30 days, so the budget
is 0.005 × 24,000 = 120 failed submissions per rolling 30 days.

The budget turns reliability from an opinion into a quantity that is spent. Incidents spend it.
Risky releases spend it. Planned maintenance that users can see spends it. The SRE book's argument
is that this gives the people who want to ship features and the people who want stability one
number to argue over, instead of two temperaments. **When the budget is spent, the change that
spent it stops**: Joana's policy for the portal says that with less than 20% of the budget left,
releases stop apart from fixes to reliability, until the rolling window recovers.

She tested the policy on the past. September's logs, replayed against the new SLI, gave this:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l12-budget\" aria-label=\"A line chart of September replayed against the new objective: failed order submissions counted cumulatively over 30 days, against an error budget of 120. About one submission a day fails for ordinary reasons. On day 2, during the close, the stock check times out and the line jumps by 48. On day 18 a portal release costs 32 more, and the line reaches 98, past the freeze threshold at 96, which is 80% of the budget. The month ends at 110, under the budget of 120.\"><path d=\"M70.0 270.0 L690.0 270.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M70.0 270.0 L70.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"62.0\" y=\"199.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><text x=\"62.0\" y=\"128.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">80</text><text x=\"62.0\" y=\"57.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">120</text><text x=\"90.7\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"173.3\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"276.7\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"380.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">15</text><text x=\"483.3\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><text x=\"586.7\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">25</text><text x=\"690.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><text x=\"380.0\" y=\"302.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">day of September</text><text x=\"18.0\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">failed</text><path d=\"M70.0 57.7 L690.0 57.7\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"76.0\" y=\"48.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">error budget: 120 failed submissions in 30 days</text><path d=\"M70.0 100.2 L690.0 100.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"76.0\" y=\"110.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">80% spent: releases stop</text><path d=\"M70.0 270.0 L90.7 268.2 L110.9 266.5 L111.3 181.5 L132.0 179.8 L152.7 178.0 L173.3 176.2 L194.0 174.5 L214.7 172.7 L235.3 170.9 L256.0 169.2 L276.7 167.4 L297.3 165.6 L318.0 163.8 L338.7 162.1 L359.3 160.3 L380.0 158.5 L400.7 156.8 L421.3 155.0 L441.6 153.2 L442.0 96.6 L462.7 94.8 L483.3 93.1 L504.0 91.3 L524.7 89.5 L545.3 87.8 L566.0 86.0 L586.7 84.2 L607.3 82.5 L628.0 80.7 L648.7 78.9 L669.3 77.2 L690.0 75.4\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"442.0\" cy=\"96.6\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"690.0\" cy=\"75.4\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"119.3\" y=\"197.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">day 2: close, stock check times out, +48</text><text x=\"434.0\" y=\"66.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">day 18: a portal release, +32 → 98</text><text x=\"686.0\" y=\"91.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">110 at the end</text></svg>", "caption": "September, replayed against the new objective. Two incidents spent most of the budget, and from the evening of the 18th the policy would have stopped releases."}
```

About one submission a day failed for ordinary reasons, the dropped connection and the browser that
gave up. On 2 September, the second working day of August's close, SAP was slow under the closing
batch and the stock check timed out for 48 bakeries. On 18 September a portal release broke the
basket for one browser version and cost 32 more. By the evening of the 18th the month had spent 98
of its 120: 82% of the budget, with twelve days still to run. Under the new policy the portal team
would have frozen releases that evening. The month ended at 110, inside the objective. Nobody had
noticed anything at the time, because nobody had been counting.

## The SLA a vendor sells

Every software-as-a-service vendor publishes an availability commitment, and Serra Alta's estate is
full of them: Salesforce, Microsoft 365, the EDI provider, the bank's file gateway. They differ in
their numbers and agree in their shape, and the shape is what an architect reads:

| what the contract says | what it means for you |
|---|---|
| a monthly percentage | measured by the vendor, at the vendor's edge, not at your users |
| exclusions | planned maintenance, and causes outside the vendor's control, are not downtime |
| the remedy | a service credit: a percentage of that month's fee, usually requested by you within a deadline |
| the limit | the credit is capped, and it is the only remedy for downtime |

Serra Alta's contract with its EDI provider is a fair example. It promises 99.5% a month, and below
that a credit of 10% of the monthly fee. The fee is R$ 6,000, so the credit for a bad month is
R$ 600.
On a weekday, orders worth about R$ 4 million reach Serra Alta through that provider from the
supermarket chains. **A vendor's SLA is a price term, not an architecture.** It tells you what the
vendor will refund when it fails. It says nothing about what the business needs while it is
failing, and the gap between the two is the design work: a queue that holds the orders, a second
route for the largest customers, a person who knows how to take an order by e-mail.

So Joana's policy keeps two numbers for each external service: the commitment the vendor sells, and
the objective Serra Alta needs. Where the second is higher than the first, the registry of
contracts (two sections on) has to name what covers the difference.

## Inside the company

Between Serra Alta's own teams there is no money to move. When Rui's team promises the portal team
that the bus will answer, there is no credit to pay if it does not. ITIL calls an internal promise
of this kind an operational level agreement, an OLA, to keep it apart from the contract with
customers. Joana's policy calls them objectives, which is what they are, and gives each one the
consequence an internal promise can actually carry: a budget, a release freeze when it is spent,
and a review with both teams in the room. **An internal "SLA" with no consequence is an SLO that
claims an authority it does not have**, and the first missed month teaches everybody that.
