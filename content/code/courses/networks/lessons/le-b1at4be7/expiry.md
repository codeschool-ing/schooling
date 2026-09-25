---
title: Seeing the expiry before it arrives
version: 1
---

An expired certificate is the most common certificate outage, and the most avoidable: its date was
written into it on the day it was made. `openssl x509 -checkend` answers "will it still be valid in
this many seconds?":

```
ana@laptop:~$ echo | openssl s_client -connect www.example.com:443 -servername www.example.com 2>/dev/null | openssl x509 -noout -enddate -checkend 2592000
notAfter=Dec 24 17:03:48 2026 GMT
Certificate will not expire
ana@laptop:~$ echo | openssl s_client -connect expired.example.com:443 -servername expired.example.com 2>/dev/null | openssl x509 -noout -enddate -checkend 0
notAfter=Aug 30 00:00:00 2025 GMT
Certificate will expire
```

`2592000` seconds is 30 days. **`Certificate will not expire` means it is good for at least another
thirty days**; the expired one fails even `-checkend 0`. The dates are judged by the client's own
clock, so a PC whose clock is wrong calls every certificate expired, or not yet valid, whatever the
server sends. The command also exits with a status, 0 or
1, which makes it easy to run from a scheduled task (operating-systems lesson 14) that sends a
warning a month ahead.

Monitoring services do the same from outside, which also catches a certificate that was renewed on disk
but never loaded by a server that was not restarted. **Checking the certificate the server actually
sends, as these commands do, is the only check that counts**: the file on disk is what should be
served, not necessarily what is.
