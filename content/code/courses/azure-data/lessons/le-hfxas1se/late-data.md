---
title: Watermarks, and what happens to the late
version: 1
---

**A window by event time cannot be published the moment its minute ends, and it cannot wait for
ever.** At 20:01:00 by the customers' clocks, clicks from 20:00 are still in phones, in tunnels and
in retry loops. Wait too little and the window is published without them; wait too long and the
operations screen shows a number from five minutes ago. The **watermark** is how a stream processor
says how long it waited: a moving line in event time meaning "everything older than this has
arrived, as far as I am concerned". A window is final once the watermark passes its end, and an
event older than the watermark is **late**.

The program of two sections back drew its watermark at the latest event time seen minus a
tolerance. The same ten checkouts, now with the late one kept rather than dropped:

```
ana@laptop:~/azure$ python windows.py adjust 20
10 events, enqueued from 18:40:31.980000 to 18:40:31.980000 UTC
window 20:00-20:01  4 checkouts  closed by #6
#7  at 20:00:55  15 s behind the watermark: adjusted to 20:01:10
window 20:01-20:02  4 checkouts  closed by #10
window 20:02-20:03  1 checkouts  still open
window 20:03-20:04  1 checkouts  still open
```

**Checkout 7 was counted, in the wrong minute.** It happened at 20:00:55, arrived when the watermark
was 20:01:10, and `adjust` moved its time forward to the watermark, so the 20:01 window has four
checkouts and the 20:00 window still has four. The total over the evening is now right and the
minute-by-minute picture is not. **Neither choice is correct; they are wrong in different
directions.** `drop` keeps every published window true to the clicks it counted and loses an event.
`adjust` loses no event and places one in a window it did not happen in. A count of revenue per day
prefers `adjust`; a chart of when people shop prefers `drop`.

The third way is to wait longer. The same events, dropping again, with sixty seconds of tolerance:

```
ana@laptop:~/azure$ python windows.py drop 60
10 events, enqueued from 18:40:31.980000 to 18:40:31.980000 UTC
window 20:00-20:01  5 checkouts  closed by #8
window 20:01-20:02  3 checkouts  closed by #10
window 20:02-20:03  1 checkouts  still open
window 20:03-20:04  1 checkouts  still open
```

**Nothing was late and the 20:00 window has all five checkouts, but it closed later**: with twenty
seconds it was closed by checkout 6, with sixty it stayed open until checkout 8, at 20:02:05, more
than a minute of event time after its end. On a live screen that is a minute more before the number
appears. **Tolerance is a trade between completeness and delay, and only the use of the number can
set it.**

## How Stream Analytics does it

Stream Analytics has the same three choices, in two settings of the job and one policy, called its
event ordering:

| setting | what it tolerates | the Terraform name |
|---|---|---|
| out-of-order tolerance | events arriving behind events with a later time, up to this many seconds | `events_out_of_order_max_delay_in_seconds` |
| late arrival tolerance | events whose own time is older than their arrival time by up to this much | `events_late_arrival_max_delay_in_seconds` |
| the policy | what happens to events beyond either tolerance: `Adjust` or `Drop` | `events_out_of_order_policy` |

The program of this lesson only had the first, because the emulator delivered everything at once and
arrival time told it nothing. **The late arrival tolerance compares two clocks, the app's and Azure's**,
and it is the one that catches the phone in the tunnel even when no later event has arrived to move a
watermark. Microsoft's documentation describes `Adjust` as moving such an event's time to the edge of
the tolerance, the same move the program made. And **an out-of-order tolerance is paid in latency**:
the service holds the events of that many seconds to sort them before any window can close, which is
the delay the sixty-second run showed.

The provider for Terraform knows the limits of both, and `validate` refuses a value outside them.
In the directory of the job, with the file of the first section, three changes one at a time:

```
ana@laptop:~/azure/tf/asa$ cp main.tf.orig main.tf && sed -i 's/_out_of_order_max_delay_in_seconds = 20/_out_of_order_max_delay_in_seconds = 600/' main.tf && terraform validate -no-color 2>&1 | grep Error
Error: expected events_out_of_order_max_delay_in_seconds to be in the range (0 - 599), got 600
ana@laptop:~/azure/tf/asa$ cp main.tf.orig main.tf && sed -i 's/_late_arrival_max_delay_in_seconds = 60/_late_arrival_max_delay_in_seconds = 1814400/' main.tf && terraform validate -no-color 2>&1 | grep Error
Error: expected events_late_arrival_max_delay_in_seconds to be in the range (-1 - 1814399), got 1814400
ana@laptop:~/azure/tf/asa$ cp main.tf.orig main.tf && sed -i 's/"Adjust"/"Keep"/' main.tf && terraform validate -no-color 2>&1 | grep Error
Error: expected events_out_of_order_policy to be one of ["Adjust" "Drop"], got Keep
```

**The out-of-order tolerance stops at 599 seconds**, just under ten minutes, and the late arrival
tolerance at 1,814,399 seconds, which is one second short of 21 days; `-1` means waiting
indefinitely. The policy is `Adjust` or `Drop` and nothing else. These are the provider's checks,
read from its schema; the service applies its own when the job is created.

**One question a watermark cannot answer is whether the app's clock is right.** `TIMESTAMP BY at`
trusts the field; a phone whose clock is an hour fast sends clicks from the future, moves the
watermark an hour ahead, and makes every honest click from that hour late. A job that counts by an
app's time is wise to check it against the arrival time and to treat a large difference in either
direction as a bad clock rather than as an event, which is what the late arrival tolerance does in
one direction.
