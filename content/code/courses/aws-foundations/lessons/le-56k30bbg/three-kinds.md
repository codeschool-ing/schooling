---
title: Three load balancers, three layers
version: 1
---

**Elastic Load Balancing is three products under one API**, and the difference between them is how
much of the traffic each one reads. The **application** load balancer reads every HTTP request. The **network**
load balancer reads only addresses and ports. The **gateway** load balancer reads almost nothing and
passes whole packets to a row of appliances. The wrong picture is one load balancer with a few
options, where you pick the cheapest. They answer different questions, and the question comes first:
what does the thing in front of the machines need to know?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l22-three-kinds\" aria-label=\"The three load balancers side by side. On the left, the application load balancer, layer 7: it reads the host, the path and the headers of each request, and sends /api/* to the shop-api target group and everything else to shop-web-app. In the middle, the network load balancer, layer 4: it passes TCP, UDP and TLS connections from one fixed address per zone to one target group, and the target sees the caller's own address. On the right, the gateway load balancer, layer 3: traffic entering the VPC goes to a GWLB endpoint, the gateway load balancer sends each packet wrapped in GENEVE on port 6081 to a firewall appliance, and takes it back to continue to its destination.\"><defs><marker id=\"l22-three-kinds-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l22-three-kinds-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l22-three-kinds-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"200.0\" height=\"34.0\" rx=\"17\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a customer, over HTTPS</text><rect x=\"20.0\" y=\"92.0\" width=\"200.0\" height=\"66.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">application</text><text x=\"120.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">layer 7</text><text x=\"120.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads host, path, headers</text><rect x=\"260.0\" y=\"20.0\" width=\"200.0\" height=\"34.0\" rx=\"17\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a partner's terminal, raw TCP</text><rect x=\"260.0\" y=\"92.0\" width=\"200.0\" height=\"66.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">network</text><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">layer 4</text><text x=\"360.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads addresses and ports</text><rect x=\"500.0\" y=\"20.0\" width=\"200.0\" height=\"34.0\" rx=\"17\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">traffic entering the VPC</text><rect x=\"500.0\" y=\"92.0\" width=\"200.0\" height=\"66.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">gateway</text><text x=\"600.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">layer 3</text><text x=\"600.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads nothing, all ports</text><path d=\"M120.0 56.0 L120.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-paper-dim)\"></path><rect x=\"25.0\" y=\"230.0\" width=\"90.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-api</text><text x=\"70.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">target group</text><rect x=\"125.0\" y=\"230.0\" width=\"110.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-web-app</text><text x=\"180.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">target group</text><path d=\"M95.0 160.0 L72.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-amber)\"></path><path d=\"M145.0 160.0 L176.0 226.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-phosphor)\"></path><text x=\"60.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">/api/*</text><text x=\"170.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">default</text><text x=\"120.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">rules choose the group</text><path d=\"M360.0 56.0 L360.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-paper-dim)\"></path><text x=\"372.0\" y=\"74.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one fixed IP per zone</text><rect x=\"300.0\" y=\"230.0\" width=\"120.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-tcp</text><text x=\"360.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">target group</text><path d=\"M360.0 160.0 L360.0 226.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the target sees the caller's IP</text><rect x=\"520.0\" y=\"64.0\" width=\"160.0\" height=\"22.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"600.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">GWLB endpoint</text><path d=\"M600.0 56.0 L600.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M600.0 87.0 L600.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-paper-dim)\"></path><rect x=\"540.0\" y=\"230.0\" width=\"120.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">firewall</text><text x=\"600.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">appliances</text><path d=\"M580.0 160.0 L580.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-amber)\"></path><path d=\"M620.0 226.0 L620.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-three-kinds-af-ah-phosphor)\"></path><text x=\"574.0\" y=\"194.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">GENEVE</text><text x=\"574.0\" y=\"207.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">6081</text><text x=\"628.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">back</text><text x=\"600.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">then on to its destination</text><text x=\"360.0\" y=\"340.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the more a load balancer reads, the more it can decide</text><text x=\"360.0\" y=\"362.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and the more of the request it has to understand</text></svg>", "caption": "Three products under one API. The question is how much of the traffic the thing in front of the machines needs to read."}
```

| | application (ALB) | network (NLB) | gateway (GWLB) |
|---|---|---|---|
| reads | HTTP and HTTPS: host, path, headers, method | TCP, UDP and TLS connections | IP packets, all ports |
| sends to | target groups chosen by rules | one target group per listener | a fleet of appliances, and back |
| its address | a name, whose addresses change | one fixed address per zone, an Elastic IP if you choose | an endpoint in each VPC it serves |
| the target sees | the load balancer's address, with the caller's in `X-Forwarded-For` | the caller's own address | the original packet, wrapped in GENEVE |
| for the shop | the web shop and its API | a payment terminal speaking raw TCP | a firewall inspecting everything that enters |

A fourth, the **Classic** load balancer, still exists and still answers under its own API, `elb`.
It is the previous generation, AWS asks new designs not to use it, and this course does not.

## Starting from an empty AWS

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS. Lesson 16 builds the shop's VPC with public and private subnets in three zones. This
lesson needs two subnets in two zones, a security group for the load balancer, and two machines to
send traffic to. The machine image is looked up the way AWS documents it, in a public parameter that
always names the latest Amazon Linux:

```sh
vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)
a=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.0.0/24 \
  --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
b=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.1.0/24 \
  --availability-zone sa-east-1b --query Subnet.SubnetId --output text)
sg=$(aws ec2 create-security-group --group-name shop-web-lb --vpc-id "$vpc" \
  --description "the web load balancer" --query GroupId --output text)
ami=$(aws ssm get-parameter --query Parameter.Value --output text \
  --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64)
web1=$(aws ec2 run-instances --image-id "$ami" --instance-type t3.micro \
  --subnet-id "$a" --query "Instances[0].InstanceId" --output text)
web2=$(aws ec2 run-instances --image-id "$ami" --instance-type t3.micro \
  --subnet-id "$b" --query "Instances[0].InstanceId" --output text)
```

It prints nothing, and leaves seven shell variables in this terminal that the commands below read.

## The application load balancer

```
ana@laptop:~/aws$ aws elbv2 create-load-balancer --name shop-web --type application --scheme internet-facing --subnets $a $b --security-groups $sg --query "LoadBalancers[0].[Type,Scheme,DNSName,State.Code]" --output text
application	internet-facing	shop-web-1.sa-east-1.elb.amazonaws.com	provisioning
```

**The answer is a name, not an address.** `shop-web-1.sa-east-1.elb.amazonaws.com` is what clients
are given, and lesson 21 pointed the shop's apex at exactly this name with an alias. Against AWS the
addresses behind the name change as the load balancer grows and shrinks, which is why nothing should
ever be configured with one of them. **`internet-facing`** gives it public addresses. `internal`
would give it private ones only, for a load balancer between two tiers of the shop's own machines.
It starts `provisioning`, and in AWS becomes `active` a few minutes later. moto stays where it
started, since nothing is being built.

An ALB has to be placed in **at least two zones**, so that losing one zone leaves it answering. AWS
refuses a single subnet. moto 5.2.3 accepted one when it was tried, which is the pattern of this
course: moto stores what it is given and checks less than AWS does.

## The network load balancer

An NLB is chosen when the protocol is not HTTP, when every millisecond counts, or when the callers
need **an address that never changes**. A partner whose firewall lets the shop's traffic through by
address is one such caller. Each zone gets one fixed address, and for an internet-facing NLB it can
be an Elastic IP the shop already owns. Allocate two, one per zone:

```
ana@laptop:~/aws$ e1=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text)
ana@laptop:~/aws$ e2=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text)
```

```
ana@laptop:~/aws$ aws elbv2 create-load-balancer --name shop-tcp --type network --scheme internet-facing --subnet-mappings SubnetId=$a,AllocationId=$e1 SubnetId=$b,AllocationId=$e2 --query "LoadBalancers[0].AvailabilityZones"
[
    {
        "ZoneName": "sa-east-1a",
        "SubnetId": "subnet-dda1142fe1dec00ef"
    },
    {
        "ZoneName": "sa-east-1b",
        "SubnetId": "subnet-5ed24e25fb9c898bb"
    }
]
```

**Read what is missing.** Against AWS, each zone in that answer carries `LoadBalancerAddresses` with
the Elastic IP it was given. That address is what the partner writes into their firewall. moto
stored the zones and dropped the addresses, so this transcript shows the request and not the result.
The other thing an NLB does that moto cannot show is **keep the caller's address**. A target behind
an NLB sees the connection come from the customer's own IP. A target behind an ALB sees the ALB's,
and has to read the header to learn who called.

## The gateway load balancer

A GWLB is for traffic that has to pass **through** something: a firewall, an intrusion detector, a
device that inspects every packet entering the shop's network. It listens on every port at once and
sends each packet to an appliance wrapped in **GENEVE**, a tunnelling protocol on UDP port 6081.
Then it takes the packet back from the appliance to continue on its way. The wrapping is the point:
the packet arrives at the appliance exactly as it was sent, addresses and all, and leaves it the
same way.

```
ana@laptop:~/aws$ aws elbv2 create-load-balancer --name shop-inspect --type gateway --subnets $a $b --query "LoadBalancers[0].[Type,DNSName]" --output text
gateway	shop-inspect-1.sa-east-1.elb.amazonaws.com
```

Its targets are the appliances, in a target group that speaks GENEVE:

```
ana@laptop:~/aws$ aws elbv2 create-target-group --name shop-firewalls --protocol GENEVE --port 6081 --vpc-id $vpc --query "TargetGroups[0].[Protocol,Port,HealthCheckProtocol,HealthCheckPort]" --output text
GENEVE	6081	TCP	80
```

The appliances answer their health checks on an ordinary port, TCP 80 unless told otherwise, while
the traffic itself arrives on 6081. A listener joins the two, and it has no protocol and no port,
because it takes everything. The ARNs are long, so they go into variables first:

```
ana@laptop:~/aws$ gwlb=$(aws elbv2 describe-load-balancers --names shop-inspect --query "LoadBalancers[0].LoadBalancerArn" --output text)
ana@laptop:~/aws$ fw=$(aws elbv2 describe-target-groups --names shop-firewalls --query "TargetGroups[0].TargetGroupArn" --output text)
ana@laptop:~/aws$ aws elbv2 create-listener --load-balancer-arn $gwlb --default-actions Type=forward,TargetGroupArn=$fw --query "Listeners[0].[Protocol,Port]" --output text
	None
```

**The traffic reaches a GWLB through an endpoint**, not through its name. The GWLB is published as
an endpoint service, and each VPC whose traffic should be inspected gets a **GWLB endpoint** of its
own. A route table entry then sends traffic to that endpoint, as lesson 17 sends traffic to a NAT
gateway. Lesson 19's PrivateLink is the same machinery: a GWLB endpoint is one more kind of VPC
endpoint.

```
ana@laptop:~/aws$ aws ec2 create-vpc-endpoint-service-configuration --gateway-load-balancer-arns $gwlb --no-acceptance-required --query "ServiceConfiguration.ServiceName" --output text
com.amazonaws.vpce.sa-east-1.vpce-svc-da520fa0
```

```
ana@laptop:~/aws$ svc=$(aws ec2 describe-vpc-endpoint-service-configurations --query "ServiceConfigurations[0].ServiceName" --output text)
```

```
ana@laptop:~/aws$ aws ec2 create-vpc-endpoint --vpc-endpoint-type GatewayLoadBalancer --vpc-id $vpc --service-name $svc --subnet-ids $a --query "VpcEndpoint.[VpcEndpointId,VpcEndpointType,State]" --output text
vpce-78599abbf31f5912e	GatewayLoadBalancer	available
```

**moto stored all of it and carried no packet**, as it carries none anywhere. The route that sends
traffic into the endpoint, the GENEVE wrapping and the return trip are AWS's documented behaviour,
and were not run here. In practice the appliances often live in a separate security account, which
lesson 2 argued for, and the endpoints in each workload account point at them.
