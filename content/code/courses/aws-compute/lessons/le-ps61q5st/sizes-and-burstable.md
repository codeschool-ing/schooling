---
title: Sizes, prices per size, and the burstable family
version: 1
---

A size feels like a quality setting, small for a test and large for production. **Inside a
family, a size is only a quantity**: each step up is twice the vCPU and twice the memory, at twice
the price per hour. What does change with size is everything the sheet does not print in the
first columns, and one family breaks the pattern altogether.

## Twice as much, at twice the price

Every size of `m7i` that moto's catalogue knows, smallest first:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --filters "Name=instance-type,Values=m7i.*" --query "sort_by(InstanceTypes,&VCpuInfo.DefaultVCpus)[].[InstanceType,VCpuInfo.DefaultVCpus,MemoryInfo.SizeInMiB,NetworkInfo.NetworkPerformance]" --output table
-----------------------------------------------------------
|                  DescribeInstanceTypes                  |
+-----------------+------+---------+----------------------+
|  m7i.large      |  2   |  8192   |  Up to 12.5 Gigabit  |
|  m7i.xlarge     |  4   |  16384  |  Up to 12.5 Gigabit  |
|  m7i.2xlarge    |  8   |  32768  |  Up to 12.5 Gigabit  |
|  m7i.4xlarge    |  16  |  65536  |  Up to 12.5 Gigabit  |
|  m7i.8xlarge    |  32  |  131072 |  12.5 Gigabit        |
|  m7i.12xlarge   |  48  |  196608 |  18.75 Gigabit       |
|  m7i.16xlarge   |  64  |  262144 |  25 Gigabit          |
|  m7i.24xlarge   |  96  |  393216 |  37.5 Gigabit        |
|  m7i.metal-24xl |  96  |  393216 |  37.5 Gigabit        |
|  m7i.48xlarge   |  192 |  786432 |  50 Gigabit          |
|  m7i.metal-48xl |  192 |  786432 |  50 Gigabit          |
+-----------------+------+---------+----------------------+
```

The ratio stays at 4 GiB per vCPU from `large` to `48xlarge`. The two `metal` sizes have the
vCPU and memory of the size beside them because they are the same host, handed over whole. There
is no hypervisor and no other customer on it, which is what software that has to see the hardware
itself needs, such as a hypervisor of your own.

The price sheet of 16 October 2026 has three of these sizes, and they double exactly: `m7i.large`
0.16065 USD an hour, `m7i.xlarge` 0.3213, `m7i.2xlarge` 0.6426. Over a month of 730 hours that
is 117.27, 234.55 and 469.10 USD. **Two `large` cost exactly what one `xlarge` costs**, so the
choice between them is not about money. One larger machine runs one copy of the program with more
room; two smaller ones survive the loss of either, and let a group grow and shrink in smaller
steps. Lesson 4 is where that second property starts to pay.

## What the size does change: the network

The last column above says "Up to 12.5 Gigabit" for the four smallest sizes and a plain number
from `8xlarge` on. **"Up to" is a burst, and the baseline is far lower**:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types m7i.large m7i.xlarge m7i.4xlarge m7i.8xlarge --query "InstanceTypes[].[InstanceType,NetworkInfo.NetworkCards[0].BaselineBandwidthInGbps,NetworkInfo.NetworkCards[0].PeakBandwidthInGbps]" --output table
----------------------------------
|      DescribeInstanceTypes     |
+--------------+---------+-------+
|  m7i.4xlarge |  6.25   |  12.5 |
|  m7i.8xlarge |  12.5   |  12.5 |
|  m7i.large   |  0.781  |  12.5 |
|  m7i.xlarge  |  1.562  |  12.5 |
+--------------+---------+-------+
```

`m7i.large` is guaranteed 0.781 gigabits a second and may burst to 12.5 for a while, on a credit
system of its own that AWS does not publish in detail. The baseline doubles with the size, like
everything else, until it meets the peak at `8xlarge`. A service that streams files, or moves a
lot of data to a database, can be held back by the network on a small size long before its
processor is busy. That is a reason to step up a size, and no CPU graph will show it to you. EBS
bandwidth follows the same pattern, and lesson 3 comes back to it.

