---
title: Records, written as a batch of changes
version: 1
---

**Route 53 has no command that adds one record.** Every change to a zone is a **change batch**: a
list of actions, `CREATE`, `UPSERT` or `DELETE`, each on one record set. It goes in a single request
that is applied whole or not at all. The wrong picture is a table you edit row by row. A batch is
closer to a transaction. That is what makes it safe to move a name from one address to another
without a moment in which it points at neither.

## The shop's first records

A **record set** is a name, a type and the values that answer for them: `mail.shop.example.com`, type
`A`, value `203.0.113.25`. The batch below writes the five types most zones are made of. Save it as
`~/aws/records.json`:

```json
{
  "Comment": "the shop's first records",
  "Changes": [
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "mail.shop.example.com", "Type": "A", "TTL": 3600,
      "ResourceRecords": [{"Value": "203.0.113.25"}]}},
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "mail.shop.example.com", "Type": "AAAA", "TTL": 3600,
      "ResourceRecords": [{"Value": "2001:db8::25"}]}},
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "shop.example.com", "Type": "MX", "TTL": 3600,
      "ResourceRecords": [{"Value": "10 mail.shop.example.com"}]}},
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "shop.example.com", "Type": "TXT", "TTL": 3600,
      "ResourceRecords": [{"Value": "\"v=spf1 mx -all\""}]}},
    {"Action": "CREATE", "ResourceRecordSet": {
      "Name": "www.shop.example.com", "Type": "CNAME", "TTL": 300,
      "ResourceRecords": [{"Value": "shop.example.com"}]}}
  ]
}
```

| type | answers with | here |
|---|---|---|
| `A` | an IPv4 address | the mail server, at an address from the documentation range |
| `AAAA` | an IPv6 address | the same server, at an address from `2001:db8::/32`, IPv6's documentation range |
| `MX` | a mail server for the domain, with a preference | lower numbers are tried first |
| `TXT` | free text | an SPF policy: only the domain's own MX may send its mail |
| `CNAME` | another name, to be looked up instead | `www` is whatever the bare domain is |

A `TXT` value carries its own double quotes inside the JSON string, which is why they are escaped.
That is how Route 53 wants text records written. Send the batch:

```
ana@laptop:~/aws$ aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch file://records.json
{
    "ChangeInfo": {
        "Id": "/change/C2682N5HXP0BZ4",
        "Status": "INSYNC",
        "SubmittedAt": "2026-10-16T16:00:25.839195+00:00"
    }
}
```

## Whether a change has arrived

**`ChangeInfo` is a receipt, and its `Id` is how you ask about the change later.** Against AWS a new
change answers `PENDING` and becomes `INSYNC` once every Route 53 name server has it, which AWS
documents as usually within 60 seconds. A deployment script waits for it with
`aws route53 wait resource-record-sets-changed --id …` before telling anybody the name has moved.
Your change id will differ from the one below.

```
ana@laptop:~/aws$ aws route53 get-change --id /change/C2682N5HXP0BZ4
{
    "ChangeInfo": {
        "Id": "C2682N5HXP0BZ4",
        "Status": "INSYNC",
        "SubmittedAt": "2026-10-16T16:00:26.505955+00:00"
    }
}
ana@laptop:~/aws$ aws route53 get-change --id /change/NOSUCHCHANGE
{
    "ChangeInfo": {
        "Id": "NOSUCHCHANGE",
        "Status": "INSYNC",
        "SubmittedAt": "2026-10-16T16:00:27.013432+00:00"
    }
}
```

moto answered `INSYNC` at once, and the second command shows how little that means: **moto answers
`INSYNC` for a change id that never existed**. Use `get-change` in moto to learn the shape of the
answer, never as evidence that something was applied. The zone itself is the evidence:

```
ana@laptop:~/aws$ aws route53 list-resource-record-sets --hosted-zone-id $zone --query "ResourceRecordSets[].[Name,Type,TTL,join(' ', ResourceRecords[].Value)]" --output text
shop.example.com.	MX	3600	10 mail.shop.example.com
shop.example.com.	NS	172800	ns-2048.awsdns-64.com ns-2049.awsdns-65.net ns-2050.awsdns-66.org ns-2051.awsdns-67.co.uk
shop.example.com.	SOA	900	{'Value': 'ns-2048.awsdns-64.com. hostmaster.example.com. 1 7200 900 1209600 86400'}
shop.example.com.	TXT	3600	"v=spf1 mx -all"
mail.shop.example.com.	A	3600	203.0.113.25
mail.shop.example.com.	AAAA	3600	2001:db8::25
www.shop.example.com.	CNAME	300	shop.example.com
```

Sending the same file again shows the batch is **one unit**. The first action already fails, so
none of the five is applied twice, and the error names the record that stopped it:

```
ana@laptop:~/aws$ aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch file://records.json

aws: [ERROR]: An error occurred (InvalidChangeBatch) when calling the ChangeResourceRecordSets operation: Tried to create resource record set [name='mail.shop.example.com.', type='A'] but it already exists
```

