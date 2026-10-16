---
title: Surviving a failure, and choosing by the price list
version: 1
---

**A road in from the datacentre is only as good as its second road.** One Direct Connect connection
is one port, one cross-connect, one building and one fibre route, and any of them can fail; the
shop's office then loses the VPC entirely, however fast the link was a minute before. The wrong
picture is that Direct Connect is "the reliable one" and the VPN the fallback for people who cannot
afford it. Each is a single path until it is doubled, and the price list decides which doubling the
shop can pay for.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l24-resilience\" aria-label=\"Two ways to double the road from the office to the VPC. The office router has a Direct Connect connection to the location Equinix SP4, code TNDB, and from there a private virtual interface to the virtual private gateway of the VPC in sa-east-1. Drawn dashed, the second road: either a second Direct Connect connection at the location Tivit, which survives a whole building going dark, or a Site-to-Site VPN over the internet, the cheaper backup. With BGP on both, AWS prefers the Direct Connect path while it is up.\"><defs><marker id=\"l24-resilience-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l24-resilience-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"110.0\" width=\"140.0\" height=\"110.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the office</text><text x=\"90.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">router</text><text x=\"90.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AS 65000</text><rect x=\"250.0\" y=\"40.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Equinix SP4</text><text x=\"330.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">location TNDB</text><rect x=\"250.0\" y=\"140.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Tivit</text><text x=\"330.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">location TIVIT</text><rect x=\"250.0\" y=\"250.0\" width=\"160.0\" height=\"50.0\" rx=\"24\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the internet</text><rect x=\"480.0\" y=\"30.0\" width=\"220.0\" height=\"280.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"494.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"520.0\" y=\"120.0\" width=\"150.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"595.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">virtual private</text><text x=\"595.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">gateway</text><text x=\"595.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">10.20.0.0/16</text><path d=\"M162.0 140.0 L246.0 80.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M412.0 75.0 L516.0 140.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\" marker-end=\"url(#l24-resilience-af-ah-phosphor)\"></path><text x=\"200.0\" y=\"96.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Direct Connect</text><text x=\"444.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">private VIF</text><path d=\"M162.0 170.0 L246.0 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M412.0 170.0 L516.0 168.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\" marker-end=\"url(#l24-resilience-af-ah-amber)\"></path><text x=\"205.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">or a second</text><path d=\"M162.0 200.0 L246.0 268.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M412.0 270.0 L516.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"2 3\" marker-end=\"url(#l24-resilience-af-ah-amber)\"></path><text x=\"195.0\" y=\"258.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">or a VPN</text><text x=\"360.0\" y=\"330.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">with BGP on both, AWS prefers Direct Connect while it is up</text></svg>", "caption": "One connection is one building and one fibre. The second road is either another building or the internet."}
```

## The models AWS documents

AWS describes three arrangements for Direct Connect, from its own resiliency guidance:

| model | what it is | what it survives |
|---|---|---|
| development and test | two connections at **one** location, on separate AWS devices | a device or a port failing |
| high resiliency | one connection at each of **two** locations | a whole building going dark |
| maximum resiliency | two connections at each of two locations, on separate devices | a building, and a device in the other one at the same time |

**A VPN is the cheap second road**, and AWS documents it as a backup to Direct Connect. With BGP on
both, the same office prefix announced over each, AWS prefers the Direct Connect path while it is up,
and the routes move to the VPN tunnels when it is not. The VPN is slower and crosses the internet,
which is acceptable for a few hours of degraded service and not as a permanent design.

moto records the second location as readily as the first, which is all it can show of a design meant
to survive a failure:

```
ana@laptop:~/aws$ aws directconnect create-connection --location TIVIT --bandwidth 1Gbps --connection-name shop-dx-2 --query "[connectionName,location,connectionState]" --output text
shop-dx-2	TIVIT	available
```

```
ana@laptop:~/aws$ aws directconnect describe-connections --query "connections[].[connectionName,location,bandwidth]" --output text
shop-dx-1	TNDB	1Gbps
shop-dx-2	TIVIT	1Gbps
```

**Nothing failed over, because nothing was carrying anything**: the behaviour above is AWS's, and
testing it means taking one path down in a real account and watching the BGP routes move.

## The prices

The VPN connection is in the `AmazonVPC` offer the `cloud` course pinned:

```
ana@laptop:~/aws$ python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-VPN-Usage-Hours:ipsec.1
AmazonVPC 20260917190528, published 2026-09-17, USD
SAE1-VPN-Usage-Hours:ipsec.1
          0 to       Inf Hrs  0.0500
