---
title: Skew: one key with most of the work
version: 1
---

**A hash spreads keys evenly. It does not spread work evenly, because every row with the same key
goes to the same partition.** If one station has a third of the rides, the partition holding that
station has at least a third of the rides, whatever the hash function. That imbalance is called
**skew**, and the key that causes it is a **hot key**.

Every program in this lesson lives in a directory of its own, on the lab from lesson 1. Make it and
go into it:

```sh
mkdir -p ~/roda/spread && cd ~/roda/spread
```

The program below makes a Sunday of rides on which Rua XV, ST02, holds a street fair, and partitions
them three ways over four partitions. Save it as `skew.py`:

```schooling-example
{"language": "python", "file": "spread/skew.py", "parts": [
{"code": "# spread/skew.py\nimport hashlib\nimport random\nfrom collections import Counter\n\nrandom.seed(9)\nSTATIONS = [f\"ST{i:02d}\" for i in range(1, 13)]\nWEIGHTS = [1] * 12\nWEIGHTS[1] = 6                       # ST02, Rua XV: a street fair on Sunday\nrides = [(f\"R{i:06d}\", random.choices(STATIONS, WEIGHTS)[0]) for i in range(1, 10001)]\n", "note": "Ten thousand rides over twelve stations. Rua XV is given six times the weight of any other station, which is what a street fair on a Sunday does to it. The seed makes every run draw the same rides."},
{"code": "\n\ndef by_hash(key, n=4):\n    return int(hashlib.md5(key.encode()).hexdigest(), 16) % n\n\n", "note": "Hash partitioning. MD5 turns the key into a large number that looks random, and the remainder after dividing by four is the partition. Python's own `hash()` is not used, because for a string it changes from one run of Python to the next, and a partitioner has to give the same answer on every machine, every day."},
{"code": "\ndef by_range(station, n=4):\n    return (int(station[2:]) - 1) * n // 12      # ST01-ST03 to 0, ST04-ST06 to 1 ...\n\n", "note": "Range partitioning. The station number decides: ST01 to ST03 go to partition 0, ST04 to ST06 to partition 1, and so on."},
{"code": "\ndef show(title, partition_of):\n    counts = Counter(partition_of(ride_id, station) for ride_id, station in rides)\n    print(f\"{title:22}\", \" \".join(f\"{counts[p]:5}\" for p in range(4)))\n\n", "note": "Counts how many rides each partition would hold under a rule, one column per partition."},
{"code": "\nprint(f\"{'partition':22}\", \" \".join(f\"{p:5}\" for p in range(4)))\nshow(\"range of station\", lambda ride_id, station: by_range(station))\nshow(\"hash of station\", lambda ride_id, station: by_hash(station))\nspread = Counter(by_hash(station) for station in STATIONS)\nprint(f\"{'stations, by hash':22}\", \" \".join(f\"{spread[p]:5}\" for p in range(4)))\nshow(\"hash of ride id\", lambda ride_id, station: by_hash(ride_id))\nprint(\"busiest:\", Counter(station for _, station in rides).most_common(2))\n", "note": "Three rules, on the same rides: by a range of stations, by a hash of the station, and by a hash of the ride id. The middle line counts stations rather than rides, and the last names the two busiest stations."}
]}
```

```
ana@lab:~/roda/spread$ python skew.py
partition                  0     1     2     3
range of station        4724  1805  1763  1708
hash of station          544  2336  2390  4730
stations, by hash          1     4     4     3
hash of ride id         2573  2473  2508  2446
busiest: [('ST02', 3553), ('ST01', 622)]
```

Read the rows one at a time.

**By range of station**, partition 0 holds ST01 to ST03, and ST02 is among them: 4724 of the 10,000
rides, while the other three partitions hold between 1708 and 1805 each.

**By hash of the station**, the hot station moved and the problem came with it. ST02 now shares
partition 3 with two other stations, and partition 3 holds 4730 rides. The row below it shows a
second, quieter effect: twelve keys are too few for a hash to share out evenly, and partition 0 was
given a single station and 544 rides. A hash is even over thousands of keys, not over twelve.

**By hash of the ride id**, the four partitions hold between 2446 and 2573. There are ten thousand
different ride ids and each one is a single row, so no key can be hot.

The last line says why: ST02 had 3553 rides, and the next busiest station had 622.

## Why an uneven split costs time

Four machines working in parallel finish when the slowest one finishes. An even split of 10,000
rides is 2500 each; partitioned by station, the busiest partition has 4730. If the time a machine
takes follows the rows it holds, the whole job takes nearly twice as long as it needs to, and three
of the four machines spend the end of it waiting.

## What is done about it

The ride id fixed the balance, and it moved the cost. Partitioned by ride id, the question "how many
rides left Rua XV?" has to ask all four partitions and add up their answers, where partitioned by
station it asked one. **An even load and a cheap question about one station pull in opposite
directions**, and the choice of key is the choice between them.

The other common remedy goes after the hot key alone. **Salting** splits it into several keys —
`ST02#0`, `ST02#1`, `ST02#2`, `ST02#3`, the suffix taken from the ride number — so that its rows
hash to four partitions instead of one, and every question about ST02 reads those four and adds
them up. Skew in a join or a group-by over a cluster is a lesson of its own in `bigdata`; here it is
enough to recognise it, and to know that a hash cannot make it go away.
