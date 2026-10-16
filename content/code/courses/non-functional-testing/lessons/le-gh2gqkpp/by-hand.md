---
title: Percentiles by hand
version: 1
---

A percentile is easier to trust once you have computed one yourself. Twenty numbers are enough,
and they can be real ones. This script sends twenty requests to the box office one after another,
so nothing waits for anything else: four looks at show 990, then a booking, four times over. It
prints each response time in whole milliseconds, as `curl` measured it.

```sh
# boxoffice/twenty.sh
# Twenty requests, one after another: four looks at show 990, then a
# booking, four times over. Prints each response time in milliseconds.
for i in $(seq 1 20); do
  if [ $((i % 5)) -eq 0 ]; then
    curl -s -o /dev/null -w '%{time_total}\n' -X POST localhost:8000/bookings \
      -d "{\"show_id\": 990, \"seat\": $i, \"customer\": \"ana\"}"
  else
    curl -s -o /dev/null -w '%{time_total}\n' localhost:8000/shows/990
  fi
done | awk '{ printf "%.0f\n", $1 * 1000 }'
```

Save it as `~/boxoffice/twenty.sh`, keep the server running in the other terminal, and run it into
a file, then print the file on one line, then sorted:

```
ana@nft:~/boxoffice$ bash twenty.sh > times.txt
ana@nft:~/boxoffice$ paste -sd' ' times.txt
19 32 18 18 63 19 18 18 18 65 18 19 24 20 62 37 21 32 32 64
ana@nft:~/boxoffice$ sort -n times.txt | paste -sd' '
18 18 18 18 18 18 19 19 19 20 21 24 32 32 32 37 62 63 64 65
```

The second line is the order the requests were sent. The four bookings, the fifth, tenth,
fifteenth and twentieth requests, took 63, 65, 62 and 64 ms: the 40 ms payment on top of the
query. The sixteen reads took between 18 and 37 ms. The third line is the same twenty numbers
sorted, and **every percentile is read off a sorted list**.

## The nearest-rank method

There are several ways to define a percentile, and they disagree a little on small samples. This
lesson uses the simplest, which is also what `measure.py` computes:

> Sort the n values. The p-th percentile is the value at position p/100 × n, counting from 1,
> with the position rounded **up** to a whole number.

With n = 20:

| percentile | p/100 × 20 | position | value |
|---|---|---|---|
| p50, the median | 10 | 10 | 20 ms |
| p75 | 15 | 15 | 32 ms |
| p90 | 18 | 18 | 63 ms |
| p95 | 19 | 19 | 64 ms |
| p99 | 19.8 | 20 | 65 ms |

**The method always returns one of the values you measured**, which makes it easy to check by
hand: count along the sorted list to position 18 and you find 63. The median says half the
requests took 20 ms or less; the p90 says two of the twenty took longer than 63 ms, and they are
the two slowest bookings.

The mean of the twenty is their sum, 617, divided by 20: 30.85 ms. No request took that long. It
is half as large again as the median, because four slow bookings in twenty pull it up, and if you
quoted it as "the response time" you would describe neither the reads nor the bookings.

## Other tools interpolate

k6, and the `PERCENTILE` function of a spreadsheet, use a different definition: they place the
percentile at position p/100 × (n − 1) counting from 0, and when that falls between two values
they draw a straight line between them. For the twenty values above, the p90 falls at 0.9 × 19 =
17.1, a tenth of the way from the eighteenth value (63) to the nineteenth (64), so k6 would say
63.1 ms where the nearest rank says 63. Its median of these twenty is 20.5 ms, halfway between the
tenth and eleventh values.

On a sample of hundreds the two methods agree to well within the noise between runs. **On twenty
values they can differ, and neither is wrong**: a report should say which one it used, and two
numbers computed by different methods should not be compared as if a change in them meant
something.

## How many requests a percentile needs

Look at the p99 row again. Position 19.8 rounds up to 20, the last value: **with twenty
requests, the p99 is the maximum**, and so is every percentile above 95. A percentile only means
something when there are values above it. For the p99 to have ten requests beyond it, the run
needs a thousand; for the p99.9, ten thousand. A requirement at the 99th percentile is therefore
also a requirement on the length of the test: a run of a few hundred requests cannot fail it
honestly or pass it honestly.
