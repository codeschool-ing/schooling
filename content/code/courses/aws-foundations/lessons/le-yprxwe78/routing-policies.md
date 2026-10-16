---
title: Health checks and routing policies
version: 1
---

**A routing policy decides which of several records for one name a resolver is given.** Every
record so far had the default, **simple** routing: one record set, every value in it, the same answer
for everybody. The other six policies let one name hold several record sets, told apart by a
`SetIdentifier`, and choose between them at the moment of each question. The wrong picture is that
Route 53 sits in the path of the traffic and steers it. **It steers nothing.** It chooses an answer,
the answer is cached for its TTL, and the traffic goes wherever the answer said.

## The seven policies

| policy | chooses by | a use in the shop |
|---|---|---|
| simple | nothing: one answer | the mail server |
| weighted | a weight per record, in proportion | send one search request in ten to the new search cluster |
| latency | the AWS region with the lowest measured latency to the asker | São Paulo for Brazil, Virginia for North America |
| failover | a health check: the primary while healthy, the secondary otherwise | the API in São Paulo, a standby in Virginia |
| geolocation | the asker's continent, country or US state, by the resolver's address | a page in Portuguese for Brazil, in Spanish for Argentina |
| geoproximity | distance to each resource, with a bias you set to grow or shrink its share | moving traffic between regions gradually |
| multivalue | up to eight healthy records, chosen at random | several servers, each with its own health check |

Two of these are easy to confuse. **Latency is about the network**, measured by AWS between regions
and the places people ask from; **geolocation is about where the asker is**, whatever the network
says, which is what a law or a licence cares about. A geolocation set should always include a
`Default` record, or a resolver from a country nobody listed gets no answer at all.

## Health checks

**A health check is a set of probes that AWS sends from several places around the world** to an
address you name, every 30 seconds or every 10, and a verdict: healthy, or unhealthy after a number
of failures in a row. A record that names the check is left out of the answers while it is
unhealthy. Create one for the API in São Paulo:

```
ana@laptop:~/aws$ aws route53 create-health-check --caller-reference shop-api-sp-1 --health-check-config Type=HTTPS,IPAddress=203.0.113.20,Port=443,ResourcePath=/health,FullyQualifiedDomainName=api.shop.example.com,RequestInterval=30,FailureThreshold=3 --query "HealthCheck.[Id,HealthCheckConfig.Type,HealthCheckConfig.IPAddress]" --output text
283ed0d6-48b1-4372-b739-5df27b68b6fa	HTTPS	203.0.113.20
```

```
ana@laptop:~/aws$ hc=$(aws route53 list-health-checks --query "HealthChecks[0].Id" --output text)
ana@laptop:~/aws$ echo $hc
283ed0d6-48b1-4372-b739-5df27b68b6fa
```

Then ask how it is doing:

```
ana@laptop:~/aws$ aws route53 get-health-check-status --health-check-id $hc
{
    "HealthCheckObservations": [
        {
            "Region": "us-east-1",
            "IPAddress": "127.0.13.37",
            "StatusReport": {
                "Status": "Success: HTTP Status Code: 200. Resolved IP: 127.0.13.37. OK",
                "CheckedTime": "2026-10-16T16:00:34.261386+00:00"
            }
        }
    ]
}
```

**Read that answer as moto's invention, every word of it.** Nothing listens at `203.0.113.20`: it is
a documentation address, and moto sent no probe to it or anywhere else. The status, the code 200 and
the address `127.0.13.37` are what moto 5.2.3 says about every health check. Against AWS the same
command lists one observation per probing region, each with what that probe actually saw, and a
check of an address that does not answer reports a failure. **A failover plan cannot be tested in
moto**; what moto can check is that the records and the check are wired together the way you meant.

## Weighted and failover, in one batch

Both policies need the health check's id inside the batch, so this file is written with a here
document that puts `$hc` in for you. Type it as it stands:

