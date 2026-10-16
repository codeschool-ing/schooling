---
title: Reading the name of a type
version: 1
---

A name such as `c7gd.xlarge` looks like a stock code, the kind copied from a blog post and never
questioned. **It is a short sentence in a small grammar**, and each piece of it changes something
you can measure. One piece fixes the ratio of memory to processor, one the instruction set the
machine runs, one whether the host carries a disk of its own, and one how large a slice you get. Read the grammar once and
a type you have never met tells you what it is before you look it up.

```schooling-figure
{"svg": "<svg id=\"fig-type-name\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The name c7gd.xlarge split into five pieces. c is the family, compute optimised, with 2 GiB per vCPU. 7 is the generation. g is the Graviton processor, Arm. d adds a 237 GB NVMe disk in the host. xlarge is the size: 4 vCPU and 8 GiB, twice a large.\"><defs><marker id=\"type-name-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"24\" y=\"20\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"84.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">c</text><line x1=\"84.0\" y1=\"66\" x2=\"84.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#type-name-ah)\"></line><rect x=\"24\" y=\"104\" width=\"120\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"84.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">family</text><text x=\"84.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">compute</text><text x=\"84.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">optimised</text><text x=\"84.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">2 GiB per vCPU</text><rect x=\"162\" y=\"20\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"222.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">7</text><line x1=\"222.0\" y1=\"66\" x2=\"222.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#type-name-ah)\"></line><rect x=\"162\" y=\"104\" width=\"120\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"222.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">generation</text><text x=\"222.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the seventh</text><text x=\"222.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">of the family</text><text x=\"222.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">8 is newer</text><rect x=\"300\" y=\"20\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"360.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">g</text><line x1=\"360.0\" y1=\"66\" x2=\"360.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#type-name-ah)\"></line><rect x=\"300\" y=\"104\" width=\"120\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">processor</text><text x=\"360.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Graviton,</text><text x=\"360.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the Arm AWS</text><text x=\"360.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">designs</text><rect x=\"438\" y=\"20\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"498.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">d</text><line x1=\"498.0\" y1=\"66\" x2=\"498.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#type-name-ah)\"></line><rect x=\"438\" y=\"104\" width=\"120\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"498.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">extra</text><text x=\"498.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">NVMe disk</text><text x=\"498.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">in the host</text><text x=\"498.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">237 GB here</text><rect x=\"576\" y=\"20\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"636.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">xlarge</text><line x1=\"636.0\" y1=\"66\" x2=\"636.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#type-name-ah)\"></line><rect x=\"576\" y=\"104\" width=\"120\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"636.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">size</text><text x=\"636.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">4 vCPU, 8 GiB</text><text x=\"636.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">twice a large</text><text x=\"636.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">half a 2xlarge</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the dot separates the size from the rest</text></svg>", "caption": "Five pieces, five facts. Change one letter and exactly one property of the machine changes."}
```

## Before the dot: family, generation, attributes

The first letter is the **family**, and the family fixes the ratio between memory and processor:
`m` is general purpose, `c` is compute optimised and `r` is memory optimised. The next section
goes through all five categories AWS sorts its families into, with the letters that belong to
each.

The number is the **generation**. A higher number is newer hardware in the same family, faster
per vCPU and often cheaper per hour. The price sheet carries seventh-generation types because they
are the ones this course compares, but they are not the newest: the catalogue below already offers
`c8g`, `m8i` and `r8g` in São Paulo. A generation is not withdrawn when the next one arrives, so a
template written three years ago keeps launching `m5` long after `m7` became the better buy, and
nothing warns you.

What follows the number are the **attributes**, one letter each, and the processor comes first:

| letter | what it says | example |
|---|---|---|
| `i` | an Intel processor | `m7i.large` |
| `a` | an AMD processor | `m7a.large` |
| `g` | Graviton, the Arm processor AWS designs | `m7g.large` |
| `d` | local NVMe disks in the host, the instance store | `c7gd.xlarge` |
| `n` | more network bandwidth | `c7gn.xlarge` |
| `e` | extra memory or extra storage for the family | `x2iedn.xlarge`, `i7ie.large` |
| `z` | a higher sustained clock speed | `r7iz.large` |
| `-flex` | a cheaper variant that does not promise full speed all the time | `m7i-flex.large` |

