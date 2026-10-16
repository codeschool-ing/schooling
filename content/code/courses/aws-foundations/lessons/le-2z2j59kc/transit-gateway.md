---
title: Transit Gateway, a hub with route tables of its own
version: 1
---

**A Transit Gateway is a regional router that VPCs, VPNs and Direct Connect links attach to, and it
routes between them.** Where peering is a set of pairs, a Transit Gateway is a hub: each network
attaches once, and the hub's own route tables decide which attachment may reach which. **It is
transitive by design**, which is the thing peering refuses to be. It is charged by the hour for
every attachment and by the gigabyte it processes.

The wrong picture is a Transit Gateway as a bigger peering connection. It is a router with state of
its own: **attachments, route tables, associations and propagations**, four words that are the whole
of this section.

## The hub

```
ana@laptop:~/aws$ tgw=$(aws ec2 create-transit-gateway --description shop-hub --options AmazonSideAsn=64512,DefaultRouteTableAssociation=enable,DefaultRouteTablePropagation=enable --tag-specifications 'ResourceType=transit-gateway,Tags=[{Key=Name,Value=shop-hub}]' --query TransitGateway.TransitGatewayId --output text)
ana@laptop:~/aws$ aws ec2 describe-transit-gateways --transit-gateway-ids $tgw --query "TransitGateways[0].[State,Options.AmazonSideAsn,Options.DefaultRouteTableAssociation,Options.DefaultRouteTablePropagation]" --output text
available	64512	enable	enable
```

The hub was created with **a default route table**, and the two options ask that every new
attachment be associated with it and propagate into it. `AmazonSideAsn` is the hub's number in BGP,
the protocol a VPN or Direct Connect link uses to exchange routes with it. Lesson 24 uses it.

## Attachments

**A VPC attachment places an interface of the hub in one subnet per zone of the VPC**, the same idea
as an interface endpoint in lesson 19. The shop attaches production through its three app subnets
and staging through one subnet of its own:

```
ana@laptop:~/aws$ apps=$(aws ec2 describe-subnets --filters Name=tag:tier,Values=app --query "Subnets[].SubnetId" --output text)
ana@laptop:~/aws$ aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $tgw --vpc-id $vpc --subnet-ids $apps --query "TransitGatewayVpcAttachment.[State,length(SubnetIds)]" --output text
available	3
ana@laptop:~/aws$ aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id $tgw --vpc-id $svpc --subnet-ids $ssub --query "TransitGatewayVpcAttachment.[State,length(SubnetIds)]" --output text
available	1
ana@laptop:~/aws$ aws ec2 describe-transit-gateway-attachments --filters Name=transit-gateway-id,Values=$tgw --query "TransitGatewayAttachments[].[TransitGatewayAttachmentId,ResourceType,ResourceId]" --output text
tgw-attach-cb9da2b6611dc8fa7	vpc	vpc-4d9b138dab1e13c0a
tgw-attach-6d31e9a35a4c177e1	vpc	vpc-17bcf95982f6b62d7
```

## Association and propagation

Two words, and they answer two different questions:

- **Association** decides which hub route table an attachment's traffic is looked up in. Each
  attachment is associated with exactly one.
- **Propagation** decides which hub route tables learn an attachment's range as a route. An
  attachment can propagate into several, or none.

With both defaults on, every attachment is associated with the default table and propagates its
VPC's range into it. So **every VPC reaches every other**: the hub is a full mesh in one table.

