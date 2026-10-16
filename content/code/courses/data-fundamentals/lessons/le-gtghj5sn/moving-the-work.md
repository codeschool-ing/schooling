---
title: Moving the work to the data
version: 1
---

**Over a network, sending the program is cheap and sending the data is expensive, so distributed
processing sends the computation to the machines that already hold the data.** That principle is
called **data locality**. A count of rides per station, over data spread across three machines,
does not begin by copying every ride to one place. Each machine counts what it holds, and only the
counts travel.

## The shuffle

Locality runs out when the question is grouped by a different key from the one the data is
partitioned by. Rides stored by ride id, counted by station: the rides of ST05 are on all three
machines, and somewhere the counts for ST05 have to come together. Moving data between the machines
so that everything with the same key ends up in one place is called a **shuffle**. It is usually the
most expensive step of a distributed job, because it is the step that crosses the network.

The program below stores 30,000 rides on three nodes by hash of the ride id, and counts them per
station two ways. Plan A sends every ride to the node responsible for its station. Plan B counts on
each node first and sends only those partial counts. Save it as `shuffle.py`:

```schooling-example
{"language": "python", "file": "spread/shuffle.py", "parts": [
{"code": "# spread/shuffle.py\nimport hashlib\nimport random\nfrom collections import Counter\n\nrandom.seed(4)\nSTATIONS = [f\"ST{i:02d}\" for i in range(1, 13)]\nrides = [(f\"R{i:06d}\", random.choice(STATIONS)) for i in range(1, 30001)]\n\n\n", "note": "Thirty thousand rides this time, with no hot station."},
{"code": "def node_of(key, n=3):\n    return int(hashlib.md5(key.encode()).hexdigest(), 16) % n\n\n\n", "note": "One hash decides two things: which node stores a ride, by its id, and which node counts a station, by the station's id."},
{"code": "# the rides are stored on three nodes, spread by hash of ride id\nstored = [[ride for ride in rides if node_of(ride[0]) == n] for n in range(3)]\nprint(\"rides stored per node:\", [len(s) for s in stored])\n\n", "note": "The rides are where storage put them, by ride id. That is the wrong key for the question, which is per station."},
{"code": "# plan A: send every ride to the node that owns its station, and count there\nsent_a = sum(node_of(station) != n for n in range(3) for _, station in stored[n])\n\n", "note": "Plan A sends each ride whose station is counted on another node across the network."},
{"code": "# plan B: count on each node first, then send one partial count per station\npartial = [Counter(station for _, station in stored[n]) for n in range(3)]\nsent_b = sum(node_of(station) != n for n in range(3) for station in partial[n])\n\n", "note": "Plan B counts on each node first, so what travels is at most one partial count per station per node."},
{"code": "total = sum(partial, Counter())\nprint(\"records sent over the network, plan A:\", sent_a)\nprint(\"records sent over the network, plan B:\", sent_b)\nprint(\"same answer either way:\", total == Counter(s for _, s in rides), total.most_common(2))\n", "note": "Adding the partial counts gives the full count; the program checks it against counting every ride directly."}
]}
```

```
ana@lab:~/roda/spread$ python shuffle.py
rides stored per node: [9937, 9897, 10166]
records sent over the network, plan A: 19958
records sent over the network, plan B: 24
same answer either way: True [('ST12', 2606), ('ST05', 2570)]
```

Plan A sent 19,958 rides across the network, about two in every three, because a ride stays put only
when the node that stores it happens to be the node that counts its station. Plan B sent 24 records:
each of the three nodes had a partial count for each of the twelve stations, 36 in all, and the 12
already on the right node did not travel. Both gave the same answer.

**Counting first is possible because a count can be added up in pieces.** So can a sum, a minimum and
a maximum. A median cannot: the median of three medians is not the median of all the rides, so a
job that wants one has to bring the values together. Which operations combine in pieces is a large
part of why some distributed queries are fast and others are not.

## The names you will meet

**MapReduce**, described by Google in 2004, made this shape famous: a *map* step runs on each machine
over the data it holds, a shuffle groups the results by key, and a *reduce* step combines each
group. Hadoop was its open-source implementation. **Spark** came after it and keeps intermediate
results in memory instead of writing them to disk between steps, and it is what `bigdata` teaches,
shuffles, skew and all. A cloud warehouse does the same underneath a query written in SQL. None of
them is taught here. What you should be able to do is look at a question, see whether it is grouped
by the key the data is partitioned by, and know that if it is not, something is about to cross the
network.
