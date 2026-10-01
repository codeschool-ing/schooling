---
title: Going inline, and blocking
version: 1
---

`lab.sh inline` unplugs `fw`'s DMZ cable from the DMZ switch, plugs it into `ips`, and connects `ips`'s
other interface to the switch. `ips` has two interfaces and no address, like a length of cable with a
brain in the middle:

```
root@ips:~# ip -br link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
eth0@if801       UP             5e:8c:67:f7:30:7f <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth1@if830       UP             32:9b:ad:de:b6:95 <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

**With nothing running on it, nothing gets through**:

```
ana@remote:~$ curl -s -m3 http://www.example.com/; echo "exit $?"
exit 28
```

The shop is unreachable, because a cable that ends in a machine that forwards nothing is a cut cable.
Suricata is what joins the two sides: in its IPS mode it reads each packet on one interface, decides,
and writes it to the other. The same rule as the sensor's, with one word changed and its revision
raised:

```
root@ips:~# cat /etc/suricata/rules/local.rules
drop http $EXTERNAL_NET any -> $HOME_NET any (msg:"admin path requested from outside"; flow:to_server,established; http.uri; content:"/admin"; startswith; classtype:policy-violation; sid:1000101; rev:2;)
root@ips:~# suricata -c /etc/suricata/suricata.yaml --include /etc/suricata/inline.yaml --af-packet -D --pidfile /var/log/suricata/suricata.pid
Info: conf-yaml-loader: Configuration node 'af-packet' redefined.
Info: conf-yaml-loader: Configuration node 'livedev' redefined.
i: suricata: This is Suricata version 7.0.3 RELEASE running in SYSTEM mode
```

`drop` instead of `alert`. The `inline.yaml` beside the main configuration pairs `eth0` with `eth1` in
both directions. Now the shop, and then the admin path:

```
ana@remote:~$ curl -s -m3 http://www.example.com/; echo "exit $?"
orders service: ok
exit 0
ana@remote:~$ curl -s -m3 http://www.example.com/admin/; echo "exit $?"
exit 28
```

The shop answers; **the admin request times out**. Suricata saw the path in the first packet of the
request, dropped it, and dropped the rest of that connection. The log records it with a different word:

```
root@ips:~# jq -c "select(.event_type==\"alert\") | [.alert.action, .alert.signature_id, .src_ip, .http.url]" /var/log/suricata/eve.json
["blocked",1000101,"203.0.113.50","/admin/"]
```

`blocked`. The same rule, the same traffic, and this time the request never reached `www`. One word in
the rule and one cable in the wiring make the whole difference between the two systems.
