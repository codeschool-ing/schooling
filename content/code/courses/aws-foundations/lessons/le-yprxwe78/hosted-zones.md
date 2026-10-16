---
title: Hosted zones, public and private
version: 1
---

**A hosted zone is the set of records Route 53 answers for one domain**, and it comes in two kinds.
A **public** zone answers anybody on the internet who asks about `shop.example.com`. A **private**
zone answers only inside the VPCs it is associated with. The common wrong picture is that creating a
public zone puts the name on the internet. It does not. A zone is a set of answers waiting for
somebody to ask. **Nobody asks until the parent domain sends them there**, which is the delegation
at the end of this section.

## Starting from an empty AWS

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS. Lessons 16 and 17 build the shop's production network in full. This lesson needs only
a piece of it: the VPC `10.20.0.0/16`, two subnets in two zones, and a load balancer for a record to
point at, which lesson 22 explains. Type this into the second terminal:

```sh
vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)
aws ec2 modify-vpc-attribute --vpc-id "$vpc" --enable-dns-hostnames '{"Value": true}'
a=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.0.0/24 \
  --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
b=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.1.0/24 \
  --availability-zone sa-east-1b --query Subnet.SubnetId --output text)
aws elbv2 create-load-balancer --name shop-web --subnets "$a" "$b" > /dev/null
```

It prints nothing. `vpc`, `a` and `b` are **shell variables**: they live in this terminal, the
commands below read `$vpc` out of it, and a new terminal would not have them.

## A public zone

```
ana@laptop:~/aws$ aws route53 create-hosted-zone --name shop.example.com --caller-reference shop-public-2026-10-16
{
    "Location": "https://route53.amazonaws.com/2013-04-01/hostedzone/2NCCO4P25PQ1BWXHJIBIIS",
    "HostedZone": {
        "Id": "/hostedzone/2NCCO4P25PQ1BWXHJIBIIS",
        "Name": "shop.example.com.",
        "CallerReference": "shop-public-2026-10-16",
        "Config": {
            "PrivateZone": false
        },
        "ResourceRecordSetCount": 2
    },
    "ChangeInfo": {
        "Id": "/change/C1PA6795UKMFR9",
        "Status": "INSYNC",
        "SubmittedAt": "2026-10-16T16:00:21.362804+00:00"
    },
    "DelegationSet": {
        "Id": "",
        "CallerReference": "DelSet_shop.example.com.",
        "NameServers": [
            "ns-2048.awsdns-64.com",
            "ns-2049.awsdns-65.net",
            "ns-2050.awsdns-66.org",
            "ns-2051.awsdns-67.co.uk"
        ]
    }
}
```

Three things in that answer are worth reading slowly.

**The address in `Location` has no region in it.** Route 53 is a **global** service: one set of
zones for the whole account, whatever region `env.sh` names, served from AWS's locations around the
world. The command line sends it to `route53.amazonaws.com` and signs it for `us-east-1`, which is
where its control plane lives. The `cloud` course, lesson 9, has what that means on the day Virginia
has a bad afternoon.

**`DelegationSet` names four name servers, in four top-level domains**: `.com`, `.net`, `.org` and
`.co.uk`. Those four machines will answer for the zone. Spreading them over four domains means a
failure in one of those domains does not take the shop's name with it. moto prints the same four
names for every zone. AWS gives each zone its own set, and **the set is chosen when the zone is
created**, which matters further down.

**`--caller-reference` is a guard against creating the zone twice.** A script that times out and
tries again sends the same reference. AWS refuses the second with `HostedZoneAlreadyExists` rather
than leaving two zones of the same name. moto 5.2.3 does not keep that promise: sent the same
reference again, it created a second zone. Make the reference unique per zone, and do not lean on
moto to catch a repeat.

The zone's id is the handle every later command takes, so keep it in a variable too. Yours will be
a different string, as every id moto invents is:

```
ana@laptop:~/aws$ zone=$(aws route53 list-hosted-zones-by-name --dns-name shop.example.com --query "HostedZones[0].Id" --output text)
ana@laptop:~/aws$ echo $zone
/hostedzone/2NCCO4P25PQ1BWXHJIBIIS
```

A new zone is not empty. It already holds the two records that make it a zone:

