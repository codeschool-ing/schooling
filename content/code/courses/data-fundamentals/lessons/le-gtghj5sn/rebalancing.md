---
title: Adding a machine, and how much has to move
version: 1
---

**When a fifth machine joins four, the fair outcome is that a fifth of the data moves onto it and
nothing else moves. Partitioning by `hash % N` does not do that: change N and almost every key
changes machine.** Moving data between machines is the expensive part of growing, because it costs
network, disk and time while the system is still answering questions, so how much has to move is
the measure of a scheme.

The arithmetic is short. A key stays where it was only if its hash leaves the same remainder when
divided by 4 as when divided by 5. Out of every twenty consecutive numbers, that happens for four of
them, 0 to 3, so four keys in five change machine.

## The ring

**Consistent hashing puts the machines and the keys on the same circle, and a key belongs to the
first machine after it, going clockwise.** Hash every machine's name to a point on the circle, hash
every key to a point too, and walk forward from the key until you meet a machine. When a new
machine joins, it lands somewhere on the circle and takes over the keys between itself and the
machine before it. Every other key still meets the same machine first, so nothing else moves.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"A circle of hash values with four nodes on it, n1 to n4, and keys as small dots. Each key belongs to the first node clockwise from it. A fifth node, n5, is added between n1 and n2; the keys on the arc between n1 and n5 move from n2 to n5, and every other key stays where it was.\" data-fig=\"ring\"><defs><marker id=\"ring-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><circle cx=\"175\" cy=\"160\" r=\"112\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"2\"></circle><path d=\"M 213.3 54.8 A 112 112 0 0 1 280.2 121.7\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"6\"></path><circle cx=\"234.4\" cy=\"65.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"254.2\" cy=\"80.8\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"270.0\" cy=\"100.6\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"286.6\" cy=\"169.8\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"231.0\" cy=\"257.0\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"184.8\" cy=\"271.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"83.3\" cy=\"224.2\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"64.1\" cy=\"175.6\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"95.8\" cy=\"80.8\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"146.0\" cy=\"51.8\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"var(--ink)\" stroke-width=\"1\"></circle><circle cx=\"213.3\" cy=\"54.8\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"2.5\"></circle><text x=\"222.2\" y=\"30.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">n1</text><circle cx=\"280.2\" cy=\"198.3\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"2.5\"></circle><text x=\"304.7\" y=\"207.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">n2</text><circle cx=\"136.7\" cy=\"265.2\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"2.5\"></circle><text x=\"127.8\" y=\"289.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">n3</text><circle cx=\"69.8\" cy=\"121.7\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"2.5\"></circle><text x=\"45.3\" y=\"112.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">n4</text><circle cx=\"280.2\" cy=\"121.7\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></circle><text x=\"304.7\" y=\"112.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">n5</text><text x=\"175\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">hash values</text><text x=\"175\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">clockwise</text><text x=\"380\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">A key belongs to the first node</text><text x=\"380\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">clockwise from it.</text><text x=\"380\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">n5 joins between n1 and n2.</text><text x=\"380\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">The keys on the thick arc used to</text><text x=\"380\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">meet n2 first; now they meet n5.</text><text x=\"380\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Every other key meets the same</text><text x=\"380\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">node as before, and stays.</text></svg>", "caption": "A ring with one point per node, for clarity. n5 joins between n1 and n2 and takes only the keys on the thick arc, all of them from n2."}
```

One point per machine leaves the arcs uneven, since four random points rarely cut a circle into
four equal pieces. So each machine is placed at many points, often called **virtual nodes**, and its
share is the sum of many small arcs, which comes out closer to fair.

The program below places 10,000 ride ids on four nodes, adds a fifth, and counts what moved, once by
modulo and once on a ring with a hundred points per node. Save it as `rebalance.py`:

```schooling-example
{"language": "python", "file": "spread/rebalance.py", "parts": [
{"code": "# spread/rebalance.py\nimport bisect\nimport hashlib\nfrom collections import Counter\n\n\ndef h(text):\n    return int(hashlib.md5(text.encode()).hexdigest(), 16)\n\n\nKEYS = [f\"R{i:06d}\" for i in range(1, 10001)]\n\n\n", "note": "The same hash as before, and ten thousand ride ids as the keys."},
{"code": "def modulo(nodes):\n    return {k: nodes[h(k) % len(nodes)] for k in KEYS}\n\n\n", "note": "Placement by modulo: the hash, divided by the number of nodes, and the remainder picks one."},
{"code": "def ring(nodes, points=100):\n    marks = sorted((h(f\"{node}#{p}\"), node) for node in nodes for p in range(points))\n    spots = [spot for spot, _ in marks]\n    return {k: marks[bisect.bisect(spots, h(k)) % len(marks)][1] for k in KEYS}\n\n\n", "note": "Placement on a ring. Every node is put on the circle at a hundred points, `n1#0` to `n1#99`, and the points are sorted. A key belongs to the first point at or after its own hash, which `bisect` finds; past the last point it wraps round to the first, which is the `%`."},
{"code": "four = [\"n1\", \"n2\", \"n3\", \"n4\"]\nfive = four + [\"n5\"]\nfor name, place in ((\"modulo\", modulo), (\"ring\", ring)):\n    before, after = place(four), place(five)\n    moved = [k for k in KEYS if before[k] != after[k]]\n    went = Counter(after[k] for k in moved)\n    print(f\"{name:7} {len(moved):5} of {len(KEYS)} rides moved;\",\n          f\"{went['n5']} to the new node, {len(moved) - went['n5']} between old ones\")\n    print(f\"{'':7} rides per node after:\", sorted(Counter(after.values()).items()))\n", "note": "Both placements, before and after a fifth node joins. A key has moved if its node changed; the program counts how many moved, how many of those went to the new node, and how many rides each node holds afterwards."}
]}
```

```
ana@lab:~/roda/spread$ python rebalance.py
modulo   7966 of 10000 rides moved; 2018 to the new node, 5948 between old ones
        rides per node after: [('n1', 1926), ('n2', 2012), ('n3', 1999), ('n4', 2045), ('n5', 2018)]
ring     2177 of 10000 rides moved; 2177 to the new node, 0 between old ones
        rides per node after: [('n1', 1622), ('n2', 1865), ('n3', 2164), ('n4', 2172), ('n5', 2177)]
```

By modulo, 7966 of the 10,000 rides moved. Only 2018 of them went to the new node; the other 5948
moved from one old node to another, for no reason except the arithmetic. On the ring, 2177 rides
moved, every one of them to `n5`, and none moved between old nodes.

The ring is not perfectly even either. With a hundred points each, the five nodes hold between 1622
and 2177 rides against a fair share of 2000. More points per node bring them closer, at the cost of
a longer list to search.

## Where you will meet it

Cassandra places data on a ring of this kind, and so did Dynamo, the internal store Amazon described
in a 2007 paper that many later databases copied. The other design you will meet fixes the number of
partitions when the data set is created, many more partitions than machines, and moves whole
partitions when a machine joins. A key's partition then never changes, only the machine that
partition lives on. Both answer the same question, and the question is the one to ask of any system that
claims it grows by adding machines: when one is added, what moves?
