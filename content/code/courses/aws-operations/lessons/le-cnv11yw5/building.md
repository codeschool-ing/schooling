---
title: Building the shop's web ACL
version: 1
---

A web ACL protects something, and in this lab that is a load balancer. `aws-compute` built the shop's;
in moto there is none until you make one, so the first step is a network with two subnets and an
Application Load Balancer named `shop`, in `~/aws/waf`:

```sh
mkdir -p ~/aws/waf && cd ~/aws/waf
VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)
A=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.1.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
B=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.2.0/24 --availability-zone sa-east-1b --query Subnet.SubnetId --output text)
aws elbv2 create-load-balancer --name shop --subnets $A $B --query 'LoadBalancers[0].DNSName' --output text
```

## The addresses to refuse

An IP set is a list of addresses and ranges, kept apart from the rules so it can change without
touching them. The shop's holds a range and one address that the team has seen trying passwords:

```
ana@laptop:~/aws/waf$ IPSET=$(aws wafv2 create-ip-set --name blocked --scope REGIONAL --ip-address-version IPV4 --addresses 203.0.113.0/24 198.51.100.7/32 --query Summary.ARN --output text); echo $IPSET
arn:aws:wafv2:sa-east-1:123456789012:regional/ipset/blocked/a14bb4e5-a7e1-40fd-8d6d-627cc261cb16
ana@laptop:~/aws/waf$ jq --arg a "$IPSET" '.Rules[0].Statement.IPSetReferenceStatement.ARN = $a' web-acl.json > shop-acl.json
```

The addresses are from the ranges reserved for documentation, which no real computer uses.

## The web ACL

The web ACL is a file, `web-acl.json`, with the three rules of the previous section. The IP set's ARN
is not known until the set exists, so the file leaves a note in its place and `jq` writes the ARN in,
as the second command above did, into `shop-acl.json`.

`web-acl.json`:

```json
{
  "Name": "shop",
  "Scope": "REGIONAL",
  "DefaultAction": {
    "Allow": {}
  },
  "VisibilityConfig": {
    "SampledRequestsEnabled": true,
    "CloudWatchMetricsEnabled": true,
    "MetricName": "shop"
  },
  "Rules": [
    {
      "Name": "blocked-addresses",
      "Priority": 0,
      "Statement": {
        "IPSetReferenceStatement": {
          "ARN": "set by jq from the IP set"
        }
      },
      "Action": {
        "Block": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "blocked-addresses"
      }
    },
    {
      "Name": "login-rate",
      "Priority": 1,
      "Statement": {
        "RateBasedStatement": {
          "Limit": 100,
          "EvaluationWindowSec": 300,
          "AggregateKeyType": "IP",
          "ScopeDownStatement": {
            "ByteMatchStatement": {
              "FieldToMatch": {
                "UriPath": {}
              },
              "PositionalConstraint": "STARTS_WITH",
              "SearchString": "/login",
              "TextTransformations": [
                {
                  "Priority": 0,
                  "Type": "NONE"
                }
              ]
            }
          }
        }
      },
      "Action": {
        "Block": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "login-rate"
      }
    },
    {
      "Name": "aws-common",
      "Priority": 2,
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesCommonRuleSet",
          "RuleActionOverrides": [
            {
              "Name": "SizeRestrictions_BODY",
              "ActionToUse": {
                "Count": {}
              }
            }
          ]
        }
      },
      "OverrideAction": {
        "None": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "aws-common"
      }
    }
  ]
}
```

Every rule and the web ACL itself carry a `VisibilityConfig`: the name of the CloudWatch metric its
matches are counted under, and whether WAF keeps a sample of the requests it matched. Those metrics
are lesson 8's, in the namespace `AWS/WAFV2`, and they are how the section after next knows what a rule
would have done.

The managed rule group says `OverrideAction: None`, which means *use the group's own actions*, and then
overrides one of them. `SizeRestrictions_BODY` blocks request bodies over 8 KB, and the shop's product
photos are uploaded in larger ones; set to `Count`, that rule reports and refuses nothing, and the other
rules of the group still block.

## The first refusal, from the command line

```
ana@laptop:~/aws/waf$ aws wafv2 create-web-acl --cli-input-json file://shop-acl.json

aws: [ERROR]: Invalid base64: "/login"
```

**This one is the command line, not WAF.** `SearchString` is binary in the API, and when the command
line reads binary values from JSON it expects them in base64, so `/login` is not a valid value. Either
the file says `L2xvZ2lu`, which nobody can review, or the command says the file is plain text:

```
ana@laptop:~/aws/waf$ aws wafv2 create-web-acl --cli-input-json file://shop-acl.json --cli-binary-format raw-in-base64-out --query Summary.Id --output text
1649d3ae-e59b-4d9f-a513-7fcaae2067c3
```

```
ana@laptop:~/aws/waf$ ID=$(aws wafv2 list-web-acls --scope REGIONAL --query "WebACLs[0].Id" --output text)
ana@laptop:~/aws/waf$ aws wafv2 get-web-acl --name shop --scope REGIONAL --id $ID --query 'WebACL.Rules[].[Priority,Name,keys(Action || OverrideAction)[0]]' --output text
0	blocked-addresses	Block
1	login-rate	Block
2	aws-common	None
ana@laptop:~/aws/waf$ aws wafv2 get-web-acl --name shop --scope REGIONAL --id $ID --query WebACL.Capacity
3
```

Three rules in the order of their priority, two that act and the group that keeps its own actions. The
capacity is the number to distrust: **moto charges one unit a rule**. On AWS this web ACL costs about
705 WCU, 700 of them the common rule set, and the command that asks before saving is not in moto at all:

```
ana@laptop:~/aws/waf$ aws wafv2 check-capacity --scope REGIONAL --cli-binary-format raw-in-base64-out --rules "$(jq .Rules shop-acl.json)" 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the CheckCapacity operation (reached max retries: 2): <!doctype html>
```

## Attaching it

A web ACL does nothing until it is associated with a resource, and one resource has at most one web
ACL:

```
ana@laptop:~/aws/waf$ ACL=$(aws wafv2 list-web-acls --scope REGIONAL --query "WebACLs[0].ARN" --output text)
ana@laptop:~/aws/waf$ LB=$(aws elbv2 describe-load-balancers --names shop --query "LoadBalancers[0].LoadBalancerArn" --output text)
ana@laptop:~/aws/waf$ aws wafv2 associate-web-acl --web-acl-arn $ACL --resource-arn $LB
ana@laptop:~/aws/waf$ aws wafv2 get-web-acl-for-resource --resource-arn $LB --query WebACL.Name
"shop"
```

From here, on AWS, every request to the load balancer passes through the three rules. **In the lab
nothing does**: moto keeps the web ACL and the association and inspects no traffic, so whether a rule
matches is something to learn from AWS's documentation and, on a real account, from the web ACL's
metrics and logs.