```
ana@laptop:~/aws$ aws route53 list-resource-record-sets --hosted-zone-id $zone --query "ResourceRecordSets[].[Type,TTL,join(' ', ResourceRecords[].Value)]" --output text
NS	172800	ns-2048.awsdns-64.com ns-2049.awsdns-65.net ns-2050.awsdns-66.org ns-2051.awsdns-67.co.uk
SOA	900	{'Value': 'ns-2048.awsdns-64.com. hostmaster.example.com. 1 7200 900 1209600 86400'}
```

**The NS record lists the zone's own name servers**, the same four as the delegation set, with a TTL
of 172,800 seconds: two days. **The SOA record, start of authority, describes the zone itself.** Its
seven fields start with the primary name server, the administrator's mailbox written as a name, and
a serial number. Then come three timers for secondary servers, 7,200, 900 and 1,209,600 seconds. The
last, 86,400, bounds how long a resolver may remember that a name does **not** exist. Its own TTL is
900, and a resolver takes the smaller of the two, so an answer of "no such name" is remembered for
fifteen minutes.

**The braces around that SOA value are moto's.** It stores the record as a small Python dictionary
and prints the dictionary. AWS answers with the plain seven fields. The numbers are the defaults AWS
documents. Change neither record in a real zone without a reason. The NS record has to keep matching
what the parent domain says, and the SOA's timers are what every resolver on the internet has been
told.

## A private zone

A private zone answers **only to machines inside the VPCs associated with it**. The shop's servers
can then find `db.shop.internal` without that name existing anywhere a stranger can look it up.

```
ana@laptop:~/aws$ aws route53 create-hosted-zone --name shop.internal --caller-reference shop-private-2026-10-16 --vpc VPCRegion=sa-east-1,VPCId=$vpc --hosted-zone-config PrivateZone=true,Comment="inside shop-prod" --query "[HostedZone.Name,HostedZone.Config.PrivateZone]" --output text
shop.internal.	True
```

**The association is the point**, and it can be asked from the VPC's side as well as the zone's:
which zones does this network see?

```
ana@laptop:~/aws$ aws route53 list-hosted-zones-by-vpc --vpc-id $vpc --vpc-region sa-east-1 --query "HostedZoneSummaries[].[HostedZoneId,Name]" --output text
30N3SH0VOW90OXXX40SLW9	shop.internal.
```

Inside the VPC, a machine sends its DNS questions to the **Route 53 Resolver**, at the VPC's base
address plus two, `10.20.0.2` here. The Resolver answers from the private zones associated with the
VPC first, and from the public internet for everything else. It only does that while the VPC's
`enableDnsSupport` and `enableDnsHostnames` attributes are both on. That is why the setup above
turned the second one on: a new VPC starts with it off. **None of that was run here.** moto stores
the association and has no Resolver and no machine to ask it, so the answering half is AWS's
documented behaviour.

Two details that save an afternoon. A private zone can be associated with more VPCs later, with
`associate-vpc-with-hosted-zone`, including a VPC in another account once that account is
authorised. And a public and a private zone may have **the same name**: inside the VPC the private
one answers, outside it the public one does. That arrangement is called split-horizon DNS. It is how
one name can lead to an internal address for the shop's own machines and a public one for everybody
else.

moto 5.2.3 also needs `PrivateZone=true` spelt out. Given `--vpc` alone, it made a public zone.

## Registering the domain, and handing it over

**Nothing in this part was run**, for two reasons. Registering a domain costs money and needs an
account. And nobody can register `example.com`: it is reserved for documentation, which is why every
course uses it.

A domain is bought from a **registrar**, and the registrar records it with the **registry** of its
top-level domain. That is Verisign for `.com` and Registro.br for `.com.br`, which is where a shop
in São Paulo would most likely buy its name. Route 53 is also a registrar, under the API
`route53domains`, whose endpoint exists only in `us-east-1`. Registered there, the domain gets a
hosted zone and its name servers set for you.

