---
title: Site-to-Site VPN, two tunnels over the internet
version: 1
---

**A Site-to-Site VPN joins a network you run to a VPC through encrypted tunnels across the public
internet.** Three objects make it: a **customer gateway**, which is AWS's record of your router; a
**virtual private gateway** (or a Transit Gateway), which is AWS's end, attached to the VPC; and the
**VPN connection** between them, which is always **two IPsec tunnels**. The wrong picture is one
tunnel, as an office's own VPN to a branch usually is. AWS puts its two ends of the tunnels on
different equipment and maintains them one at a time, so a design with one tunnel up is a design
that goes down on AWS's maintenance schedule.

## The office, and an empty AWS

The shop's office is the network `192.168.0.0/16` behind one router, whose public address is
`203.0.113.12`, and the router speaks **BGP**, the routing protocol networks use to tell each other
which addresses they can reach, as the private AS number `65000`. Restart moto in the first terminal
(Ctrl+C, then `moto_server -p 4567`) so this lesson starts from an empty AWS, and make the part of the
shop's VPC this lesson needs, a subnet and its route table:

```sh
vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)
subnet=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.10.0/24 \
  --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
rt=$(aws ec2 create-route-table --vpc-id "$vpc" --query RouteTable.RouteTableId --output text)
aws ec2 associate-route-table --route-table-id "$rt" --subnet-id "$subnet" > /dev/null
```

**Nothing on the office's side was run.** There is no router in this lab, so everything the router
does, negotiating the tunnels, speaking BGP, sending packets, is described from AWS's documentation.

## The customer gateway

```
ana@laptop:~/aws$ aws ec2 create-customer-gateway --type ipsec.1 --public-ip 203.0.113.12 --bgp-asn 65000 --device-name office-router
{
    "CustomerGateway": {
        "Tags": [],
        "CustomerGatewayId": "cgw-d87f294afcc3f525a",
        "State": "available",
        "Type": "ipsec.1",
        "IpAddress": "203.0.113.12",
        "BgpAsn": "65000"
    }
}
```

**A customer gateway is a description, not a device.** It tells AWS where the other end of the
tunnels will be and which AS number it will speak BGP with. Creating it reaches nothing, which is why
it is `available` at once in AWS as well as in moto.

```
ana@laptop:~/aws$ cgw=$(aws ec2 describe-customer-gateways --query "CustomerGateways[0].CustomerGatewayId" --output text)
```

## AWS's end: a virtual private gateway

The **virtual private gateway** is the VPC's door for VPN and for Direct Connect, and it has an AS
number of its own on the AWS side, `64512` here unless you choose another:

```
ana@laptop:~/aws$ aws ec2 create-vpn-gateway --type ipsec.1 --amazon-side-asn 64512 --query "VpnGateway.[VpnGatewayId,AmazonSideAsn,State]" --output text
vgw-20474c8c293a43205	64512	available
```

Then it is attached to the VPC, which is what makes it the VPC's:

```
ana@laptop:~/aws$ vgw=$(aws ec2 describe-vpn-gateways --query "VpnGateways[0].VpnGatewayId" --output text)
ana@laptop:~/aws$ aws ec2 attach-vpn-gateway --vpn-gateway-id $vgw --vpc-id $vpc
{
    "VpcAttachment": {
        "VpcId": "vpc-e1a208744d0ad63a7",
        "State": "attached"
    }
}
```

In AWS the attachment passes through `attaching` before it is `attached`; moto skips to the end. A
VPC takes one virtual private gateway at a time. **A Transit Gateway is the alternative end**, which
lesson 20 builds: the VPN attaches to the Transit Gateway instead, and every VPC attached to it
reaches the office through the one connection. That is the right end once there are more than a
couple of VPCs, and the section after next prices both.

## The connection, and what moto says about its tunnels

```
ana@laptop:~/aws$ aws ec2 create-vpn-connection --type ipsec.1 --customer-gateway-id $cgw --vpn-gateway-id $vgw --query "VpnConnection.[VpnConnectionId,State,Type]" --output text
vpn-d6e93da7bd7bbbfd9	available	ipsec.1
```

Keep its id, as with everything else here:

```
ana@laptop:~/aws$ vpn=$(aws ec2 describe-vpn-connections --query "VpnConnections[0].VpnConnectionId" --output text)
```

**The configuration for the router comes back with the connection**, as an XML document in
`CustomerGatewayConfiguration`: the addresses of both ends of each tunnel, the BGP numbers, the
encryption, and a pre-shared key per tunnel. The key is a secret, so this command keeps it off the
screen and prints only the lines that place the tunnels:

```
ana@laptop:~/aws$ aws ec2 describe-vpn-connections --vpn-connection-ids $vpn --query "VpnConnections[0].CustomerGatewayConfiguration" --output text | grep -E "ipsec_tunnel>|<ip_address>|<asn>"
          <ipsec_tunnel>
              <ip_address>12.1.2.3</ip_address>
              <ip_address>169.254.44.42</ip_address>
              <asn>65000</asn>
              <ip_address>52.2.144.13</ip_address>
              <ip_address>169.254.44.41</ip_address>
              <asn>7224</asn>
          </ipsec_tunnel>
          <ipsec_tunnel>
              <ip_address>12.1.2.3</ip_address>
              <ip_address>169.254.44.42</ip_address>
              <asn>65000</asn>
              <ip_address>52.2.144.13</ip_address>
              <ip_address>169.254.44.41</ip_address>
              <asn>7224</asn>
          </ipsec_tunnel>
```

