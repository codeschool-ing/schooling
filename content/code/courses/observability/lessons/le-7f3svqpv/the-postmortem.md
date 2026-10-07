---
title: The postmortem of lesson 17's incident
version: 2
---

A postmortem has a shape, and keeping to it makes a team's reviews comparable and quick to read. Here
is lesson 17's incident written up the way a team would, every time and number taken from that
lesson's transcripts.

**Summary.** On 2 October, a release of payments made one charge in eight fail. Checkouts failed for
about four minutes until the release was rolled back. The fast burn-rate alert paged three minutes
after the release, and the incident was closed nine minutes after it began.

**Impact.**

| | |
|---|---|
| users | about one checkout in nine failed with a 502 for four minutes |
| services | payments, and through it orders and the storefront |
| error budget | a five-minute burn rate of about 15 to 19; the thirty-minute rate peaked above 12 |
| data | none lost; failed charges were not taken, so nobody was charged for a failed order |

**Timeline**, all times UTC, from the marks:

| time | event |
|---|---|
| 20:46:49 | payments 1.4.2 released |
| 20:49:58 | page: `CheckoutBudgetBurningFast` |
| 20:50:00 | SEV-2 declared, ana in command |
| 20:51:01 | payments rolled back to 1.4.0 |
| 20:51:58 | page resolved |
| 20:55:55 | incident closed |

**Contributing factors.** The table of the previous section: the bug as the trigger, the mock and the
missing canary as defences that were absent, the five-minute window as the cost of detection, and the
deploy mark as the defence that worked.

**What went well.** The page was a symptom, so it described what customers saw. The release was
marked, so *what changed?* took one command. The rollback was one step and was marked too.

**Actions.**

| action | owner | due |
|---|---|---|
| add the card network's error responses to the payments mock | Carla | 20 October |
| release payments to one instance first and watch its error ratio before the rest | Bruno | 31 October |
| fix the error handling of 1.4.2 and release it through the canary | ana | 24 October |

The document names people only as owners of actions and as roles in the timeline. **Nowhere does it say
who wrote the bug**, because that fact changes nothing in the list above, and asking for it would make
the next postmortem shorter.
