---
title: "Sizes and price: paying for what the task reserves"
version: 1
---

On EC2 you pay for the instance, and the tasks inside it are free riders until the instance is
full. **On Fargate the instance disappears from the bill too.** You pay for the vCPU and the memory the
task definition reserves, by the second, from the moment the image starts downloading until the
task stops. A task that uses a tenth of its quarter-vCPU pays for the quarter. A task that
is not running pays nothing at all.

## The sizes there are

The size is the task's `cpu` and `memory`, and Fargate offers fixed pairs rather than any
combination. This is AWS's table for Linux tasks:

| cpu | vCPU | memory allowed |
|---|---|---|
| 256 | 0.25 | 512 MiB, 1 GB, 2 GB |
| 512 | 0.5 | 1 to 4 GB, in steps of 1 GB |
| 1024 | 1 | 2 to 8 GB, in steps of 1 GB |
| 2048 | 2 | 4 to 16 GB, in steps of 1 GB |
| 4096 | 4 | 8 to 30 GB, in steps of 1 GB |
| 8192 | 8 | 16 to 60 GB, in steps of 4 GB |
| 16384 | 16 | 32 to 120 GB, in steps of 8 GB |

**The memory range rises with the CPU**, at between two and eight gigabytes per vCPU. A task that
wants a quarter of a vCPU and 4 GB, say a cache that holds a lot and computes little, is not on
the table, and has to buy 0.5 vCPU to get it. moto does not know the table:

```
ana@laptop:~/aws$ aws ecs register-task-definition --family odd-size --network-mode awsvpc --requires-compatibilities FARGATE --cpu 256 --memory 4096 --container-definitions "[{\"name\":\"web\",\"image\":\"nginx:1.29-alpine\",\"memory\":512}]" --query "taskDefinition.[family,cpu,memory]" --output text
odd-size	256	4096
```

AWS refuses that registration, because 4,096 MiB is not among the memories allowed with 256 CPU
units. It is one more case where a definition that works against moto has been checked for its
shape and not for its values.

## The price, from the sheet

The four Fargate lines of the price sheet of 16 October 2026, read out of AWS's price list as
lesson 1 does:

```
ana@laptop:~/aws$ python3 prices.py containers | sed -n 3,8p
Fargate
  vCPU, x86                                       0.0696  per hour
  memory, x86                                     0.0076  per GB-hour
  vCPU, Arm                                       0.0557  per hour
  memory, Arm                                    0.00612  per GB-hour
  ephemeral storage above 20 GB                 0.000211  per GB-hour
```

Two meters, one per vCPU-hour and one per GB-hour, and lower ones for Arm. Save the program below
as `~/aws/fargate_cost.py` and run it; it works the two meters through three cases:

```schooling-example
{"language": "python", "file": "fargate_cost.py", "parts": [{"code": "# fargate_cost.py: what Fargate tasks cost in sa-east-1, from the price sheet\nHOURS = 730\n\n", "note": "730 hours is the month the price sheet and every lesson of this course use."}, {"code": "PRICE = {                      # USD, 16 October 2026\n    \"x86\": {\"vcpu\": 0.0696, \"gb\": 0.0076},\n    \"arm\": {\"vcpu\": 0.0557, \"gb\": 0.00612},\n}\n\n", "note": "The four Fargate lines of `prices.py containers`, typed in. Fargate has two meters, one per vCPU-hour and one per GB-hour, and the Arm ones are lower."}, {"code": "def per_hour(arch, vcpu, gb):\n    p = PRICE[arch]\n    return vcpu * p[\"vcpu\"] + gb * p[\"gb\"]\n\n", "note": "A task's hourly price is its vCPUs times one meter plus its gigabytes times the other. Nothing else enters it below 20 GB of ephemeral storage."}, {"code": "for arch, vcpu, gb, tasks in [(\"x86\", 0.25, 0.5, 1), (\"x86\", 1, 2, 2), (\"arm\", 1, 2, 2)]:\n    hour = per_hour(arch, vcpu, gb)\n    month = hour * tasks * HOURS\n    print(f\"{tasks} x {vcpu:>4} vCPU {gb:>3} GB {arch}:  {hour:.5f}/h each,  {month:7.2f} USD a month\")\n", "note": "Three cases: the smallest task there is, then two tasks of 1 vCPU and 2 GB on each architecture, the shape of a small web service kept at two for availability."}]}
```

```
ana@laptop:~/aws$ python3 fargate_cost.py
1 x 0.25 vCPU 0.5 GB x86:  0.02120/h each,    15.48 USD a month
2 x    1 vCPU   2 GB x86:  0.08480/h each,   123.81 USD a month
2 x    1 vCPU   2 GB arm:  0.06794/h each,    99.19 USD a month
```

**The smallest task there is, a quarter-vCPU with 512
MiB, costs 0.0212 USD an hour**, 0.25 × 0.0696 plus 0.5 × 0.0076, and 15.48 USD for a month left
running. Two tasks of 1 vCPU and 2 GB, a small web service kept at two so that one can fail, cost
123.81 USD a month on x86 and 99.19 on Arm. The Arm figure is 20% lower for the same service,
which is why the definition in the last section asked for `ARM64`; the price of moving is an
image built for `arm64`, which lesson 10 builds and pushes.

## Against an instance

Lesson 8 put an `m7i.large` at 117.27 USD a month as a container instance. It has 2 vCPUs and 8
GB. The two x86 tasks above reserve 2 vCPUs and 4 GB between them, and cost 123.81. **Full, the
instance is cheaper and has twice the memory; the instance is almost never full.** An EC2 cluster
keeps spare room: for deployments, as lesson 8's figure showed, for the next task to be placed,
and for an instance being replaced. And an instance a third empty costs the same as one packed. Fargate charges nothing for room nobody uses, and nothing for the operating system, the
agent and the patching that an instance carries, which never appear on the price sheet at all.

The arithmetic flips back as the fleet grows and stays steady: at many tasks running all month,
the instance hours are cheaper, and Savings Plans, `aws-operations` lesson 22, cut both. Lesson 23
puts the same workload on EC2, Fargate and Lambda side by side.

Two smaller meters belong to a Fargate bill. **Ephemeral storage**: every task gets 20 GB of disk
at no charge, and can be given up to 200 GB. What is above 20 costs 0.000211 USD per GB-hour, so
50 GB on one task is 30 × 0.000211 × 730 = 4.62 USD a month. And **the minimum**: Fargate
bills a Linux task per second with a minimum of one minute, so a job of ten seconds pays for
sixty. That matters only to work started thousands of times a day, which is lesson 14's
territory.
