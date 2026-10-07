---
title: Options, not alarms
version: 1
---

**A risk presented on its own asks the decider to be worried. A risk presented with options asks
them to choose, which is the thing they are there to do.** An engineer who reports a risk and stops
has handed the hard part, deciding what to do about it, to the person least equipped to do it.

## Four responses, and accepting is one of them

Every risk has the same four possible responses, whatever the methodology calls them:

1. **Avoid** it: stop doing the thing that creates it. Stop running the route planner at peak.
2. **Reduce** it: make it less likely or less costly. A replica, connection limits, a faster alert.
3. **Transfer** it: make somebody else carry it. Insurance, a contract clause, a managed service
   with a penalty for downtime.
4. **Accept** it: decide, knowingly, to carry it.

The fourth is the one engineers forget is legitimate. **Accepting a risk is a correct decision when
reducing it costs more than it is worth**, and only the person who owns the budget can make it. What
is not legitimate is accepting it by default, because nobody decided.

## Options with their price

Lívia's proposal put the four alternatives from lesson 2 on one line each, in the units Caio uses:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Four horizontal bars on one scale. The expected revenue loss from doing nothing is R$ 561,600 a year. The first-year cost of a larger server is R$ 108,000, of a read replica R$ 96,000, and of connection pooling R$ 16,000.\"><defs><marker id=\"optionsbar-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">expected loss, do nothing</text><rect x=\"20\" y=\"40\" width=\"524.16\" height=\"18\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"534.16\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 561,600 a year</text><text x=\"20\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">larger server</text><rect x=\"20\" y=\"96\" width=\"100.8\" height=\"18\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"130.8\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 108,000</text><text x=\"20\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">read replica</text><rect x=\"20\" y=\"144\" width=\"89.6\" height=\"18\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"119.6\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 96,000</text><text x=\"20\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">connection pooling</text><rect x=\"20\" y=\"192\" width=\"14.933333333333334\" height=\"18\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"44.93333333333334\" y=\"201\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 16,000</text><text x=\"20\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">revenue lost a year against the first-year cost of each fix</text></svg>", "caption": "On one scale, every fix is small next to the loss it addresses, so the decision stops being \"is it worth it?\" and becomes \"which fix lasts longest?\". The chronic loss alone is drawn; the tail risk would add to it."}
```

| option | cost in the first year | what it does to the loss |
|---|---|---|
| do nothing | R$ 0 | chronic loss continues and grows; tail risk 2 to 4 times a year |
| larger server | R$ 108,000 (R$ 9,000 a month) | both drop for about a year, then return with volume |
| connection pooling | about R$ 16,000 (two engineer-weeks) | tail risk lower; chronic loss mostly remains |
| read replica | about R$ 96,000 (six engineer-weeks, R$ 4,000 a month) | both removed for the foreseeable growth |

The engineer-week is costed at R$ 8,000, the figure finance uses for planning, and the document says
so. **Against an expected loss of R$ 560,000 a year in revenue, every option except doing nothing
pays for itself**, and the comparison between them is about how long the fix lasts.

That changes the conversation. Caio no longer has to decide whether to believe that the database is
fragile. He decides between four priced options, one of which is the free one, and he can choose
the free one with his eyes open.

## Accepted risks are written down

If the decider accepts a risk, the acceptance goes into the risk register with three things: **who
accepted it, when it will be looked at again, and what would trigger an earlier look.**

> **Risk:** checkout database runs out of connections at peak. **Accepted** by Caio, 12 February,
> pending the April work. **Review:** 31 March. **Trigger for earlier review:** any Friday where
> connections exceed 95% of the limit, or any checkout outage.

On 6 March the trigger fired. Nobody had to argue about whether to reopen the decision: the register
said it was reopened.

## The opposite failure

Crying wolf is the other way to lose. An engineer who escalates every risk as critical trains the
directors to discount all of them, and the real one arrives in a voice nobody listens to any more.
**Reserve the alarm for the risk whose expected loss justifies it**, say plainly when a risk is small,
and the large ones will be heard.
