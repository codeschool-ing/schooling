---
title: Reaching a service without reaching the internet
version: 1
---

**A private endpoint is a route to one AWS service that never leaves the VPC, so a private subnet can
use S3 without having a route to the internet at all.** It also gives you a place to say *which*
buckets that path may reach, and that second half is the one that stops data leaving.

The wrong picture is that S3 is "inside AWS" and therefore inside your network. It is not. S3 answers
on public addresses, and without an endpoint, a machine in a private subnet reaches it the way it
reaches anything else on the internet: through a NAT gateway, out of the VPC, and back in. That path
is open to every bucket of every AWS account in the world, including one a thief created this
morning.

## Two kinds

| | gateway endpoint | interface endpoint |
|---|---|---|
| for | S3 and DynamoDB only | most AWS services, and services other companies publish |
| what it is | a route, in the route tables you name, to a prefix list | a network interface with a private address in your subnet, built on AWS PrivateLink |
| what it costs | nothing | billed per hour and per gigabyte |
| filtered by | an endpoint policy | an endpoint policy and a security group |

The equivalents elsewhere are Azure's **Private Endpoint** and Google Cloud's **Private Service
Connect** and **Private Google Access**; they are taught from their documentation, not run here.

## A gateway endpoint for the records subnet

The clinic's records database writes its nightly backup to a bucket, `clinic-records`. An endpoint
policy is an ordinary IAM policy document attached to the endpoint, and this one lets the path reach
that bucket and nothing else. Save it as `endpoint-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::clinic-records", "arn:aws:s3:::clinic-records/*"]
    }
  ]
}
```

`"Principal": "*"` here does not mean the public, as it did in lesson 1's bucket policy: an endpoint
policy only judges requests that already came through the endpoint, from inside the VPC, and it can
only narrow what the caller's own permissions allow. It grants nothing on its own. Create the bucket and the endpoint
on the records subnet's table, then read that table again:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-records
ana@laptop:~/aws$ vpce=$(aws ec2 create-vpc-endpoint --vpc-id "$vpc" --service-name com.amazonaws.sa-east-1.s3 --route-table-ids "$private" --policy-document file://endpoint-policy.json --query VpcEndpoint.VpcEndpointId --output text)
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids "$private" --query "RouteTables[].Routes[].[DestinationCidrBlock||DestinationPrefixListId,GatewayId]" --output text
10.20.0.0/16	local
pl-d029879653b03e4de	vpce-12eafc0257a0346f7
ana@laptop:~/aws$ pl=$(aws ec2 describe-prefix-lists --filters Name=prefix-list-name,Values=com.amazonaws.sa-east-1.s3 --query "PrefixLists[0].PrefixListId" --output text)
```

**A new route, and its destination is not an address range but a prefix list**: the `pl-` id names
the set of addresses S3 uses in São Paulo, and AWS keeps that set up to date. The records subnet can
now reach S3 and still has no route to anything else outside the VPC.

The security group closed in the last section still stops it, though, since S3's addresses are not
in `10.20.0.0/16`. The outbound rule names the same prefix list, on HTTPS only:

```
ana@laptop:~/aws$ aws ec2 authorize-security-group-egress --group-id "$db" --ip-permissions "IpProtocol=tcp,FromPort=443,ToPort=443,PrefixListIds=[{PrefixListId=$pl}]" --query Return
true
```

## The other side: a bucket that only answers its endpoint

The endpoint policy limits where the VPC's requests may go. The bucket can limit where its requests
may come from, with a condition on the endpoint's id, `aws:SourceVpce`. This bucket policy refuses
every request to `clinic-records` that did not arrive through the clinic's endpoint:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "OnlyThroughTheClinicEndpoint",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": ["arn:aws:s3:::clinic-records", "arn:aws:s3:::clinic-records/*"],
      "Condition": {"StringNotEquals": {"aws:SourceVpce": "VPCE-ID"}}
    }
  ]
}
```

Put the endpoint's id where `VPCE-ID` is, save the file as `only-endpoint.json`, and attach it:

```
ana@laptop:~/aws$ sed "s/VPCE-ID/$vpce/" only-endpoint.json > only-endpoint-filled.json
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket clinic-records --policy file://only-endpoint-filled.json
ana@laptop:~/aws$ aws s3api get-bucket-policy --bucket clinic-records --query Policy --output text | jq -c .Statement[0].Condition
{"StringNotEquals":{"aws:SourceVpce":"vpce-12eafc0257a0346f7"}}
```

**moto stored the policy, and it cannot show what it does**: it ignores conditions, as lesson 1's
table says. On AWS, the documented effect is that a request from outside the endpoint — the console,
a laptop, a stolen key used from another network — is refused even when its identity policy allows
it, because an explicit `Deny` wins. That is AWS's documentation, not a run.

Be careful with a policy like this on a real account. It refuses everybody outside the endpoint,
including the administrators who would want to remove it; AWS's examples add an exception for an
administrative role for exactly that reason.

## What the two halves stop

Put together, the two policies close the exfiltration path this section opened with. A credential
stolen from the database host can no longer copy the records to the thief's bucket through the
endpoint, because the endpoint policy names one bucket. And it can no longer read `clinic-records`
from somewhere else, because the bucket refuses anything that did not come through the endpoint.
**Neither half needs the other to be right, which is what defence in depth means in a network.**
