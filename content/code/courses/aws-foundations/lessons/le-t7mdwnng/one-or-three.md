---
title: One NAT gateway per zone, or one for all, and what each costs
version: 1
---

**A NAT gateway belongs to one zone, so the shop chooses between losing a zone's way out with the
zone, and paying for three.** With one gateway in `public-a`, the private subnets of zones b and c
send their internet traffic across a zone boundary to reach it, and when zone a fails they lose the
internet with it, although their own zones are fine. With a gateway in every zone, each zone's
private table points at its own, and a failure stays where it happened. The rest of this section
puts prices on both.

## The prices

A NAT gateway is billed by the hour it exists and by the gigabyte it processes, and those two lines
are in the **EC2 offer** rather than in the VPC one. That offer prices every machine type in every
combination, so it is large: `price.py` downloads it once, and the `ls` at the end shows what it
keeps.

```
ana@laptop:~/aws$ python3 price.py AmazonEC2 20260925174521 sa-east-1 SAE1-NatGateway-Hours SAE1-NatGateway-Bytes SAE1-RegionalNatGateway-Hours
AmazonEC2 20260925174521, published 2026-09-25, USD
SAE1-NatGateway-Hours
          0 to       Inf Hrs  0.0930
SAE1-NatGateway-Bytes
          0 to       Inf GB   0.0930
SAE1-RegionalNatGateway-Hours
          0 to       Inf Hrs  0.0930
ana@laptop:~/aws$ ls -sh ~/.cache/aws-prices | grep AmazonEC2
279M AmazonEC2-20260925174521-sa-east-1.json
```

These are the prices AWS published on **25 September 2026** for São Paulo, and the public address
comes from the VPC offer of **17 September 2026**:

```
ana@laptop:~/aws$ python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-PublicIPv4:InUseAddress
AmazonVPC 20260917190528, published 2026-09-17, USD
SAE1-PublicIPv4:InUseAddress
          0 to       Inf Hrs  0.0050
```

**0.093 dollars an hour, 0.093 dollars a gigabyte, and 0.005 an hour for the Elastic IP.** A month
is about 730 hours, which AWS's own examples use, so one NAT gateway with its address costs:

| | per month |
|---|---|
| the gateway, 730 × 0.093 | 67.89 |
| its Elastic IP, 730 × 0.005 | 3.65 |
| **one NAT gateway, before any traffic** | **71.54** |
| **three, one per zone** | **214.62** |

The gigabytes cost the same either way: 200 GB a month through NAT is 200 × 0.093 = **18.60
dollars**, whether one gateway carries them or three share them. **What changes with the number of
gateways is the hourly part, and the crossing.**

The third line, `SAE1-RegionalNatGateway-Hours`, is a newer kind of NAT gateway that AWS spreads
across the zones itself, at the same hourly price. moto 5.2.3 builds only the zonal kind, so this
lesson does too; read AWS's pages on the regional one before relying on it, because it changes the
trade below.

## What the shared gateway costs instead

One shared gateway saves two of them, **143.08 dollars a month**. What it adds is the crossing:
every gigabyte from zones b and c reaches `public-a` across a zone boundary, and lesson 1 measured
that at 0.01 a gigabyte **each way**, so 0.02 for a gigabyte that crosses. The break-even point is
143.08 / 0.02 ≈ **7,154 GB a month** crossing to the shared gateway. Below that, one gateway is
cheaper in money; above it, three are.

