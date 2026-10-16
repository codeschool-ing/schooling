---
title: Direct Connect, a cable into AWS
version: 1
---

**Direct Connect is a physical link between your network and AWS's**, made in a building where both
have equipment. The traffic between the office and the VPC never crosses the public internet. The
wrong picture is a faster VPN. A VPN is a tunnel you can bring up in an afternoon over whatever
internet you have. Direct Connect is a port, a fibre and a contract, ordered over weeks. It buys a
path whose bandwidth and latency are the same at nine in the morning as at three in the night. Three
pieces make it: a **connection** at a **location**, one or more **virtual interfaces** on it, and
often a **Direct Connect gateway** to reach VPCs beyond one region.

## Locations, and the two kinds of connection

**A Direct Connect location is a colocation datacentre where AWS has routers**, not an AWS region.
The price list names two in São Paulo, `Equinix SP4` under the code `TNDB` and `Tivit` under
`TIVIT`. A connection made at either is homed to `sa-east-1`. The shop's own equipment, or its
telecom provider's, has to reach that building. The last metres inside it are a **cross-connect**, a
cable the building's operator lays between the two racks.

| | dedicated connection | hosted connection |
|---|---|---|
| ordered from | AWS | an AWS Direct Connect Partner |
| speeds | a whole port: 1, 10 or 100 Gbps | a share of the partner's port: 50 Mbps to 10 Gbps in this price list |
| what you receive | a **Letter of Authorization (LOA-CFA)** to hand to the building for the cross-connect | a connection the partner provisions, which you accept |
| for the shop | when it has a rack in that building | when it does not, which is the usual case for one office |

## What moto answers

```
ana@laptop:~/aws$ aws directconnect describe-locations

aws: [ERROR]: An error occurred (500) when calling the DescribeLocations operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**moto 5.2.3 cannot list locations**, so the code this lesson uses is the one the price list gave,
`TNDB`. moto would have accepted any string. A dedicated 1 Gbps connection:

```
ana@laptop:~/aws$ aws directconnect create-connection --location TNDB --bandwidth 1Gbps --connection-name shop-dx-1 --query "[connectionId,connectionState,location,bandwidth,awsDevice]" --output text
arn:aws:directconnect:sa-east-1:123456789012:dx-con/dx-moto-shop-dx-1-20261016134801	available	TNDB	1Gbps	mock_device
```

Three things in that line are moto's and not AWS's. **The state is `available` at once**, where AWS
starts a dedicated connection `requested` and keeps it there until you download the LOA. AWS moves
it to `available` only once the cross-connect is in and light is seen on the fibre, which takes days
to weeks. **The id is an ARN with a timestamp in it**, where AWS gives an id such as `dxcon-`
followed by a few characters. And `mock_device` is moto saying there is no device. Keep the id for
the next step:

```
ana@laptop:~/aws$ dx=$(aws directconnect describe-connections --query "connections[0].connectionId" --output text)
```

## Virtual interfaces: what travels on the cable

**A connection is a cable; a virtual interface (VIF) is a conversation on it**, a VLAN with a BGP
session of its own. One connection carries several. There are three kinds:

| VIF | reaches | the shop uses it for |
|---|---|---|
| private | one VPC, through its virtual private gateway, or several through a Direct Connect gateway | the office's servers talking to the database in `10.20.0.0/16` |
| transit | Transit Gateways, through a Direct Connect gateway | every VPC of every account, through lesson 20's Transit Gateway |
| public | AWS's public addresses, such as S3's, over the cable instead of the internet | backups to `shop-backups` without crossing the internet |

The virtual private gateway from the previous section is the same object a private VIF lands on, so
the VPC needs no second door. moto stops here:

```
ana@laptop:~/aws$ aws directconnect create-private-virtual-interface --connection-id $dx --new-private-virtual-interface virtualInterfaceName=shop-prod,vlan=101,asn=65000,virtualGatewayId=$vgw,addressFamily=ipv4

aws: [ERROR]: An error occurred (500) when calling the CreatePrivateVirtualInterface operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**moto 5.2.3 answers `500` to every virtual interface and every Direct Connect gateway**, so from here
the section is AWS's documented behaviour and none of it was run.

## The Direct Connect gateway

**A Direct Connect gateway is a global object that joins virtual interfaces to gateways in any
region.** Without one, a private VIF reaches one virtual private gateway in the connection's home
region. With one, the same VIF can reach virtual private gateways in several regions and accounts,
and a transit VIF can reach Transit Gateways. It routes between the VIFs and the VPCs, not between
two VPCs and not between two offices. Traffic from one VPC to another through a Direct Connect
gateway is refused by design, and joining VPCs is lesson 20's job.

## What the cable does not do

**Direct Connect is private, and it is not encrypted.** The traffic crosses a cable nobody else
shares, between equipment the shop and AWS control, and it is still clear text on that cable. There
are two answers, both documented by AWS and neither run here. **MACsec** is link encryption on
dedicated connections at 10 and 100 Gbps. The other is a **Site-to-Site VPN over the Direct
Connect**: the tunnels of the previous section, carried on a public or transit VIF instead of the
internet. For a shop sending payment data between the office and the VPC, one of the two belongs in
the design, whatever the cable's privacy suggests.
