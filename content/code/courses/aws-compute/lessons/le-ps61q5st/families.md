---
title: The five categories, and choosing between them
version: 1
---

The commonest way to choose an instance type is to take the biggest one the budget allows, as if
the families were quality tiers and `r` were a better `m`. **A family is a ratio, not a rank.**
Each one pairs processor with memory, and sometimes with disks or accelerators, in a proportion
that suits one kind of work. The right type is the one where the resource your program runs out
of first is the one you are paying for most of.

## Where the catalogue comes from

moto answers `describe-instance-types` with a copy of AWS's own data for every type, taken when
that moto release was made. The specifications in this section are therefore AWS's, unlike moto's
prices, which are placeholders:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --query "length(InstanceTypes)"
1373
ana@laptop:~/aws$ aws ec2 describe-instance-type-offerings --query "length(InstanceTypeOfferings)"
743
ana@laptop:~/aws$ aws ec2 describe-instance-type-offerings --location-type availability-zone --filters Name=instance-type,Values=i4i.large --query "InstanceTypeOfferings[].Location" --output text
sa-east-1a	sa-east-1b	sa-east-1c
```

**1,373 types exist, and 743 of them are offered in São Paulo.** The second count is the one that
matters to a template: a type that is not offered in a region, or in one of its zones, cannot be
launched there, however correct the rest of the request is. The third command asks per zone, and
`i4i.large` is offered in all three of `sa-east-1`'s. A type that is offered in two zones out of
three is the reason an auto scaling group, lesson 4, sometimes cannot place an instance where you
expected it.

## The five categories

AWS sorts its families into five categories, and the first letter of the name says which:

| category | families | what it is for |
|---|---|---|
| general purpose | `m`, `t` | web and application servers, most things when you have no reason to choose |
| compute optimised | `c` | work that is mostly arithmetic: encoding, compiling, batch, game servers |
| memory optimised | `r`, `x`, `u`, `z` | databases, caches, analytics that hold a working set in memory |
| storage optimised | `i`, `d`, `h` | databases that read and write their own local disks at very high rates |
| accelerated computing | `p`, `g`, `inf`, `trn`, `f` | GPUs and AWS's own chips, for training and running models, video, rendering |

One machine of each, side by side:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types m7i.large c7i.large r7i.large i4i.large g4dn.xlarge --query "InstanceTypes[].[InstanceType,VCpuInfo.DefaultVCpus,MemoryInfo.SizeInMiB,InstanceStorageInfo.TotalSizeInGB,GpuInfo.Gpus[0].Name]" --output table
-----------------------------------------------
|            DescribeInstanceTypes            |
+--------------+----+--------+-------+--------+
|  c7i.large   |  2 |  4096  |  None |  None  |
|  g4dn.xlarge |  4 |  16384 |  125  |  T4    |
|  i4i.large   |  2 |  16384 |  468  |  None  |
|  m7i.large   |  2 |  8192  |  None |  None  |
|  r7i.large   |  2 |  16384 |  None |  None  |
+--------------+----+--------+-------+--------+
```

Read the memory column against the vCPU column. `c7i.large` has 4,096 MiB for 2 vCPU, which is
**2 GiB per vCPU**. `m7i.large` has 4 GiB per vCPU and `r7i.large` has 8. `i4i.large` has the same
2 vCPU and 16 GiB as `r7i.large` and adds a 468 GB NVMe disk in the host, which lesson 3 is about.
`g4dn.xlarge` adds an NVIDIA T4 graphics processor to 4 vCPU and 16 GiB.

The price sheet of 16 October 2026 puts numbers on the first four, per hour in `sa-east-1`:
`c7i.large` 0.13755 USD, `m7i.large` 0.16065, `r7i.large` 0.21105 and `i4i.large` 0.274. The same
two vCPU cost half as much again once they come with four times the memory, and the disk on
`i4i` adds another 0.06295 USD an hour on top of `r7i`. Accelerated types are not on the sheet,
because nothing in this course needs one; their prices are many times these.

## Choosing by what runs out first

Every program has a resource it exhausts first, and the right family is chosen by that resource
and by nothing else. Two examples with the sheet's numbers:

**A Java service holding a 12 GiB heap and using about one vCPU.** The general-purpose type that
fits the memory is `m7i.xlarge`, 4 vCPU and 16 GiB, at 0.3213 USD an hour. The memory-optimised
`r7i.large` has the same 16 GiB with 2 vCPU, at 0.21105. The service never used the two extra
vCPU, so the `r` saves 0.11025 USD an hour, which over a month of 730 hours is 80.48 USD for one
instance, and the same again for every copy behind the load balancer.

**A video encoder that keeps both vCPU at 100% and uses 3 GiB.** `m7i.large` carries 8 GiB it does
not need. `c7i.large` has the same two vCPU and 4 GiB, and costs 0.0231 USD an hour less: 16.86
USD a month per instance.

The opposite mistake is just as easy. A cache on `c7i.large` holds a quarter of what `r7i.large`
holds, for about two thirds of the price, and spends its days evicting entries the `r` would have
kept.

**None of this is visible from the outside.** CPU and memory use come from measuring the program
under its real load, which in AWS means CloudWatch, and `aws-operations` lessons 8 to 10 set that
up. moto keeps no metrics at all, so in this course the measurement is described rather than
taken. AWS also runs Compute Optimizer, which reads those metrics and suggests a type; it is
`aws-operations` lesson 23, and what it suggests is the same comparison made above, at scale.

## When nothing is measured yet

A new service with no history has no first resource to run out of. Start on a general-purpose
type, `m` and the current generation, and treat the choice as a hypothesis: measure under load
for a week, then move along the ratio. Changing type is a stop and start with a different type,
which lesson 4's launch templates make routine, so the first guess is cheap to correct.