The shop sends about 200 GB a month to the internet from its private subnets, two thirds of it from
zones b and c. Sharing would cost 133 × 0.02 ≈ 2.67 dollars of crossing, to save 143.08 of
gateways. **On money alone the shared gateway wins by a wide margin.** What it costs is not on the
bill:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" data-fig=\"l17-nat-choice\" aria-label=\"Two ways to give the shop's private subnets a way out, drawn side by side across the three zones of sa-east-1. On the left, one NAT gateway per zone: app-a uses nat-a in public-a, app-b uses nat-b, app-c uses nat-c, and nothing crosses a zone. It costs 214.62 dollars a month before traffic, and losing zone a costs only zone a's way out. On the right, one shared NAT gateway, nat-a in public-a: app-b and app-c reach it across the zone boundaries, at 0.01 dollars per gigabyte each way. It costs 71.54 dollars a month plus the crossing, and losing zone a cuts zones b and c off from the internet too.\"><defs><marker id=\"l17-nat-choice-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17-nat-choice-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"195.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">one per zone</text><text x=\"195.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">214.62 a month</text><text x=\"535.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">one shared</text><text x=\"535.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">71.54 a month, plus 0.02 per GB crossing</text><rect x=\"30.0\" y=\"56.0\" width=\"330.0\" height=\"210.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><rect x=\"42.0\" y=\"70.0\" width=\"92.0\" height=\"184.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"88.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sa-east-1a</text><rect x=\"50.0\" y=\"96.0\" width=\"76.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"88.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-a</text><rect x=\"50.0\" y=\"196.0\" width=\"76.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"88.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">public-a</text><rect x=\"62.0\" y=\"218.0\" width=\"52.0\" height=\"18.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"88.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">nat-a</text><path d=\"M88.0 138.0 L88.0 192.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-nat-choice-af-ah-phosphor)\"></path><rect x=\"150.0\" y=\"70.0\" width=\"92.0\" height=\"184.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"196.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sa-east-1b</text><rect x=\"158.0\" y=\"96.0\" width=\"76.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"196.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-b</text><rect x=\"158.0\" y=\"196.0\" width=\"76.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"196.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">public-b</text><rect x=\"170.0\" y=\"218.0\" width=\"52.0\" height=\"18.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"196.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">nat-b</text><path d=\"M196.0 138.0 L196.0 192.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-nat-choice-af-ah-phosphor)\"></path><rect x=\"258.0\" y=\"70.0\" width=\"92.0\" height=\"184.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"304.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sa-east-1c</text><rect x=\"266.0\" y=\"96.0\" width=\"76.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"304.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-c</text><rect x=\"266.0\" y=\"196.0\" width=\"76.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"304.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">public-c</text><rect x=\"278.0\" y=\"218.0\" width=\"52.0\" height=\"18.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"304.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">nat-c</text><path d=\"M304.0 138.0 L304.0 192.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-nat-choice-af-ah-phosphor)\"></path><rect x=\"370.0\" y=\"56.0\" width=\"330.0\" height=\"210.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><rect x=\"382.0\" y=\"70.0\" width=\"92.0\" height=\"184.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sa-east-1a</text><rect x=\"390.0\" y=\"96.0\" width=\"76.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-a</text><rect x=\"390.0\" y=\"196.0\" width=\"76.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"428.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">public-a</text><rect x=\"394.0\" y=\"218.0\" width=\"52.0\" height=\"18.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">nat-a</text><path d=\"M420.0 138.0 L420.0 192.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-nat-choice-af-ah-phosphor)\"></path><rect x=\"490.0\" y=\"70.0\" width=\"92.0\" height=\"184.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"536.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sa-east-1b</text><rect x=\"498.0\" y=\"96.0\" width=\"76.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"536.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-b</text><rect x=\"498.0\" y=\"196.0\" width=\"76.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"536.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">public-b</text><rect x=\"598.0\" y=\"70.0\" width=\"92.0\" height=\"184.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"644.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sa-east-1c</text><rect x=\"606.0\" y=\"96.0\" width=\"76.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"644.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-c</text><rect x=\"606.0\" y=\"196.0\" width=\"76.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"644.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">public-c</text><path d=\"M536.0 138.0 L536.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M536.0 166.0 L490.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M644.0 138.0 L644.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M644.0 166.0 L598.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M598.0 166.0 L582.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M582.0 166.0 L536.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M490.0 166.0 L474.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M474.0 166.0 L460.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M460.0 166.0 L460.0 196.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M460.0 196.0 L460.0 227.0 L449.0 227.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-nat-choice-af-ah-amber)\"></path><text x=\"535.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">each crossing of a zone: 0.01 per GB each way</text><text x=\"195.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zone a lost: zone a's machines</text><text x=\"195.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lose the way out, and nobody else</text><text x=\"535.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">zone a lost: zones b and c lose</text><text x=\"535.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the way out as well</text><text x=\"360.0\" y=\"352.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">NAT prices: EC2 offer of 25 September 2026; 730 hours a month, with one Elastic IP each</text></svg>", "caption": "Three gateways cost 143.08 dollars a month more than one. One gateway turns a zone's failure into everybody's."}
```

- **A zone's failure becomes everybody's.** With the gateway in zone a, losing zone a stops the
  payment calls of the machines in b and c too, which were the reason the shop spread across zones.
- **The whole VPC's outbound traffic goes through one zone's capacity.** A gateway scales by itself
  within limits; one gateway still carries everything.

So the shop's choice is **one per zone in production and one shared in staging**, where a lost zone
costs an afternoon rather than sales. It is a decision about what an outage is worth, and the table
above is what the decision is weighed with. And if most of the 200 GB is traffic to S3, lesson 19
shows a way to send it there for nothing, which beats both.

## The lesson as a script

This is the production arrangement, every zone with its own gateway and table, as one script for
the next lessons to rebuild from. It looks subnets up by the names lesson 16 gave them:

```sh
cat > ~/aws/net/17-routes.sh <<'EOF'
# Lesson 17: the shop's routes. An internet gateway and one public route table
# for the three public subnets; in each zone, a NAT gateway and a private route
# table for that zone's app and data subnets. Run it after 16-vpc.sh.
subnet() { aws ec2 describe-subnets --filters Name=tag:Name,Values="$1" \
  --query "Subnets[0].SubnetId" --output text; }