```
ana@laptop:~/aws$ rtb=$(aws ec2 describe-transit-gateways --transit-gateway-ids $tgw --query "TransitGateways[0].Options.AssociationDefaultRouteTableId" --output text)
ana@laptop:~/aws$ aws ec2 get-transit-gateway-route-table-associations --transit-gateway-route-table-id $rtb --query "Associations[].[ResourceId,State]" --output text
vpc-4d9b138dab1e13c0a	associated
vpc-17bcf95982f6b62d7	associated
ana@laptop:~/aws$ for a in $(aws ec2 describe-transit-gateway-attachments --filters Name=transit-gateway-id,Values=$tgw --query "TransitGatewayAttachments[].TransitGatewayAttachmentId" --output text); do aws ec2 enable-transit-gateway-route-table-propagation --transit-gateway-route-table-id $rtb --transit-gateway-attachment-id $a --query Propagation.State --output text; done
enabled
enabled
ana@laptop:~/aws$ aws ec2 search-transit-gateway-routes --transit-gateway-route-table-id $rtb --filters Name=type,Values=propagated --query Routes
[]
ana@laptop:~/aws$ for a in $(aws ec2 describe-transit-gateway-attachments --filters Name=transit-gateway-id,Values=$tgw --query "TransitGatewayAttachments[].[TransitGatewayAttachmentId,ResourceId]" --output text | tr "\t" ":"); do cidr=$(aws ec2 describe-vpcs --vpc-ids ${a#*:} --query "Vpcs[0].CidrBlock" --output text); aws ec2 create-transit-gateway-route --transit-gateway-route-table-id $rtb --destination-cidr-block $cidr --transit-gateway-attachment-id ${a%:*} --query "Route.[DestinationCidrBlock,Type,State]" --output text; done
10.20.0.0/16	static	active
10.30.0.0/16	static	active
```