```

If the VPN ends on a Transit Gateway instead, the attachment has an hour of its own and every
gigabyte through it is processed and billed. The usage type is shared by every kind of attachment,
so lesson 22's `ops.py` tells them apart:

```
ana@laptop:~/aws$ python3 ops.py AmazonVPC 20260917190528 sa-east-1 SAE1-TransitGateway-Hours SAE1-TransitGateway-Bytes
SAE1-TransitGateway-Hours
  TransitGatewayConcentratorVPN 0.09000 per hour
  TransitGatewayConnect      0.09000 per hour
  TransitGatewayDirectConnect 0.09000 per hour
  TransitGatewayPeering      0.09000 per hour
  TransitGatewayVPC          0.09000 per hour
  TransitGatewayVPN          0.09000 per hour
SAE1-TransitGateway-Bytes
  TransitGatewayConcentratorVPN 0.02000 per GigaBytes
  TransitGatewayDirectConnect 0.02000 per GigaBytes
  TransitGatewayVPC          0.02000 per GigaBytes
  TransitGatewayVPN          0.02000 per GigaBytes
```

Direct Connect has its own offer, with each location's code inside each usage type, so the lines
for Equinix SP4 carry `TNDB`:

```
ana@laptop:~/aws$ python3 price.py AWSDirectConnect 20260917204010 sa-east-1 SAE1-TNDB-PortUsage:1G SAE1-TNDB-PortUsage:10G SAE1-TNDB-HCPortUsage:1G SAE1-TNDB-DataXfer-Out:dc.3
AWSDirectConnect 20260917204010, published 2026-09-17, USD
SAE1-TNDB-PortUsage:1G
          0 to       Inf hours 0.3000
SAE1-TNDB-PortUsage:10G
          0 to       Inf hours 2.2500
SAE1-TNDB-HCPortUsage:1G
          0 to       Inf hours 0.3300
SAE1-TNDB-DataXfer-Out:dc.3
          0 to       Inf GB   0.1100
```

`dc.3` is the line for traffic leaving AWS over a private virtual interface. In the lists of **17
September 2026** for both offers, in dollars:

| | per hour | per GB leaving AWS |
|---|---|---|
| a VPN connection | 0.05 | the internet's, 0.15 for the first 10 TB, from lesson 1 |
| a Transit Gateway VPN attachment, on top | 0.09 | plus 0.02 processed |
| a dedicated 1 Gbps port at Equinix SP4 | 0.30 | 0.11 over a private VIF |
| a dedicated 10 Gbps port | 2.25 | 0.11 |
| a hosted 1 Gbps connection | 0.33 | 0.11 |

**Traffic into AWS is free on both roads**, as it is from the internet: the bill is for the hours and
for what leaves.

## The shop's month, both ways

The office pulls 2 TB a month out of the VPC: reports, backups restored, images for the catalogue.
A month is 730 hours.

- **VPN to the virtual private gateway**: 730 × 0.05 = 36.50 for the hours, 2,048 × 0.15 = 307.20
  for the bytes, so **343.70 dollars**.
- **A dedicated 1 Gbps Direct Connect port**: 730 × 0.30 = 219.00 for the port, 2,048 × 0.11 = 225.28
  for the bytes, so **444.28 dollars**, before the cross-connect and the circuit from the office to
  the building, which the building and the telecom provider bill and the price list does not carry.

**At 2 TB the VPN is cheaper; the bytes decide where that changes.** The port costs 182.50 a month
more than the VPN's hours, and each gigabyte over Direct Connect saves 0.04, so the two meet at
182.50 / 0.04 = **4,562.5 GB**, about 4.5 TB a month. Above that the cable is cheaper on the price
list alone, and it was already the steadier path.

That arithmetic is for one road. A high-resiliency design is two ports at two locations, 438.00 a
month in hours before a byte moves. The cheaper doubling, for an office of the shop's size, is the
one this section opened with: **one Direct Connect connection, with a VPN behind it**, for
219.00 + 36.50 = 255.50 a month in hours.
