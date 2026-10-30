---
title: Sizes, the limits that grow with them, and the B family
version: 1
---

A size feels like a quality setting, small for a test and large for production. **Inside a
series, a size is only a quantity**: each step up doubles the vCPUs and the memory and keeps the
ratio. What does change with the size is everything the name leaves out, the limits on disks and
network, and one family sells its processor in a different way altogether.

## Twice as much, and the limits beside it

Every size of the Dsv5 series, the series of the CLI's default, with the limits Microsoft
publishes for each on the series page, read on 2026-10-30 and not measured here:

| size | vCPUs | GiB | data disks | disk IOPS | disk MBps | network Mbps |
| --- | --- | --- | --- | --- | --- | --- |
| `Standard_D2s_v5` | 2 | 8 | 4 | 3,750 | 85 | 12,500 |
| `Standard_D4s_v5` | 4 | 16 | 8 | 6,400 | 145 | 12,500 |
| `Standard_D8s_v5` | 8 | 32 | 16 | 12,800 | 290 | 12,500 |
| `Standard_D16s_v5` | 16 | 64 | 32 | 25,600 | 600 | 12,500 |
| `Standard_D32s_v5` | 32 | 128 | 32 | 51,200 | 865 | 16,000 |
| `Standard_D48s_v5` | 48 | 192 | 32 | 76,800 | 1,315 | 24,000 |
| `Standard_D64s_v5` | 64 | 256 | 32 | 80,000 | 1,735 | 30,000 |
| `Standard_D96s_v5` | 96 | 384 | 32 | 80,000 | 2,600 | 35,000 |

The disk columns are for Premium SSD without the host cache. The memory stays at 4 GiB per vCPU
all the way down, and the steps double up to 32 vCPUs and then go to 48, 64 and 96.

**The disk limits grow with the size, and the network limit on the small sizes does not.** A
`D2s_v5` may attach four data disks and is held to 3,750 IOPS across all of them, whatever disks
you buy; a `D8s_v5` may attach sixteen and do 12,800. Lesson 3 gives each disk a limit of its own,
and a program gets the lower of the disk's limit and the machine's. A database that is slow on a
small size can be waiting on that ceiling with its processor nearly idle, and the fix is a size up
rather than a faster disk.

The network column runs the other way: the four smallest sizes share the same 12,500 Mbps. That
number is a ceiling and not a promise. Microsoft's table notes say the upper limits are not
guaranteed and are offered as guidance, and the throughput a machine actually gets depends on
the traffic around it.

## Two small or one large

With the price list out of reach, take an illustrative rate, not Azure's: 0.10 USD an hour for a
`D2s_v5`. If the rate scales with the vCPUs, which is the thing to check in the real list before
relying on it, a `D4s_v5` is 0.20. Over a month of 730 hours that is 73 USD and 146 USD, so two
`D2s_v5` cost what one `D4s_v5` costs. The choice between them is then not about money. One
larger machine runs one copy of the program with more room; two smaller ones survive the loss of
either and let a group grow in smaller steps, which is what lesson 4's scale sets are for.

## Constrained vCPUs: the processors you do not license

Some software is licensed per processor core: a commercial database is the usual case, and SQL
Server is the one Microsoft's documentation names. A database often needs a large size for its
memory and its disk limits and uses only a few of the vCPUs, and every vCPU it was given counts
against the licence. **A constrained size keeps the memory, the disks and the I/O of a size and
switches off most of its vCPUs.**

The example from that page: `Standard_E32s_v5` has 32 vCPUs, 256 GiB, 32 disks and 80,000 IOPS.
`Standard_E32-16s_v5` and `Standard_E32-8s_v5` have the same memory, disks and IOPS with 16 and 8
vCPUs active. Microsoft prices them as the original size, so the machine costs the same and the
saving is in the licence. With an illustrative licence of 100 USD per vCPU a month, which is no
vendor's price, the database on `E32s_v5` owes 3,200 USD a month and on `E32-8s_v5` owes 800.