**Read that as moto's document, not as a configuration.** It has the shape AWS documents, two
`<ipsec_tunnel>` blocks, each with an outside address for both ends, a pair of addresses inside the
tunnel from `169.254.0.0/16`, and the BGP numbers. The values do not hold up:

- the customer's outside address is `12.1.2.3`, not the `203.0.113.12` the customer gateway was
  given;
- the AWS side's AS number is `7224`, not the `64512` this gateway was created with;
- the two tunnels are identical, outside address, inside addresses and all, where AWS gives each
  tunnel **its own outside address on its own equipment** and its own `/30` inside.

Against AWS this document is what a network engineer loads into the router, often through a file
AWS generates for the router's make; from moto it is a template to read and nothing to load. The
state AWS keeps about the tunnels is missing too:

```
ana@laptop:~/aws$ aws ec2 describe-vpn-connections --vpn-connection-ids $vpn --query "VpnConnections[0].[Options.StaticRoutesOnly,VgwTelemetry]"
[
    null,
    null
]
```

**`VgwTelemetry` is where AWS reports each tunnel**, one entry each, `UP` or `DOWN`, with the number of
routes it learnt; it is the first thing to look at when the office cannot reach the VPC. moto returns
nothing there, because there are no tunnels behind its answer.

## Static routes or BGP

The VPC and the office have to learn each other's addresses, and there are two ways.

**Static routing** writes them down: the VPN connection is told that `192.168.0.0/16` is behind it,
and the route table is told the same. It works with any router, and every change is made by hand at
both ends. It also fails over less well: without BGP, the router has to notice a dead tunnel with
checks of its own before it moves to the other one.

**BGP** lets the two ends tell each other: the office router announces `192.168.0.0/16` over each
tunnel, AWS announces `10.20.0.0/16`, and when a tunnel goes down the routes learnt over it are
withdrawn and the other tunnel carries the traffic. **Use BGP when the router can speak it**, which is
why the customer gateway carries an AS number at all.

**Route propagation** is the half that touches the VPC: a route table with propagation on from the
virtual private gateway receives whatever routes the gateway has learnt, and keeps them up to date by
itself. moto 5.2.3 cannot do it:

```
ana@laptop:~/aws$ aws ec2 enable-vgw-route-propagation --route-table-id $rt --gateway-id $vgw

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

moto answered `500`, and so did its `create-vpn-connection-route`, the static route on the
connection's side. Against AWS, `enable-vgw-route-propagation` succeeds and prints nothing, and the
route table's `PropagatingVgws` names the gateway from then on. What moto does store is a static route in the route table, the
same route a static design would write by hand:

```
ana@laptop:~/aws$ aws ec2 create-route --route-table-id $rt --destination-cidr-block 192.168.0.0/16 --gateway-id $vgw --query Return --output text
True
```

```
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids $rt --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId,Origin]" --output text
10.20.0.0/16	local	CreateRouteTable
192.168.0.0/16	vgw-20474c8c293a43205	CreateRoute
```

Lesson 17 reads a route table line by line. **`CreateRoute` in the last column is how a static route
says who wrote it**; a propagated one says `EnableVgwRoutePropagation`. The local route, `10.20.0.0/16`,
is what the VPC knows about itself.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l24-tunnels\" aria-label=\"A Site-to-Site VPN. On the left, the office, 192.168.0.0/16, with its router at the public address 203.0.113.12, BGP AS 65000. In the middle, the internet. On the right, the region sa-east-1, where AWS runs two tunnel endpoints on separate equipment, and behind them the virtual private gateway, AS 64512, attached to the VPC 10.20.0.0/16. Two tunnels join the router to the two endpoints, each with its own BGP session. When AWS maintains one endpoint, the routes learnt over that tunnel are withdrawn and the other tunnel carries the traffic.\"><rect x=\"20.0\" y=\"50.0\" width=\"170.0\" height=\"220.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the office</text><text x=\"105.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.0.0/16</text><rect x=\"45.0\" y=\"130.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">router</text><text x=\"105.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.12</text><text x=\"105.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">AS 65000</text><rect x=\"240.0\" y=\"120.0\" width=\"120.0\" height=\"80.0\" rx=\"36\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the internet</text><rect x=\"410.0\" y=\"30.0\" width=\"290.0\" height=\"260.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"424.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"430.0\" y=\"73.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">tunnel endpoint 1</text><text x=\"490.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">separate equipment</text><rect x=\"430.0\" y=\"203.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">tunnel endpoint 2</text><text x=\"490.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">separate equipment</text><rect x=\"580.0\" y=\"100.0\" width=\"110.0\" height=\"120.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"635.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">virtual</text><text x=\"635.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">private gateway</text><text x=\"635.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AS 64512</text><text x=\"635.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">attached to</text><text x=\"635.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">10.20.0.0/16</text><path d=\"M552.0 95.0 L578.0 130.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M552.0 225.0 L578.0 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M167.0 150.0 L260.0 138.0\" stroke=\"var(--amber)\" stroke-width=\"2.0\" fill=\"none\"></path><path d=\"M340.0 132.0 L428.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"2.0\" fill=\"none\"></path><path d=\"M167.0 170.0 L260.0 182.0\" stroke=\"var(--amber)\" stroke-width=\"2.0\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M340.0 188.0 L428.0 222.0\" stroke=\"var(--amber)\" stroke-width=\"2.0\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"212.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">tunnel 1</text><text x=\"212.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">tunnel 2</text><text x=\"360.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">two tunnels, two BGP sessions: maintenance on one end moves the routes to the other</text></svg>", "caption": "A VPN connection is always two tunnels. A design that keeps one of them down loses the office during AWS's maintenance."}
```
