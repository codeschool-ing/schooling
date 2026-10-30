---
title: The timeline, from the evidence
version: 1
---

**A postmortem starts with a timeline built from evidence, not from memory.** Memory puts events in the order
that makes the best story; logs and metrics put them in the order they happened. The payment incident of lesson
10 is in `checkout.log`, the thirty minutes `genlogs.py` writes, so its timeline can be rebuilt on your computer.
Generate the file again if you deleted it (`python3 genlogs.py > checkout.log`, in `~/gcp`).

When did retries first run above five a minute, and when did that stop?

```
ana@laptop:~/gcp$ jq -r 'select(.message == "payment retried") | .timestamp[11:16]' checkout.log | sort | uniq -c | awk '$1 > 5 {print $2}' | sed -n '1p;$p'
14:12
14:17
```

The first and the last retry inside that stretch, to the second:

```
ana@laptop:~/gcp$ jq -r 'select(.message == "payment retried") | .timestamp' checkout.log | sort | sed -n '/T14:1[2-7]/p' | sed -n '1p;$p'
2026-10-30T14:12:08+00:00
2026-10-30T14:17:53+00:00
```

And what the customers experienced in those six minutes:

```
ana@laptop:~/gcp$ jq -r 'select(.timestamp[11:16] >= "14:12" and .timestamp[11:16] <= "14:17") | .message' checkout.log | sort | uniq -c
    155 order placed
     85 payment retried
```

In six minutes, 85 checkouts needed a retry against 155 that went through at once: **more than one in three**.
Every retried order in this log completed, so the damage was delay, not lost orders. That is a fact the
postmortem states with a number rather than "some customers were affected".

## What the timeline says about the alert

The incident ran from 14:12:08 to 14:17:53, under six minutes. Lesson 14's policy fires only after retries stay
above five a minute **for ten minutes**. So the policy would not have fired at all: the incident was over before
its condition could be true. That is not a mistake in the timeline; it is the first finding of the postmortem,
and the kind of finding only a timeline built from evidence produces. Whether ten minutes is still right is a
decision about what a six-minute payment problem is worth to the shop, and the postmortem is where it is made.

The rest of the timeline comes from the incident channel: when somebody noticed, when the incident was declared,
what was tried, when it ended. Put the two sources side by side and the gaps show: here, a gap between 14:12,
when the retries started, and the moment anybody knew.
