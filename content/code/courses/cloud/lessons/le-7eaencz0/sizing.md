---
title: "Sizing: reading the sheet and working out a month"
version: 1
---

Every price in this course comes from one sheet, `prices.py`, which reads the AWS public price list
at pinned offer versions. It is the list price for Linux, in US dollars and excluding tax, for
`sa-east-1` (São Paulo) and `us-east-1` (N. Virginia). It is not a bill, and nobody's account was
involved. The first seventeen lines hold everything this section needs:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | sed -n 1,17p
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

EC2, Linux, on demand, USD per hour
  t3.micro    2 vCPU   1 GiB              0.01680      0.01040
  t4g.small   2 vCPU   2 GiB              0.02680      0.01680
  t3.medium   2 vCPU   4 GiB              0.06720      0.04160
  m7i.large   2 vCPU   8 GiB              0.16065      0.10080
  m7g.large   2 vCPU   8 GiB              0.13010      0.08160
  c7i.large   2 vCPU   4 GiB              0.13755      0.08925
  m7i.xlarge  4 vCPU  16 GiB              0.32130      0.20160
```

**Read it down one column at a time.** Mixing the two regions in one comparison is the easiest way
to reach a wrong conclusion from right numbers; `m7i.large` is 0.10080 in N. Virginia and 0.16065
in São Paulo, and why regions differ belongs to lessons 9 and 10. This section stays in
`sa-east-1`.

## One step up doubles everything

`m7i.large` is 2 vCPU and 8 GiB for 0.16065 USD an hour. `m7i.xlarge` is 4 vCPU and 16 GiB for
0.32130. **Each step in size doubles the processor, the memory and the price together**, and the
pattern continues up the family: `2xlarge`, then `4xlarge`, each twice the one before.

The consequence is that within a family the price is linear in size. Two `m7i.large` cost exactly
what one `m7i.xlarge` costs, so the choice between one big machine and two small ones is never
about the hourly rate. It is about what happens when one machine fails, and about whether your
program can spread its work over two. The second half of this lesson is built on that choice.

## From an hourly price to a month

A price per hour means nothing to whoever signs off the budget. Multiply by the hours in a month,
and the question is which month: February has 672 hours and a 31-day month has 744. **Use 730**,
which is 8,760 hours in a year divided by twelve. It is the average month, it is the figure AWS's
own pricing calculator uses, and it makes an estimate for March and one for February the same
number, which is what an estimate is for.

Here is the arithmetic as a program, so nothing in it is done in anybody's head:

```schooling-example
{"language": "python", "file": "estimate.py", "parts": [{"code": "HOURS_PER_MONTH = 8760 / 12        # 365 days x 24 hours, over 12 months\n\n", "note": "The hours in an average month: a year of 8,760 hours shared over twelve. February has 672 and a 31-day month 744; 730 makes every month the same estimate."}, {"code": "# sa-east-1, Linux, on demand, USD per hour, from prices.py\nper_hour = {\n    \"m7i.large\": 0.16065,\n    \"m7i.xlarge\": 0.32130,\n    \"m7g.large\": 0.13010,\n}\n\n", "note": "Three lines of the sheet, copied as they are. Keeping the numbers in one place means a new price is one edit, and the comment says where each number came from."}, {"code": "for name, price in per_hour.items():\n    month = price * HOURS_PER_MONTH\n    print(f\"{name:10}  {price:.5f} x {HOURS_PER_MONTH:.0f} h = {month:6.2f} USD\")\n", "note": "Hourly price times hours. The f-string pads the name to ten characters and prints the price to five places, as the sheet does, and the month to two."}], "output": "m7i.large   0.16065 x 730 h = 117.27 USD\nm7i.xlarge  0.32130 x 730 h = 234.55 USD\nm7g.large   0.13010 x 730 h =  94.97 USD\n"}
```

So an `m7i.large` running all month in São Paulo is 117.27 USD at the list price, before its disk,
its network traffic and tax. The `xlarge` is 234.55, twice as much, as the doubling says.

## Arm against x86 at the same size

`m7g.large` and `m7i.large` have the same size on paper, 2 vCPU and 8 GiB. The Graviton one is
0.13010 an hour and the Intel one 0.16065: 0.03055 less, which is 19% of the Intel price, and
22.30 USD a month at 730 hours.

That saving holds on two conditions. Your software has to
run on Arm, which the previous section covered. And it has to run at least as fast on it, which
nobody can tell you without trying, because two vCPU are one core on the `m7i` and two on the
`m7g`. For some programs the Graviton machine is faster and the saving is larger than 19%; for
others it is slower, and the saving disappears into needing a bigger size.

## Right-sizing: measure, then choose

The common mistake is to choose by guessing, and to guess big "just in case". An `m7i.xlarge`
that sits at 10% CPU all month does the work of an `m7i.large` and costs 234.55 USD a month instead of 117.27. Nobody notices, because nothing is broken.

**Size from a measurement.** Run the program on a size you can afford, under a realistic load, for
long enough to see its busiest hour, and look at two numbers:

- memory is a hard limit. A machine that runs out of it swaps or has a process killed, so the
  peak has to fit with room to spare;
- processor is a soft limit. A machine short of it gets slow rather than broken, so the
  average matters as much as the peak.

Then pick the smallest type whose peak fits, and look again a month later, because the program and
its traffic both change. The family follows from the ratio you measured: a service using 6 GiB of
memory and half a core is asking for an `m`, and one using two full cores and 1 GiB is asking for
a `c`. Collecting those numbers over weeks is what the `observability` course sets up; here the
point is only that the type is chosen after the numbers, never before.
