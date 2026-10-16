---
title: Cutting the range into subnets, and the five addresses AWS keeps
version: 1
---

**A subnet is a slice of the VPC's range that lives in exactly one Availability Zone.** Every
address AWS hands out comes from a subnet, so every machine sits in one zone, the zone of its
subnet. The wrong picture is a subnet stretched across the region; there is no such thing. **A
design that survives losing a zone needs a subnet in every zone for every kind of machine**, which
is what lesson 1 promised this lesson would do.

## Three tiers, three zones, nine subnets

The shop runs three kinds of thing, and each gets a tier of its own:

| tier | what lives there | reached from |
|---|---|---|
| `public` | the load balancer (lesson 22) and the NAT gateways (lesson 17) | the internet |
| `app` | the shop's application machines | the load balancer only |
| `data` | the database | the application only |

Three tiers in three zones are nine subnets. Each gets a `/20`, 4,096 addresses, and a `/16` holds
sixteen of those, so nine leave **seven blocks spare** for a tier nobody has thought of yet. That
spare room matters more than it looks, because **a subnet's range cannot be changed after it is
created**: a subnet that runs out of addresses is replaced, and everything in it moves.

Working out where each `/20` starts is binary arithmetic, and it is the kind that goes wrong by one
bit in a hurry. Python's `ipaddress` module does it, and the plan becomes a program that anybody can
rerun and read. Make a directory for this lesson's files with `mkdir -p ~/aws/net` and save this as
`~/aws/net/plan.py`:

