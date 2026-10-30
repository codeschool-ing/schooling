---
title: Whose clock decides
version: 1
---

**"Last" needs a clock, and every clock available gives a different answer.** The run in the
previous section used the devices' own clocks, and that only worked because both were right. A
phone's clock is set by the network most of the time and by the person some of the time, and
nothing stops it being wrong by minutes or by hours. Lesson 11 met the same problem with a cursor;
here it decides who wins.

## A phone two hours ahead

Give the phone a clock two hours fast. The program takes the skew as an argument, in minutes:

```
ana@dev:~/planner/lww$ node lww.ts device-clock phone=120
policy: device-clock, phone=120
10:05 phone   edits s3: minutes 20 -> 30, stamped 12:05
10:20 tablet  edits s3: done false -> true, stamped 10:20
10:40 tablet  syncs: 10:20 is newer than the server's row, kept
11:00 phone   syncs: 12:05 is newer than the server's row, kept
server s3: minutes 30, done false
```

The phone's edit was made at 10:05 and stamped 12:05, so it beat the tablet's tick, made a quarter
of an hour later. This time `done` is lost. **The device with the wrong clock wins every conflict
until somebody notices the clock**, and the person who owns that phone will never see anything
odd: their edits always stick.

## The server's clock

The obvious repair is to stop trusting devices and stamp each write when it arrives. The server
has one clock, it is kept right, and nobody can set it from a phone:

```
ana@dev:~/planner/lww$ node lww.ts server-clock
policy: server-clock
10:05 phone   edits s3: minutes 20 -> 30, stamped 10:05
10:20 tablet  edits s3: done false -> true, stamped 10:20
10:40 tablet  syncs: 10:40 is newer than the server's row, kept
11:00 phone   syncs: 11:00 is newer than the server's row, kept
server s3: minutes 30, done false
```

The skew no longer matters, and the answer is still arbitrary. **The server's clock orders writes
by when they arrived, which is when each device happened to find a network.** The phone was on a
train; it arrived last, so its 30 minutes won and the tick was lost. On another morning the tablet
syncs last and the other field goes. Arrival time measures connectivity, not intent.

| stamp | the winner is | wrong when |
|---|---|---|
| the device's clock | the edit made latest, by that device's reckoning | a clock is wrong, or set by hand |
| the server's clock | the device that synced last | the devices were offline for different lengths of time |

Neither stamp answers the question that matters, which is the one from the start of this lesson:
had the second writer seen the first write? A clock cannot say. A version number can, and lesson
14 starts there. What the table does settle is which mistake you prefer, and for most apps the
server's clock is the better of the two: it cannot be gamed, its errors do not pile up on one
person, and it is the same for everybody.