## Graviton, about a fifth cheaper

The `g` types are priced below their Intel counterparts of the same shape. From the same sheet,
per hour:

| shape | Intel | Graviton | difference |
|---|---|---|---|
| 2 vCPU, 8 GiB | `m7i.large` 0.16065 | `m7g.large` 0.1301 | 19.0% |
| 2 vCPU, 4 GiB | `c7i.large` 0.13755 | `c7g.large` 0.1111 | 19.2% |
| 2 vCPU, 16 GiB | `r7i.large` 0.21105 | `r7g.large` 0.1704 | 19.3% |

For one `m7g.large` that is 94.97 USD a month instead of 117.27, 22.30 saved per instance before
any difference in speed. Remember from the section on names that Graviton's two vCPU are two
cores where Intel's are one. **The saving is real only if the software runs on Arm**, which is the
question to answer first, and an `x86_64` image will not answer it for you.

## The burstable family

The `t` types (`t3` on Intel, `t3a` on AMD, `t4g` on Graviton) do not sell the whole vCPU. They
sell a **baseline**: a share of each vCPU the instance may use all the time, and **CPU credits**
that pay for anything above it. One credit is one vCPU at 100% for one minute. Below the baseline
the instance earns credits; above it, it spends them. AWS documents the numbers per size, and two
of them are on the sheet:

| type | vCPU | baseline per vCPU | credits earned per hour | most it can hold | price per hour |
|---|---|---|---|---|---|
| `t3.micro` | 2 | 10% | 12 | 288 | 0.0168 |
| `t3.medium` | 2 | 20% | 24 | 576 | 0.0672 |

The credits per hour are the baseline in minutes: 20% of two vCPU for sixty minutes is 24. The
most it can hold is a day's earnings. So a `t3.medium` that runs both vCPU at 50% spends 60
credits an hour and earns 24, losing 36; from a full balance of 576 it has 16 hours before the
credits are gone.

What happens then depends on the **credit mode**. In `standard` mode the instance is held to its
baseline, and a service that was busy at 50% has to fit its work into 20%. In `unlimited` mode it keeps
running at full speed, and the surplus is billed per vCPU-hour at a rate AWS publishes and the
sheet does not carry. AWS launches `t3`, `t3a` and `t4g` in `unlimited` mode unless the request
says otherwise.

This is the part moto does not model. It has the flag that says a type is burstable, and nothing
behind it:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types t3.micro t3.medium t4g.medium m7i.large --query "InstanceTypes[].[InstanceType,BurstablePerformanceSupported]" --output text
m7i.large	False
t3.medium	True
t3.micro	True
t4g.medium	True
ana@laptop:~/aws$ ID=$(aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type t3.medium --credit-specification CpuCredits=unlimited --query "Instances[0].InstanceId" --output text)
ana@laptop:~/aws$ aws ec2 describe-instance-credit-specifications --instance-ids "$ID"
{
    "InstanceCreditSpecifications": [
        {
            "InstanceId": "i-e9e4d8eb7983437bb",
            "CpuCredits": "standard"
        }
    ]
}
ana@laptop:~/aws$ aws ec2 modify-instance-credit-specification --instance-credit-specifications "InstanceId=$ID,CpuCredits=unlimited"

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

The instance was launched with `CpuCredits=unlimited`, and moto reports it as `standard`; asked to
change the mode, it fails with an error of its own rather than AWS's. moto runs no processor, so
it earns and spends no credits, and the `CPUCreditBalance` metric that AWS publishes for every
burstable instance does not exist here. **What this section says about credits was taken from
AWS's documentation and was not run.**

## Burstable or fixed

`t3.medium` is 2 vCPU and 4 GiB for 0.0672 USD an hour; `c7i.large` has the same two vCPU and
4 GiB for 0.13755. The burstable machine costs less than half because it is not promising you the
processor all day. **For a machine that idles, that is a bargain**: a staging server, a bastion
host, a small internal tool, anything averaging under its baseline. A service that sits above
20% all working day is either throttled in `standard` mode or quietly billing surplus in
`unlimited`. A fixed type would have been faster, for the same money or less. The test is the average CPU over a week against the baseline in the table, which, again,
comes from CloudWatch.
