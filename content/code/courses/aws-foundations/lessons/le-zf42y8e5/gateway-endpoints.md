---
title: Gateway endpoints, a free route to S3 and DynamoDB
version: 1
---

**A gateway endpoint is a route.** It puts a line in a route table that sends traffic for S3, or for
DynamoDB, straight to AWS's network. Nothing goes out through the NAT gateway and back in from the
internet. It has no address, sits in no subnet and **costs nothing**, neither by the hour nor by the
gigabyte. Only those two services have one.

The wrong picture is that an application in a private subnet talking to S3 stays "inside AWS"
anyway. Without an endpoint it does not, as far as the VPC is concerned. S3's addresses are public,
and the private table sends them to `0.0.0.0/0`. So **every gigabyte to S3 goes through a NAT
gateway**, at the 0.093 dollars a gigabyte lesson 17 read. The shop's nightly backups to
`shop-backups` are about 1 TB a month, which is 1,024 × 0.093 = **95.23 dollars a month** of NAT
processing for traffic that never needed the internet.

## Starting from lesson 18

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS, and rebuild lessons 16 to 18:

```
ana@laptop:~/aws$ bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh > /dev/null && bash net/18-filters.sh > /dev/null
ana@laptop:~/aws$ vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)
ana@laptop:~/aws$ rts=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a,private-b,private-c --query "RouteTables[].RouteTableId" --output text); echo $rts
rtb-2f5b255a96df86cac rtb-8a1f0f36b3db1cfbe rtb-2725b1ebad62ad346
```

The second command keeps the VPC's id in `vpc` as before. The third keeps the ids of the three
private route tables in `rts`, the ones lesson 17 made for the app and data subnets.

## Which services have an endpoint, and of which kind

```
ana@laptop:~/aws$ aws ec2 describe-vpc-endpoint-services --query "length(ServiceNames)"
256
ana@laptop:~/aws$ aws ec2 describe-vpc-endpoint-services --query "ServiceDetails[?ServiceName==\`com.amazonaws.sa-east-1.s3\` || ServiceName==\`com.amazonaws.sa-east-1.dynamodb\` || ServiceName==\`com.amazonaws.sa-east-1.sts\`].[ServiceName,ServiceType[0].ServiceType]" --output text
com.amazonaws.sa-east-1.dynamodb	Gateway
com.amazonaws.sa-east-1.s3	Interface
com.amazonaws.sa-east-1.s3	Gateway
com.amazonaws.sa-east-1.sts	Interface
```

moto knows 256 services that can be reached through an endpoint, a list close to AWS's own. **S3 is
there twice**, once as `Gateway` and once as `Interface`, DynamoDB once as `Gateway`, and STS, like
almost everything else, only as `Interface`. The interface kind is the next section.

## A prefix list in the route table

A gateway endpoint does not route to one address, since S3 has thousands. It routes to a **prefix
list**: a named set of ranges that AWS keeps up to date as the service grows, so the route never
goes stale.

```
ana@laptop:~/aws$ aws ec2 describe-managed-prefix-lists --filters Name=prefix-list-name,Values=com.amazonaws.sa-east-1.s3 --query "PrefixLists[0].[PrefixListId,PrefixListName,OwnerId]" --output text
pl-d029879653b03e4de	com.amazonaws.sa-east-1.s3	AWS
ana@laptop:~/aws$ aws ec2 get-managed-prefix-list-entries --prefix-list-id $(aws ec2 describe-managed-prefix-lists --filters Name=prefix-list-name,Values=com.amazonaws.sa-east-1.s3 --query "PrefixLists[0].PrefixListId" --output text) --query "Entries[].Cidr" --output text
52.216.0.0/15	3.5.0.0/19	54.231.0.0/16
```

The second command lists the ranges. **The three ranges are moto's**, a fixed list it ships with.
AWS's list for `sa-east-1` is its own and changes over time, which is exactly why a route names the
list rather than the ranges.

## The endpoint, and its policy

