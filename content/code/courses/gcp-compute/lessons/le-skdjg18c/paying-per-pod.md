---
title: Paying per pod
version: 1
---

On Standard the bill is nodes, and a half-empty node costs as much as a full one. **On Autopilot
the bill is the CPU, memory and ephemeral storage the pods request, for as long as they run**,
plus the same cluster fee lesson 13 priced. Neither is cheaper in general; which one wins depends
on how well your pods would fill nodes, and that can be worked out before choosing.

## The rates

```
ana@laptop:~/gcp$ python3 prices.py serverless | grep Autopilot
  Autopilot pod vCPU                                  0.0445  per vCPU-hour
  Autopilot pod memory                             0.0049225  per GiB-hour
```

**0.0445 a vCPU-hour and 0.0049225 a GiB-hour.** For comparison, an `e2-standard-4` is 0.134 an
hour for four vCPU and 16 GiB, about 0.034 per vCPU if its memory came free. Autopilot's rate is
higher per unit, and what it buys is that no unit is paid for while it sits empty.

Autopilot also has a Spot price for pods that can be interrupted, the same idea lesson 6 applies
to machines. Google's GKE pricing page lists it on 30 October 2026 at 0.0133 a vCPU-hour and
0.0014767 a GiB-hour, in Iowa; a pod asks for it with a node selector, and section 04 comes back to
which of the shop's pods qualify.

## A program that compares the two

The comparison is arithmetic, and it is worth having as a program, because the answer changes with
every change to the pods. **Save this as `~/gcp/autopilot.py`, beside `prices.py`**, which it
imports:

```schooling-example
{"language": "python", "file": "autopilot.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Autopilot or Standard, for the same pods.\n\nEach argument is COUNT:VCPU:GIB, a number of pods and what each one requests.\nAutopilot bills the requests; Standard bills the nodes they are packed onto.\nPrices are prices.py's: Iowa, 30 October 2026, on demand.\n\n    python3 autopilot.py 6:0.5:1 2:1:4\n\"\"\"\n", "note": "The docstring says what the arguments are and where the prices come from. Each pod shape is written COUNT:VCPU:GIB, so a mix of services is several arguments."}, {"code": "import math\nimport sys\n\nfrom prices import MONTH, VM\n\nPOD_VCPU = 0.0445     # Autopilot, per vCPU-hour of requests\nPOD_GIB = 0.0049225   # Autopilot, per GiB-hour of requests\nNODE = 'e2-standard-4'\n\n\n", "note": "The program imports the month and the machine table from prices.py, which is why it has to sit beside it in ~/gcp. The two Autopilot rates are on the same GKE pricing page as the cluster fee, and prices.py prints them too."}, {"code": "def allocatable(cpus, gib):\n    \"\"\"What GKE leaves for pods on a Standard node, by its documented reservation.\"\"\"\n    cpu_steps = [(1, 0.06), (1, 0.01), (2, 0.005)]\n    cpu_reserved, left = 0.0, cpus\n    for size, share in cpu_steps:\n        take = min(size, left)\n        cpu_reserved += take * share\n        left -= take\n    cpu_reserved += left * 0.0025\n    mem_steps = [(4, 0.25), (4, 0.20), (8, 0.10), (112, 0.06)]\n    mem_reserved, left = 0.0, gib\n    for size, share in mem_steps:\n        take = min(size, left)\n        mem_reserved += take * share\n        left -= take\n    mem_reserved += left * 0.02 + 0.1   # and the eviction threshold, 100 MiB\n    return cpus - cpu_reserved, gib - mem_reserved\n\n\n", "note": "What a Standard node keeps back for the system before any pod lands: a shrinking share of each vCPU and of each GiB, by the steps in GKE's documentation on node allocatable resources, plus the 100 MiB the kubelet holds for eviction. It leaves out the system pods GKE runs on every node, so the real room is a little smaller still."}, {"code": "def main():\n    pods = [tuple(float(x) for x in arg.split(':')) for arg in sys.argv[1:]]\n    cpu = sum(n * c for n, c, _ in pods)\n    gib = sum(n * g for n, _, g in pods)\n    print(f'{int(sum(n for n, _, _ in pods))} pods requesting {cpu:g} vCPU and {gib:g} GiB')\n\n    auto = (cpu * POD_VCPU + gib * POD_GIB) * MONTH\n    print(f'  Autopilot, the requests:          {auto:8.2f} a month')\n", "note": "Autopilot first: the sum of the requests, priced per vCPU-hour and per GiB-hour, for 730 hours."}, {"code": "\n    node_cpu, node_gib, hourly, _ = VM[NODE]\n    free_cpu, free_gib = allocatable(node_cpu, node_gib)\n    nodes = math.ceil(max(cpu / free_cpu, gib / free_gib))\n    std = nodes * hourly * MONTH\n    print(f'  {NODE} leaves {free_cpu:.2f} vCPU and {free_gib:.2f} GiB for pods')\n    print(f'  Standard, {nodes} x {NODE}:          {std:8.2f} a month')\n    print('  (both also pay the cluster fee, and Standard rounds up to whole nodes)')\n\n\nif __name__ == '__main__':\n    main()\n", "note": "Standard next: enough whole nodes for the larger of the two totals, CPU or memory, and the price of those nodes. Real packing is per pod and never perfect, so this is the floor, not the bill."}]}
```

