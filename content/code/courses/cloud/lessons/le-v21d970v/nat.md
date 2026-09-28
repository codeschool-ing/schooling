---
title: "NAT: a way out that is not a way in"
version: 1
---

A database server, or the application in front of it, has no business being reachable from the
internet. It still needs to reach out: to download security updates, to fetch a package, to call a
payment provider's API. Giving it a public address and a route to the internet gateway solves the
second problem by reopening the first. **A NAT gateway is the way out that is not a way in.**

## How one works

The NAT gateway sits in a **public** subnet, with a public address of its own, and the private
subnet's route table sends everything outside the VPC to it:

| destination | target |
|---|---|
| `10.0.0.0/16` | `local` |
| `0.0.0.0/0` | the NAT gateway |

When a private instance, say `10.0.32.10`, opens a connection to a package mirror, the packet goes
to the NAT gateway. The gateway **rewrites the source** to its own public address, notes the
connection in a table, and sends the packet on through the internet gateway. The reply comes back
to the NAT gateway's address, the gateway finds the connection in its table, rewrites the
destination back to `10.0.32.10`, and delivers it.

A packet that arrives at the NAT gateway without a connection in the table, somebody on the internet
trying to open a connection inward, matches nothing and goes nowhere. That is the whole security
property, and it is the same one your home router gives every phone in the house: the conversation
has to start inside. It is **one-way by construction**, not because of a rule somebody could get
wrong.

## What it costs, worked in the open

A NAT gateway is billed in two ways at once: for every hour it exists, and for every gigabyte that
passes through it, in either direction. The public list:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | grep -E 'sa-east-1|NAT'
                                        sa-east-1    us-east-1
  NAT gateway, per hour                    0.0930       0.0450
  NAT gateway, per GB processed            0.0930       0.0450
ana@laptop:~/cloud$ python3 -c "print(round(730 * 0.0930, 2), round(100 * 0.0930, 2), round(730 * 0.0930 + 100 * 0.0930, 2))"
67.89 9.3 77.19
ana@laptop:~/cloud$ python3 -c "print(round(730 * 0.0450, 2), round(100 * 0.0450, 2), round(730 * 0.0450 + 100 * 0.0450, 2))"
32.85 4.5 37.35
```

One month is 730 hours in AWS's arithmetic. Say the private instances pull 100 GB of updates and
images through it in that month. In `sa-east-1` the hours are 730 × 0.0930 = 67.89 dollars and the
data 100 × 0.0930 = 9.30, **77.19 dollars for one NAT gateway for one month**; in `us-east-1` the
same month is 32.85 plus 4.50, 37.35. That is before the instances themselves, and before a second
gateway: a NAT gateway lives in one zone, so a layout in two zones usually runs one in each.

Two details change the size of the number. The processing charge applies to bytes coming in as
well as going out, so a fleet that downloads a lot pays it on every download, even though data
coming in from the internet is itself free on the sheet. And bytes that leave for the internet
pay the data transfer line as well as the processing, 0.15 dollars a GB for the first 10 TB in
`sa-east-1`.

**This is one of the classic surprises of lesson 10.** It is a bill for plumbing, it grows with
traffic nobody thinks of as traffic, and the worst case is a private fleet copying terabytes to the
provider's own storage service through the NAT gateway when a free path existed. The private-paths
section of this lesson is that path.

The figures are AWS's public list for `sa-east-1` and `us-east-1`, in dollars and before tax, at
the offer versions `prices.py` prints. They are a list, not a bill; there is no account here.
