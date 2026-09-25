---
title: FTPS: FTP inside TLS
version: 1
---

The same server can speak **FTPS**, FTP wrapped in the TLS of lessons 5 and 6, with the same
certificate as the website. `--ssl-reqd` makes curl insist on it:

```
ana@laptop:~$ curl -sS -v --ssl-reqd -u example:Sunflower-77 ftp://www.example.com/ 2>&1 | grep -E "^[<>] (AUTH|234|USER|230)|SSL connection|^-rw"
> AUTH SSL
< 234 Proceed with negotiation.
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / prime256v1 / id-ecPublicKey
> USER example
< 230 Login successful.
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / prime256v1 / UNDEF
-rw-r--r--    1 1001     1001          109 Sep 25 18:26 index.html
ana@isp:~$ sudo timeout 6 tcpdump -i eth0 -n -l "tcp port 21" 2>/dev/null | grep -aoE "FTP: (220|AUTH|234|USER|PASS)[ -~]*"
FTP: 220 (vsFTPd 3.0.5)
FTP: AUTH SSL
FTP: 234 Proceed with negotiation.
```

Before logging in, curl sent `AUTH SSL` and the server answered `234 Proceed with negotiation`; then a
TLS 1.3 handshake, and only then `USER`. On the ISP's machine, all that could still be read was the
greeting and those two lines. Everything after them, password included, is encrypted.

Offering encryption is not the same as requiring it: a client that does not ask still logs in the old
way. The server can refuse that:

```
ana@www:~$ grep -E "^(ssl_enable|force_local)" /etc/vsftpd.conf
ssl_enable=YES
force_local_logins_ssl=YES
force_local_data_ssl=YES
ana@laptop:~$ curl -sS -v -u example:Sunflower-77 ftp://www.example.com/ 2>&1 | grep -E "^< 530|curl:"
< 530 Non-anonymous sessions must use encryption.
curl: (67) Access denied: 530
```

With `force_local_logins_ssl=YES`, a login without TLS gets `530` and goes no further.

Two things to know about FTPS. This is **explicit** FTPS, which starts plain on port 21 and upgrades
with `AUTH`; an older form, implicit FTPS, speaks TLS from the first byte on port 990. And FTPS keeps
both connections and the passive range: a firewall has the same range to open, and can no longer read
the `229` replies to help, because they are encrypted too.
