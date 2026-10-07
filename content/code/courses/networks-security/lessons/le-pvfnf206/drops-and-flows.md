---
title: Reading drops and flows
version: 1
---

Four packets were refused, so the drop log has four lines. One of them, whole:

```
root@fw:~# wc -l /var/log/lab/drops.json
4 /var/log/lab/drops.json
root@fw:~# head -1 /var/log/lab/drops.json | jq .
{
  "timestamp": "2026-09-28T18:52:30.943369-0300",
  "dvc": "Netfilter",
  "raw.pktlen": 60,
  "raw.pktcount": 1,
  "oob.prefix": "forward-drop",
  "oob.time.sec": 1790632350,
  "oob.time.usec": 943369,
  "oob.mark": 0,
  "oob.ifindex_in": 1939,
  "oob.ifindex_out": 1945,
  "oob.hook": 2,
  "raw.mac_len": 14,
  "oob.family": 2,
  "oob.protocol": 2048,
  "raw.label": 0,
  "raw.type": 1,
  "raw.mac.addrlen": 6,
  "ip.protocol": 6,
  "ip.tos": 0,
  "ip.ttl": 63,
  "ip.totlen": 60,
  "ip.ihl": 5,
  "ip.csum": 2260,
  "ip.id": 37733,
  "ip.fragoff": 16384,
  "src_port": 43936,
  "dest_port": 5432,
  "tcp.seq": 2289721423,
  "tcp.ackseq": 0,
  "tcp.window": 64240,
  "tcp.offset": 0,
  "tcp.reserved": 0,
  "tcp.urg": 0,
  "tcp.ack": 0,
  "tcp.psh": 0,
  "tcp.rst": 0,
  "tcp.syn": 1,
  "tcp.fin": 0,
  "tcp.res1": 0,
  "tcp.res2": 0,
  "tcp.csum": 40881,
  "oob.in": "eth2",
  "oob.out": "eth3",
  "src_ip": "192.168.10.20",
  "dest_ip": "192.168.20.30"
}
```

Most of these fields describe the packet's headers, and a few carry nearly all the meaning: the time,
the prefix that names the rule, the interfaces it came in and would have gone out of, and the two
addresses and ports. `tcp.syn` is 1 and `tcp.ack` is 0: it is the first packet of a connection that
never happened. The same four lines, cut down to those fields:

```
root@fw:~# jq -c '[.timestamp, .src_ip, .dest_ip, .dest_port, ."oob.in", ."oob.out"]' /var/log/lab/drops.json
["2026-09-28T18:52:30.943369-0300","192.168.10.20","192.168.20.30",5432,"eth2","eth3"]
["2026-09-28T18:52:32.063164-0300","203.0.113.50","192.0.2.80",22,"eth0","eth1"]
["2026-09-28T18:52:33.066979-0300","203.0.113.50","192.0.2.53",22,"eth0","eth1"]
["2026-09-28T18:52:34.071430-0300","203.0.113.50","192.168.20.30",5432,"eth0","eth3"]
```

The first is the laptop trying the database, which the policy has never allowed; the other three are
`remote`, one second apart, against three machines on two segments. **One second apart across three
machines is a scan**, small as it is.

The flow records are written later, and that is the first thing to know about them. A connection's
record is written when the firewall **forgets** it, not when it closes: a closed TCP connection stays in
the table for two minutes, and the kernel notices it has expired up to a minute after that. So wait
three minutes after the traffic before reading them:

```
root@fw:~# wc -l /var/log/lab/flows.json
7 /var/log/lab/flows.json
root@fw:~# jq -c 'select(.src_ip == "203.0.113.50") | {start: ."flow.start.sec", end: ."flow.end.sec", src: .src_ip, dst: .dest_ip, dport: ."orig.l4.dport", sent: ."orig.raw.pktlen", received: ."reply.raw.pktlen"}' /var/log/lab/flows.json
{"start":1790632352,"end":1790632472,"src":"203.0.113.50","dst":"192.0.2.80","dport":80,"sent":402,"received":734}
{"start":1790632351,"end":1790632471,"src":"203.0.113.50","dst":"192.0.2.80","dport":80,"sent":398,"received":437}
```

Two conversations from `remote` to the shop, both on port 80, both allowed. `start` and `end` are in
seconds since 1970: 1790632351 is 18:52:31 in São Paulo, and `end` is exactly 120 seconds later for
both. That is the two minutes of remembering, not the length of the conversation; the requests
themselves took milliseconds. `sent` and `received` are bytes each way. The later flow, which started
at 1790632352, received 734 bytes against the earlier one's 437, because a 404 page is longer than the
lab's front page.

**The refused attempts are not here.** A connection the firewall drops never enters the table as a
confirmed entry, so it never produces a flow record. Flows say what happened; the drop log says what
was stopped. A defender needs both, and neither contains the other.

The question lesson 19 asked, which pairs of machines actually use a rule, is a count over flows:

```
root@fw:~# jq -r '[.src_ip, .dest_ip, ."orig.l4.dport"] | @tsv' /var/log/lab/flows.json | sort | uniq -c | sort -rn
      3 192.0.2.80	192.168.20.10	8080
      2 203.0.113.50	192.0.2.80	80
      1 192.168.10.20	192.168.20.10	8080
      1 192.168.10.20	192.0.2.80	80
```

Three conversations from the proxy to the application, two from `remote` to the shop, one from the
laptop to each. On a real firewall, a week of this per rule shows the pairs that use it, and a rule
that allows a whole segment used by two machines is one to narrow.
