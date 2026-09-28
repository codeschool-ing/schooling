---
title: Three kinds of record
version: 1
---

Every earlier lesson ended with something written down: a drop logged by the firewall in lesson 5, an
alert from the sensor in lesson 14, a line in the switch's port log in lesson 22. Each was read once, on
the machine that wrote it, by the person who had just caused it. That is a demonstration. **A defence
needs the records kept, in one place, for long enough to answer questions nobody has asked yet.**

A network produces three kinds, and they answer different questions:

| record | written by | one record is | it answers |
|---|---|---|---|
| **firewall log** | a `log` rule | one packet the rule matched, usually a refused one | what was **tried** and stopped |
| **flow record** | the firewall's connection tracking, or a router | one conversation: two addresses, two ports, bytes and packets each way, start and end | what **happened**, between which pairs, and how much |
| **IDS alert** | the sensor | one match of a signature, with the HTTP, DNS or TLS details around it | what **looked wrong**, and why the sensor thought so |

None of them holds the content of the conversation. That is deliberate: full packet capture is kept
for minutes or hours on a busy link, and these three are kept for months.

Flow records are the one this course has not built yet. On routers they travel as **NetFlow** or
**IPFIX**, a binary format sent to a collector. On a Linux firewall, the same fields already exist in
**conntrack**, the table lessons 1 and 21 read: every connection the firewall tracks has its addresses
and ports, and with accounting turned on, its packet and byte counts too. The lab writes both the log
and the flows with **ulogd**, as one JSON object per line:

```schooling-example
{"language": "conf", "file": "ulogd.conf", "parts": [{"code": "[global]\nlogfile=\"/var/log/lab/ulogd.log\"\nplugin=\"/usr/lib/x86_64-linux-gnu/ulogd/ulogd_inpflow_NFCT.so\"\nplugin=\"/usr/lib/x86_64-linux-gnu/ulogd/ulogd_inppkt_NFLOG.so\"\nplugin=\"/usr/lib/x86_64-linux-gnu/ulogd/ulogd_raw2packet_BASE.so\"\nplugin=\"/usr/lib/x86_64-linux-gnu/ulogd/ulogd_filter_IFINDEX.so\"\nplugin=\"/usr/lib/x86_64-linux-gnu/ulogd/ulogd_filter_IP2STR.so\"\nplugin=\"/usr/lib/x86_64-linux-gnu/ulogd/ulogd_output_JSON.so\"", "note": "Where ulogd reports on itself, and the plugins it loads: two inputs, a packet decoder, two filters that turn numbers into names, and JSON output."}, {"code": "# one record per connection, written when the firewall forgets it\nstack=ct1:NFCT,ip2str1:IP2STR,flows:JSON\n# one record per packet a log rule sends to group 1\nstack=log1:NFLOG,base1:BASE,ifi1:IFINDEX,ip2str2:IP2STR,drops:JSON", "note": "Two stacks. The first reads connection tracking and writes a flow record when a connection ends. The second reads packets sent by a log rule to group 1."}, {"code": "[ct1]\nevent_mask=0x00000005", "note": "0x5 asks for two events, a new connection and a destroyed one, so each record carries its start as well as its end."}, {"code": "[log1]\ngroup=1", "note": "The group number matches the one in the firewall's log rule."}, {"code": "[flows]\nfile=\"/var/log/lab/flows.json\"\nsync=1\n\n[drops]\nfile=\"/var/log/lab/drops.json\"\nsync=1", "note": "Each stack writes its own file, one JSON object per line, flushed as it is written."}]}
```

The administrator turns on the counters, adds a log rule at the end of the forward chain, where it only
sees what every rule above it refused, and starts ulogd:

```
root@fw:~# sysctl net.netfilter.nf_conntrack_acct=1 net.netfilter.nf_conntrack_timestamp=1
net.netfilter.nf_conntrack_acct = 1
net.netfilter.nf_conntrack_timestamp = 1
root@fw:~# nft 'add rule ip filter forward log group 1 prefix "forward-drop"'
root@fw:~# ulogd -d -c /root/ulogd.conf
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Where the lesson&#x27;s records are made and where they end up. On fw, ulogd writes drops.json from the log rule and flows.json from connection tracking, and rsyslog sends every new line over TCP port 514 to admin, on the management network. The sensor writes eve.json, which in a real network reaches admin over a management link of its own. admin&#x27;s firewall accepts port 514 from fw and nothing else, so fw can add lines but cannot log in to change them.\"><defs><marker id=\"co-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"co-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"co-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"250\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw</text><rect x=\"35\" y=\"60\" width=\"105\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"45\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">drops.json</text><text x=\"45\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">log rule</text><rect x=\"150\" y=\"60\" width=\"105\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">flows.json</text><text x=\"160\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">conntrack</text><text x=\"32\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ulogd writes, rsyslog ships</text><rect x=\"20\" y=\"180\" width=\"250\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sensor</text><text x=\"30\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eve.json: alerts, HTTP, flows</text><rect x=\"450\" y=\"30\" width=\"250\" height=\"200\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"462\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">admin</text><text x=\"462\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">collector, on the management network</text><rect x=\"465\" y=\"85\" width=\"220\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"475\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/var/log/lab/remote/</text><text x=\"475\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">fw/drops.json  fw/flows.json</text><rect x=\"465\" y=\"145\" width=\"220\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"475\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">correlate.py</text><text x=\"475\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one timeline per address</text><path d=\"M270 80 L450 80\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#co-ah-phosphor)\"></path><text x=\"360\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">tcp/514</text><path d=\"M270 120 L450 120\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#co-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"360\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ssh: dropped</text><path d=\"M270 205 L450 205\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#co-ah-paper-dim)\" stroke-dasharray=\"4 3\"></path><text x=\"360\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own management link</text></svg>", "caption": "Records are written where things happen and kept where nobody who is watched can reach them."}
```

Then a short, ordinary stretch of traffic. Two staff requests and one the policy refuses:

```
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" http://www.example.com/
200
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" http://app:8080/
200
ana@laptop:~$ probe db:5432
db:5432                blocked
```

And a stranger on the internet, `remote`, who loads the shop's front page, asks for a file that
should never be public, and then tries three ports:

```
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" http://www.example.com/
200
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" http://www.example.com/.env
404
ana@remote:~$ probe 192.0.2.80:22 192.0.2.53:22 192.168.20.30:5432
192.0.2.80:22          blocked
192.0.2.53:22          blocked
192.168.20.30:5432     blocked
```

The next section reads what that left behind.
