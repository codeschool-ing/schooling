---
title: Layers 5 to 7: one command, every layer
version: 1
---

Above layer 4, the model has three layers, and in practice the program does all three. `curl -v`
narrates what it does to fetch a page, and six of its lines, picked out with `grep`, walk up the
stack:

```
ana@laptop:~$ curl -sv -o /dev/null https://www.example.com/ 2>&1 | grep -E 'IPv4:|Trying|Connected|SSL connection|^> GET|^< HTTP'
* IPv4: 192.0.2.80
*   Trying 192.0.2.80:443...
* Connected to www.example.com (192.0.2.80) port 443
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519 / id-ecPublicKey
> GET / HTTP/2
< HTTP/2 200 
```

| line | layer | what happened |
|---|---|---|
| `IPv4: 192.0.2.80` | 7, DNS | the name `www.example.com` became an address |
| `Trying 192.0.2.80:443` | 3 and 4 | an address and a port: where to connect |
| `Connected to … port 443` | 4 | TCP's handshake completed |
| `SSL connection using TLSv1.3` | 5 and 6 | an encrypted session was agreed |
| `> GET / HTTP/2` | 7 | the request |
| `< HTTP/2 200` | 7 | the answer: OK |

**Layer 5, the session, is the one the model describes least clearly.** It was meant for keeping a
conversation going across interruptions; today that job is done by TLS session resumption, by a
login cookie, or by the application itself, and nothing on the wire is labelled "layer 5". Layer 6,
presentation, is how the data is encoded, and encryption is the part of it that matters most now.

Layer 7 is the protocol a program speaks: HTTP for the web, DNS for names, SMTP for mail, SSH for a
remote shell. Most of this course lives here, lessons 4 to 9, because it is where users meet the
network.