```sh
cat > ~/aws/policies.json <<EOF
{
  "Comment": "a canary for search, a standby for the API",
  "Changes": [
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "search.shop.example.com", "Type": "A", "TTL": 60,
      "SetIdentifier": "current", "Weight": 90,
      "ResourceRecords": [{"Value": "203.0.113.30"}]}},
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "search.shop.example.com", "Type": "A", "TTL": 60,
      "SetIdentifier": "canary", "Weight": 10,
      "ResourceRecords": [{"Value": "203.0.113.31"}]}},
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "api.shop.example.com", "Type": "A", "TTL": 60,
      "SetIdentifier": "sao-paulo", "Failover": "PRIMARY", "HealthCheckId": "$hc",
      "ResourceRecords": [{"Value": "203.0.113.20"}]}},
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "api.shop.example.com", "Type": "A", "TTL": 60,
      "SetIdentifier": "virginia", "Failover": "SECONDARY",
      "ResourceRecords": [{"Value": "198.51.100.20"}]}}
  ]
}
EOF
```

```
ana@laptop:~/aws$ aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch file://policies.json --query ChangeInfo.Status --output text
INSYNC
```

```
ana@laptop:~/aws$ aws route53 list-resource-record-sets --hosted-zone-id $zone --query "ResourceRecordSets[?SetIdentifier].[Name,SetIdentifier,Weight,Failover,HealthCheckId]" --output text
api.shop.example.com.	sao-paulo	None	PRIMARY	283ed0d6-48b1-4372-b739-5df27b68b6fa
api.shop.example.com.	virginia	None	SECONDARY	None
search.shop.example.com.	current	90	None	None
search.shop.example.com.	canary	10	None	None
```

**A weight is a share, not a percentage.** Route 53 divides each record's weight by the sum of the
weights for that name, so 90 and 10 are nine answers in ten and one in ten, and so are 9 and 1. A
weight of 0 takes a record out of rotation without deleting it, which is how a canary is stopped in a
hurry.

**The failover pair answers with the primary while its check is healthy**, and with the secondary
when it is not. The secondary has no check here, so it is always considered healthy: a standby that
is never checked is a bet that it is still there on the day it is needed, and a real one gets a check
of its own. The TTL of 60 is part of the design. A resolver that cached the São Paulo address keeps
using it for up to a minute after the switch, so the TTL is the floor on how fast a failover can be.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l21-routing\" aria-label=\"Two routing policies side by side. On the left, weighted: the name search.shop.example.com holds two records, current with weight 90 at 203.0.113.30 and canary with weight 10 at 203.0.113.31, so nine answers in ten give the first address. On the right, failover: api.shop.example.com holds a primary in São Paulo at 203.0.113.20, watched by a health check, and a secondary in Virginia at 198.51.100.20, given only while the check says the primary is unhealthy. Underneath: Route 53 chooses the answer, and the traffic never passes through it.\"><defs><marker id=\"l21-routing-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l21-routing-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"330.0\" height=\"250.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"36.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">weighted</text><rect x=\"370.0\" y=\"20.0\" width=\"330.0\" height=\"250.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"386.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">failover</text><rect x=\"70.0\" y=\"60.0\" width=\"230.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">search.shop.example.com</text><rect x=\"40.0\" y=\"180.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">current</text><text x=\"105.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">203.0.113.30</text><rect x=\"200.0\" y=\"180.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">canary</text><text x=\"265.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">203.0.113.31</text><path d=\"M150.0 98.0 L110.0 176.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\" marker-end=\"url(#l21-routing-af-ah-phosphor)\"></path><path d=\"M220.0 98.0 L260.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.0\" fill=\"none\" marker-end=\"url(#l21-routing-af-ah-amber)\"></path><text x=\"112.0\" y=\"132.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">9 in 10</text><text x=\"256.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">1 in 10</text><text x=\"185.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">weights 90 and 10, a share of their sum</text><rect x=\"420.0\" y=\"60.0\" width=\"230.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">api.shop.example.com</text><rect x=\"390.0\" y=\"180.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">PRIMARY, São Paulo</text><text x=\"460.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">203.0.113.20</text><rect x=\"550.0\" y=\"180.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"620.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SECONDARY, Virginia</text><text x=\"620.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">198.51.100.20</text><path d=\"M500.0 98.0 L465.0 176.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l21-routing-af-ah-phosphor)\"></path><path d=\"M570.0 98.0 L615.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l21-routing-af-ah-amber)\"></path><text x=\"494.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">while healthy</text><text x=\"600.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">when it is not</text><circle cx=\"425.0\" cy=\"128.0\" r=\"11\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"425.0\" y=\"128.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">✓</text><text x=\"425.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">check</text><path d=\"M430.0 158.0 L440.0 176.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.0\" fill=\"none\" stroke-dasharray=\"2 2\"></path><text x=\"535.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a health check on the primary only</text><text x=\"360.0\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Route 53 chooses the answer; the traffic never passes through it</text></svg>", "caption": "A policy is a rule for choosing between records. The choice is made once per question, and cached for the TTL."}
```

## Asking Route 53 what it would answer

AWS has a command for exactly the question moto cannot answer: `test-dns-answer` asks Route 53 which
values it would return for a name and a type, from a resolver address you may choose.

```
ana@laptop:~/aws$ aws route53 test-dns-answer --hosted-zone-id $zone --record-name search.shop.example.com --record-type A

