---
title: Which versions the server accepts
version: 1
---

TLS has had four versions, and SSL two before it. **SSL 2 and 3, TLS 1.0 and TLS 1.1 are all
deprecated**, the last two formally since 2021. Each has known weaknesses, and a server that still
accepts them lets a client, or somebody pretending to be one, choose them. The shop's proxy
allows two:

```
root@www:~# grep -n ssl_protocols /etc/nginx/sites-enabled/shop
15:    ssl_protocols TLSv1.2 TLSv1.3;
```

Tested from `laptop`, asking for each version by name:

```
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/
200
ana@laptop:~$ openssl s_client -connect www.example.com:443 -servername www.example.com -tls1_3 </dev/null 2>/dev/null | grep "^New,"
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
ana@laptop:~$ openssl s_client -connect www.example.com:443 -servername www.example.com -tls1_2 </dev/null 2>/dev/null | grep "^New,"
New, TLSv1.2, Cipher is ECDHE-ECDSA-AES256-GCM-SHA384
```

TLS 1.3 with `TLS_AES_256_GCM_SHA384`, and TLS 1.2 with `ECDHE-ECDSA-AES256-GCM-SHA384`. Then TLS 1.1:

```
ana@laptop:~$ curl -sS -o /dev/null --tls-max 1.1 https://www.example.com/; echo "exit $?"
curl: (35) OpenSSL/3.0.13: error:0A0000BF:SSL routines::no protocols available
exit 35
```

**The client refused before the server was asked**: the OpenSSL on Ubuntu 24.04 will not offer TLS 1.1
at its default security level. That protects this client and proves nothing about the server. To
test the server, the client's own floor has to be lowered on purpose, for this one test:

```
ana@laptop:~$ openssl s_client -connect www.example.com:443 -servername www.example.com -tls1_1 -cipher "DEFAULT:@SECLEVEL=0" </dev/null 2>&1 | grep -oE "alert protocol version|SSL alert number [0-9]+"
alert protocol version
SSL alert number 70
```

The server answered with **alert 70, `protocol version`**: it refused. Both ends now refuse old
versions independently, and either one alone protects every connection it takes part in.

## Downgrade protection

A downgrade attack does not need the server to *prefer* an old version, only to *accept* one. An
attacker on the path interferes with the first handshake so that the client retries with an older
version, and the connection settles on the weakest thing both sides tolerate. Two mechanisms close it.
TLS 1.3 servers write a fixed marker into their random value when they negotiate an older version for
a client that could do better, so a TLS 1.3 client detects the trick. And removing the old versions
from both ends leaves nothing to downgrade to. **The second is the one an administrator controls**,
with one line.
