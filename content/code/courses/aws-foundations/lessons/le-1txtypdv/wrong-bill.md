---
title: A bill that arrived wrong
version: 1
---

**A bill that arrives larger than expected is almost never a wrong price; it is a line nobody
expected to exist.** The machines are on everybody's list, and somebody already did the sum in the
section on paying for one machine. What arrives unannounced is the cost of things that are not
machines: something left running, traffic crossing a boundary, an address nobody is using. Each is
small per hour, and a month is 730 hours.

## The case

The shop's staging account, `shop-staging`, runs one `m7i.large` on demand, and the team expected
its September bill to be that instance, 117.27 dollars, from the table in the section on paying for
one machine. The bill arrived at more than twice that. This is a worked case: the four lines below
are a set of mistakes this course's network lessons teach you to avoid, priced from the
list, not an invoice anybody received. Its prices come from three offers:

```
ana@laptop:~/aws$ python3 price.py AmazonEC2 20260925174521 sa-east-1 SAE1-NatGateway-Hours SAE1-NatGateway-Bytes
AmazonEC2 20260925174521, published 2026-09-25, USD
SAE1-NatGateway-Hours
          0 to       Inf Hrs  0.0930
SAE1-NatGateway-Bytes
          0 to       Inf GB   0.0930
```

The NAT gateway is in the EC2 offer, which `terms.py` already downloaded into the same cache, so
`price.py` reads it without downloading again. A **NAT gateway** is what lets machines in a private
subnet reach the internet, and lesson 17 builds one; it costs 0.093 dollars for every hour it
exists and 0.093 for every gigabyte it passes, in the list of 25 September 2026.

```
ana@laptop:~/aws$ python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-PublicIPv4:InUseAddress SAE1-PublicIPv4:IdleAddress
AmazonVPC 20260917190528, published 2026-09-17, USD
SAE1-PublicIPv4:InUseAddress
          0 to       Inf Hrs  0.0050
SAE1-PublicIPv4:IdleAddress
          0 to       Inf Hrs  0.0050
```

**Every public IPv4 address costs 0.005 dollars an hour, attached to something or not**, in the
list of 17 September 2026. The two lines have the same price; what the name of the second one says
is that an address held and attached to nothing is still paid for.

```
ana@laptop:~/aws$ python3 price.py AWSDataTransfer 20260916132208 sa-east-1 SAE1-DataTransfer-Regional-Bytes
AWSDataTransfer 20260916132208, published 2026-09-16, USD
SAE1-DataTransfer-Regional-Bytes
          0 to       Inf GB   0.0100
```

The crossing between zones is lesson 1's line, 0.01 per gigabyte, charged on both sides.

## The four lines nobody expected

| usage type on the bill | what happened | quantity | dollars |
|---|---|---|---|
| `SAE1-NatGateway-Hours` | a NAT gateway made for a test in August and never deleted | 730 hours × 0.093 | 67.89 |
| `SAE1-NatGateway-Bytes` | the instance's software updates and logs, sent out through it | 200 GB × 0.093 | 18.60 |
| `SAE1-PublicIPv4:IdleAddress` | two addresses kept after the machines they belonged to were deleted | 2 × 730 hours × 0.005 | 7.30 |
| `SAE1-DataTransfer-Regional-Bytes` | the instance in `sa-east-1a` talking to a database in `sa-east-1b` | 800 GB × 0.02 | 16.00 |

Together they are **109.79 dollars**, and the bill is 117.27 + 109.79 = 227.06, before tax. Not one
of the four is a machine, and the largest is a gateway that carried almost nothing: the hours of a
NAT gateway cost more than its traffic until it passes 730 GB a month.

## Finding them

**Group the month by usage type, filtered to the account.** In Cost Explorer that is the query of
lesson 13 with `--group-by Type=DIMENSION,Key=USAGE_TYPE` and a filter on `LINKED_ACCOUNT`; in the
Cost and Usage Report it is a `GROUP BY` on the usage type column, which lesson 15 writes. A usage
type names the thing exactly, `NatGateway-Hours` rather than "EC2", and the region prefix says
where. Each line then has an owner to ask and a fix:

- the NAT gateway is deleted, or staging stops having one: lesson 19 reaches AWS services through
  VPC endpoints without it;
- the two addresses are released; an address is only worth keeping when something is attached to
  it;
- the instance and the database move into one zone, which for staging is a fair trade, since
  staging does not need to survive the loss of a zone (lesson 1's rule for chatty pairs).

**The bill that arrived wrong is the reason for the tags of lesson 13.** Grouped by `team`, these
four lines would have arrived under somebody's name. Untagged, they sit in `team$`, and the question
"whose is this" becomes an afternoon of reading usage types, which is the afternoon this section
just spent.
