---
title: Acting on it, and the hours nobody uses
version: 1
---

Three kinds of change come out of this lesson, and they are made in a particular order, the cheapest and
safest first.

1. **Delete what is idle**, after the week of tagging and asking. It saves money and risks nothing that
   somebody did not have a week to object to.
2. **Turn off what is not needed at night.** A development or staging environment used in working hours
   does not need to run at three in the morning.
3. **Resize what is running**, with a test, because this one can make something slower.

## Hours, not sizes

The second item is often the largest. A week has 168 hours; a team works perhaps 12 hours on 5 days, 60 of
them. **An environment that runs only then is billed for 36% of the week**, and stopping it outside them
removes 64% of its compute cost with no change to any instance.

For the shop's staging, four `m7g.large` at 0.1301 USD an hour:

| | hours a week | USD a month |
|---|---|---|
| always on | 168 | 4 × 0.1301 × 730 = 379.89 |
| working hours only | 60 | 379.89 × 60 / 168 = 135.68 |
| **saved** | | **244.21** |

The mechanism is ordinary: a schedule in EventBridge Scheduler that stops the instances in the evening and
starts them in the morning, or an auto scaling group whose scheduled actions set the desired count to zero
and back. Their disks keep their price, as the stopped instance in `idle.py` did, so a stopped
environment is cheaper, not free.

## In what order to look

The section on commitments ended with *rightsize first*, and this is why: **commitments in lesson 22 are
sized to the floor of what runs**, and every idle disk, oversized instance and staging fleet running at
night raises that floor. Clean first, resize second, schedule what can sleep, and only then commit to the
floor that is left, which is smaller and truer.
