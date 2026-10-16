---
title: PrivateLink for a service of your own
version: 1
---

**PrivateLink lets one VPC offer a service to others the way AWS offers STS.** The provider puts a
Network Load Balancer in front of the service and publishes it as an **endpoint service**. Each
consumer creates an interface endpoint to it in its own VPC. Traffic goes one way, from consumer to
provider, and nothing else of either VPC is visible to the other.

The wrong picture is that two VPCs have to be joined to share a service. Joining them, with the
peering or the Transit Gateway of lesson 20, opens routes between whole ranges in both directions,
and **fails when the two ranges overlap**. PrivateLink joins nothing: the consumer sees one
interface with an address of its own range, and the provider sees connections arriving at its load
balancer. Two VPCs that both use `10.20.0.0/16` can still use each other's services this way.

## The shop's stock service

The shop's application has an internal API that answers "how many of this item are left". The
staging environment, in the `shop-staging` account of lesson 2, needs to read production's stock
figures to test against real data, and nothing else of production. The API runs on the application
machines, so the load balancer in front of it is an **internal** Network Load Balancer in the three
app subnets:

```
ana@laptop:~/aws$ nlb=$(aws elbv2 create-load-balancer --name stock-api --type network --scheme internal --subnets $apps --query "LoadBalancers[0].LoadBalancerArn" --output text)
ana@laptop:~/aws$ aws elbv2 describe-load-balancers --names stock-api --query "LoadBalancers[0].[Type,Scheme,length(AvailabilityZones)]" --output text
network	internal	3
```

Lesson 22 is about load balancers. Here all that matters is that an endpoint service needs a Network
Load Balancer (or a Gateway Load Balancer, which serves another purpose) behind it.

## Publishing it as an endpoint service

```
ana@laptop:~/aws$ svc=$(aws ec2 create-vpc-endpoint-service-configuration --network-load-balancer-arns $nlb --acceptance-required --query ServiceConfiguration.ServiceId --output text)
ana@laptop:~/aws$ aws ec2 describe-vpc-endpoint-service-configurations --service-ids $svc --query "ServiceConfigurations[0].[ServiceName,AcceptanceRequired,length(AvailabilityZones)]" --output text
com.amazonaws.vpce.sa-east-1.vpce-svc-4fbe58fe	True	3
```

**The service name is the address consumers ask for**, `com.amazonaws.vpce.sa-east-1.vpce-svc-…`,
in the same family as `com.amazonaws.sa-east-1.sts`. `--acceptance-required` means that every
consumer's endpoint waits until the provider accepts it, so the shop decides each connection rather
than each account.

