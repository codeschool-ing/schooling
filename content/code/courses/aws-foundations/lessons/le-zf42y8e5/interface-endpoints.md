---
title: Interface endpoints, an address for a service inside your subnets
version: 1
---

**An interface endpoint puts a network interface with a private address into each subnet you choose,
and the service answers on it.** Every other AWS service that can be reached privately is reached
this way: STS, Systems Manager, the container registry, CloudWatch Logs and some two hundred more.
The technology underneath is **AWS PrivateLink**. The last section of this lesson uses it for a
service of the shop's own.

Where a gateway endpoint is a route, an interface endpoint is a place: **an interface in a subnet,
with a security group on it**, like a small machine that only forwards. It is charged by the hour
for each zone it sits in and by the gigabyte it carries, which a gateway endpoint is not.

## Private DNS, which makes it invisible to the application

The application keeps calling `sts.sa-east-1.amazonaws.com`, the name every SDK uses. **With private
DNS turned on, that name resolves inside the VPC to the endpoint's private addresses**, and outside
the VPC to the public ones as before. Nothing in the application's code or configuration changes.
The VPC's resolver gives a different answer to the same question. For that to work **the VPC needs
two attributes on**, `enableDnsSupport` and `enableDnsHostnames`. A VPC you create has the first and
not the second, as the first two commands show. The third switches the second on:

```
ana@laptop:~/aws$ aws ec2 describe-vpc-attribute --vpc-id $vpc --attribute enableDnsSupport --query EnableDnsSupport.Value
true
ana@laptop:~/aws$ aws ec2 describe-vpc-attribute --vpc-id $vpc --attribute enableDnsHostnames --query EnableDnsHostnames.Value
false
ana@laptop:~/aws$ aws ec2 modify-vpc-attribute --vpc-id $vpc --enable-dns-hostnames '{"Value":true}'
```

AWS offers STS through an endpoint in all three zones. Its `PrivateDnsName` is the name the endpoint
will take over:

```
ana@laptop:~/aws$ aws ec2 describe-vpc-endpoint-services --service-names com.amazonaws.sa-east-1.sts --query "ServiceDetails[0].[ServiceType[0].ServiceType,PrivateDnsName,AvailabilityZones]"
[
    "Interface",
    "sts.sa-east-1.amazonaws.com",
    [
        "sa-east-1a",
        "sa-east-1b",
        "sa-east-1c"
    ]
]
```

## Creating one for STS

The endpoint's interfaces need a security group of their own, which lets HTTPS in from the
application machines and nothing else. That is lesson 18's chain once more, one link longer:

```
ana@laptop:~/aws$ ep=$(aws ec2 create-security-group --vpc-id $vpc --group-name endpoints-sg --description "interface endpoints" --query GroupId --output text)
ana@laptop:~/aws$ app=$(aws ec2 describe-security-groups --filters Name=group-name,Values=app-sg --query "SecurityGroups[0].GroupId" --output text)
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id $ep --protocol tcp --port 443 --source-group $app --query "SecurityGroupRules[0].[FromPort,ReferencedGroupInfo.GroupId]" --output text
443	sg-19bff292e592ad5d8
ana@laptop:~/aws$ apps=$(aws ec2 describe-subnets --filters Name=tag:tier,Values=app --query "Subnets[].SubnetId" --output text)
ana@laptop:~/aws$ sts=$(aws ec2 create-vpc-endpoint --vpc-id $vpc --vpc-endpoint-type Interface --service-name com.amazonaws.sa-east-1.sts --subnet-ids $apps --security-group-ids $ep --private-dns-enabled --query VpcEndpoint.VpcEndpointId --output text)
ana@laptop:~/aws$ aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $sts --query "VpcEndpoints[0].[State,PrivateDnsEnabled,length(NetworkInterfaceIds),DnsEntries[0].DnsName]" --output text
available	True	3	vpce-76049ed7aeedc4428-0307bbc6.com.amazonaws.sa-east-1.sts
ana@laptop:~/aws$ aws ec2 describe-network-interfaces --network-interface-ids $(aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $sts --query "VpcEndpoints[0].NetworkInterfaceIds" --output text) --query "NetworkInterfaces[].AvailabilityZone" --output text
sa-east-1a	sa-east-1b	sa-east-1c
```

**One interface per subnet named, so three**, one in each zone, so that losing a zone loses only
that zone's interface. moto spells the endpoint's DNS name its own way. AWS's has the form
`vpce-…-….sts.sa-east-1.vpce.amazonaws.com`, and with private DNS turned on nobody needs to use it.

## What it costs

```
ana@laptop:~/aws$ python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-VpcEndpoint-Hours SAE1-VpcEndpoint-Bytes
AmazonVPC 20260917190528, published 2026-09-17, USD
SAE1-VpcEndpoint-Hours
          0 to       Inf Hrs  0.0210
SAE1-VpcEndpoint-Bytes
          0 to 1,048,576 GB   0.0100
  1,048,576 to 5,242,880 GB   0.0060
  5,242,880 to       Inf GB   0.0040
```

