---
title: What is worth keeping, and for how long
version: 1
---

Keeping everything for ever is not a policy. It costs space, it makes every search slower, and much of
it is personal data that the law says must have a reason to exist. The lab's collection after one
short scenario:

```
root@admin:~# cd /var/log/lab/remote; wc -lc fw/flows.json fw/drops.json sensor/eve.json
     7   4366 fw/flows.json
     8   6900 fw/drops.json
    43 197592 sensor/eve.json
    58 208858 total
```

About 600 bytes per flow record and 860 per drop, and `eve.json` far larger per record. The sensor's
file is mostly not alerts:

```
root@admin:~# jq -r .event_type /var/log/lab/remote/sensor/eve.json | sort | uniq -c | sort -rn
     24 stats
      6 http
      6 flow
      6 fileinfo
      1 alert
```

One alert, and 24 `stats` records, the sensor's periodic report on itself, which make up most of the
file. **The first saving is choosing record types**, not shortening how long they are kept. The same
arithmetic at a real scale: a firewall refusing 50 packets a second writes about 3.7 GB of drops a day
at this size, and 20 new connections a second write about 1.1 GB of flows. Both compress well, and
neither is small.

A reasonable starting policy, to be adjusted per company:

| record | keep | why |
|---|---|---|
| IDS alerts | a year or more | few, small, and the history of attacks against you |
| flow records | 90 days to a year | the look-back of the previous sections; intrusions are often found weeks after they began |
| firewall drops | 30 to 90 days, then counts only | mostly background noise; the totals per day keep the trend |
| HTTP and DNS details from the sensor | days to weeks | full URLs and names can carry personal data |
| 802.1X and DHCP logs | as long as the flows they explain | they turn an address into a person, which is their use and their risk |

**The law sets both floors and ceilings.** In Brazil, the **Marco Civil da Internet** obliges a
company that offers an application on the internet, such as the lab's shop, to keep its access
records for six months (article 15). A connection provider must keep connection records for a year
(article 13). The **LGPD** pulls the other way: its principles include purpose, necessity and security
(article 6), so records that identify people are kept for a stated reason, no longer than it needs,
and protected while they exist. Lesson 2 raised the same question about what a firewall decrypts;
here it applies to every line in the collection.

Retention is enforced by the collector, not by good intentions. On `admin` it is one file:

```schooling-example
{"language": "conf", "file": "logrotate.conf", "parts": [{"code": "/var/log/lab/remote/*/*.json {\n    daily\n    rotate 90", "note": "Every file in the collection, once a day. Ninety old files are kept, so the oldest line is about ninety days old."}, {"code": "    compress\n    delaycompress", "note": "Old files are compressed, except the most recent one, which a reader may still have open."}, {"code": "    missingok\n    notifempty", "note": "A source that sent nothing today is not an error for logrotate; the alarm on silence is a separate check."}, {"code": "    postrotate\n        kill -HUP $(cat /var/log/lab/rsyslog.pid)\n    endscript\n}", "note": "rsyslog is told to reopen its files, so new lines go to the new file rather than the renamed one."}]}
```

Three last rules close the course's thread on records:

- **Access to the collection is itself logged.** It is the most sensitive store on the network, because
  it says who did what, when.
- **Deletion is scheduled, not remembered.** A retention period nobody enforces is a period of for
  ever.
- **A record that nobody reads protects nothing.** The alerts go somewhere a person looks, the feed
  hunt runs on a schedule, and a source that falls silent raises its own alarm.
