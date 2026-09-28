---
title: Reading an alert properly
version: 1
---

`eve.json` holds the full record of every event Suricata logs, one JSON object per line. The alert
from the previous section, with the fields that matter picked out:

```
root@sensor:~# jq "select(.event_type==\"alert\") | {timestamp, src_ip, dest_ip, dest_port, alert: {action: .alert.action, signature_id: .alert.signature_id, signature: .alert.signature, category: .alert.category}, http: {hostname: .http.hostname, url: .http.url, status: .http.status}}" /var/log/suricata/eve.json
{
  "timestamp": "2026-09-28T17:59:18.623794-0300",
  "src_ip": "203.0.113.50",
  "dest_ip": "192.0.2.80",
  "dest_port": 80,
  "alert": {
    "action": "allowed",
    "signature_id": 1000101,
    "signature": "admin path requested from outside",
    "category": "Potential Corporate Privacy Violation"
  },
  "http": {
    "hostname": "www.example.com",
    "url": "/admin/",
    "status": 200
  }
}
```

Read it in the order an analyst would:

| field | here | the question it answers |
|---|---|---|
| `timestamp` | 17:59:18, in the lab's time zone | when, to line it up with other logs |
| `src_ip`, `dest_ip`, `dest_port` | `203.0.113.50` to `192.0.2.80:80` | who, to what |
| `alert.signature_id`, `signature` | 1000101, *admin path requested from outside* | which rule, and what its author meant by it |
| `alert.action` | **`allowed`** | whether anything was done about it |
| `http.url`, `http.status` | `/admin/`, **200** | what was asked for, and **whether it worked** |

The last row turns an alert into a finding. A `404` would mean somebody guessed a path that does not
exist; a `403` that a control refused it; **a `200` means the admin console was served to the
internet**, and the question is no longer about the requester but about why the proxy allowed it.

`action: allowed` is the honest word for what an IDS does on every match. It is also the field that
changes in the next section.

Two habits make alerts useful rather than merely numerous. **Write the message for the person who will
read it at 3 a.m.**: *admin path requested from outside* says what happened and why it matters;
*rule 7 match* does not. And **send every alert somewhere somebody looks**, with its HTTP, DNS and flow
records beside it, which is lesson 23's subject.
