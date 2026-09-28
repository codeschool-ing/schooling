---
title: When the blocker is wrong, or stops
version: 1
---

Blocking is only as good as the rule, and the rule was written in a hurry. The shop publishes a help
page called `admin-guide.html`, for customers:

```
ana@remote:~$ curl -s -m3 http://www.example.com/admin-guide.html; echo "exit $?"
exit 28
root@ips:~# jq -c "select(.event_type==\"alert\") | [.alert.action, .alert.signature_id, .src_ip, .http.url]" /var/log/suricata/eve.json | tail -1
["blocked",1000101,"203.0.113.50","/admin-guide.html"]
```

**Blocked**: `/admin-guide.html` starts with `/admin`, which is all the rule asked. On the sensor this
would have been one more alert to dismiss; inline, every customer who clicks the help link waits three
seconds and gets nothing. The fix is a narrower rule, `/admin/` with the slash, and the lesson is the
general one: **a rule goes inline only after it has been watched against real traffic**, long enough
to know what else it matches.

## Failing closed, or failing open

When the program on `ips` stops, the question is what happens to the cable:

```
root@ips:~# kill -INT $(cat /var/log/suricata/suricata.pid); sleep 2; pgrep -c suricata
0
ana@remote:~$ curl -s -m3 http://www.example.com/; echo "exit $?"
exit 28
```

Suricata is gone, and the shop is unreachable again. This inline element **fails closed**: nothing
passes unless it was inspected. Whether that is right depends on what the link carries:

| | fails closed | fails open |
|---|---|---|
| when the IPS stops | the link stops | traffic flows uninspected |
| the risk | an outage caused by the security device itself | a window with no inspection, possibly unnoticed |
| suits | links where uninspected traffic is worse than none: a payment segment | links where availability comes first: the shop's front door |

Commercial IPS appliances and network taps often include a **bypass** that physically joins the two
ports when the device loses power or its software stops, so that a failing IPS becomes a cable rather
than a wall. Whichever the design, it is a decision to make and write down in advance, and to test,
exactly as this section did: stop the service on purpose and watch what the link does.
