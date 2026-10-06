---
title: Base rates and alert fatigue
version: 1
---

The shop's week had 98 cases, eleven of them the exercise: a little over one in ten. Real
environments are nothing like that. Almost everything that happens is harmless, and attacks are
rare. That rarity, the **base rate**, changes what a detector's numbers mean.

### A small error on a large number

Imagine a detector that is excellent by any reasonable standard: it catches 99% of attacks, and it
wrongly alerts on only 1% of harmless cases. Now give it a busier system than the shop's: 10,000
cases a day, of which one is an attack.

| | count |
|---|---|
| attacks caught (99% of 1) | about 1 |
| harmless cases alerted on (1% of 9,999) | about 100 |
| alerts in a day | about 101 |
| precision | about 1% |

**About a hundred alerts a day, and one of them matters.** The detector did not get worse; the
haystack got bigger. This is the **base rate fallacy**: judging an alert by how accurate the detector
is, while forgetting how rare the thing it detects is. When the thing is rare, even a tiny false
positive rate produces mostly false alarms.

### What that does to people

A person who opens a hundred alerts and finds them all harmless learns a habit: alerts are noise.
On the day one is real, it is closed with the others. This is **alert fatigue**, and it is how real
incidents go unnoticed in organisations that had a detection for exactly what happened. The alert
fired; nobody believed it.

Alert fatigue turns false positives into false negatives, one step later, in people's heads. That
is why precision matters as much as recall, and why "alert on everything, just in case" is not the
safe choice it sounds like.

### What to do about it

- **Count the alerts per week, per rule.** A rule nobody has acted on in three months is either
  tuned wrong or measuring nothing.
- **Fix noisy sources at the cause**, as with the backup job, rather than teaching people to ignore
  them.
- **Grade alerts.** Not everything needs to wake somebody: some alerts go to a daily summary, a few
  go to a phone at night.
- **Measure against the truth when you can.** A purple exercise, like lesson 10's and this lesson's,
  is the one moment the truth is known. Use it to count the four boxes, every time.

The shop's final rule, three failures in ten minutes with the backup job fixed, would have raised
five alerts in this week without the exercise: the staff with three or four typing mistakes. That is
a number ana can read every one of, and that is a property of a detection as important as its
recall.
