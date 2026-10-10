---
title: Little's law
version: 1
---

One relation connects the three numbers every load test talks about: how many requests are in the
system at once, how fast they arrive, and how long each one stays. John Little proved it in 1961.
It needs no assumption about the shape of the arrivals or the order of service, and it holds
for any system that is stable over the period measured:

> **L = λ × W**: the average number inside equals the arrival rate times the average time each
> one spends inside.

In load testing it is usually written with the throughput, `X`, in place of the arrival rate,
which is the same thing for a system that keeps up: what goes in per second comes out per second.
**The averages are means, and here the mean is the right statistic**: the law is an identity about
totals, and lesson 8's warnings about means do not apply to it.

## Checking it on the box office

`users.py` measures both sides separately. It counts the requests in flight directly, ten times a
second, and it computes `X × R` from the throughput and the mean response time. Here are the two
lines from each of the runs in "Virtual users, think time and ramp-up":

| run | in flight, counted | X × R |
|---|---|---|
| 10 users, think 0.5 s | 0.2 | 0.3 |
| 100 users, no think time | 99.9 | 98.7 |
| 240 users, think 4 s | 0.9 | 1.1 |

They agree to within the rounding of a short run on a shared machine, and the middle row agrees at
nearly a hundred. Nothing in `users.py` forces that agreement: the count and the product are
computed from different data.

## The law applied to the whole loop

Draw the boundary wider, around a virtual user's whole loop, and the time inside becomes the
response time plus the think time. Everybody is always somewhere in the loop, so the number inside
is the number of users:

> **N = X × (R + Z)**: users equal throughput times the response time plus the think time.

That is the line `X × (R + think)` in the output, and it came out at 10.0, 98.7 and 240.5 for runs
of 10, 100 and 240 users. Where it falls a little short, the gap is time a user spent neither
waiting nor thinking: inside the generator itself, between one request and the next.

**Rearranged, it turns a rate into a number of users**, which is the calculation every closed
test needs:

- To offer 50 requests a second, the rate in lesson 1's requirement, with a think time of 2 s
  and responses of about 20 ms, you need about 50 × 2.02 = 101 virtual users.
- Fifty users who think for 1.9 s against a server answering in 100 ms will send at most
  50 / 2.0 = 25 requests a second, however powerful the generator is.
- If the server slows from 20 ms to 2 s, the same 101 users fall from 50 requests a second to
  101 / 4.0, about 25: the closed model backing off, written as arithmetic.

The last line is why a closed test sized this way is only right while the server keeps up. Once
`R` grows, the rate it offers falls, and the test stops asking the question it was sized for.
