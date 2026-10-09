---
title: What makes an alert worth having
version: 2
---

The four rules share a structure, and the structure is what a team writes down for every alert it
keeps:

1. **A signal with a definition.** Here the share of replies that are the agreed refusal, counted by
   its exact text. A signal whose meaning drifts makes every threshold on it drift too.
2. **A window and a minimum sample.** Long enough to hold enough replies, short enough to notice in
   hours. Lesson 9's arithmetic says how many is enough; the Wilson rule puts it inside the test.
3. **A comparison with normal.** A baseline from the assistant's own recent past, not a round number.
4. **A measured record.** How many false alarms it would have raised, how long it takes to fire, and
   whether it stays on while the problem lasts, measured on history before it is turned on, as
   `alerts.py` does. Lesson 11's precision and recall, applied to the alert itself.

## Where it sends

Lesson 11 said an alert that wakes somebody needs precision above all. The Wilson rule raised no false
alarm in two and a half days, which is fine for a message in the team's channel and says too little for
a page at three in the morning: a few days of history cannot promise the next month. Most quality alerts belong in the first place: a rise in refusals is a problem for the
morning, not an outage. What pages somebody is the assistant failing outright, the errors and timeouts
of lesson 4, which have no definition problem at all.

**Every alert carries what the person needs to start.** The release in production, the window and the
numbers that set it off, and a link to the traces behind it, filtered to the refusals of that window.
The person who opens it should be one click from lesson 1's trace tree.

## Beyond refusals

The same structure applies to every signal the course has built:

- **Thumbs down and rephrasing**, lesson 5's, with a longer window, because there are fewer of them.
- **Cost per request**, lesson 3's, against its own baseline: the release that is suddenly expensive is
  as much a regression as the one that is suddenly bad, as lesson 14 found.
- **Latency**, lesson 4's, on the slow percentiles rather than the median.
- **The judge's sampled score**, lesson 9's, always with its n, and only on a criterion lesson 10
  showed the judge can see.
- **No traffic at all.** An hour at a busy time with no replies is not a good hour: it is a broken
  pipeline, and an alert on rates will never fire on it, because there is nothing to divide.