The CLI also offers the same idea per machine, on sizes that support it, as two options of
`az vm create`:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-v-cpus-[a-z-]* : [^.]*\."
--v-cpus-available : Specify the number of vCPUs available.
--v-cpus-per-core : Specify the ratio of vCPU to physical core.
```

`--v-cpus-available` sets how many vCPUs the machine keeps. `--v-cpus-per-core 1` switches off
the second thread on each core, so a hyper-threaded size gives you whole cores and half as many
vCPUs. Microsoft documents both as costing nothing extra: the machine is billed as the full size.

## The B family: a share of the processor and credits for the rest

The B family is the one series where a vCPU is not yours all the time. It comes in three series,
`Bsv2` on Intel, `Basv2` on AMD and `Bpsv2` on Ampere Altra, which is Arm. Each size has a
**base CPU performance**, a percentage of the whole machine it may use for ever, and
**credits** that pay for anything above it. Below the base it banks credits; above it, it spends
them. Microsoft's numbers for four sizes of `Bsv2`:

| size | vCPUs | GiB | base | credits at start | banked per hour | most it can hold |
| --- | --- | --- | --- | --- | --- | --- |
| `Standard_B2ts_v2` | 2 | 1 | 20% | 60 | 24 | 576 |
| `Standard_B2ls_v2` | 2 | 4 | 30% | 60 | 36 | 864 |
| `Standard_B2s_v2` | 2 | 8 | 40% | 60 | 48 | 1,152 |
| `Standard_B4s_v2` | 4 | 16 | 40% | 120 | 96 | 2,304 |

`Basv2` and `Bpsv2` carry the same numbers size for size. The base is a share of the whole
machine, on a scale of 0 to 100% that Microsoft adopted in 2024. Older pages used 0 to the number
of vCPUs times 100%, so an old article giving `B2s_v2` a base of 80% means the same 40% as this
table.

Microsoft gives the arithmetic as one formula, credits banked per minute:

`(base × vCPUs − CPU used × vCPUs) / 100`

**One credit is one vCPU at 100% for one minute**, which is what the formula comes to. An idle
`B2s_v2` banks (40 × 2 − 0) / 100 = 0.8 credits a minute, which is the 48 an hour in the table,
and the most it can hold, 1,152, is exactly 24 hours of that.

Three cases for the shop, on a `B2s_v2`:

- The staging server overnight, at 10%: (80 − 20) / 100 = 0.6 credits a minute banked, 36 an
  hour. Ten quiet hours bank 360.
- A load test against it, both vCPUs at 100%: (80 − 200) / 100 = −1.2 a minute, 72 spent an
  hour. A full bank of 1,152 lasts 16 hours; the 360 of one night last 5 hours; the 60 credits a
  new machine starts with last 50 minutes.
- The order API on a busy day, at a steady 70%: (80 − 140) / 100 = −0.6 a minute, 36 an hour,
  and a full bank lasts 32 hours.

**When the credits run out, the machine is held to its base** until it banks more. For a
`B2s_v2` that is 40% of the machine, eight tenths of one vCPU, and the order API that was using
1.4 vCPUs worth of processor now has to fit into 0.8. Microsoft's documentation describes no
other outcome, and there is nothing to choose about it when the machine is created:

```
ana@laptop:~/azure$ az vm create --help | grep -ci credit
0
```

The help of `az vm create` does not mention credits once. The balance is visible only while the
machine runs, as the metrics *CPU Credits Remaining* and *CPU Credits Consumed* in Azure Monitor,
which `azure-operations` lessons 8 to 13 set up. Nothing on this laptop earns or spends a credit,
so **what this section says about credits comes from Microsoft's documentation and was not run.**

## Burstable or fixed

`B2s_v2` and `D2s_v5` have the same shape, 2 vCPUs and 8 GiB, and Microsoft describes the Bsv2
series as low-cost. What the lower price buys you out of is the processor above 40%. **For a
machine that idles, that is a bargain**: a staging server, a jump host, an internal tool used a
few times a day, anything whose average stays under the base. For a machine that sits above the
base through the working day, the bank only delays the moment it is throttled, and a fixed size
would have run the same work at full speed. The test is the average CPU over a typical week
against the base in the table, measured rather than guessed.
