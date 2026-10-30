---
title: Reading an answer with dig
version: 1
---

**A DNS answer is not one fact; it is a chain, and every link has its own owner and its own lifetime.**
The wrong picture is a phone book with a name on one side and an address on the other. Real names
on the internet are often aliases of aliases, each link held in a different zone by a different
company, and the address at the end is the last thing in the chain, not the first. This lesson is
about the part of that chain Azure holds, and it starts by reading a whole one.

Make the lesson's directory and ask for the address of the Azure portal:

```sh
mkdir -p ~/azure/dns && cd ~/azure/dns
```

```
ana@laptop:~/azure/dns$ dig portal.azure.com +noall +answer +nottlid
portal.azure.com.	IN	CNAME	portal-prod-02-linkage.trafficmanager.net.
portal-prod-02-linkage.trafficmanager.net. IN CNAME azureportal.z01.azurefd.net.
azureportal.z01.azurefd.net. IN	CNAME	azurefd-p-prod.trafficmanager.net.
azurefd-p-prod.trafficmanager.net. IN CNAME shed.s-part-19.p-0010.p-msedge.net.
shed.s-part-19.p-0010.p-msedge.net. IN CNAME p-0010.p-msedge.net.
p-0010.p-msedge.net.	IN	A	150.171.84.10
```

Each line is one **record**: a name, the class `IN`, a **type**, and the value. Five of these are
`CNAME`, which says "this name is another name; ask about that one", and the last is an `A`, an IPv4
address. The resolver followed the chain for you and printed every link. Read the names rather than
the address: the first hop is `trafficmanager.net`, Azure Traffic Manager, then `azurefd.net`, Azure
Front Door, then Microsoft's edge network. **Each of those is a service that chooses the next link at
the moment you ask**, by where you are and what is healthy. That is why lesson 22 can build a global
service out of DNS alone, and why this exact chain will not be the one you get.

`+noall +answer` keeps only the answer section; `+nottlid` leaves out the column dig normally prints
between the name and `IN`: the **TTL**, the number of seconds a resolver may keep the record before
asking again. It is left out here because it counts down while you watch, and a transcript that
changed every second would say nothing. On your machine, run the command without `+nottlid` twice a
few seconds apart and see the numbers fall.

## The records a zone holds

Every record above lives in some **zone**: a part of the naming tree one party answers for. These are
the types this lesson writes into the shop's zones, and the one rule about each that catches people:

| type | it holds | the rule that catches people |
|---|---|---|
| `A`, `AAAA` | an IPv4 or IPv6 address | a name may have several, and a client may pick any of them |
| `CNAME` | another name | **a name with a CNAME may have no other record**, so the top of a zone, which must have `NS` and `SOA`, can never be a CNAME |
| `MX` | a mail server's name, with a preference | the value is a name, never an address |
| `TXT` | free text | where a domain proves to a service that it is yours |
| `NS` | the name servers that answer for a zone | in the parent, they hand the zone over; in the zone, they repeat it |
| `SOA` | the zone's own record: its primary server, its serial number, its timers | one per zone, made by Azure, edited rarely |

## What this lab could not ask

`dig` can ask any of those types, and the next section's delegation is checked with `dig NS`. **On the
machine this course was recorded on it gets no answer**: names resolve there through a resolver that
answers address questions for a short list of hosts and nothing else, so `NS`, `SOA` and `TXT`
questions come back empty and no transcript of them is shown. On your own computer the same commands
answer from the real DNS, and the two sections after this one say what to type and what kind of answer
to expect.
