---
title: A NAT gateway, and reading where a packet goes
version: 1
---

**A NAT gateway lets machines with only private addresses open connections to the internet, and lets
nothing from the internet open one to them.** It sits in a public subnet with a public address of
its own. A private machine's packet goes to it and leaves with the gateway's public address in place
of its own. The reply comes back the same way. The shop's application machines need exactly that.
They call a payment provider and download updates, and nobody outside should be able to call them.

The wrong picture is a NAT gateway as a firewall. **It is a translator with a one-way door.** It
blocks connections opened from outside because it has no way to know which private machine they are
for, not because it inspects anything. The filters are lesson 18.

## A public address, and the gateway

A NAT gateway's public address is an **Elastic IP**, an IPv4 address allocated to the account and
kept until it is released. Allocating one is a command of its own, and the NAT gateway is created
in `public-a` with it:

```
ana@laptop:~/aws$ eip=$(aws ec2 allocate-address --domain vpc --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=nat-a}]' --query AllocationId --output text)
ana@laptop:~/aws$ nat=$(aws ec2 create-nat-gateway --subnet-id $pa --allocation-id $eip --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=nat-a}]' --query NatGateway.NatGatewayId --output text)
ana@laptop:~/aws$ aws ec2 describe-nat-gateways --nat-gateway-ids $nat --query "NatGateways[0].[NatGatewayId,State,VpcId]" --output text
nat-e507e5fbc7de6b4a9	available	vpc-4d9b138dab1e13c0a
```

**A NAT gateway lives in one subnet, so in one zone.** AWS runs it redundantly inside that zone and
not beyond it, which is the whole question of the next section. Placing it in a public subnet is not
decoration. `public-a`'s table routes its own packets to the internet, and only that table has a way
out.

## The private route table

Zone a's private subnets get a table whose way out is the NAT gateway:

```
ana@laptop:~/aws$ priv=$(aws ec2 create-route-table --vpc-id $vpc --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=private-a}]' --query RouteTable.RouteTableId --output text)
ana@laptop:~/aws$ aws ec2 create-route --route-table-id $priv --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $nat
{
    "Return": true
}
ana@laptop:~/aws$ for s in app-a data-a; do aws ec2 associate-route-table --route-table-id $priv --subnet-id $(aws ec2 describe-subnets --filters Name=tag:Name,Values=$s --query "Subnets[0].SubnetId" --output text) --query AssociationState.State --output text; done
associated
associated
ana@laptop:~/aws$ aws ec2 create-route --route-table-id $priv --destination-cidr-block 0.0.0.0/0 --gateway-id $igw

aws: [ERROR]: An error occurred (RouteAlreadyExists) when calling the CreateRoute operation: The route identified by 0.0.0.0/0 already exists
```

`app-a` and `data-a` are associated with it, so a packet from either one for an address outside
the VPC goes to `nat-a`. A second route for the same destination is refused, as the last command
shows: **one destination, one route**, in moto as in AWS.

## The longest prefix wins

A packet's address can match several routes at once. `10.20.97.10` is inside `10.20.0.0/16` and
inside `0.0.0.0/0`, because everything is inside `0.0.0.0/0`. **The router takes the route with the
longest prefix, the most specific one**, and the order the routes were written in plays no part. To
see it with three routes, the table gets one more: the office's `192.168.0.0/16`, sent to a virtual
private gateway. That is the VPC's end of a VPN, which lesson 24 builds properly. Here it is only a
target.

```
ana@laptop:~/aws$ vgw=$(aws ec2 create-vpn-gateway --type ipsec.1 --query VpnGateway.VpnGatewayId --output text)
ana@laptop:~/aws$ aws ec2 attach-vpn-gateway --vpn-gateway-id $vgw --vpc-id $vpc --query VpcAttachment.State --output text
attached
ana@laptop:~/aws$ aws ec2 create-route --route-table-id $priv --destination-cidr-block 192.168.0.0/16 --gateway-id $vgw
{
    "Return": true
}
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids $priv --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId || NatGatewayId]" --output text
10.20.0.0/16	local
0.0.0.0/0	nat-e507e5fbc7de6b4a9
192.168.0.0/16	vgw-b9be566075fd466e2
```

Reading that table for three packets sent by a machine in `app-a`:

| packet for | routes that contain it | longest | goes to |
|---|---|---|---|
| `10.20.97.10`, the database in `data-a` | `10.20.0.0/16`, `0.0.0.0/0` | `/16` | `local` |
| `192.168.4.20`, a printer in the office | `192.168.0.0/16`, `0.0.0.0/0` | `/16` | the virtual private gateway |
| `198.51.100.7`, the payment provider | `0.0.0.0/0` | `/0` | `nat-a` |

