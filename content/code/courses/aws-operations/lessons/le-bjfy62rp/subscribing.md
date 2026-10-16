---
title: Subscribing, in a lab where it costs nothing
version: 1
---

**Read this first: on a real account, the command in this section commits the account's organisation
to 3,000 USD a month for a year, and it cannot be cancelled.** In moto it is a row in memory. That
difference is the reason this course is practised in moto, and the reason this section exists: to see
what the subscription is, as data, without paying for it.

The thing to protect is the shop's load balancer, made as in lesson 15, in `~/aws/shield`:

```sh
mkdir -p ~/aws/shield && cd ~/aws/shield
VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)
A=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.1.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
B=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.2.0/24 --availability-zone sa-east-1b --query Subnet.SubnetId --output text)
aws elbv2 create-load-balancer --name shop --subnets $A $B --query 'LoadBalancers[0].DNSName' --output text
```

## Before, and after

An account with only Shield Standard has no subscription to describe:

```
ana@laptop:~/aws/shield$ LB=$(aws elbv2 describe-load-balancers --names shop --query "LoadBalancers[0].LoadBalancerArn" --output text)
ana@laptop:~/aws/shield$ aws shield describe-subscription

aws: [ERROR]: An error occurred (ResourceNotFoundException) when calling the DescribeSubscription operation: The subscription does not exist.
```

Then the command, which in moto bills nothing:

```
ana@laptop:~/aws/shield$ aws shield create-subscription
ana@laptop:~/aws/shield$ aws shield describe-subscription --query 'Subscription.[StartTime,EndTime,TimeCommitmentInSeconds,AutoRenew]' --output text
2026-10-16T16:19:00	2027-10-16T16:19:00	31536000	ENABLED
```

The second line is the subscription's terms. It starts now, ends in a year, the commitment is
**31,536,000 seconds**, which is 365 days, and it renews by itself unless somebody turns that off.
With a subscription, a resource is protected by naming it:

```
ana@laptop:~/aws/shield$ aws shield create-protection --name shop-alb --resource-arn $LB
{
    "ProtectionId": "94c399d2-bd42-40f5-a501-2d086bdf60c2"
}
ana@laptop:~/aws/shield$ aws shield list-protections --query 'Protections[].[Name,ResourceArn]' --output text
shop-alb	arn:aws:elasticloadbalancing:sa-east-1:123456789012:loadbalancer/app/shop/9c657181d428d45b
```

A protection is per resource, and the subscription allows a number of them per type. On AWS, each
protected load balancer, distribution or address also starts paying the data transfer line of the last
section. moto accepted a protection here; it also accepts one before any subscription exists, which AWS
does not.

## What cannot be done, in the lab or out of it

```
ana@laptop:~/aws/shield$ aws shield delete-subscription 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the DeleteSubscription operation (reached max retries: 2): <!doctype html>
ana@laptop:~/aws/shield$ aws shield list-attacks 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the ListAttacks operation (reached max retries: 2): <!doctype html>
```

Both are moto's 500s, and they stand for two different things on AWS. `list-attacks` works there, and
it is how a team sees the attacks Shield detected on its protected resources, with their start, end and
vectors; moto keeps no attacks. `delete-subscription` is the one that matters: **AWS does not let a
subscription be cancelled during its year**. What can be changed is the renewal, with
`update-subscription --auto-renew DISABLED`, so it ends at the year's end rather than continuing. The way
to try Shield Advanced is this lab, or an organisation that has already decided to buy it.
