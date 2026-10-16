---
title: VPC peering, one pair at a time
version: 1
---

**A peering connection joins exactly two VPCs, so that each can route to the other's range as if
it were a neighbour.** Nothing sits in the middle: there is no gateway to size, no hourly charge and
no single point to fail. The price of that simplicity is three rules, and each of them catches
somebody. **The two ranges may not overlap, both sides need routes, and nothing passes through.**

The wrong picture is a peering connection as a cable between two networks that then become one. They
do not become one. A peering is a pair, and **it is not transitive**. If production is peered with
staging and with the disaster-recovery copy, staging still cannot reach the copy through production.
Each pair that must talk needs its own peering.

## Starting from lesson 17

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS, and rebuild lessons 16 and 17. Lesson 18's filters and lesson 19's endpoints play no
part in routing, so they are left out:

```
ana@laptop:~/aws$ bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh > /dev/null
ana@laptop:~/aws$ vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)
ana@laptop:~/aws$ rts=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a,private-b,private-c --query "RouteTables[].RouteTableId" --output text)
ana@laptop:~/aws$ svpc=$(aws ec2 create-vpc --cidr-block 10.30.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop-staging},{Key=env,Value=staging}]' --query Vpc.VpcId --output text)
ana@laptop:~/aws$ ssub=$(aws ec2 create-subnet --vpc-id $svpc --cidr-block 10.30.48.0/20 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
ana@laptop:~/aws$ echo $vpc $svpc
vpc-4d9b138dab1e13c0a vpc-17bcf95982f6b62d7
```

The other side is staging's VPC, `10.30.0.0/16`. **On AWS it lives in the `shop-staging` account**.
The lab puts both VPCs in moto's default account, which changes the commands by one option and the
reasoning not at all. A peering across accounts names the other account with `--peer-owner-id`, and
the other account accepts it with its own credentials. That variant was not run here.

## Overlapping ranges

Lesson 16 promised this. A copy of production's range, made the way somebody would make a quick
test VPC by copying a command, is asked to peer with production:

```
ana@laptop:~/aws$ copy=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)
ana@laptop:~/aws$ bad=$(aws ec2 create-vpc-peering-connection --vpc-id $vpc --peer-vpc-id $copy --query VpcPeeringConnection.VpcPeeringConnectionId --output text)
ana@laptop:~/aws$ aws ec2 describe-vpc-peering-connections --vpc-peering-connection-ids $bad --query "VpcPeeringConnections[0].[Status.Code,RequesterVpcInfo.CidrBlock,AccepterVpcInfo.CidrBlock]" --output text
pending-acceptance	10.20.0.0/16	10.20.0.0/16
ana@laptop:~/aws$ aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $bad --query Return && aws ec2 delete-vpc --vpc-id $copy
true
```

**moto accepted the request**, and its state says it is on its way. AWS refuses a peering between
VPCs whose ranges overlap, and no other answer could make sense. An address in `10.20.0.0/16` would
be in both, and no route table could say which one a packet is for. That refusal was not run here,
and the copy is deleted. This is why lesson 16 chose every range against every other network the
shop has. It is also why six default VPCs, all `172.31.0.0/16`, can never be peered with each other.

## Request, accept, and the routes on both sides

```
ana@laptop:~/aws$ pcx=$(aws ec2 create-vpc-peering-connection --vpc-id $vpc --peer-vpc-id $svpc --tag-specifications 'ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=prod-staging}]' --query VpcPeeringConnection.VpcPeeringConnectionId --output text)
ana@laptop:~/aws$ aws ec2 describe-vpc-peering-connections --vpc-peering-connection-ids $pcx --query "VpcPeeringConnections[0].Status.Code" --output text
pending-acceptance
ana@laptop:~/aws$ aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $pcx --query VpcPeeringConnection.Status.Code --output text
active
ana@laptop:~/aws$ for r in $rts; do aws ec2 create-route --route-table-id $r --destination-cidr-block 10.30.0.0/16 --vpc-peering-connection-id $pcx --query Return --output text; done
True
True
True
ana@laptop:~/aws$ srt=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$svpc --query "RouteTables[0].RouteTableId" --output text)
ana@laptop:~/aws$ aws ec2 create-route --route-table-id $srt --destination-cidr-block 10.20.0.0/16 --vpc-peering-connection-id $pcx --query Return --output text
True
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId || NatGatewayId || VpcPeeringConnectionId]" --output text
10.20.0.0/16	local
0.0.0.0/0	nat-99abbf31f5912eafc
10.30.0.0/16	pcx-d070c3104627acba3
```