The third packet takes a **second hop**. `nat-a` sits in `public-a`, so `public-a`'s table routes
the packet that leaves the gateway, and its `0.0.0.0/0` points at the internet gateway. Two tables,
read one after the other, are the whole path.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 430\" role=\"img\" data-fig=\"l17-packet-walk\" aria-label=\"Three packets from a machine in app-a, read against the route table private-a. The table holds four routes: 10.20.0.0/16 to local, 192.168.0.0/16 to the virtual private gateway, 0.0.0.0/0 to nat-a, and ::/0 to the egress-only internet gateway. The packet for 10.20.97.10 matches the /16 and the /0; the /16 is longer, so it stays local and reaches data-a. The packet for 192.168.4.20 matches 192.168.0.0/16 and the /0; the /16 wins and it goes to the virtual private gateway, towards the office. The packet for 198.51.100.7 matches only the /0, so it goes to nat-a in public-a, and there the public route table sends 0.0.0.0/0 to the internet gateway and out to the internet.\"><defs><marker id=\"l17-packet-walk-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17-packet-walk-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l17-packet-walk-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"46.0\" width=\"160.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a machine in app-a</text><text x=\"100.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.48.10</text><path d=\"M182.0 74.0 L236.0 74.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-packet-walk-af-ah-paper-dim)\"></path><rect x=\"240.0\" y=\"16.0\" width=\"300.0\" height=\"138.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">route table private-a</text><text x=\"262.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.20.0.0/16</text><text x=\"420.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">→</text><text x=\"446.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">local</text><text x=\"262.0\" y=\"83.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.168.0.0/16</text><text x=\"420.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">→</text><text x=\"446.0\" y=\"83.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vgw</text><text x=\"262.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.0.0.0/0</text><text x=\"420.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">→</text><text x=\"446.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">nat-a</text><text x=\"262.0\" y=\"129.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">::/0</text><text x=\"420.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">→</text><text x=\"446.0\" y=\"129.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">eigw</text><text x=\"630.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">read three times,</text><text x=\"630.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">once per packet</text><text x=\"85.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">packet for</text><rect x=\"20.0\" y=\"212.0\" width=\"130.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.20.97.10</text><path d=\"M152.0 230.0 L241.0 230.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-packet-walk-af-ah-phosphor)\"></path><text x=\"197.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">/16 beats /0</text><rect x=\"20.0\" y=\"292.0\" width=\"130.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.168.4.20</text><path d=\"M152.0 310.0 L241.0 310.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-packet-walk-af-ah-paper-dim)\"></path><text x=\"197.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/16 beats /0</text><rect x=\"20.0\" y=\"372.0\" width=\"130.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"390.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">198.51.100.7</text><path d=\"M152.0 390.0 L241.0 390.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-packet-walk-af-ah-amber)\"></path><text x=\"197.0\" y=\"378.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">only /0 matches</text><rect x=\"245.0\" y=\"212.0\" width=\"150.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">local: data-a</text><rect x=\"245.0\" y=\"292.0\" width=\"150.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">virtual private gw</text><path d=\"M397.0 310.0 L496.0 310.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-packet-walk-af-ah-paper-dim)\"></path><rect x=\"500.0\" y=\"292.0\" width=\"200.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the office (lesson 24)</text><rect x=\"245.0\" y=\"372.0\" width=\"150.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"320.0\" y=\"390.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nat-a in public-a</text><path d=\"M397.0 390.0 L496.0 390.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-packet-walk-af-ah-amber)\"></path><text x=\"446.0\" y=\"378.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">public: /0 → igw</text><rect x=\"500.0\" y=\"372.0\" width=\"70.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"390.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">igw</text><path d=\"M572.0 390.0 L606.0 390.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l17-packet-walk-af-ah-amber)\"></path><rect x=\"610.0\" y=\"372.0\" width=\"90.0\" height=\"36.0\" rx=\"16\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"390.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">internet</text></svg>", "caption": "The longest prefix that contains the address wins. The third packet is routed twice: by private-a to the NAT gateway, then by public-a to the internet gateway."}
```

## IPv6: the egress-only internet gateway

IPv6 needs no translation, since lesson 16's addresses are already public, so a NAT gateway has
nothing to do for it. What a private subnet needs is the one-way door on its own. **An egress-only
internet gateway lets connections out over IPv6 and none in**, and it costs nothing by the hour. The
route that uses it names `::/0`, IPv6's every-address:

```
ana@laptop:~/aws$ eigw=$(aws ec2 create-egress-only-internet-gateway --vpc-id $vpc --query EgressOnlyInternetGateway.EgressOnlyInternetGatewayId --output text)
ana@laptop:~/aws$ aws ec2 create-route --route-table-id $priv --destination-ipv6-cidr-block ::/0 --egress-only-internet-gateway-id $eigw
{
    "Return": true
}
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids $priv --query "RouteTables[0].Routes[].[DestinationCidrBlock || DestinationIpv6CidrBlock,GatewayId || NatGatewayId || EgressOnlyInternetGatewayId]" --output text
10.20.0.0/16	local
0.0.0.0/0	nat-e507e5fbc7de6b4a9
192.168.0.0/16	vgw-b9be566075fd466e2
::/0	eigw-6cc5c52ce541a0121
```

The shop's private subnets have no IPv6 addresses, so this route will carry nothing for now. It is
here so that the table reads the way a dual-stack one does.

## Nothing moved

**Every row of that table was read, not tested.** moto stores the routes and moves no packet, so the
three walks above are reasoning from the tables. AWS would follow them the same way only because the
rule is the same: of the routes that contain the address, the one with the longest prefix. On AWS,
VPC Reachability Analyzer answers "can this machine reach that one, and through what" from the same
configuration. VPC Flow Logs record what did move. Lesson 18 says more about both, and neither was
run here.