Older generations have no processor letter when the processor is Intel: `m5.large` is Intel and
`m5a.large` is AMD, because the letter arrived together with the alternatives. From the sixth
generation on, Intel carries its `i` like everybody else.

moto carries AWS's own description of every type, so the letters can be checked against it. Three
types that differ by one letter each:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types c7g.xlarge c7gd.xlarge c7gn.xlarge --query "InstanceTypes[].[InstanceType,ProcessorInfo.SupportedArchitectures[0],InstanceStorageInfo.TotalSizeInGB,NetworkInfo.NetworkPerformance]" --output table
--------------------------------------------------------
|                 DescribeInstanceTypes                |
+--------------+--------+-------+----------------------+
|  c7g.xlarge  |  arm64 |  None |  Up to 12.5 Gigabit  |
|  c7gd.xlarge |  arm64 |  237  |  Up to 12.5 Gigabit  |
|  c7gn.xlarge |  arm64 |  None |  Up to 40 Gigabit    |
+--------------+--------+-------+----------------------+
```

All three are Graviton, so all three are `arm64`. The `d` adds a 237 GB disk inside the host, and
the `n` raises the network ceiling from 12.5 to 40 gigabits a second. Everything else about the
three machines is the same.

## The processor letter decides what will run

**`g` is the letter with consequences.** An Arm processor runs programs compiled for Arm, and an
image built for `x86_64` does not boot on it. Language runtimes, the major Linux distributions and
most container images publish both builds, so a Python or Java service usually moves across with
nothing changed. Where the move stops is a vendor's closed binary, or a native library nobody
compiled for `arm64`.

The letter also changes what a vCPU is:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types m7i.large m7a.large m7g.large --query "InstanceTypes[].[InstanceType,ProcessorInfo.Manufacturer,ProcessorInfo.SupportedArchitectures[0],VCpuInfo.DefaultCores,VCpuInfo.DefaultThreadsPerCore]" --output table
--------------------------------------------
|           DescribeInstanceTypes          |
+------------+--------+---------+----+-----+
|  m7a.large |  AMD   |  x86_64 |  2 |  1  |
|  m7g.large |  AWS   |  arm64  |  2 |  1  |
|  m7i.large |  Intel |  x86_64 |  1 |  2  |
+------------+--------+---------+----+-----+
```

On `m7i.large` the two vCPU are **one core running two threads**, Intel's simultaneous
multithreading. On `m7a.large` and `m7g.large` they are two whole cores with one thread each: AMD's
seventh generation on AWS runs without the second thread, and Graviton has never had one. So "2
vCPU" on the price sheet is not the same amount of processor in all three, and a CPU-bound program
can finish noticeably sooner on the type with two real cores. The only way to know by how much is
to run your own program on each.

## What moto lets through, and AWS does not

Here moto is more forgiving than AWS, and the difference is worth seeing once. Both of these were
accepted:

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type m7g.large --query "Instances[0].[InstanceType,Architecture]" --output text
m7g.large	x86_64
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type m7i.huge --query "Instances[0].[InstanceType,State.Name]" --output text
m7i.huge	pending
```

The first launched an Arm type from an `x86_64` image, the Amazon Linux 2023 image lesson 2 starts
from, and moto even reports the instance as `x86_64`. The second launched `m7i.huge`, a size that
does not exist. **On AWS both calls are refused before anything starts or is billed**: EC2 checks
that the image's architecture matches the type's, and that the type exists and is offered where
you asked for it. moto keeps a record of whatever it was given.

The habit to take from this is to check the pair yourself, because an error that moto never
raises is one you will first meet on AWS. `aws ec2 describe-images --image-ids … --query
'Images[0].Architecture'` names the image's architecture, and the type's is in the table above.

## After the dot: the size

Everything after the dot is the **size**: `nano`, `micro`, `small`, `medium`, `large`, `xlarge`,
then `2xlarge` and upwards, and `metal` for the whole physical host with no hypervisor between you
and it. Within one family each step up doubles the vCPU and the memory and keeps the ratio. The
last reading section of this lesson puts prices on that doubling, and on the one family whose
sizes do not behave like the others.
