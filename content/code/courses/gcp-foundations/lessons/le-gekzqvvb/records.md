---
title: Records, and a zone answering
version: 1
---

**A record is a name, a type, a time to live and the data**, and a zone is a list of them. The types the
planner uses are the ones nearly everybody uses:

| type | says | example |
|---|---|---|
| `A` | the name's IPv4 address | `api` → `203.0.113.20` |
| `CNAME` | the name is another name; ask about that one instead | `www` → `planner.example.com.` |
| `MX` | where mail for the domain goes, with a preference | `10 mail.example.net.` |
| `TXT` | free text, mostly read by machines: mail policies, proofs of ownership | `v=spf1 …` |
| `NS`, `SOA` | which servers answer for the zone, and the zone's own settings | created by Cloud DNS with the zone |

The **TTL** is how many seconds a resolver may keep an answer before asking again. It is the number that
decides how long a change takes to be seen: with 300 seconds, a moved address reaches everybody within five
minutes; with a day, within a day. The planner lowers a record's TTL a day before moving it, and raises it
again afterwards.

## A zone on the laptop

Cloud DNS answers from Google's name servers, which the lab cannot create a zone on. It can do the next best
thing: answer the same records from a **zone file**, the text format DNS has used since the 1980s and the one
Cloud DNS imports and exports. `gcloud dns record-sets import` reads it:

```
ana@laptop:~/gcp$ gcloud dns record-sets import --help | grep -A2 "zone-file-format$"
     --zone-file-format
        Indicates that the input records-file is in BIND zone format. If
        omitted, indicates that the records-file is in YAML format.
```

The lab needs two things it does not have yet: `dig`, the standard tool for asking DNS servers questions, and
`dnslib`, a small Python library that can answer them:

```sh
sudo apt install -y bind9-dnsutils
~/gcp/venv/bin/pip install -q 'dnslib==0.9.26'
mkdir -p ~/gcp/dns && cd ~/gcp/dns
```

Save the planner's public zone as `~/gcp/dns/planner.example.com.zone`. The addresses are from
`203.0.113.0/24`, a range set aside for documentation, and the name servers are written the way Cloud DNS
names its own:

```ini
$ORIGIN planner.example.com.
$TTL 300
@        IN SOA  ns-cloud-a1.googledomains.com. cloud-dns-hostmaster.google.com. 1 21600 3600 259200 300
@        IN NS   ns-cloud-a1.googledomains.com.
@        IN NS   ns-cloud-a2.googledomains.com.
@        IN A    203.0.113.10
www      IN CNAME planner.example.com.
api      IN A    203.0.113.20
@        IN MX   10 mail.example.net.
@        IN TXT  "v=spf1 include:mail.example.net -all"
```

And a server that answers from it, as `serve.py`:

```schooling-example
{"language": "python", "file": "serve.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Answers DNS questions from one zone file, on this laptop only.\n\n    python3 serve.py ZONEFILE\n\nListens on 127.0.0.1, UDP port 5353, until it is stopped.\n\"\"\"\nimport sys\nimport time\n\n", "note": "How it is called: one zone file. It answers only on the laptop's own address, on port 5353, so nothing on the network can ask it and it needs no administrator rights."}, {"code": "from dnslib.server import DNSServer\nfrom dnslib.zoneresolver import ZoneResolver\n\n", "note": "`dnslib` is a small DNS library, installed into the lab's environment above. Its `ZoneResolver` reads a zone file in the same BIND format Cloud DNS imports."}, {"code": "resolver = ZoneResolver(open(sys.argv[1]).read(), glob=True)\nserver = DNSServer(resolver, address='127.0.0.1', port=5353)\nserver.start_thread()\n", "note": "Read the zone and start the server. It answers what the zone holds, says a name that is not there does not exist, and has no opinion about anything outside the zone."}, {"code": "print(f'answering for {sys.argv[1]} on 127.0.0.1:5353')\nwhile server.isAlive():\n    time.sleep(1)\n", "note": "Say it is ready, and keep running until stopped with Control-C."}]}
```

In a second terminal, after `source ~/gcp/env.sh`:

```
ana@laptop:~/gcp/dns$ python3 serve.py planner.example.com.zone
answering for planner.example.com.zone on 127.0.0.1:5353
```

Back in the first, ask it four questions in one command:

```
ana@laptop:~/gcp/dns$ dig @127.0.0.1 -p 5353 +noall +answer planner.example.com A www.planner.example.com A planner.example.com MX planner.example.com TXT
planner.example.com.	300	IN	A	203.0.113.10
www.planner.example.com. 300	IN	CNAME	planner.example.com.
planner.example.com.	300	IN	MX	10 mail.example.net.
planner.example.com.	300	IN	TXT	"v=spf1 include:mail.example.net -all"
```

**`www` answered with a CNAME and nothing else**: the server says what `www` is, another name, and a resolver
would go on to ask about `planner.example.com` itself. Every answer carries its TTL, 300, from the zone's
`$TTL`. Now a name that is not in the zone:

```
ana@laptop:~/gcp/dns$ dig @127.0.0.1 -p 5353 nothing.planner.example.com A | grep -o "status: [A-Z]*"
status: NXDOMAIN
```

`NXDOMAIN`: the name does not exist. That is a real answer, cached like any other, which is why creating a
record a few seconds after somebody asked for it can still look missing to them for a while.

Two rules this server does not enforce and Cloud DNS does. **A CNAME cannot sit beside other records of the
same name**, so the apex, `planner.example.com.` itself, which must have its `SOA` and `NS`, can never be a
CNAME. And every record set in Cloud DNS is a resource of its own, `google_dns_record_set` in Terraform, one
per name and type, with all its values in one list.

Stop the server with Control-C in its terminal when you are done.
