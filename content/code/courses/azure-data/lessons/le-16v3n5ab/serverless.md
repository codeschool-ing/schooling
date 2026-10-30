---
title: Serverless, and the database that pauses
version: 1
---

**Serverless is a way of buying vCore compute by the second instead of by the hour.** A provisioned
database has a fixed number of vCores and is billed for them every hour of the month, used or not. A
serverless database has a range, a minimum and a maximum, and Azure moves it inside that range with
the load. Each second is billed for what the database used, with the minimum as a floor. And in
General Purpose, a serverless database that has had no connection for a set delay **pauses**: its
compute is released and billed at nothing until the next connection wakes it.

**This section is taught from Microsoft's documentation; the program in it does arithmetic with
illustrative prices, and nothing in it touched Azure.**

## What you declare, and what the provider accepts

The development copy in the previous section's `main.tf` is serverless: `GP_S_Gen5_2`, where the `S`
says so and the `2` is the maximum. Two more settings belong to it, and the provider checks both:

```
ana@laptop:~/azure/tf/sql$ sed -i.bak 's/auto_pause_delay_in_minutes = 60/auto_pause_delay_in_minutes = 5/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf
Error: expected auto_pause_delay_in_minutes to be one of [-1], got 5
Error: expected auto_pause_delay_in_minutes to be in the range (15 - 10080), got 5
```

```
ana@laptop:~/azure/tf/sql$ sed -i.bak 's/min_capacity                = 0.5/min_capacity                = 0.1/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf
Error: expected min_capacity to be one of [0 0.5 0.75 1 1.25 1.5 1.75 2 2.25 2.5 3 4 5 6 8 10 12 14 16 18 20 24 32 40], got 0.100000
```

**The pause delay is 15 minutes to a week, or -1 to never pause**, and the minimum is one of a fixed
list of sizes, which the provider's message prints whole. The minimum matters twice. It is the floor every running second
is billed at, and it sets the smallest amount of memory the database keeps: a minimum chosen too low
for the working set makes every quiet period evict the cache the busy one built.

## What it costs, and when it wins

**What is billed each second is the larger of the processor and the memory the database used,
converted to vCores**, never below the minimum, and nothing while it is paused. Storage is billed
every hour, paused or not, because the data is still there. So serverless wins when the database is
idle for long stretches, and loses when it is busy all day, if a second of serverless costs more than
a second of the same vCore provisioned. Check whether it does in your region with `prices.py`; this
program assumes it does, at round numbers that say they are illustrative. Save it as
`~/azure/breakeven.py`:

```schooling-example
{"language": "python", "file": "breakeven.py", "parts": [{"code": "\"\"\"Two vCores provisioned against serverless, at ILLUSTRATIVE prices.\"\"\"\n\nVCORE_HOUR = 0.25            # USD per vCore per hour, provisioned\nSERVERLESS_SECOND = 0.0001   # USD per vCore per second, serverless\nHOURS = 730                  # a month, as Microsoft's calculator counts it\nDAYS = HOURS / 24\n", "note": "**Two invented prices, chosen so that a serverless vCore-second costs more than a provisioned vCore's share of an hour**: 0.0001 a second is 0.36 an hour, against 0.25. Replace them with the real ones and the shape of the answer stays; where it crosses moves."}, {"code": "\n\ndef provisioned(vcores):\n    return vcores * VCORE_HOUR * HOURS\n\n\ndef serverless(busy_hours, busy_vcores, min_vcores=0.5, pause_after=1):\n    idle = 24 - busy_hours\n    online_idle = min(idle, pause_after)\n    per_day = busy_hours * busy_vcores + online_idle * min_vcores\n    return per_day * DAYS * 3600 * SERVERLESS_SECOND\n", "note": "A provisioned database is billed for every hour. A serverless one, each day, for its busy hours at the vCores it used, then for the hour it waits at its minimum before pausing, the `auto_pause_delay_in_minutes = 60` of the declaration, and then for nothing."}, {"code": "\n\nprint(f\"{'busy hours a day':>16}{'serverless':>12}{'provisioned':>13}\")\nfor busy in (1, 2, 4, 8, 12, 16, 17, 20, 23):\n    print(f'{busy:>16}{serverless(busy, 2):>12,.2f}{provisioned(2):>13,.2f}')\n", "note": "**A month for each number of busy hours a day**, both databases at two vCores while busy."}]}
```

```
ana@laptop:~/azure$ python breakeven.py
busy hours a day  serverless  provisioned
               1       27.38       365.00
               2       49.28       365.00
               4       93.08       365.00
               8      180.68       365.00
              12      268.28       365.00
              16      355.88       365.00
              17      377.78       365.00
              20      443.48       365.00
              23      509.18       365.00
```

**At these prices, serverless is cheaper until the database is busy for about 16 hours a day**, and
past that the provisioned two vCores win, since they cost the same 365.00 however much they are used.
Quitanda's development copy is used during a working day of eight hours, which is 180.68 against
365.00. Its orders database takes orders from seven in the morning to midnight, every day, and the
first section's provisioned `GP_Gen5_2` is the right purchase for it.

## The cost of waking up

**A paused database is not instantly there.** The first connection after a pause starts the resume,
and the database is unavailable until it finishes, so an application that does not retry can see its
first connection fail. That is acceptable for a developer opening a laptop at nine. It is not
acceptable for a shop whose first customer of the day gets an error, and it is the reason serverless
with auto-pause is a development and reporting choice far more often than a production one. Setting
the delay to `-1` keeps the per-second billing and gives up the pause.