Who may ask at all is the second control. **An endpoint service is invisible to everybody until a
principal is allowed**, and the shop allows exactly one, the `shop-staging` account. That account
is created here in moto's organisation, as lesson 3 did:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --query Organization.FeatureSet --output text
ALL
ana@laptop:~/aws$ staging=$(aws organizations create-account --email aws+shop-staging@example.com --account-name shop-staging --query CreateAccountStatus.AccountId --output text); echo $staging
321532293571
ana@laptop:~/aws$ aws ec2 modify-vpc-endpoint-service-permissions --service-id $svc --add-allowed-principals arn:aws:iam::$staging:root
{
    "ReturnValue": true
}
ana@laptop:~/aws$ aws ec2 describe-vpc-endpoint-service-permissions --service-id $svc --query "AllowedPrincipals[].Principal" --output text
arn:aws:iam::321532293571:root
```

## The consumer, in the other account

The staging side works through a profile that assumes the account's administrator role, as lesson 2
set one up. The profile names this run's account number, so it is set again after a restart of moto.
Staging's VPC is `10.30.0.0/16`, with one subnet for the test:

```
ana@laptop:~/aws$ aws configure set profile.shop-staging.role_arn arn:aws:iam::$staging:role/OrganizationAccountAccessRole
ana@laptop:~/aws$ aws configure set profile.shop-staging.credential_source Environment
ana@laptop:~/aws$ aws configure set profile.shop-staging.role_session_name ana
ana@laptop:~/aws$ aws --profile shop-staging sts get-caller-identity --query Account --output text
321532293571
ana@laptop:~/aws$ svpc=$(aws --profile shop-staging ec2 create-vpc --cidr-block 10.30.0.0/16 --query Vpc.VpcId --output text)
ana@laptop:~/aws$ ssub=$(aws --profile shop-staging ec2 create-subnet --vpc-id $svpc --cidr-block 10.30.48.0/20 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
ana@laptop:~/aws$ aws --profile shop-staging ec2 create-vpc-endpoint --vpc-id $svpc --vpc-endpoint-type Interface --service-name com.amazonaws.vpce.sa-east-1.$svc --subnet-ids $ssub --query "VpcEndpoint.[VpcEndpointId,State,OwnerId]" --output text
vpce-d2da24b6a04de105b	available	321532293571
```

**On AWS that endpoint would now be `pendingAcceptance`**, and it would carry no traffic until the
shop ran `accept-vpc-endpoint-connections` for it. moto creates it `available` at once. It answers
both `describe-vpc-endpoint-connections` and `accept-vpc-endpoint-connections` with an internal
error, so the acceptance was not run here. Once accepted, staging's machines would reach the stock
API at the endpoint's interface in their own subnet, with an address from `10.30.0.0/16`. Production
would see the connections arrive from the load balancer's own private addresses, never from
staging's, which is why the two ranges are free to overlap.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l19-privatelink\" aria-label=\"PrivateLink between two accounts. On the left, the account shop-staging with its VPC 10.30.0.0/16, a test machine and an interface endpoint in one of its subnets. On the right, the account shop-prod with its VPC 10.20.0.0/16, the internal Network Load Balancer stock-api in the app subnets, and the application machines behind it. One arrow goes from the interface endpoint to the load balancer: PrivateLink, one way, accepted by the provider. Between the two VPCs there is no route, so their ranges could even overlap.\"><defs><marker id=\"l19-privatelink-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"300.0\" height=\"250.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shop-staging</text><rect x=\"36.0\" y=\"62.0\" width=\"268.0\" height=\"202.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"50.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VPC 10.30.0.0/16</text><rect x=\"50.0\" y=\"94.0\" width=\"240.0\" height=\"156.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"400.0\" y=\"30.0\" width=\"300.0\" height=\"250.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"416.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shop-prod</text><rect x=\"416.0\" y=\"62.0\" width=\"268.0\" height=\"202.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VPC 10.20.0.0/16</text><rect x=\"430.0\" y=\"94.0\" width=\"240.0\" height=\"156.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"52.0\" y=\"112.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"107.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">test machine</text><rect x=\"170.0\" y=\"176.0\" width=\"110.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"193.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">interface</text><text x=\"225.0\" y=\"206.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">endpoint</text><path d=\"M140.0 154.0 L140.0 200.0 L166.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-privatelink-af-ah-phosphor)\"></path><rect x=\"444.0\" y=\"176.0\" width=\"110.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"499.0\" y=\"193.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">stock-api</text><text x=\"499.0\" y=\"206.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">(internal NLB)</text><rect x=\"566.0\" y=\"112.0\" width=\"96.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"614.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">app machines</text><path d=\"M556.0 192.0 L604.0 192.0 L604.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19-privatelink-af-ah-phosphor)\"></path><path d=\"M282.0 200.0 L290.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M290.0 200.0 L304.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M304.0 200.0 L320.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M320.0 200.0 L400.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M400.0 200.0 L416.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M416.0 200.0 L430.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M430.0 200.0 L440.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l19-privatelink-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">PrivateLink</text><text x=\"360.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">one way</text><text x=\"360.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no route between 10.30.0.0/16 and 10.20.0.0/16: the ranges could overlap</text><text x=\"360.0\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">acceptance required; allowed principal: shop-staging</text></svg>", "caption": "The consumer sees one interface in its own subnet; the provider sees connections at its load balancer. Nothing else of either VPC is visible to the other."}
```

**Who pays for what follows the pieces.** The consumer pays for its interface endpoint, the 0.021 an
hour per zone and 0.01 a gigabyte of the previous section. The provider pays for its Network Load
Balancer, which lesson 22 prices. Neither pays for a NAT gateway or for data sent to the internet,
because nothing went there.

## When to use which

| you want | use |
|---|---|
| a private route to S3 or DynamoDB | a gateway endpoint: free, a line in a route table |
| a private way to another AWS service | an interface endpoint: an interface per zone, by the hour and the gigabyte |
| to offer one service of yours to other VPCs or accounts, one way | PrivateLink: an endpoint service behind a Network Load Balancer |
| two VPCs whose machines talk to each other freely | peering or Transit Gateway, lesson 20 |

The last row is the one this lesson does not do. When two networks need to reach many things in each
other, endpoint by endpoint is the wrong tool. Lesson 20 joins the ranges themselves.
