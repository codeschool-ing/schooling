---
title: Which HTTP, which TLS
version: 1
---

The two sides agree on versions during the handshake, and both agreements can be forced from `curl`.
Asking for HTTP/1.1 only:

```
ana@laptop:~$ curl -sv -o /dev/null --http1.1 https://www.example.com/ 2>&1 | grep -E 'ALPN|^> GET|^< HTTP'
* ALPN: curl offers http/1.1
* ALPN: server accepted http/1.1
> GET / HTTP/1.1
< HTTP/1.1 200 OK
ana@laptop:~$ curl -sS -o /dev/null --tls-max 1.1 https://www.example.com/
curl: (35) OpenSSL/3.0.13: error:0A0000BF:SSL routines::no protocols available
```

`curl offers http/1.1`, the server accepts it, and the request and answer are HTTP/1.1. By default the
offer was `h2,http/1.1`, and the server picked **`h2`, HTTP/2**: the same requests and answers, sent in
binary frames, many at once over one connection. HTTP/3 is lesson 3's QUIC, over UDP; this nginx
does not offer it.

The second command asked for **TLS 1.1 at most**, and did not even reach the server: `no protocols
available`. The laptop's own TLS library, OpenSSL 3, **refuses to offer TLS 1.0 or 1.1 at all**, and
so does every current browser. Both versions were retired in 2021 (RFC 8996). A device that fails to
connect to anything modern, an old printer or an old scanner uploading to a web page, often fails for
this reason, and the fix is its firmware, not the network.