Run it for the shop: three `web` and three `orders` pods of half a vCPU and 1 GiB, and two `photos`
pods of one vCPU and 4 GiB:

```
ana@laptop:~/gcp$ python3 autopilot.py 6:0.5:1 2:1:4
8 pods requesting 5 vCPU and 14 GiB
  Autopilot, the requests:            212.73 a month
  e2-standard-4 leaves 3.92 vCPU and 13.30 GiB for pods
  Standard, 2 x e2-standard-4:            195.67 a month
  (both also pay the cluster fee, and Standard rounds up to whole nodes)
```

**Close, and Standard slightly ahead at 195.67 against 212.73** — but that Standard figure is a
floor that assumes two nodes in one zone packed perfectly. Lesson 13 put a regional pool at one
node per zone, three at least, which is 293.51 a month; Autopilot spreads pods across zones without
charging for the empty space that requires.

Now a team whose services are tiny, two pods of a quarter vCPU and half a GiB:

```
ana@laptop:~/gcp$ python3 autopilot.py 2:0.25:0.5
2 pods requesting 0.5 vCPU and 1 GiB
  Autopilot, the requests:             19.84 a month
  e2-standard-4 leaves 3.92 vCPU and 13.30 GiB for pods
  Standard, 1 x e2-standard-4:             97.84 a month
  (both also pay the cluster fee, and Standard rounds up to whole nodes)
```

**19.84 against 97.84.** One node is the smallest Standard can be, and these pods use a sixteenth
of it. And a team that runs big, steady pods that fill nodes:

```
ana@laptop:~/gcp$ python3 autopilot.py 12:1:4
12 pods requesting 12 vCPU and 48 GiB
  Autopilot, the requests:            562.30 a month
  e2-standard-4 leaves 3.92 vCPU and 13.30 GiB for pods
  Standard, 4 x e2-standard-4:            391.35 a month
  (both also pay the cluster fee, and Standard rounds up to whole nodes)
```

**391.35 against 562.30.** Twelve pods of one vCPU and 4 GiB pack onto four nodes with little left
over, and the node price per vCPU is lower than Autopilot's.

The pattern is the one to remember: **Autopilot wins when nodes would sit partly empty, and
Standard wins when pods fill nodes steadily.** Small services, uneven load, and clusters that idle
at night lean to Autopilot. Large, steady fleets lean to Standard.

## What the program leaves out

It is a first answer, not a bill, and it says three things it does not model. Standard's nodes run
system pods of their own, so they hold less than `allocatable` says. Autopilot **raises requests
that are below its minimums or outside its allowed ratio of memory to CPU**, and charges for the
raised values; Google's documentation has the current table, and a pod asking for 0.1 vCPU may be
billed for more. And both pay the cluster fee, which the program leaves out because it is the same
on both sides.
