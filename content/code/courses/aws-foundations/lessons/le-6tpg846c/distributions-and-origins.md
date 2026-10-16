---
title: Distributions, edges and origins
version: 1
---

**CloudFront keeps copies of the shop's files in AWS's edge locations, near the people asking for
them**, and fetches from the shop only what no nearby copy has. The shop's side is called the **origin**.
The configuration that joins the origins to the edges, with the rules for what is kept and for how
long, is a **distribution**. The common wrong picture is that CloudFront is a faster copy of the
bucket. It is a cache in front of anything that answers HTTP, and its job is to make most requests
never reach the origin at all.

## Edges, and the cache between them and the shop

**An edge location is a point of presence in a city**, one of hundreds around the world, and it is
where a viewer's request lands. The DNS name of a distribution answers with an edge close to whoever
asks. Behind the edges sit the **regional edge caches**, fewer and larger, which keep what has
fallen out of the edges' smaller caches. A request that finds nothing at the edge asks its regional
cache, and only a miss there goes back to the origin.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l23-edges\" aria-label=\"The path of a request through CloudFront, left to right. Two viewers, in Manaus and in Recife, each reach the edge location nearest them. A hit is answered at the edge. A miss goes to a regional edge cache, which both edges share, and a hit there is answered from it. Only a miss at the regional cache reaches the origin in sa-east-1, the bucket shop-assets or the load balancer shop-web, and the transfer from the origin to CloudFront is free. Most requests stop at the first box.\"><defs><marker id=\"l23-edges-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l23-edges-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"68.0\" width=\"130.0\" height=\"44.0\" rx=\"22\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a viewer in Manaus</text><rect x=\"200.0\" y=\"60.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">edge location</text><text x=\"265.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">hit: answered here</text><path d=\"M152.0 90.0 L196.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l23-edges-af-ah-paper-dim)\"></path><path d=\"M332.0 90.0 L382.0 132.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-edges-af-ah-amber)\"></path><rect x=\"20.0\" y=\"188.0\" width=\"130.0\" height=\"44.0\" rx=\"22\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a viewer in Recife</text><rect x=\"200.0\" y=\"180.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">edge location</text><text x=\"265.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">hit: answered here</text><path d=\"M152.0 210.0 L196.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l23-edges-af-ah-paper-dim)\"></path><path d=\"M332.0 210.0 L382.0 168.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-edges-af-ah-amber)\"></path><text x=\"357.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">miss</text><rect x=\"386.0\" y=\"115.0\" width=\"140.0\" height=\"70.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"456.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">regional edge cache</text><text x=\"456.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">larger, shared</text><text x=\"456.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">hit: answered here</text><path d=\"M528.0 150.0 L572.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-edges-af-ah-amber)\"></path><text x=\"550.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">miss</text><rect x=\"576.0\" y=\"50.0\" width=\"130.0\" height=\"200.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"590.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"590.0\" y=\"86.0\" width=\"102.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"641.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-assets</text><text x=\"641.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">bucket</text><rect x=\"590.0\" y=\"160.0\" width=\"102.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"641.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-web</text><text x=\"641.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">load balancer</text><text x=\"641.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">origin</text><text x=\"550.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">origin to CloudFront: free</text><text x=\"360.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the further right a request has to travel, the rarer it should be</text></svg>", "caption": "Two tiers of cache stand between the viewer and the shop. A miss at both is the only request the shop sees."}
```

That arrangement is what changes the bill as well as the speed. A file asked for a million times a
day is fetched from the shop a handful of times, once per regional cache whenever its copy expires.
AWS's network answers the rest. **The bytes from the origin to CloudFront are free**, which the
offer lesson 1 read says on a line of its own, and the last section of this lesson prints.

## Starting from an empty AWS

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS. The distribution needs two origins: the bucket `shop-assets`, where the images and
scripts live, and the load balancer lesson 22 built for the pages. The setup makes both, and the
load balancer gets only the two subnets an ALB needs:

```sh
aws s3api create-bucket --bucket shop-assets \
  --create-bucket-configuration LocationConstraint=sa-east-1 > /dev/null
vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)
a=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.0.0/24 \
  --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
b=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.1.0/24 \
  --availability-zone sa-east-1b --query Subnet.SubnetId --output text)
aws elbv2 create-load-balancer --name shop-web --subnets "$a" "$b" > /dev/null
```

## Three kinds of origin

| origin | how CloudFront reaches it | in the shop |
|---|---|---|
| an S3 bucket | the bucket's regional name, with **Origin Access Control** signing every request | `shop-assets`, the images and scripts |
| a load balancer | its DNS name, as a custom origin over HTTPS | `shop-web`, the pages and the API |
| any other HTTP server | its DNS name, as a custom origin | a payment provider's status page, a server in the datacentre |

**Origin Access Control (OAC) is how a bucket stays private and still serves the world.** CloudFront
signs each request it makes to the bucket, and the bucket's own policy allows those signed requests
and nobody else's. The files can then be read through the distribution and never straight from S3.
An OAC is an object of its own, made once and named in the origin:

```
ana@laptop:~/aws$ aws cloudfront create-origin-access-control --origin-access-control-config Name=shop-assets-oac,SigningProtocol=sigv4,SigningBehavior=always,OriginAccessControlOriginType=s3
{
    "ETag": "A0OWIEQ4SXBGK",
    "OriginAccessControl": {
        "Id": "ERHAWSV4GX0UT",
        "OriginAccessControlConfig": {
            "Name": "shop-assets-oac",
            "SigningProtocol": "sigv4",
            "SigningBehavior": "always",
            "OriginAccessControlOriginType": "s3"
        }
    }
}
```

## A distribution

The configuration is one JSON document. Save it as `~/aws/distribution.json`, with your own OAC's
`Id` in place of `ERHAWSV4GX0UT` if yours differs:

```json
{
  "CallerReference": "shop-cdn-2026-10-16",
  "Comment": "the shop's pages, images and scripts",
  "Enabled": true,
  "PriceClass": "PriceClass_All",
  "Origins": {"Quantity": 2, "Items": [
    {"Id": "assets", "DomainName": "shop-assets.s3.sa-east-1.amazonaws.com",
     "OriginAccessControlId": "ERHAWSV4GX0UT",
     "S3OriginConfig": {"OriginAccessIdentity": ""}},
    {"Id": "web", "DomainName": "shop-web-1.sa-east-1.elb.amazonaws.com",
     "CustomOriginConfig": {"HTTPPort": 80, "HTTPSPort": 443,
                            "OriginProtocolPolicy": "https-only"}}
  ]},
  "DefaultCacheBehavior": {
    "TargetOriginId": "web",
    "ViewerProtocolPolicy": "redirect-to-https",
    "CachePolicyId": "4135ea2d-6df8-44a3-9df3-4b5a84be39ad",
    "OriginRequestPolicyId": "216adef6-5c7f-47e4-b989-5492eafa07d3"
  },
  "CacheBehaviors": {"Quantity": 1, "Items": [
    {"PathPattern": "/static/*", "TargetOriginId": "assets",
     "ViewerProtocolPolicy": "redirect-to-https",
     "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
     "Compress": true}
  ]},
  "ViewerCertificate": {"CloudFrontDefaultCertificate": true}
}
```

Read it from the top. **Two origins**, each with an `Id` the behaviours refer to. **A default
behaviour** sends everything to the load balancer, without caching it, since pages and the API are
different for every customer. The next section reads the three policy ids. **One more behaviour**
sends `/static/*` to the bucket, cached, compressed. And `redirect-to-https` turns a viewer's plain
HTTP request into a redirect, as lesson 22's listener on port 80 did.

```
ana@laptop:~/aws$ aws cloudfront create-distribution --distribution-config file://distribution.json --query "[Location,Distribution.Id,Distribution.DomainName,Distribution.Status]" --output text
https://cloudfront.amazonaws.com/2020-05-31/distribution/DOF70T4DOCRTU	DOF70T4DOCRTU	wtn4hbbp1mje6.cloudfront.net	InProgress
```

**The distribution has a name of its own, under `cloudfront.net`**, and that is what viewers are
sent to. `InProgress` means AWS is copying the configuration to every edge, which against AWS takes
minutes. moto calls it `Deployed` the next time it is asked. Keep the id:

```
ana@laptop:~/aws$ id=$(aws cloudfront list-distributions --query "DistributionList.Items[0].Id" --output text)
```

```
ana@laptop:~/aws$ aws cloudfront get-distribution --id $id --query "Distribution.DistributionConfig.Origins.Items[].[Id,DomainName,OriginAccessControlId]" --output text
assets	shop-assets.s3.sa-east-1.amazonaws.com	None
web	shop-web-1.sa-east-1.elb.amazonaws.com	None
```

**moto dropped the OAC.** The bucket origin came back with no `OriginAccessControlId`, so moto 5.2.3
stores the origin and not the protection on it. Against AWS the same command prints the id.

## The bucket's half of the bargain

The OAC signs; **the bucket has to agree.** Its policy allows the CloudFront service to read objects,
and only on behalf of this one distribution, which is what the condition on `AWS:SourceArn` says. Save
it as `~/aws/assets-policy.json`, with your own distribution's id at the end of the ARN:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "OnlyThroughTheShopsDistribution",
    "Effect": "Allow",
    "Principal": {"Service": "cloudfront.amazonaws.com"},
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::shop-assets/*",
    "Condition": {"StringEquals": {
      "AWS:SourceArn": "arn:aws:cloudfront::123456789012:distribution/DOF70T4DOCRTU"}}
  }]
}
```

```
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket shop-assets --policy file://assets-policy.json
```

**moto stores a bucket policy and does not judge it**, the limit lesson 1 named, so nothing here
proves that a stranger is refused. In AWS the bucket's **Block Public Access** stays on, and nothing
in the policy is public. A direct request for
`shop-assets.s3.sa-east-1.amazonaws.com/static/logo.png` is refused, while the same file through the
distribution is served.

## Global, with its API in Virginia

**CloudFront belongs to no region**, like Route 53 in lesson 21. Against AWS the command line sends
every CloudFront call to one address and signs it for `us-east-1`, where the service's control plane
runs. The answers show it in three places. The `Location` above is `cloudfront.amazonaws.com`, with
no region in it. The ARN has an empty region field, `arn:aws:cloudfront::123456789012:…`. And
`--region` changes nothing:

```
ana@laptop:~/aws$ aws cloudfront list-distributions --region ap-southeast-2 --query "DistributionList.Items[].[Id,DomainName]" --output text
DOF70T4DOCRTU	wtn4hbbp1mje6.cloudfront.net
```

**The one place a region is not optional is the certificate.** To serve `cdn.shop.example.com`
instead of the `cloudfront.net` name, the distribution needs the name in `Aliases` and an ACM
certificate for it. **CloudFront takes certificates only from `us-east-1`**, wherever the shop
lives. The other services attached to a distribution follow the same rule: a WAF web ACL for
CloudFront is made in `us-east-1`, and CloudFront's metrics land in CloudWatch in `us-east-1`.

```
ana@laptop:~/aws$ aws acm request-certificate --domain-name cdn.shop.example.com --validation-method DNS --region us-east-1 --query CertificateArn --output text
arn:aws:acm:us-east-1:123456789012:certificate/fb5b7f04-8228-47c2-a212-0a76442e0d79
ana@laptop:~/aws$ aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[].DomainName" --output text
cdn.shop.example.com
ana@laptop:~/aws$ aws acm list-certificates --query "CertificateSummaryList[].DomainName" --output text
```

The last command asked São Paulo, and São Paulo has none: a certificate lives in the region that
issued it. **This one was not attached**, because AWS would not accept it until the DNS record that
validates it exists, and moto would accept it at once and prove nothing. The distribution keeps its
`cloudfront.net` name in this lab.
