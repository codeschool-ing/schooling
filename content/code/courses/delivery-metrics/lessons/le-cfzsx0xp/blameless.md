---
title: Blameless, and why it is not soft
version: 1
---

After the incident of 30 September, the obvious question is **who** let a change that double-charges shops reach production. Rafa wrote the retry; Duda reviewed it; the release went out at 17:20 on the busiest afternoon of the month. Any of them could be named, and naming one would feel like accountability.

It would also be the end of learning anything. A **blameless postmortem** sets out to understand how the system, including the people in it, produced the failure, on the premise that **people did what made sense to them with what they knew at the time**. The question changes from "who made the mistake?" to "how did it make sense to make it, and what would have caught it?"

## Where the idea comes from

It comes from fields where failure kills people. Aviation and medicine learned, over decades, that blaming the pilot or the nurse produced fewer reports, not fewer accidents; the next person to make the same error kept quiet. The safety researcher Sidney Dekker calls the blaming account **the first story**, "human error", and the account of the circumstances that made the error likely **the second story**. Only the second leads anywhere. In software, John Allspaw's 2012 essay about practice at Etsy, *Blameless PostMortems and a Just Culture*, made the idea widely known.

## Why it is not soft

Blameless does not mean nobody is responsible. It means responsibility is placed where it can do some good:

- **The facts come out.** People who expect to be blamed leave things out, or remember them differently. People who expect to be understood say "I saw the alert and thought it was the usual noise", which is exactly the sentence lesson 18 needs.
- **The fixes land on the system.** "Rafa should be more careful" fixes nothing, because the next person will not be Rafa. "Retries on card charges need an idempotency key, and the review checklist asks about it" fixes it for everybody.
- **Hindsight is named.** After an incident, the path to failure looks obvious, because you know where it ended. At the time, it was one of hundreds of ordinary changes. A postmortem that forgets this concludes that everybody involved was careless, which is almost never true.

## The line that remains

A just culture still distinguishes **an honest mistake** from **recklessness**, knowingly skipping a safeguard for no reason, and from malice, which are rare and are a matter for management rather than a postmortem. The default, for everything else, is the second story. A team that keeps that default finds out about its near misses as well as its incidents, which is where most of the learning is.