**A peering is requested by one side and accepted by the other**, which matters across accounts:
the owner of each VPC agrees. Once it is `active`, nothing has changed yet for any packet, because
no table names it. The last commands of the transcript give production's three private tables a
route for staging's range, and staging's main table one for production's.

The longest-prefix rule of lesson 17 does the rest. A packet from `app-a` for `10.30.48.10` matches
`10.30.0.0/16` and `0.0.0.0/0`, and the `/16` sends it to the peering. **Forgetting one side is the
classic fault**: the packet arrives, and the reply has no route home. Security groups on both sides
still apply. Lesson 18's groups named each other, and a group can also refer to a group in a peered
VPC of the same region.

## Across regions

The shop keeps a disaster-recovery copy in Virginia, `10.40.0.0/16` in `us-east-1`. A peering can
cross regions. The request names the other region, and the acceptance is made there:

```
ana@laptop:~/aws$ dr=$(aws ec2 create-vpc --region us-east-1 --cidr-block 10.40.0.0/16 --query Vpc.VpcId --output text)
ana@laptop:~/aws$ xpcx=$(aws ec2 create-vpc-peering-connection --vpc-id $vpc --peer-vpc-id $dr --peer-region us-east-1 --query VpcPeeringConnection.VpcPeeringConnectionId --output text)
ana@laptop:~/aws$ aws ec2 describe-vpc-peering-connections --region us-east-1 --vpc-peering-connection-ids $xpcx --query "VpcPeeringConnections[0].[Status.Code,RequesterVpcInfo.Region,AccepterVpcInfo.Region]" --output text
pending-acceptance	sa-east-1	us-east-1
ana@laptop:~/aws$ aws ec2 accept-vpc-peering-connection --region us-east-1 --vpc-peering-connection-id $xpcx --query VpcPeeringConnection.Status.Code --output text
active
```

The traffic between the two is priced as **traffic between regions**, the 0.138 a gigabyte out of
São Paulo that lesson 1 read, and 0.02 in the other direction.

## Not transitive

Production is now peered with staging and with Virginia. Staging's table could be given a route for
`10.40.0.0/16` pointing at the production peering, and the packet would still be dropped. **A
peering carries only traffic between its own two VPCs**, never traffic on its way to a third. The
figure is the whole rule.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l20-not-transitive\" aria-label=\"Three VPCs. At the top, shop-prod, 10.20.0.0/16 in sa-east-1. At the bottom left, shop-staging, 10.30.0.0/16 in sa-east-1; at the bottom right, the disaster-recovery copy, 10.40.0.0/16 in us-east-1. Production is peered with staging and, across regions, with the copy. Between staging and the copy there is no peering, and a packet from one to the other cannot pass through production: a peering carries only traffic between its own two VPCs.\"><rect x=\"260.0\" y=\"30.0\" width=\"200.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shop-prod</text><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.0.0/16</text><text x=\"360.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"40.0\" y=\"210.0\" width=\"200.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shop-staging</text><text x=\"140.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.30.0.0/16</text><text x=\"140.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"480.0\" y=\"210.0\" width=\"200.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">dr copy</text><text x=\"580.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.40.0.0/16</text><text x=\"580.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">us-east-1</text><path d=\"M280.0 96.0 L160.0 208.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"168.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">peering</text><path d=\"M440.0 96.0 L560.0 208.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"552.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">peering, across regions</text><path d=\"M242.0 242.0 L478.0 242.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 5\"></path><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">no path</text><text x=\"360.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">not through production either</text><text x=\"360.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">each pair that must talk needs a peering of its own</text></svg>", "caption": "A peering is a pair. Two of them that share a VPC do not make a path between the other two."}
```

moto carries no packet, so this, like every path in these lessons, is read from the configuration
and AWS's documented behaviour rather than seen.
