---
title: Going inline, and blocking
version: 1
---

One more script rewires the lab: it unplugs `fw`'s DMZ cable from the DMZ switch, plugs it into `ips`,
and connects `ips`'s other interface to the switch. Save it beside `nslab.sh` and run it on a lab that
is up, with `sudo bash inline.sh`. Stop the sensor's Suricata first, with
`kill -INT $(cat /var/log/suricata/suricata.pid)` on `sensor`; from here on the engine runs on `ips`:

```schooling-example
{"language": "sh", "file": "inline.sh", "parts": [{"code": "#!/bin/bash\n# inline.sh: run after nslab.sh up, from the same directory.\n#   sudo bash inline.sh\nset -euo pipefail\nLAB=/lab\n[ -e /run/netns/wire ] || { echo \"the lab is not up: sudo bash nslab.sh up\" >&2; exit 1; }\n[ -e /run/netns/ips ] && { echo \"ips is already inline: sudo bash nslab.sh reset, then run this again\" >&2; exit 1; }\nfwport=$(ip -n wire -o link show master br-dmz | awk -F': ' '{print $2}' | grep -- '-fw@' | cut -d@ -f1)\nip netns add ips\nip -n ips link set lo up\nip -n wire link set \"$fwport\" nomaster\nip -n wire link set \"$fwport\" netns ips\nip -n ips link set \"$fwport\" name eth0\nip link add i-ips type veth peer name lab-ips\nip link set lab-ips netns ips\nip -n ips link set lab-ips name eth1\nip link set i-ips netns wire\nip -n wire link set i-ips master br-dmz\nip -n wire link set i-ips up", "note": "Lesson 14's intrusion prevention: a machine called `ips` put **inline** on the cable between `fw` and the DMZ. `fw`'s DMZ cable is unplugged from the DMZ switch and plugged into `ips`'s first card; its second card goes to the switch. From then on nothing passes between `fw` and the DMZ without crossing `ips`."}, {"code": "for i in eth0 eth1; do\n  ip -n ips link set \"$i\" up\n  ip netns exec ips ethtool -K \"$i\" gro off gso off tso off >/dev/null 2>&1 || true\ndone\nip netns exec fw ethtool -K eth1 tx off >/dev/null 2>&1 || true\nfor h in www dns; do ip netns exec \"$h\" ethtool -K eth0 tx off >/dev/null 2>&1 || true; done\nmkdir -p \"/etc/netns/ips\" \"$LAB/ips/root\" \"$LAB/ips/home\" \"$LAB/ips/var/log/suricata\" \"$LAB/ips/var/lib/suricata\"\nprintf 'ips\\n' > /etc/netns/ips/hostname\nmkdir -p \"$LAB/ips/etc\"\ncp -a \"$LAB/sensor/etc/suricata\" \"$LAB/ips/etc/\"", "note": "Virtual cables leave each TCP checksum for network hardware to fill in, and there is none. A packet Suricata copies from one card to the other would leave with an unfinished checksum and be dropped, so the machines on both sides are told to compute their own."}, {"code": "cat > \"$LAB/ips/etc/suricata/inline.yaml\" <<'Y'\n%YAML 1.1\n---\naf-packet:\n  - interface: eth0\n    copy-mode: ips\n    copy-iface: eth1\n    cluster-id: 98\n    cluster-type: cluster_flow\n    defrag: no\n  - interface: eth1\n    copy-mode: ips\n    copy-iface: eth0\n    cluster-id: 97\n    cluster-type: cluster_flow\n    defrag: no\nlivedev:\n  use-for-tracking: false\nY", "note": "`ips` gets a copy of the sensor's Suricata configuration and `inline.yaml`, which joins its two cards: whatever arrives on one leaves by the other, unless a rule drops it. With `use-for-tracking` off, a connection is one flow across both cards; on, Suricata 7 keeps a flow per card, sees every answer as a stranger, and drops it."}]}
```

Now `ips` has two interfaces and no address, like a length of cable with a
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
