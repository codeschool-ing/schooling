---
title: Maintenance: from fixing to predicting
version: 1
---

The 28-minute breakdown in IM-07's shift is one entry in a long record, and the decision that record
serves is when to stop a machine on purpose so that it does not stop on its own. **There are three
ways to make that decision, and each needs more data than the one before.**

| | when the work is done | what it needs |
|---|---|---|
| **corrective** | after the machine fails | a technician and spare parts |
| **preventive** | on a calendar or a counter: every 500 hours, every 200,000 cycles | the manufacturer's interval, or the plant's own history of failures |
| **predictive** | when the machine's condition says a failure is coming | sensor readings over time, and failures recorded with their causes, so the readings can be matched to what followed |

Corrective maintenance is not a failure of management: for a cheap part whose failure stops nothing
important, running it until it breaks is the right choice. Preventive maintenance replaces parts that
might have lasted longer, which is its cost. Predictive maintenance tries to replace them at the
right moment, and it is the one people mean when they say a factory is "using data".

## Two numbers for how a machine fails

Rafael's quarterly maintenance report has two numbers per machine. **MTBF**, mean time between
failures, is the operating hours divided by the number of failures: how long the machine runs, on
average, before it stops on its own. **MTTR**, mean time to repair, is the hours under repair divided
by the number of failures: how long it stays stopped when it does. From the two comes the share of
time the machine is available:

availability = MTBF ÷ (MTBF + MTTR)

Type July to September 2025 for two machines:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Machine | Hours | Failures | Repair hours |
| 2 | IM-07 | 1860 | 6 | 27 |
| 3 | IM-11 | 1790 | 15 | 52.5 |

In E2, F2 and G2, copied down to row 3:

```localised
=ROUND(B2/C2,1)      310
=ROUND(D2/C2,1)      4.5
=ROUND(E2/(E2+F2)*100,1)      98.6
```

IM-11 comes out at an MTBF of 119.3 hours, an MTTR of 3.5 and an availability of 97.1%. This
availability counts only failures, which is why it sits far above the 86.0% of the OEE section: that
one also counted the mould change and measured a single shift.

**The two availabilities are 1.5 points apart, and the machines are not similar at all.** IM-11
fails two and a half times as often as IM-07; its repairs are quicker, and that hides the
difference in one number. Quick repairs of frequent failures are usually the same small fault fixed
again and again, a heater band or a sensor, and each failure costs more than its repair time: the
machine has to come back up to temperature, and the first parts after a restart go in the bin. **A
report that showed only availability would rank these two machines as nearly equal**; MTBF beside it
shows that one of them has a problem nobody has solved.

## What predictive maintenance needs

The plant manager read the report and asked whether IM-11 could be fitted with sensors and a model
that predicted its failures. Rafael's answer started from the data, and it is the answer this course
would give for any industry: a model learns which readings come before which failures, and it can
only learn from failures that were recorded with a cause.

Of IM-11's 15 failures, 9 were recorded in the maintenance log as "machine stopped", with no cause.
**60% of the history that a model would learn from says nothing about what went wrong.** No sensor
added today fixes that, because the sensor readings from before those failures do not exist either.

So Rafael proposed the step before the model: for the next six months, every failure is logged with
a cause from a short list, and the two sensors the machine already has, hydraulic oil temperature
and injection pressure, are recorded every minute instead of being shown on the panel and
discarded. **Predictive maintenance is bought with history**, and the history has to be started
before anybody can predict anything. A data scientist can then build the model (lesson 3 says who
does what); the BI work is making sure there is something to build it from.
