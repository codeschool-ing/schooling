---
title: Choosing the bound
version: 1
---

**The bound trades latency for completeness, and the only honest way to choose it is to measure
how late the events really are.** A bound of two minutes means every result waits two minutes
after its window ends; a bound of three hours means it waits three hours. What each buys is the
share of events that arrive in time to count.

The trade is visible on the twelve sales. With a bound of six minutes:

```
ubuntu@stream:~/work$ python watermark.py --bound 6
 #  happened  shop      watermark  what happened
 1  09:00:40  recife    08:54:40  
 2  09:02:10  natal     08:56:10  
 3  09:03:55  olinda    08:57:55  
 4  09:05:00  recife    08:59:00  
 5  09:06:20  natal     09:00:20  
 6  09:12:30  caruaru   09:06:30  
                              emit 09:00:00-09:05:00: 3 sales, 12470
 7  09:13:05  recife    09:07:05  
 8  09:08:50  natal     09:07:05  
 9  09:14:10  olinda    09:08:10  
10  09:21:00  recife    09:15:00  
                              emit 09:05:00-09:10:00: 3 sales, 21380
                              emit 09:10:00-09:15:00: 3 sales, 12690
11  09:04:30  natal     09:15:00  too late for 09:00:00-09:05:00: dropped
12  09:23:10  olinda    09:17:10  
still open: 09:20:00 (2)
```

Nothing emits until sale 6, and then only the 09:00 window; the 09:05 window waits until sale 10.
But when it is emitted it holds **three sales and 21,380 cents**, sale 8 included, and nothing is
dropped except sale 11, which no reasonable bound would have caught. **Waiting longer bought one
sale and cost four arrivals' worth of delay.** On a dashboard that is the difference between a
number that appears four sales later and is right, and one that appears sooner and stays wrong.

## Measuring it

Lesson 9 measured how far each sale of a day at Ponto Final arrived behind the latest sale seen
before it. That distance is exactly what a bound has to cover: a sale whose distance is under the
bound is never late. So the bound is chosen from the distribution of that distance, and the
question is which percentile to cover.

The `late` topic from lesson 9 holds the day. If your cluster has been rebuilt since, make it again
with the same two commands as there:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic late --partitions 1 --config retention.ms=-1
Created topic late.
ubuntu@stream:~/work$ python late_tills.py
sent 360 sales to late, from 09:00:27 to 15:13:59; natal held 38 from 10:20 to 14:00
```

Then the same pipeline as lesson 9's, with a different ending: it prints each sale's distance,
sorts them, reads off the percentiles, where p90 is the distance that 90 per cent of sales are at
or under, and counts how many are within a minute and within two:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic late --from-beginning --max-messages 360 2>/dev/null \
  | jq -r '.at[:19] + "Z" | fromdate' \
  | awk '$1 > seen { seen = $1 } { print seen - $1 }' | sort -n \
  | awk '{ d[NR] = $1 } $1 <= 0 { w0++ } $1 <= 60 { w60++ } $1 <= 120 { w120++ }
         END { split("50 80 85 90 95 99 100", p, " ")
               for (i = 1; i <= 7; i++) { k = int(NR * p[i] / 100 + 0.99); print "p" p[i], d[k], "s" }
               print "within 0 s:", w0, " within 60 s:", w60, " within 120 s:", w120 }'
p50 0 s
p80 0 s
p85 40 s
p90 1847 s
p95 6373 s
p99 11332 s
p100 12154 s
within 0 s: 292  within 60 s: 311  within 120 s: 322
```

Read it from the top. **Half the sales, and four in five, arrive in order**: their distance is
zero. By p85 the distance is under a minute. Between p85 and p90 it leaps from seconds to half an
hour, because that is where lesson 9's second population starts, Natal's held sales. Covering the
last 10 per cent means waiting more than three hours.

| bound | sales never behind it | each result waits |
|---|---|---|
| 0 | 292 of 360 | nothing |
| 1 minute | 311 of 360 | one minute |
| 2 minutes | 322 of 360 | two minutes |
| the largest distance | 360 of 360 | over three hours, which is a batch |

**A bound of a minute or two is right for these tills**, and it is right because of the shape, not
the numbers: the slow deliveries end at 92 seconds and the next thing is Natal, half an hour later.
A bound anywhere in the gap catches the first group and none of the second, so the shortest bound
past the first group is the best one. The second group is not the bound's job. It is what allowed
lateness, the late topic and the nightly batch are for.

## When the distribution moves

A bound measured once goes stale. A new till with a slow connection widens the first group; a
shop on a mobile network that drops every afternoon creates a third. That is why the count of late
events on the late topic is worth watching: **a bound that fits produces a steady trickle of late
events, and a change in the trickle is a change in the stream.** Measure again, with the same
pipeline, and move the bound when the data says so, not when a window is inconveniently late.
