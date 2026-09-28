---
title: The anatomy of a rule
version: 1
---

The rule this lesson loads on `sensor` counts login attempts arriving from outside:

```
root@sensor:~# cat /etc/suricata/rules/local.rules
alert http $EXTERNAL_NET any -> $HOME_NET any (msg:"login form posted from outside"; flow:to_server,established; http.method; content:"POST"; http.uri; content:"/login"; startswith; detection_filter:track by_src, count 10, seconds 60; classtype:attempted-user; sid:1000201; rev:1;)
```

Engines read a rule as one line, and a backslash at the end of a line continues it, which is how it is split here. Every part does something:

```schooling-example
{"language": "conf", "file": "/etc/suricata/rules/local.rules", "parts": [{"code": "alert http \\", "note": "The **action** and the **protocol**. `alert` writes an event; lesson 14 used `drop`. `http` means the application protocol as Suricata recognised it, on any port. Snort 2 writes `tcp` here and matches the port instead."}, {"code": "$EXTERNAL_NET any -> $HOME_NET any \\", "note": "The **header**: from any address outside the company, any source port, to any address inside, any port. The variables come from `suricata.yaml`, where this lab's `HOME_NET` lists its own ranges."}, {"code": "(msg:\"login form posted from outside\"; \\", "note": "The text an analyst reads. Written for the person, not the engine."}, {"code": " flow:to_server,established; \\", "note": "Only the client's half of a connection whose handshake completed. Rules that skip this match stray packets and forged ones."}, {"code": " http.method; content:\"POST\"; http.uri; content:\"/login\"; startswith; \\", "note": "Two **sticky buffers**: `http.method` points the next `content` at the request method, `http.uri` points the one after at the path. Each content matches only inside its buffer, so `/login` in a cookie or a form field does not count."}, {"code": " detection_filter:track by_src, count 10, seconds 60; \\", "note": "The **count**: per source address, the rule fires only once that source has matched more than 10 times within 60 seconds. One login is a customer; the eleventh in a minute is something else."}, {"code": " classtype:attempted-user; sid:1000201; rev:1;)", "note": "The category, which sets the priority; the rule's number; its revision, raised on every change so an alert says which version of the rule produced it."}]}
```

Before anything runs, the configuration is tested, rule files included. This one also loads
`http-events.rules`, rules shipped with Suricata that fire on malformed HTTP, which the section on
anomalies uses:

```
root@sensor:~# grep -A2 "^rule-files" /etc/suricata/suricata.yaml; ls /etc/suricata/rules/http-events.rules
rule-files:
  - local.rules
  - http-events.rules
/etc/suricata/rules/http-events.rules
root@sensor:~# suricata -T -c /etc/suricata/suricata.yaml 2>&1 | tail -1
i: suricata: Configuration provided was successfully loaded. Exiting.
```

Then the sensor starts on the DMZ:

```
root@sensor:~# suricata -c /etc/suricata/suricata.yaml --af-packet=eth0 -D --pidfile /var/log/suricata/suricata.pid
i: suricata: This is Suricata version 7.0.3 RELEASE running in SYSTEM mode
```

**Write rules against a buffer, never against the raw packet, whenever a buffer exists.** A `content`
without one searches the whole payload: the same five letters in a header, a cookie or a product
description all match, and the false positives that follow are the reason people stop reading alerts.