`UPSERT` is the action that does not care whether the record exists: it creates it or replaces it.
It is what a script uses when it runs every day. `CREATE` is what you use when an existing record
would be a surprise worth stopping for.

## The apex, and why a CNAME cannot sit there

The shop's own name, `shop.example.com` with nothing in front, is the **zone apex**, and it should
lead to the load balancer. A load balancer has no fixed address, only a name AWS gives it, so the
obvious record is a `CNAME`. **The DNS standard forbids it**: a name that has a `CNAME` may have no
other record. The apex always has at least two, the NS and the SOA, plus the MX and TXT the batch
just wrote. Here is moto accepting it anyway:

```
ana@laptop:~/aws$ aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch '{"Changes":[{"Action":"CREATE","ResourceRecordSet":{"Name":"shop.example.com","Type":"CNAME","TTL":300,"ResourceRecords":[{"Value":"shop-web-1.sa-east-1.elb.amazonaws.com"}]}}]}'
{
    "ChangeInfo": {
        "Id": "/change/C2682N5HXP0BZ4",
        "Status": "INSYNC",
        "SubmittedAt": "2026-10-16T16:00:29.095461+00:00"
    }
}
```

**AWS refuses that batch with `InvalidChangeBatch`; moto 5.2.3 stored the record.** It is the
clearest case in this lesson of moto checking less than AWS. The answer is the usual one: delete
what moto should never have accepted.

```
ana@laptop:~/aws$ aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch '{"Changes":[{"Action":"DELETE","ResourceRecordSet":{"Name":"shop.example.com","Type":"CNAME","TTL":300,"ResourceRecords":[{"Value":"shop-web-1.sa-east-1.elb.amazonaws.com"}]}}]}' --query ChangeInfo.Status --output text
INSYNC
```

**An alias record is Route 53's answer.** It is an `A` or `AAAA` record whose value is not an
address but a pointer to an AWS resource: a load balancer, a CloudFront distribution, an S3 website,
another record in the same zone. Route 53 looks the target up itself and answers with **its current
addresses**. To the resolver asking, it is an ordinary `A` record, and an ordinary `A` record is
allowed at the apex. The pointer needs the target's name and the hosted zone AWS keeps it in, and
the load balancer says both:

```
ana@laptop:~/aws$ aws elbv2 describe-load-balancers --names shop-web --query "LoadBalancers[0].[DNSName,CanonicalHostedZoneId]" --output text
shop-web-1.sa-east-1.elb.amazonaws.com	Z2P70J7EXAMPLE
```

`Z2P70J7EXAMPLE` is moto's placeholder. AWS publishes one real id per region and per kind of load
balancer, and `describe-load-balancers` prints the right one. Save the alias as `~/aws/apex.json`:

```json
{
  "Changes": [
    {"Action": "UPSERT", "ResourceRecordSet": {
      "Name": "shop.example.com", "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "Z2P70J7EXAMPLE",
        "DNSName": "shop-web-1.sa-east-1.elb.amazonaws.com",
        "EvaluateTargetHealth": true}}}
  ]
}
```

```
ana@laptop:~/aws$ aws route53 change-resource-record-sets --hosted-zone-id $zone --change-batch file://apex.json --query ChangeInfo.Status --output text
INSYNC
ana@laptop:~/aws$ aws route53 list-resource-record-sets --hosted-zone-id $zone --query "ResourceRecordSets[?Name=='shop.example.com.'].[Type,TTL,AliasTarget.DNSName]" --output text
A	None	shop-web-1.sa-east-1.elb.amazonaws.com
MX	3600	None
NS	172800	None
SOA	900	None
TXT	3600	None
```

**An alias has no TTL of its own**, which is why the listing printed `None` in its TTL column: the
answer carries the target's. `EvaluateTargetHealth` makes Route 53 count the alias as unhealthy when
the load balancer has no healthy targets. That matters once there is another record to fall back to,
as the next section builds. And a query that Route 53 answers from an alias to an AWS resource is **free**,
where the same answer from a `CNAME` is billed. The last section reads that line of the price list.

## TTL, and what "propagation" really is

**A TTL is a promise to every resolver that caches the answer**: keep this for 3,600 seconds and do
not ask again. It is the one number in a record that decides how fast a change is seen.

The common wrong picture is that a DNS change "propagates" across the internet over a day or two,
slowly, the way news spreads. **Nothing is pushed anywhere.** Within about a minute every Route 53
name server has the new answer. What takes time is **the caches that already hold the old one**. A
resolver that asked five minutes before the change keeps its copy until the TTL it was given runs
out, and a TTL of 86,400 means a day. So the delay is chosen in advance, by whoever wrote the TTL.

The working habit follows from that. A day before moving a name, lower its TTL to 60 seconds, and
wait one old TTL so that every cache has the short one. Then make the change, and raise the TTL
again once the new address has proved itself. A low TTL costs queries, because resolvers ask more
often, and queries are what Route 53 bills.

The delegation is the exception, and it is slow for the same reason. The `.com` registry's NS
records carry a TTL of two days, set by the registry and not by you. So changing name servers at the
registrar is the one DNS change that really does take that long.