moto associated both attachments by itself, as AWS does. **Propagation is where it stops short**. It
records nothing until propagation is enabled explicitly. Even then the search for propagated routes
comes back empty, where AWS would list `10.20.0.0/16` and `10.30.0.0/16` with the type `propagated`.
That answer was not run here. The shop writes the two routes as **static** routes instead, which
moto stores and which AWS accepts as well. A static route is what you write when a range must be
reached that no attachment propagates.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l20-hub\" aria-label=\"The Transit Gateway shop-hub in the middle, with two VPC attachments: shop-prod, 10.20.0.0/16, through its three app subnets, and shop-staging, 10.30.0.0/16, through one subnet. Below the hub, its default route table, with a route for 10.20.0.0/16 to the production attachment and one for 10.30.0.0/16 to the staging attachment. Association says which hub table an attachment's traffic is looked up in; propagation says which tables learn the attachment's range. Each VPC's own route table still needs a route pointing at the hub.\"><defs><marker id=\"l20-hub-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l20-hub-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"200.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shop-prod</text><text x=\"120.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.0.0/16</text><text x=\"120.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 app subnets</text><rect x=\"500.0\" y=\"40.0\" width=\"200.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shop-staging</text><text x=\"600.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.30.0.0/16</text><text x=\"600.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 subnet</text><rect x=\"290.0\" y=\"44.0\" width=\"140.0\" height=\"56.0\" rx=\"12\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shop-hub</text><text x=\"360.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Transit Gateway</text><path d=\"M222.0 72.0 L288.0 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l20-hub-af-ah-phosphor)\" marker-start=\"url(#l20-hub-af-ah-phosphor)\"></path><path d=\"M432.0 72.0 L498.0 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l20-hub-af-ah-phosphor)\" marker-start=\"url(#l20-hub-af-ah-phosphor)\"></path><text x=\"255.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">attachment</text><text x=\"465.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">attachment</text><path d=\"M360.0 102.0 L360.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-hub-af-ah-paper-dim)\"></path><rect x=\"200.0\" y=\"154.0\" width=\"320.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">hub route table (default)</text><text x=\"360.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.0.0/16  →  attach shop-prod</text><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.30.0.0/16  →  attach shop-staging</text><text x=\"120.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">association:</text><text x=\"120.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">which table an attachment's</text><text x=\"120.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">traffic is looked up in</text><text x=\"600.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">propagation:</text><text x=\"600.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">which tables learn</text><text x=\"600.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">an attachment's range</text><text x=\"360.0\" y=\"344.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">each VPC's own table still points the other range at the hub</text></svg>", "caption": "The hub routes between attachments, by tables of its own. The VPCs still have to send their packets to it."}
```

## The VPCs' own tables point at the hub

The hub routes between attachments, and the VPCs still have to send their packets to it. That is a
route in each VPC's table with the hub as target. Production's private tables had a route for
staging's range through the peering. **Replacing its target** moves that traffic onto the hub, and
the peering is then removed:

```
ana@laptop:~/aws$ for r in $rts; do aws ec2 replace-route --route-table-id $r --destination-cidr-block 10.30.0.0/16 --transit-gateway-id $tgw; done
ana@laptop:~/aws$ aws ec2 replace-route --route-table-id $srt --destination-cidr-block 10.20.0.0/16 --transit-gateway-id $tgw
ana@laptop:~/aws$ aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $pcx --query Return --output text
True
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId || NatGatewayId || TransitGatewayId]" --output text
10.20.0.0/16	local
0.0.0.0/0	nat-99abbf31f5912eafc
10.30.0.0/16	tgw-7c18a17f112a84b50
```

## More than one table: who may reach whom

The default table gives everybody a route to everybody. The shop's real need is narrower: **staging
must not reach production**, and both must reach a shared VPC of tools, a CI runner and a log
collector. That is two hub route tables. Production and staging are each associated with a table
that holds only the tools VPC's route. The tools VPC is associated with a table that holds both of
theirs. Each sees the hub, and the hub's tables decide that they cannot see each other. **This is
something peering cannot express at all**, since every peering is all or nothing between its pair.
The second table is one command, and moto creates it as AWS would:

```
ana@laptop:~/aws$ iso=$(aws ec2 create-transit-gateway-route-table --transit-gateway-id $tgw --tag-specifications 'ResourceType=transit-gateway-route-table,Tags=[{Key=Name,Value=isolated}]' --query TransitGatewayRouteTable.TransitGatewayRouteTableId --output text)
ana@laptop:~/aws$ aws ec2 describe-transit-gateway-route-tables --filters Name=transit-gateway-id,Values=$tgw --query "TransitGatewayRouteTables[].[TransitGatewayRouteTableId,DefaultAssociationRouteTable,Tags[?Key==\`Name\`]|[0].Value]" --output text
tgw-rtb-8d83589407cbbe367	True	None
tgw-rtb-4cf6ba861b4c25b4b	False	isolated
```

Moving an attachment onto it is `disassociate-transit-gateway-route-table` and then
`associate-transit-gateway-route-table`. With no tools VPC in the lab, the shop stops at the table.
What it would prevent is, as always here, read from the tables rather than seen.

## Sharing the hub with another account

A Transit Gateway belongs to one account. **AWS Resource Access Manager (RAM) shares it** with other
accounts of the organisation, which then attach their own VPCs to it:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --query Organization.FeatureSet --output text
ALL
ana@laptop:~/aws$ staging=$(aws organizations create-account --email aws+shop-staging@example.com --account-name shop-staging --query CreateAccountStatus.AccountId --output text); echo $staging
049133565432
ana@laptop:~/aws$ aws ram create-resource-share --name shop-hub --resource-arns $(aws ec2 describe-transit-gateways --transit-gateway-ids $tgw --query "TransitGateways[0].TransitGatewayArn" --output text) --principals $staging --query "resourceShare.[name,status,allowExternalPrincipals]" --output text
shop-hub	ACTIVE	True
ana@laptop:~/aws$ aws ram get-resource-share-associations --association-type PRINCIPAL --query "resourceShareAssociations[].[associatedEntity,status]" --output text
049133565432	ASSOCIATED
```

moto records the share and its association with the new account. On AWS, `shop-staging` would then
see `shop-hub` in its own `describe-transit-gateways` and create its attachment there. The hub's
owner would accept it, unless the hub accepts shared attachments by itself
(`AutoAcceptSharedAttachments`, `disable` by default). That half was not run here.