aws: [ERROR]: An error occurred (404) when calling the TestDNSAnswer operation: Not Found
```

**moto 5.2.3 does not implement it**, and the `404` is moto saying so, not Route 53 saying the name is
missing. Nor does moto serve DNS on any port, so `dig` has nothing to ask; pointing `dig` at Route
53's real name servers is the internet's business and outside this course. What the lab gives you is
the configuration, read back exactly as it was written, and that is where most mistakes in a zone
live anyway.

## What a million answers cost

`price.py` prints four decimals, and a single DNS query costs less than a hundredth of a cent, so the
lines would all read `0.0000`. This short program reads the file `price.py` already downloaded and
prints the price per million instead. Save it as `~/aws/per-million.py`:

```python
#!/usr/bin/env python3
"""Prints prices per million units, from an offer price.py has already downloaded.

    python3 per-million.py OFFER VERSION REGION USAGETYPE...
"""
import json
import os
import sys

code, version, region, *usages = sys.argv[1:]
path = os.path.expanduser(f'~/.cache/aws-prices/{code}-{version}-{region}.json')
with open(path) as f:
    doc = json.load(f)
for usage in usages:
    tiers = []
    for sku, product in doc['products'].items():
        if product['attributes'].get('usagetype') == usage:
            for term in doc['terms']['OnDemand'].get(sku, {}).values():
                for d in term['priceDimensions'].values():
                    tiers.append((float(d['beginRange']), float(d['pricePerUnit']['USD'])))
    print(usage)
    for begin, price in sorted(tiers):
        print(f'  from {begin:>13,.0f}  {price * 1_000_000:.2f} per million')
```

```
ana@laptop:~/aws$ python3 per-million.py AmazonRoute53 20260911124504 aws-other DNS-Queries LBR-Queries Geo-Queries Intra-AWS-DNS-Queries
DNS-Queries
  from             0  0.40 per million
  from 1,000,000,000  0.20 per million
LBR-Queries
  from             0  0.60 per million
  from 1,000,000,000  0.30 per million
Geo-Queries
  from             0  0.70 per million
  from 1,000,000,000  0.35 per million
Intra-AWS-DNS-Queries
  from             0  0.00 per million
```

```
ana@laptop:~/aws$ python3 price.py AmazonRoute53 20260911124504 aws-other Health-Check-AWS Health-Check-Non-AWS Health-Check-Option-Non-AWS
AmazonRoute53 20260911124504, published 2026-09-11, USD
Health-Check-AWS
          0 to        50 Mo   0.0000
         50 to       Inf Mo   0.5000
Health-Check-Non-AWS
          0 to       Inf Mo   0.7500
Health-Check-Option-Non-AWS
          0 to       Inf Mo   2.0000
```

In the list of **11 September 2026**:

| what | dollars |
|---|---|
| a million standard queries, the first billion of a month | 0.40 |
| a million latency-based queries (`LBR`) | 0.60 |
| a million geolocation queries | 0.70 |
| a million queries answered from an alias to an AWS resource | free |
| a health check of an AWS endpoint, per month | free for the first 50, then 0.50 |
| a health check of anything else, per month | 0.75 |
| each optional feature on such a check, per month | 2.00 |

**The policy is part of the price.** The same question costs half as much again when the record
behind it is latency-based, and three quarters as much again when it is geolocation. The API's check
probes `203.0.113.20`, an address outside AWS, so it is the 0.75 line; and it probes over HTTPS,
which AWS's pricing page counts as one of the optional features, with string matching, the 10-second
interval and latency measurement. That adds the 2.00 line, so the one check costs 2.75 dollars a
month. A shop answering ten million queries a month from simple records pays 4 dollars for them,
and nothing for the ones the alias at the apex answers.