An endpoint carries a **policy**, a resource policy that says what may pass through it. It grants
nothing on its own: a request through the endpoint still needs the caller's own IAM permission, as
lessons 7 and 8 taught. It narrows the door, so that a machine in the shop's VPC cannot use the free
route to copy data into somebody else's bucket. Save this as `~/aws/endpoint-s3.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ShopBucketsOnly",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::shop-assets", "arn:aws:s3:::shop-assets/*",
        "arn:aws:s3:::shop-backups", "arn:aws:s3:::shop-backups/*",
        "arn:aws:s3:::shop-logs", "arn:aws:s3:::shop-logs/*"
      ]
    }
  ]
}
```

The endpoint is created against the three private route tables at once:

```
ana@laptop:~/aws$ s3e=$(aws ec2 create-vpc-endpoint --vpc-id $vpc --vpc-endpoint-type Gateway --service-name com.amazonaws.sa-east-1.s3 --route-table-ids $rts --policy-document file://endpoint-s3.json --query VpcEndpoint.VpcEndpointId --output text)
ana@laptop:~/aws$ aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $s3e --query "VpcEndpoints[0].[VpcEndpointType,State,length(RouteTableIds)]" --output text
Gateway	available	3
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a --query "RouteTables[0].Routes[].[DestinationCidrBlock || DestinationPrefixListId,GatewayId || NatGatewayId]" --output text
10.20.0.0/16	local
0.0.0.0/0	nat-99abbf31f5912eafc
pl-d029879653b03e4de	vpce-5365ddb620e8ec4a9
```

**`private-a` now has three routes**, and the new one names a prefix list rather than a range, with
the endpoint as its target. A packet for S3 matches both `0.0.0.0/0` and one of the list's ranges.
The list's range is longer, so lesson 17's rule sends it to the endpoint and not to the NAT gateway.
The application changes nothing: it calls the same S3 address it always called.

## The other side: a bucket that accepts only the endpoint

The endpoint policy limits what leaves the VPC. The bucket can limit what arrives, with the
condition key **`aws:SourceVpce`**, which AWS sets on every request that came through an endpoint.
This policy on `shop-backups` refuses everything that did not come through the shop's endpoint. It
needs the endpoint's id, so it is written with the shell's help:

```sh
cat > backups-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "OnlyThroughTheShopEndpoint",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": ["arn:aws:s3:::shop-backups", "arn:aws:s3:::shop-backups/*"],
      "Condition": {"StringNotEquals": {"aws:SourceVpce": "$s3e"}}
    }
  ]
}
EOF
```

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-backups --create-bucket-configuration LocationConstraint=sa-east-1 > /dev/null
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket shop-backups --policy file://backups-policy.json
ana@laptop:~/aws$ echo "nightly dump" > dump.txt && aws s3api put-object --bucket shop-backups --key 2026-10-16/dump.txt --body dump.txt

aws: [ERROR]: An error occurred (403) when calling the PutObject operation: Forbidden
ana@laptop:~/aws$ aws s3api get-object --bucket shop-backups --key 2026-10-16/dump.txt dump-back.txt

aws: [ERROR]: An error occurred (403) when calling the GetObject operation: Forbidden
ana@laptop:~/aws$ aws s3api list-objects-v2 --bucket shop-backups --query "length(Contents || \`[]\`)"
0
ana@laptop:~/aws$ aws s3api delete-bucket-policy --bucket shop-backups
```

**On AWS this policy refuses every request from the laptop**, because none of them came through the
endpoint. moto refused the two object requests with a bare 403, where AWS answers `AccessDenied`.
But **it did not judge the condition**. moto ignores a policy's `Condition` block, so it applied the
Deny as if the condition were not there, and it would refuse a request through the endpoint just the
same. It also let the listing through, which AWS would refuse. So the transcript shows the shape of
the policy and part of its effect. The rest is AWS's documented behaviour and was not run here.

**A Deny on `s3:*` refuses administrators too**, including whoever wrote it, from the console and
from the command line, whenever they are not inside the VPC. The account's root user can still
delete such a policy, which is the way back. The safer habit is a condition that also exempts a
named role, such as the `deployer` role of lesson 9. The policy is deleted at the end, so that the
lab keeps working from the laptop.
