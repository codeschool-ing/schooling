---
title: Reading the name of a size
version: 1
---

`Standard_D2s_v5`, the size the CLI chose when nobody named one, looks like a part number copied
from a supplier's catalogue. **It is a short sentence in a grammar Microsoft publishes**, and each
piece of it says one thing about the machine: which family, how many vCPUs, which processor,
whether the host gives it a disk of its own, and which version of the series. Read the grammar
once and a size you have never met tells you most of what it is before you look it up.

The grammar, in the order the pieces appear, is family, sub-family, the number of vCPUs,
constrained vCPUs, additive features, accelerator type, memory capacity and version. Four of the
eight are optional, and most names carry only the other four. `Standard_` comes first in every
size in Microsoft's lists, and the grammar starts after it.

```schooling-figure
{"svg": "<svg id=\"fig-size-name\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The size name Standard_D4pds_v6 split into seven pieces. Standard_ is the prefix every size carries. D is the family, general purpose, 4 GiB per vCPU. 4 is the number of vCPUs. p is an Arm processor, Cobalt 100. d adds a local temporary disk, 220 GiB here. s means it can use any Premium SSD. _v6 is the version of the series.\"><defs><marker id=\"size-name-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"20\" width=\"94\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"57.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--phosphor)\" font-weight=\"600\">Standard_</text><line x1=\"57.0\" y1=\"66\" x2=\"57.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#size-name-ah)\"></line><rect x=\"10.0\" y=\"104\" width=\"94\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"57.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">prefix</text><text x=\"57.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">every size</text><text x=\"57.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">carries it</text><text x=\"57.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">first</text><rect x=\"111.0\" y=\"20\" width=\"94\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"158.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">D</text><line x1=\"158.0\" y1=\"66\" x2=\"158.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#size-name-ah)\"></line><rect x=\"111.0\" y=\"104\" width=\"94\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"158.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">family</text><text x=\"158.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">general</text><text x=\"158.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">purpose</text><text x=\"158.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 GiB per vCPU</text><rect x=\"212.0\" y=\"20\" width=\"94\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"259.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">4</text><line x1=\"259.0\" y1=\"66\" x2=\"259.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#size-name-ah)\"></line><rect x=\"212.0\" y=\"104\" width=\"94\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"259.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">vCPUs</text><text x=\"259.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">four of them,</text><text x=\"259.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">so 16 GiB</text><text x=\"259.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">in a D</text><rect x=\"313.0\" y=\"20\" width=\"94\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"360.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">p</text><line x1=\"360.0\" y1=\"66\" x2=\"360.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#size-name-ah)\"></line><rect x=\"313.0\" y=\"104\" width=\"94\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">processor</text><text x=\"360.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Arm:</text><text x=\"360.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Cobalt 100</text><text x=\"360.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">on v6</text><rect x=\"414.0\" y=\"20\" width=\"94\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"461.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">d</text><line x1=\"461.0\" y1=\"66\" x2=\"461.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#size-name-ah)\"></line><rect x=\"414.0\" y=\"104\" width=\"94\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"461.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">feature</text><text x=\"461.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a local</text><text x=\"461.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">temporary disk</text><text x=\"461.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">220 GiB here</text><rect x=\"515.0\" y=\"20\" width=\"94\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"562.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">s</text><line x1=\"562.0\" y1=\"66\" x2=\"562.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#size-name-ah)\"></line><rect x=\"515.0\" y=\"104\" width=\"94\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"562.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">feature</text><text x=\"562.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">can use any</text><text x=\"562.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Premium SSD</text><text x=\"562.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">type</text><rect x=\"616.0\" y=\"20\" width=\"94\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"663.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" font-weight=\"600\">_v6</text><line x1=\"663.0\" y1=\"66\" x2=\"663.0\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#size-name-ah)\"></line><rect x=\"616.0\" y=\"104\" width=\"94\" height=\"112\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"663.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">version</text><text x=\"663.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the sixth</text><text x=\"663.0\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">of the</text><text x=\"663.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">series</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">upper case before the number, lower case after it</text></svg>", "caption": "Seven pieces, and each says one thing. Leave out the p and the same size runs on Intel; leave out the d and it has no local disk."}
```

## Before the number: the family

The capital letter after `Standard_` is the **family**, and the family fixes the ratio between
memory and processor: `D` is general purpose, `E` memory optimised, `F` compute optimised. The
next section goes through all of them. Some families take a second capital, the **sub-family**,
for a variation the parent family does not have: `DC` and `EC` are the confidential-computing
versions of `D` and `E`, and `NC`, `ND` and `NV` are three kinds of machine with a GPU in the `N`
family.

## The number is the size

