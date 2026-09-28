---
title: What the wire cannot see
version: 1
---

The network sensor on the DMZ watches for the admin path requested from outside, as in lesson 14. A
stranger asks for it twice: once over plain HTTP, once over HTTPS:

```
ana@remote:~$ curl -s http://www.example.com/admin/; curl -s https://www.example.com/admin/
admin console
admin console
```

Both requests were served. The sensor's alerts:

```
root@sensor:~# jq -c "select(.event_type==\"alert\") | [.alert.signature_id, .dest_port, .http.url]" /var/log/suricata/eve.json
[1000101,80,"/admin/"]
```

**One alert, for port 80.** The HTTPS request produced none, because the rule looks for a path and the
path was encrypted. The sensor did record the TLS connection, but all it could read was the name:

```
root@sensor:~# jq -c "select(.event_type==\"tls\") | [.src_ip, .dest_port, .tls.sni]" /var/log/suricata/eve.json
["203.0.113.50",443,"www.example.com"]
```

A client on the internet, a TLS connection to `www.example.com`, and nothing about what was asked.
The machine that terminated TLS knows exactly what was asked, and wrote it down:

```
root@www:~# grep "/admin/" /var/log/nginx/access.log | cut -d" " -f1,4,6-9
203.0.113.50 [28/Sep/2026:18:06:19 "GET /admin/ HTTP/1.1" 200
203.0.113.50 [28/Sep/2026:18:06:19 "GET /admin/ HTTP/1.1" 200
```

**Both requests, both for `/admin/`, both answered `200`.** Nothing about this is a flaw in the sensor;
TLS is doing its job. It means that detection for anything inside HTTPS has to happen where TLS ends:
in the proxy's logs, in a WAF there (lesson 3), or in an agent on that host shipping those logs to where
somebody reads them. Most of the web's traffic is encrypted, so most web detection has moved to hosts,
and the network sensor's job has shifted towards what it still sees well: who talked to whom, when, how
much, and in which protocol.