These are the prices of 17 September 2026. **0.021 dollars an hour for each zone the endpoint sits
in**, and 0.01 a gigabyte for the first petabyte of a month. For the STS endpoint in three zones:

| | per month |
|---|---|
| 3 zones × 730 hours × 0.021 | 45.99 |
| each gigabyte through it | 0.01 |
| the same gigabyte through a NAT gateway (lesson 17) | 0.093 |

So **an interface endpoint saves 0.083 a gigabyte against NAT and costs 45.99 a month to exist**.
The NAT gateways may stay anyway, because the application calls a payment provider. Then the
endpoint pays for itself above 45.99 / 0.083 ≈ **554 GB a month** to that one service. STS calls are
small, so for STS it would not on money alone. For a container registry pulling images all day, it
often does.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" data-fig=\"l19-three-ways\" aria-label=\"Three ways an application machine in the private subnet app-a reaches something outside the VPC shop-prod, 10.20.0.0/16. To S3, its packet matches the S3 prefix list in the route table and goes to the gateway endpoint: a route, and free. To STS, it goes to the interface endpoint, a network interface inside app-a itself: 0.021 dollars an hour per zone and 0.01 a gigabyte. To the payment provider on the internet, it matches 0.0.0.0/0 and goes to nat-a in public-a, then through the internet gateway: 0.093 dollars a gigabyte and 0.093 an hour.\"><defs><marker id=\"l19-three-ways-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-three-ways-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10.0\" y=\"30.0\" width=\"480.0\" height=\"350.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"26.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"25.0\" y=\"58.0\" width=\"450.0\" height=\"310.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"41.0\" y=\"76.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-prod  10.20.0.0/16</text><rect x=\"45.0\" y=\"90.0\" width=\"230.0\" height=\"160.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">app-a</text><rect x=\"60.0\" y=\"120.0\" width=\"100.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">app machine</text><rect x=\"150.0\" y=\"190.0\" width=\"110.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"205.0\" y=\"205.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">interface</text><text x=\"205.0\" y=\"218.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">endpoint</text><rect x=\"45.0\" y=\"270.0\" width=\"230.0\" height=\"84.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"60.0\" y=\"286.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">public-a</text><rect x=\"150.0\" y=\"300.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"320.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">nat-a</text><rect x=\"560.0\" y=\"108.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S3</text><rect x=\"560.0\" y=\"192.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">STS</text><rect x=\"560.0\" y=\"300.0\" width=\"140.0\" height=\"40.0\" rx=\"16\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"320.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">payment provider</text><path d=\"M162.0 128.0 L275.0 128.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M275.0 128.0 L475.0 128.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M475.0 128.0 L490.0 128.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M490.0 128.0 L556.0 128.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l19-three-ways-af-ah-phosphor)\"></path><text x=\"375.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">gateway endpoint: a route, free</text><path d=\"M110.0 166.0 L110.0 212.0 L146.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-three-ways-af-ah-phosphor)\"></path><path d=\"M262.0 212.0 L275.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M275.0 212.0 L475.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M475.0 212.0 L490.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M490.0 212.0 L556.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-three-ways-af-ah-phosphor)\"></path><text x=\"375.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">0.021/h per zone + 0.01/GB</text><path d=\"M80.0 166.0 L80.0 250.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80.0 250.0 L80.0 270.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80.0 270.0 L80.0 320.0 L146.0 320.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-three-ways-af-ah-amber)\"></path><path d=\"M262.0 320.0 L275.0 320.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M275.0 320.0 L475.0 320.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M475.0 320.0 L490.0 320.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M490.0 320.0 L556.0 320.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-three-ways-af-ah-amber)\"></path><text x=\"375.0\" y=\"308.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">NAT: 0.093/GB + 0.093/h</text><text x=\"375.0\" y=\"338.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">then the internet gateway</text><text x=\"600.0\" y=\"380.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">VPC and EC2 offers, September 2026</text></svg>", "caption": "The same machine, three destinations, three prices. Only the gateway endpoint is free, and only S3 and DynamoDB have one."}
```

## Skipping the NAT gateway altogether

The real saving is when a subnet needs nothing from the internet. The shop's database talks to the
application and writes its backups to S3, and nothing else. With the gateway endpoint of the
previous section, **the data subnets could have no `0.0.0.0/0` route at all**: their only way out
would be the free route to S3. That removes the database's last path to the internet, a
security gain as well as a saving. It is why many VPCs give the data tier a route table of its
own rather than sharing the app tier's, as lesson 17's script does.

Where a subnet needs a handful of AWS services and nothing else, interface endpoints for those
services and a gateway endpoint for S3 replace the NAT gateway for that subnet. With three NAT
gateways at 214.62 a month and a few interface endpoints at 45.99 each, the arithmetic depends on
how many services are needed. Lesson 17's table and this one are the tools for it.
