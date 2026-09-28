---
title: Anomalies, which no rule named
version: 1
---

A signature finds what somebody knew to describe. **Anomaly detection** finds what departs from what
is normal, which catches things nobody wrote a rule for, at the price of more false alarms. Suricata
does it at two levels.

**Protocol anomalies.** Suricata parses every HTTP request, and a request that breaks the protocol's
rules raises an event. `http-events.rules`, loaded earlier, turns those events into alerts. A request
from `remote` with no `Host` header, which every HTTP/1.1 request must carry:

```
ana@remote:~$ printf "GET / HTTP/1.1\r\n\r\n" | nc -w2 www.example.com 80 | head -1
HTTP/1.1 400 Bad Request
```

The proxy refused it with `400`, and the sensor noticed:

```
root@sensor:~# jq -c "select(.event_type==\"alert\" and .alert.signature_id!=1000201) | [.alert.signature_id, .alert.signature, .src_ip]" /var/log/suricata/eve.json
[2221014,"SURICATA HTTP missing Host header","203.0.113.50"]
```

Rule 2221014, *SURICATA HTTP missing Host header*. Nobody wrote a rule about this request; the protocol
parser knew what a valid request looks like. Malformed traffic is a useful signal because ordinary
clients do not produce it: scanners, hand-made tools and broken software do.

**Behavioural anomalies** need a baseline: what each machine normally does, so that a departure stands
out. The raw material is the records Suricata writes whether or not anything matched. Two machines ask
the name server questions, one of them rather a lot:

```
ana@remote:~$ for n in www shop mail vpn ftp dev test admin intranet portal; do dig +short @192.0.2.53 $n.example.com >/dev/null; done
ana@laptop:~$ dig +short @192.0.2.53 www.example.com >/dev/null
```

Counting questions per source, from the DNS records alone:

```
root@sensor:~# jq -r "select(.event_type==\"dns\" and .dns.type==\"query\") | .src_ip" /var/log/suricata/eve.json | sort | uniq -c | sort -rn
     10 203.0.113.50
      1 192.168.10.20
```

**Ten questions from `203.0.113.50`, one from `laptop`.** And what the ten asked for:

```
root@sensor:~# jq -r "select(.event_type==\"dns\" and .dns.type==\"query\" and .src_ip==\"203.0.113.50\") | .dns.rrname" /var/log/suricata/eve.json | tr "\n" " "; echo
www.example.com shop.example.com mail.example.com vpn.example.com ftp.example.com dev.example.com test.example.com admin.example.com intranet.example.com portal.example.com 
```

A list of likely host names, tried one after another, is somebody **mapping the company's names** to
find what exists. Each question was harmless and legitimate; no signature would fire on any of them.
The pattern shows only when the records are counted, and a baseline says whether ten is a lot: for a
resolver serving an office, ten names from one source might be a Tuesday; for the public name server,
ten names from one stranger is a survey. Lesson 23 comes back to keeping these records long enough to
build a baseline from.
