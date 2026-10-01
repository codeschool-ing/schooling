---
title: Counting instead of matching once
version: 1
---

Some behaviour is only suspicious in quantity. One login is a customer. Fifteen in a few seconds from
one address is a script, and whether it is somebody's buggy integration or somebody trying passwords,
a person should hear about it. `remote` posts the login form fifteen times, with no password at all:

```
ana@remote:~$ for i in $(seq 15); do curl -s -o /dev/null -w "%{http_code} " -d "user=ana" http://www.example.com/login; done; echo
200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 
```

Every request was answered, because the sensor stands beside the traffic. What it recorded:

```
root@sensor:~# grep -c 1000201 /var/log/suricata/fast.log
5
root@sensor:~# jq -c "select(.event_type==\"alert\" and .alert.signature_id==1000201) | [.timestamp[11:19], .src_ip, .http.url]" /var/log/suricata/eve.json | head -2
["18:03:37","203.0.113.50","/login"]
["18:03:37","203.0.113.50","/login"]
```

**Five alerts for fifteen requests.** The first ten matched the rule and stayed silent, because
`count 10` had not been exceeded; requests eleven to fifteen each produced an alert. The first two
alerts carry the same second, which is what *a script* looks like in a log.

Suricata offers three ways to make a rule count, and they answer different questions:

| keyword | fires | answers |
|---|---|---|
| `detection_filter` | on every match **after** the count is exceeded | "tell me once this is clearly happening, and keep telling me" |
| `threshold: type threshold` | once per **every** N matches | "one alert per ten, so the volume shows without drowning me" |
| `threshold: type limit` | at most N times per period | "tell me it started; I do not need the rest" |

Counting belongs in the rule when the pattern *is* the count, as here. When the rule is fine and the
problem is how often it fires, the count belongs in the engine's threshold file instead, the subject of
this lesson's last section.
