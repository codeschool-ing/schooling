---
title: How many regions, counted from published data
version: 1
---

"How many regions does AWS have?" has an answer on a marketing page, and it changes whenever a
region opens. This section counts them a different way, from a file AWS publishes for another
purpose, because counting teaches you to read that file, and the file is one you will meet again.

**`ip-ranges.json` lists every block of IP addresses AWS uses in public**, with the region and the
service each block belongs to. It exists for firewalls. Your office firewall may be allowed to let traffic
out only to S3 in São Paulo, or your server may accept connections only from AWS's content delivery
network. Either rule takes its addresses from this file, and people fetch it on a schedule to keep
such rules current. It needs no account:

```
ana@laptop:~/cloud$ curl -s https://ip-ranges.amazonaws.com/ip-ranges.json -o ip-ranges.json
ana@laptop:~/cloud$ jq '.prefixes[0]' ip-ranges.json
{
  "ip_prefix": "3.4.12.4/32",
  "region": "eu-west-1",
  "service": "AMAZON",
  "network_border_group": "eu-west-1"
}
ana@laptop:~/cloud$ jq -r '.createDate, (.prefixes | length), (.ipv6_prefixes | length)' ip-ranges.json
2026-09-28-15-57-04
10532
6901
ana@laptop:~/cloud$ jq '[.prefixes[].region] | unique | length' ip-ranges.json
43
ana@laptop:~/cloud$ jq -r '[.prefixes[].region] | unique | .[] | select(startswith("sa-"))' ip-ranges.json
sa-east-1
sa-west-1
```

Each entry is one block of addresses with three labels. This copy was created on 28 September 2026,
by its own `createDate`, and holds 10532 IPv4 blocks and 6901 IPv6 blocks. **The IPv4 blocks carry
43 different values in `region`.** Two of them start with `sa-`, which is South America: `sa-east-1`
is São Paulo, and `sa-west-1` is the first surprise.

43 is not the number of regions, and the reason is in the values themselves. Three kinds do not
belong in the count:

```
ana@laptop:~/cloud$ jq -r '.prefixes[] | select(.region == "GLOBAL") | .service' ip-ranges.json | sort | uniq -c
    220 AMAZON
      1 AMAZON_CONNECT
      1 CHIME_MEETINGS
    118 CLOUDFRONT
     44 CLOUDFRONT_ORIGIN_FACING
     24 EC2
     45 GLOBALACCELERATOR
      1 IVS_LOW_LATENCY
      9 IVS_REALTIME
      8 ROUTE53
      1 ROUTE53_HEALTHCHECKS
     20 S3
ana@laptop:~/cloud$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v37 exe/x86_64.ubuntu.24
ana@laptop:~/cloud$ jq -r '.partitions[] | select(.id != "aws") | .id as $p | .regions | to_entries[] | select(.key | test("global") | not) | "\($p)  \(.key)  \(.value.description)"' partitions.json | grep -v iso
aws-cn  cn-north-1  China (Beijing)
aws-cn  cn-northwest-1  China (Ningxia)
aws-eusc  eusc-de-east-1  AWS European Sovereign Cloud (Germany)
aws-us-gov  us-gov-east-1  AWS GovCloud (US-East)
aws-us-gov  us-gov-west-1  AWS GovCloud (US-West)
ana@laptop:~/cloud$ jq -rn --slurpfile a ip-ranges.json --slurpfile p partitions.json '([$a[0].prefixes[].region] | unique) - [$p[0].partitions[].regions | keys[]] | .[]'
GLOBAL
me-west-1
sa-west-1
us-south-1
ana@laptop:~/cloud$ jq -r '.prefixes[] | select(.region == "sa-west-1") | .service' ip-ranges.json | sort | uniq -c
     27 AMAZON
      2 DYNAMODB
      7 EC2
      1 ROUTE53_HEALTHCHECKS_PUBLISHING
      2 S3
```

**`GLOBAL` is not a region.** It labels addresses that belong to no single region, and the services
under it say why: `CLOUDFRONT` is AWS's content delivery network, `GLOBALACCELERATOR` its global entry
point and `ROUTE53` its DNS. They answer from many places at once, which is the subject of the
section on the edge.

**Five values are regions in separate partitions.** `partitions.json` ships inside the AWS CLI; it is
the list of regions this CLI knows, grouped into partitions, which are separate copies of AWS with
their own accounts. The ordinary partition is `aws`. China, AWS GovCloud and the European Sovereign
Cloud are partitions of their own, and an ordinary account cannot create anything in them. The
`grep -v iso` removes more partitions that have no addresses in `ip-ranges.json` at all.

**Three values are in the address file and not in this CLI's list**: `me-west-1`, `sa-west-1` and
`us-south-1`. Neither file says what they are. They have address space, so something of AWS's is
there; they are unknown to CLI 2.37.4, so it cannot address them. The last command shows how thin
`sa-west-1` is: 27 + 2 + 7 + 1 + 2 = 39 blocks. Reading it as a region being built is a guess, and
this lesson leaves it as one.

The arithmetic, then: 43 values, minus `GLOBAL`, is 42 names; minus the 5 in other partitions, 37;
minus the 3 the CLI does not know, **34 ordinary regions that both files agree on**. That is a
reasonable proxy for "regions you can use from an ordinary account today". It is not an official list:
AWS could open a region before it has public addresses in this file, and a region can have addresses
here before it takes customers, as the three above suggest. When the number matters, the provider's
own region table is the source, and the call that lists the regions enabled for an account belongs
to `aws-foundations`.
