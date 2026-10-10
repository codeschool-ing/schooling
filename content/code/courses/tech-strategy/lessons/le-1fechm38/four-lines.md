---
title: The four lines of a total cost
version: 1
---

Coreto's Platform team runs its own observability: metrics, logs and traces from every service,
stored and searched on machines the team looks after. Rafaela Nunes, who leads Platform, has been
asked whether a hosted observability service would be cheaper. The vendor publishes its price — so
much a host, so much a gigabyte of logs — and the comparison looks like it takes five minutes.

**It takes five minutes because it compares one line out of four.** Here is that comparison, for
three years:

| | hosted | self-hosted |
|---|---|---|
| what the price page shows, three years | R$ 275,400 | R$ 151,200 |

The hosted service charges R$ 90 a month for each of Coreto's 60 hosts (R$ 5,400) and R$ 2.50 a
gigabyte for the 900 GB of logs Coreto sends each month (R$ 2,250): R$ 7,650 a month, R$ 91,800 a
year. The self-hosted stack's equivalent is the machines and storage it runs on, R$ 4,200 a month.
**On this line, self-hosting is cheaper by R$ 124,200**, and plenty of decisions are made right
here.

The total cost of ownership, TCO, is the same comparison with every line in it. It has four.

## Licence

**What you pay to have the thing at all**, usually monthly: a subscription, a per-host or per-seat
fee, or, for something you run yourself, the machines and storage it needs. It is the line
everybody sees, because it arrives as an invoice and somebody has to approve it. It is also the
line a vendor designs to look small: priced per unit, monthly, and in a currency of hosts or
gigabytes whose growth nobody has estimated yet.

At Coreto, the licence is the R$ 275,400 and R$ 151,200 above.

## Integration

**The work before anything works**: installing, configuring, connecting to what already exists,
moving data across, and teaching people to use it. It is paid once, at the start, in hours.

Moving to the hosted service would take Platform 320 hours: installing the vendor's agent on 60
hosts, rebuilding the dashboards and alerts the teams rely on, and running both systems side by
side long enough to trust the new one. At R$ 150 an hour that is **R$ 48,000**. The self-hosted
stack's integration is zero, because it is already in place — every service already ships its
metrics and logs to it. That asymmetry is common: the option you have is always integrated, and
the option you are considering never is.

## Operation

**The time people spend keeping it running**, every week, for as long as it runs: upgrades,
capacity, backups, the alert at night, the questions from other teams. It is paid in hours, and it
does not stop.

A hosted service still needs operating — somebody manages the account, the agents, the access and
the log volume that drives the bill — and Rafaela estimates a tenth of an engineer for it, 176
hours a year. The self-hosted stack takes 60% of an engineer, 1,056 hours a year. Over three years
at R$ 264,000 an engineer-year, that is **R$ 79,200 hosted and R$ 475,200 self-hosted**. The next
section is about this line, because it is the one that changes the answer.

## Exit

**What it would cost to leave**: exporting the data, replacing the integration, running two
systems while you move, and any notice the contract demands. It is paid once, at the end — and it
is priced at the start or not at all.

Leaving the hosted service later would take 280 hours (R$ 42,000) to move dashboards, alerts and
agents to whatever replaces it, plus a month of licence while both run, R$ 7,650: **R$ 49,650**.
Coreto's sheet prices the self-hosted exit at zero, a simplification the last section of this
lesson comes back to.

## When each line is paid

The four lines fall at different points in the life of the decision, and that is part of why one
of them gets compared and three get forgotten:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"A timeline of three years with four rows. Licence: a bar across all three years, paid every month on an invoice. Integration: a short block at the very start, paid once before anything works. Operation: a bar across all three years, paid every month in people’s hours. Exit: a dashed block after year 3, paid once on the way out.\"><text x=\"210\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">year 1</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">year 2</text><text x=\"510\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">year 3</text><path d=\"M135 38 L135 46\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M285 38 L285 46\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M435 38 L435 46\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M585 38 L585 46\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"122\" y=\"74\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">licence</text><text x=\"122\" y=\"120\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">integration</text><text x=\"122\" y=\"166\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">operation</text><text x=\"122\" y=\"212\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">exit</text><rect x=\"135\" y=\"56\" width=\"450\" height=\"26\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"360\" y=\"73\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--ink)\">every month, on an invoice</text><rect x=\"135\" y=\"102\" width=\"30\" height=\"26\" rx=\"0\" fill=\"var(--phosphor-dim)\"></rect><text x=\"175\" y=\"119\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">once, before anything works</text><rect x=\"135\" y=\"148\" width=\"450\" height=\"26\" rx=\"0\" fill=\"var(--phosphor)\"></rect><text x=\"360\" y=\"165\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--ink)\">every month, in people’s hours</text><rect x=\"590\" y=\"194\" width=\"40\" height=\"26\" rx=\"0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"580\" y=\"211\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">once, on the way out</text></svg>", "caption": "When each of the four lines is paid. A price comparison sees the top bar. Integration is paid before anything works, operation every month in hours, and the exit once, on the way out."}
```

A price comparison sees the bar at the top. The integration is spent before the first useful
dashboard, operation is spent in hours that nobody invoices, and the exit is spent by whoever is in
the job when the company decides to leave — often somebody who was not there when it signed.

One rule keeps the four honest: **every line in hours is converted at the same rate**, here Coreto's
R$ 150, and every line runs over the same horizon, here three years. A sheet that converts the
vendor's invoice into reais and leaves the operating hours in hours has compared money with time,
and hours left as hours look small beside a figure in reais.
