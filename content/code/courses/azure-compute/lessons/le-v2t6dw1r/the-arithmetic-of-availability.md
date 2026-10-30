---
title: The arithmetic of availability
version: 1
---

A percentage close to a hundred reads as "almost never down", and a service level agreement reads
as a promise that the machines will be up. Both readings are off, and the arithmetic is what
corrects them. **99.9% of thirty days is forty-three minutes**, which is a lunchtime for a shop
that takes orders at lunch. And an SLA is a promise about money: what Microsoft credits back when
a percentage is missed, measured the way the agreement defines it.

## What Microsoft promises for a virtual machine

The percentages are in the *Service Level Agreement for Microsoft Online Services*, a document
Microsoft publishes as a download and revises often. The edition dated 1 October 2026, read on
2026-10-30, gives these for Virtual Machines and for the Standard load balancer in front of them:

| arrangement | uptime promised |
|---|---|
| one VM, Premium SSD for the OS disk and Premium SSD, Premium SSD v2 or Ultra Disk for every data disk | 99.9% |
| one VM, Standard SSD | 99.5% |
| one VM, Standard HDD | 95% |
| two or more VMs in the same availability set | 99.95% |
| two or more VMs across two or more zones of one region | 99.99% |
| a Standard load balancer serving two or more healthy VMs | 99.99% |

A machine with disks of different types gets the percentage of its weakest disk. The Basic load
balancer has no SLA at all.

**Read what counts as downtime before trusting a number.** For machines across zones, a minute is
down when there is no connectivity to any of them in the region, and a set is measured the same
way across its machines. One machine of two dead for a day is not downtime in the agreement's
sense, because the other one answered. The agreement also leaves out maintenance announced at
least five days ahead, and anything you started yourself, such as a restart or a scale operation.

What a missed percentage buys is a **service credit**, a share of that service's fees for the
period. For machines across zones it is 10% below 99.99%, 25% below 99% and 100% below 95%, and it
is paid only on a claim made within 60 days of the incident. So an SLA tells you what Microsoft
will pay for. How often your shop is unreachable is yours to work out.

## A percentage, in minutes

For a virtual machine the agreement measures over the 30 days up to and including the first day of
the incident, which is 30 × 24 × 60 = 43,200 minutes. The minutes a percentage allows are the rest:

downtime = 43,200 × (1 − availability)

At 99.95% that is 43,200 × 0.0005 = 21.6 minutes. Lesson 11 measured the same kind of promise over
a month of 730 hours instead, which gives slightly more, 21.9 minutes; the difference is the
period, and the agreement says which period it means. Each nine added divides the allowance by
ten.

## Two rules for putting parts together

A request to the shop crosses several parts, and the parts are arranged in only two ways.

**In series, every part must answer, so the availabilities multiply.** An order reaches the load
balancer and then one machine behind it. If the balancer is up 99.99% of the time and the machine
99.9%, both are up at the same moment 0.9999 × 0.999 = 0.99890 of the time, or 99.89%. **A chain is
always less available than its weakest link**, and every dependency added to it, a database, a
payment provider, a DNS name, makes the product smaller.

**In parallel, any one copy will do, so what multiplies is the chance of failing.** Two copies each
up 99.9% of the time are each down 0.001 of it. Both are down together 0.001 × 0.001 of the time,
if their failures have nothing to do with each other, and the pair is up for the rest:

availability of n copies = 1 − (1 − a)ⁿ = 1 − 0.001² = 0.999999

That is six nines from two machines of three, and it is too good, for a reason the formula hides
in its assumption. **It is only true if the two copies never fail for the same reason.** Two
machines on one host fail together; two in one rack, two in one datacentre, two running the same
bad release, the same. Fault domains and zones exist to make the assumption more nearly true, and
none of them makes it entirely true. The agreement does not assume it either: two machines in a set
are promised 99.95%, not 99.9999%.

## The program

Here is the arithmetic as a program, so the numbers below were computed rather than typed. Save it
as `availability.py`. It needs nothing beyond Python itself, and the `python3` that lesson 1
installed runs it:

```schooling-example
{"language": "python", "file": "availability.py", "parts": [{"code": "# availability.py\nPERIOD = 30 * 24 * 60  # minutes in the 30 days a VM's SLA is measured over\n\n\ndef downtime(availability):\n    return PERIOD * (1 - availability)\n\n\n", "note": "The period the agreement measures a virtual machine over, in minutes, and the minutes an availability leaves out of it. Availability is written as a fraction, `0.999`, so that the arithmetic below needs no division by a hundred."}, {"code": "def serial(*parts):\n    total = 1.0\n    for part in parts:\n        total *= part\n    return total\n\n\n", "note": "**In series, multiply.** Every part has to be up at the same moment."}, {"code": "def redundant(part, copies):\n    return 1 - (1 - part) ** copies\n\n\n", "note": "**In parallel, one minus the product of failures.** `1 - part` is the share of time one copy is down; raised to `copies`, all of them are down together, which is true only if they never fail for the same reason."}, {"code": "print('promise    minutes down in 30 days')\nfor promise in (0.95, 0.995, 0.999, 0.9995, 0.9999):\n    print(f'{promise:<9.2%}  {downtime(promise):8.2f}')\n\n", "note": "The conversion table, for the five percentages of the agreement's table. `:.2%` prints a fraction as a percentage with two decimals."}, {"code": "balancer = 0.9999\npaths = {\n    'one VM, Premium SSD': serial(balancer, 0.999),\n    'availability set': serial(balancer, 0.9995),\n    'two zones': serial(balancer, 0.9999),\n}\nprint()\nfor name, total in paths.items():\n    print(f'{name:<20} {total:.4%}  {downtime(total):6.2f} min')\n\n", "note": "The shop's order API in each arrangement: the Standard load balancer in series with what is behind it. The figures are the agreement's, read on 2026-10-30."}, {"code": "print()\nboth = redundant(0.999, 2)\nprint(f'two VMs that never fail together: {both:.4%}  {downtime(both):.2f} min')\n", "note": "The formula's answer for two machines of 99.9%, which no arrangement in one region is promised."}]}
```

Run it:

```
ana@laptop:~/azure$ python3 availability.py
promise    minutes down in 30 days
95.00%      2160.00
99.50%       216.00
99.90%        43.20
99.95%        21.60
99.99%         4.32

one VM, Premium SSD  99.8900%   47.52 min
availability set     99.9400%   25.92 min
two zones            99.9800%    8.64 min

two VMs that never fail together: 99.9999%  0.04 min
```

Three things to read off it. The table is the conversion to keep in your head: 43.2 minutes at
99.9%, 21.6 at 99.95%, 4.32 at 99.99%, and 36 hours at the 95% of a single machine on Standard HDD.
The three paths are what the promises add up to for the shop's order API once the balancer is
counted: 47.52 minutes for one machine, 25.92 for an availability set, 8.64 for two zones. And the
last line, two machines that never fail together at 0.04 minutes, is the number nobody is promised,
because no two machines in one region share nothing.