Bought elsewhere, the step is yours, and it is the step that **delegates** the name. In the
registrar's form, replace its name servers with the four from the zone's delegation set. The
registry then publishes NS records for `shop.example.com` in the `.com` zone. From then on, a
resolver anywhere that asks about the shop is sent to Route 53.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" data-fig=\"l21-delegation\" aria-label=\"How a resolver finds the shop, drawn as a sequence with time running downwards. Four columns: a resolver, the root servers, the .com servers, and Route 53, whose name server is ns-2048.awsdns-64.com. Step 1, the resolver asks the root about mail.shop.example.com; step 2, the root answers: ask .com. Step 3, it asks the .com servers; step 4, they answer: ask ns-2048.awsdns-64.com. Step 5, it asks Route 53; step 6, Route 53 answers with the record, 203.0.113.25. Under the .com column, the registrar, which wrote the four NS names that step 4 answers with. Only step 6 reads the hosted zone.\"><defs><marker id=\"l21-delegation-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l21-delegation-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l21-delegation-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10.0\" y=\"20.0\" width=\"160.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a resolver</text><path d=\"M90.0 66.0 L90.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.0\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"200.0\" y=\"20.0\" width=\"160.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the root</text><path d=\"M280.0 66.0 L280.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.0\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"370.0\" y=\"20.0\" width=\"160.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the .com servers</text><path d=\"M450.0 66.0 L450.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.0\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"540.0\" y=\"20.0\" width=\"160.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Route 53</text><text x=\"620.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ns-2048.awsdns-64.com</text><path d=\"M620.0 66.0 L620.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.0\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M92.0 95.0 L277.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-paper-dim)\"></path><text x=\"102.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">mail.shop.example.com?</text><circle cx=\"56.0\" cy=\"95.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></circle><text x=\"56.0\" y=\"95.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M278.0 125.0 L95.0 125.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-amber)\"></path><text x=\"270.0\" y=\"116.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ask .com</text><circle cx=\"56.0\" cy=\"125.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"56.0\" y=\"125.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">2</text><path d=\"M92.0 165.0 L447.0 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-paper-dim)\"></path><text x=\"102.0\" y=\"156.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">mail.shop.example.com?</text><circle cx=\"56.0\" cy=\"165.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></circle><text x=\"56.0\" y=\"165.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">3</text><path d=\"M448.0 195.0 L95.0 195.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-amber)\"></path><text x=\"440.0\" y=\"186.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ask ns-2048.awsdns-64.com</text><circle cx=\"56.0\" cy=\"195.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"56.0\" y=\"195.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">4</text><path d=\"M92.0 235.0 L617.0 235.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-paper-dim)\"></path><text x=\"102.0\" y=\"226.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">mail.shop.example.com?</text><circle cx=\"56.0\" cy=\"235.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></circle><text x=\"56.0\" y=\"235.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">5</text><path d=\"M618.0 265.0 L95.0 265.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-phosphor)\"></path><text x=\"610.0\" y=\"256.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the record: 203.0.113.25</text><circle cx=\"56.0\" cy=\"265.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"56.0\" y=\"265.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">6</text><rect x=\"370.0\" y=\"322.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450.0\" y=\"340.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the registrar</text><text x=\"450.0\" y=\"357.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">wrote the four NS names</text><path d=\"M450.0 319.0 L450.0 304.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-amber)\"></path><text x=\"360.0\" y=\"392.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">time runs downwards; only step 6 reads the hosted zone</text></svg>", "caption": "Creating a zone is step 6. Steps 3 and 4 are the delegation, and the registrar writes them."}
```

**The delegation names servers, not a zone**, and that is the trap. Delete the hosted zone and
create it again, and the new zone gets a new set of four. The registry still points at the old ones,
which now answer for nothing. The shop's name stops working everywhere as the resolvers' copies
expire. Before deleting a public zone, look at what the registrar says.

## What a zone costs

```
ana@laptop:~/aws$ python3 price.py AmazonRoute53 20260911124504 aws-other HostedZone
AmazonRoute53 20260911124504, published 2026-09-11, USD
HostedZone
          0 to        25 HostedZone 0.5000
         25 to       Inf HostedZone 0.1000
```

**Route 53's offer files its global prices under the region code `aws-other`**, because a hosted
zone belongs to no region. The `sa-east-1` file of the same offer holds only what does run in a
region, the Resolver's endpoints and the DNS firewall. In the list AWS published on **11 September
2026**: 0.50 dollars a month for each of the first 25 zones, 0.10 for each one after. AWS's pricing
page adds two rules the lines do not carry. The monthly charge is not split by day, and a zone
deleted within 12 hours of being created is not charged. The shop's two zones cost a dollar a month
before anybody asks them anything. The answers have a price of their own, which the last section of
this lesson reads.