tags() { echo "ResourceType=$1,Tags=[{Key=Name,Value=$2},{Key=project,Value=shop}]"; }
vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod \
  --query "Vpcs[0].VpcId" --output text)
igw=$(aws ec2 create-internet-gateway --tag-specifications "$(tags internet-gateway shop-prod)" \
  --query InternetGateway.InternetGatewayId --output text)
aws ec2 attach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc"
pub=$(aws ec2 create-route-table --vpc-id "$vpc" --tag-specifications "$(tags route-table public)" \
  --query RouteTable.RouteTableId --output text)
aws ec2 create-route --route-table-id "$pub" --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "$igw" > /dev/null
for z in a b c; do
  aws ec2 associate-route-table --route-table-id "$pub" --subnet-id "$(subnet public-$z)" > /dev/null
  eip=$(aws ec2 allocate-address --domain vpc --tag-specifications "$(tags elastic-ip nat-$z)" \
    --query AllocationId --output text)
  nat=$(aws ec2 create-nat-gateway --subnet-id "$(subnet public-$z)" --allocation-id "$eip" \
    --tag-specifications "$(tags natgateway nat-$z)" --query NatGateway.NatGatewayId --output text)
  priv=$(aws ec2 create-route-table --vpc-id "$vpc" --tag-specifications "$(tags route-table private-$z)" \
    --query RouteTable.RouteTableId --output text)
  aws ec2 create-route --route-table-id "$priv" --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id "$nat" > /dev/null
  for tier in app data; do
    aws ec2 associate-route-table --route-table-id "$priv" --subnet-id "$(subnet $tier-$z)" > /dev/null
  done
  echo "zone $z: $nat in public-$z, $priv for app-$z and data-$z"
done
EOF
```

It leaves out the office route and the egress-only gateway, which were there to be read rather than
used. To check it, restart moto once more and run lesson 16's script and this one, one after the
other; the last command lists the tables, how many subnets each serves, and where each sends
`0.0.0.0/0`:

```
ana@laptop:~/aws$ bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh
zone a: nat-99abbf31f5912eafc in public-a, rtb-2f5b255a96df86cac for app-a and data-a
zone b: nat-de872524ebf250fe5 in public-b, rtb-8a1f0f36b3db1cfbe for app-b and data-b
zone c: nat-c69478fa57a3113fe in public-c, rtb-2725b1ebad62ad346 for app-c and data-c
ana@laptop:~/aws$ vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[].[Tags[?Key==\`Name\`]|[0].Value, length(Associations), Routes[?DestinationCidrBlock==\`0.0.0.0/0\`]|[0].[GatewayId || NatGatewayId]|[0]]" --output text
None	1	None
public	3	igw-9b4b06c5ca27dc488
private-a	2	nat-99abbf31f5912eafc
private-b	2	nat-de872524ebf250fe5
private-c	2	nat-c69478fa57a3113fe
```

**The table with no name is the main one**: it serves no subnet now, and its single association
is the marker that makes it main. Every subnet has an explicit table, three public and six private,
and a subnet added later without one lands in the table with no way out.