Here Azure's grammar differs from the one you might have met elsewhere, where the size is a word
after a dot. **In an Azure name the size is the number, and the number is the vCPU count.**
`Standard_D2s_v5` has 2 vCPUs and `Standard_D4s_v5` has 4. Memory is not in the name at all; it
follows from the family's ratio, so a `D2s_v5` has 8 GiB and a `D4s_v5` has 16.

A second number after a hyphen is a **constrained vCPU** count. `Standard_M8-2ms` is the
`M8ms`, eight vCPUs and 218.75 GiB of memory, with six of its vCPUs switched off: the machine
keeps all the memory and disk limits of the eight-vCPU size and runs on two. The last section of
this lesson says who wants that and why. Notice that the naming page's own example writes this
size as `M8-2ms_v2`, while the M-series page and the list of constrained sizes both name it
`Standard_M8-2ms`, with no version. The size lists are the ones to trust, because they are what
Azure will accept.

## After the number: the additive features

Lower-case letters after the number are **additive features**, one letter each. These are the ones
you will meet in this course:

| letter | what it says | example |
| --- | --- | --- |
| *(none)* | an Intel processor, x86-64 | `Standard_D2s_v5` |
| `a` | an AMD processor, x86-64 | `Standard_E8as_v5` |
| `p` | an Arm processor: Microsoft's Cobalt 100, or Ampere Altra | `Standard_D4pds_v6` |
| `d` | a local temporary disk on the host | `Standard_D4ds_v5` |
| `s` | can use any Premium SSD type | `Standard_D2s_v5` |
| `l` | less memory per vCPU than the family's usual | `Standard_D2ls_v6` |
| `m` | more memory per vCPU than the family's usual | `Standard_M8ms` |
| `t` | the least memory per vCPU in the series | `Standard_B2ts_v2` |
| `b` | more bandwidth to remote disks | `Standard_E96bds_v5` |

The naming page lists a few more: `n` for more network bandwidth, `e` for confidential computing
with Intel's TDX, `i` for an isolated size that has a host to itself, and others. In the names
Microsoft publishes, the processor letter comes first and `s` comes last, so `pds` and `ads`
read the same way every time.

**There is no letter for Intel.** A name without `a` or `p` runs on Intel, which is why the
CLI's default, `Standard_D2s_v5`, says nothing about its processor and still tells you exactly
which one it is.

## Five names, worked

- `Standard_D2s_v5`: family `D`, general purpose; 2 vCPUs; Intel, because no letter says
  otherwise; `s`, any Premium SSD; version 5. 8 GiB of memory, from the family's ratio.
- `Standard_D4ds_v5`: the same series with `d` added and twice the vCPUs. The `d` is a local
  temporary disk of 150 GiB, and *temporary* is the word that matters: lesson 3 says what happens
  to it when the machine stops.
- `Standard_E8as_v5`: family `E`, memory optimised; 8 vCPUs; `a`, an AMD processor; version 5.
  64 GiB, eight for every vCPU.
- `Standard_D4pds_v6`: family `D`, 4 vCPUs, `p` for Arm, which on version 6 is Cobalt 100; a
  local disk of 220 GiB; version 6. The figure above takes it apart.
- `Standard_NC4as_T4_v3`: family `N`, sub-family `C`; 4 vCPUs; AMD; Premium SSD; and the
  **accelerator** between underscores, an NVIDIA T4. Only GPU sizes launched from the third
  quarter of 2020 carry the accelerator in the name.

## The version, and what the CLI has written down

The suffix is the **version** of the series: `_v5`, `_v6`, `_v7`. A first version often carries
none, which is why the burstable sizes of the first B-series were `Standard_B2s` and the current
ones are `Standard_B2s_v2`.

The version is also where a name ages. Microsoft sorts every series into a lifecycle stage. For
the general-purpose families its documentation, read on 2026-10-30, says that v6 and v7 are
*Current*, v4 and v5 are *Extended*, and v1 to v3 are *End of Life* where a retirement has
been announced. The CLI you installed carries two D-family sizes in the help of `az vm create`:

```
ana@laptop:~/azure$ az vm create --help | grep -o "Standard_D[A-Za-z0-9_]*"
Standard_D2s_v5
Standard_DS2_v2
```

The first is the default, and it is a v5: fully supported, and a generation behind what
Microsoft recommends for a new machine. The second comes from an example further down the help.
`DS2_v2` is from the Dsv2 series, written in the older style where the `S` was a capital and part
of the series name, and that series is End of Life, with retirement set for 1 May 2028. **Nothing
in the CLI warns you**: help text is written once and copied for years, and a size typed from it
is the size you get. Read the version of every name you copy, and prefer a v6 or v7 for anything
new unless a reason in the next two sections says otherwise.

What the name cannot tell you is whether the size is offered in `brazilsouth`, or whether your
subscription has the quota to start one. Those questions go to Azure, and the next section shows
the command that asks them and the answer it gets here.