```schooling-example
{"language": "python", "file": "plan.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"The address plan of the shop's production VPC: one /20 per zone and tier.\n\n    python3 plan.py\n\nPrints one line per subnet, zone, tier, range and usable addresses, and a\nlast line, starting with #, saying how much of the VPC is left.\n\"\"\"\nimport ipaddress\n\n", "note": "Only Python's own library. `ipaddress` knows what a network is, which addresses it holds and how to cut it into smaller ones."}, {"code": "VPC = ipaddress.ip_network('10.20.0.0/16')\nZONES = ['sa-east-1a', 'sa-east-1b', 'sa-east-1c']\nTIERS = ['public', 'app', 'data']\n\n", "note": "The three decisions the plan rests on: the VPC's range, the zones of `sa-east-1` and the tiers. Changing one of these lines changes the whole plan, which is the point of writing it as a program."}, {"code": "blocks = VPC.subnets(new_prefix=20)\n", "note": "Every `/20` inside the `/16`, in order, starting at `10.20.0.0`. It hands them out one at a time, so no two subnets can be given the same block."}, {"code": "for tier in TIERS:\n    for zone in ZONES:\n        net = next(blocks)\n        print(f'{zone}  {tier:<6}  {str(net):<14}  {net.num_addresses - 5}')\n", "note": "One block for each tier in each zone, tier by tier, so the three subnets of a tier sit next to each other. `num_addresses` is 4,096 for a `/20`, and five of them belong to AWS, as the next part of this section measures."}, {"code": "spare = list(blocks)\nprint(f'# spare: {len(spare)} blocks of /20, {spare[0]} to {spare[-1]}')\n", "note": "Whatever the loop did not take. The line starts with `#` so that a program reading the plan can skip it."}]}
```

```
ana@laptop:~/aws$ python3 net/plan.py
sa-east-1a  public  10.20.0.0/20    4091
sa-east-1b  public  10.20.16.0/20   4091
sa-east-1c  public  10.20.32.0/20   4091
sa-east-1a  app     10.20.48.0/20   4091
sa-east-1b  app     10.20.64.0/20   4091
sa-east-1c  app     10.20.80.0/20   4091
sa-east-1a  data    10.20.96.0/20   4091
sa-east-1b  data    10.20.112.0/20  4091
sa-east-1c  data    10.20.128.0/20  4091
# spare: 7 blocks of /20, 10.20.144.0/20 to 10.20.240.0/20
```

**A tier's three subnets are neighbours**, so the plan reads at a glance: the public tier runs from
`10.20.0.0` to `10.20.47.255`, the data tier ends at `10.20.143.255`, and everything from
`10.20.144.0` to the top of the range is free.

## The five addresses AWS keeps

The last column says 4,091, not 4,096. **AWS reserves five addresses in every subnet**, whatever its
size, and no machine is ever given one of them:

- the first, the subnet's own network address;
- the second, the VPC router, which is where every packet leaving the subnet goes first;
- the third, kept for the DNS resolver AWS runs at the VPC range's base plus two;
- the fourth, kept for future use;
- the last, the broadcast address, which a VPC does not carry but still keeps.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l16-reserved\" aria-label=\"The sixteen addresses of a /28, 10.20.0.0 to 10.20.0.15, drawn as a row of cells. The first four and the last are reserved by AWS: .0 is the network address, .1 the VPC router, .2 the DNS resolver, .3 is kept for future use and .15 is the broadcast address. The eleven between .4 and .14 are the ones a machine can be given. A /20 keeps the same five, so 4,096 addresses leave 4,091.\"><text x=\"360.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">a /28, the smallest subnet AWS accepts: 16 addresses</text><rect x=\"25.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"45.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.0</text><path d=\"M45.0 138.0 L45.0 146.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"45.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">network</text><rect x=\"67.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"87.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.1</text><path d=\"M87.0 138.0 L87.0 168.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"87.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">router</text><rect x=\"109.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"129.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.2</text><path d=\"M129.0 138.0 L129.0 146.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"129.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">DNS</text><rect x=\"151.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"171.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.3</text><path d=\"M171.0 138.0 L171.0 168.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"171.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">future</text><rect x=\"193.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"213.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.4</text><rect x=\"235.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.5</text><rect x=\"277.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"297.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.6</text><rect x=\"319.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"339.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.7</text><rect x=\"361.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"381.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.8</text><rect x=\"403.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"423.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.9</text><rect x=\"445.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.10</text><rect x=\"487.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"507.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.11</text><rect x=\"529.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"549.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.12</text><rect x=\"571.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"591.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.13</text><rect x=\"613.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"633.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.14</text><rect x=\"655.0\" y=\"92.0\" width=\"40.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"675.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.15</text><path d=\"M675.0 138.0 L675.0 146.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"675.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">broadcast</text><path d=\"M194.0 86.0 L194.0 78.0 L652.0 78.0 L652.0 86.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"423.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">11 a machine can be given</text><text x=\"24.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.20.0.0/28</text><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">every subnet keeps the same five: a /24 leaves 251, a /20 leaves 4,091</text></svg>", "caption": "Five addresses of every subnet belong to AWS, whatever its size."}
```

The rule is a constant, so it costs a small subnet far more than a large one: **5 of 4,096 in a
`/20` is nothing, 5 of 16 in a `/28` is almost a third.** moto subtracts the same five, and two
subnets in the spare room show it, a `/24` and a `/20`:

```
ana@laptop:~/aws$ aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.20.240.0/24 --availability-zone sa-east-1a --query "Subnet.[CidrBlock,AvailableIpAddressCount]" --output text
10.20.240.0/24	251
ana@laptop:~/aws$ aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.20.224.0/20 --availability-zone sa-east-1a --query "Subnet.[CidrBlock,AvailableIpAddressCount]" --output text
10.20.224.0/20	4091
```

**251 and 4,091 are 256 − 5 and 4,096 − 5.** `AvailableIpAddressCount` falls by one with every
address something takes, so on AWS it is also the number to watch in a subnet that is filling up.

## What a subnet may not be

Three rules decide whether a subnet is accepted, and moto refuses the first two the way AWS does:

```
ana@laptop:~/aws$ aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.20.240.128/25 --availability-zone sa-east-1a

aws: [ERROR]: An error occurred (InvalidSubnet.Conflict) when calling the CreateSubnet operation: The CIDR '10.20.240.128/25' conflicts with another subnet
ana@laptop:~/aws$ aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.21.0.0/24 --availability-zone sa-east-1a

aws: [ERROR]: An error occurred (InvalidSubnet.Range) when calling the CreateSubnet operation: The CIDR '10.21.0.0/24' is invalid.
ana@laptop:~/aws$ aws ec2 create-subnet --vpc-id $vpc --cidr-block 10.20.250.0/29 --availability-zone sa-east-1a --query "Subnet.[CidrBlock,AvailableIpAddressCount]" --output text
10.20.250.0/29	3
ana@laptop:~/aws$ for s in $(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc --query "Subnets[].SubnetId" --output text); do aws ec2 delete-subnet --subnet-id $s; done
ana@laptop:~/aws$ aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc --query "length(Subnets)"
0
```

**Two subnets of one VPC never overlap**: `10.20.240.128/25` is the top half of the `/24` made a
moment ago, and it is refused as a conflict. **A subnet lies inside one of the VPC's ranges**:
`10.21.0.0/24` is outside `10.20.0.0/16`, and it is refused as invalid. The third rule is the size,
**between `/28` and `/16`**, and here moto is more lenient than AWS: it accepted the `/29` and gave
it three usable addresses. AWS refuses a subnet smaller than a `/28`; that refusal was not run here,
since moto does not make it.

The three test subnets have done their job. The last command of that transcript deleted all of them,
so the VPC is empty again for the plan.

## The plan, as a script

The nine subnets come from the plan itself, so nobody types a range. This script reads `plan.py`'s
lines and creates one subnet for each, named after its tier and zone (`public-a`, `app-b`,
`data-c`). It also creates the VPC when there is none called `shop-prod`, which is what lets
lessons 17 to 20 rebuild this lesson in one step on an empty moto. Write it with:

```sh
cat > ~/aws/net/16-vpc.sh <<'EOF'
# Lesson 16: the shop's production VPC and its nine subnets.
# On an empty moto it creates the VPC too; after the lesson's own
# create-vpc it finds that VPC by its name and adds the subnets.
vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod \
  --query "Vpcs[0].VpcId" --output text)
if [ "$vpc" = None ]; then
  vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop-prod},{Key=project,Value=shop},{Key=env,Value=prod}]' \
    --query Vpc.VpcId --output text)
fi
python3 ~/aws/net/plan.py | grep -v '^#' | while read -r zone tier cidr usable; do
  aws ec2 create-subnet --vpc-id "$vpc" --cidr-block "$cidr" --availability-zone "$zone" \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$tier-${zone: -1}},{Key=tier,Value=$tier},{Key=project,Value=shop}]" \
    --query "Subnet.[Tags[?Key=='Name']|[0].Value,CidrBlock,AvailabilityZoneId,AvailableIpAddressCount]" \
    --output text < /dev/null
done
EOF
```

`${zone: -1}` is the last letter of the zone's name. The `< /dev/null` keeps `aws` from reading
the plan's remaining lines as its own input, which would quietly end the loop after one subnet.
Then run it:

```
ana@laptop:~/aws$ bash net/16-vpc.sh
public-a	10.20.0.0/20	sae1-az1	4091
public-b	10.20.16.0/20	sae1-az2	4091
public-c	10.20.32.0/20	sae1-az3	4091
app-a	10.20.48.0/20	sae1-az1	4091
app-b	10.20.64.0/20	sae1-az2	4091
app-c	10.20.80.0/20	sae1-az3	4091
data-a	10.20.96.0/20	sae1-az1	4091
data-b	10.20.112.0/20	sae1-az2	4091
data-c	10.20.128.0/20	sae1-az3	4091
```

**The third column is the zone id**, `sae1-az1` to `sae1-az3`, and it is the one to quote when
another account has to place something in the same zone (lesson 1). The VPC now has the shape of
the shop's network. Whether any of it can reach the internet is a separate question, and the next
section shows that the answer, so far, is no.
