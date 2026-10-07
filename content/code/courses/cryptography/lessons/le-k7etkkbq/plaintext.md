---
title: Protocols that send the password as typed
version: 1
---

**FTP, Telnet, HTTP, POP3, IMAP, SMTP and LDAP were all designed to send everything, credentials
included, as readable text.** They predate the public internet's threats, and each has been given an
encrypted version since. The old ones are still found running, usually because something depends on
them and nobody has switched them off.

## FTP, as the server receives it

Vereda's file server still offers FTP on port 2121 for an old scheduling tool. `curl -v` prints the
commands it sends, which are exactly the bytes that cross the network:

```
ana@lab:~/lab$ curl -sv --user scheduler:V-db-s3cret-2026 ftp://files.vereda.example:2121/NOTES.txt 2>&1 | grep -E '^[<>] (USER|PASS|RETR|230)|^Vereda'
> USER scheduler
> PASS V-db-s3cret-2026
< 230 Login successful.
> RETR NOTES.txt
Vereda portal 2.4.1: booking reminders by SMS.
```

`USER` and `PASS` carry the account name and the password as typed, and the file follows in clear
text too. Anybody on the path, a compromised switch, a shared Wi-Fi network, a misconfigured mirror
port, reads both without breaking anything. There is no cryptography to defeat.

## Asking for encryption the server cannot give

A client can insist on encryption. With `--ssl-reqd`, curl first asks the server to switch to TLS,
which is how **FTPS** works, and refuses to go on when the server cannot:

```
ana@lab:~/lab$ curl -sv --ssl-reqd --user scheduler:V-db-s3cret-2026 ftp://files.vereda.example:2121/NOTES.txt 2>&1 | grep -E '^[<>] (AUTH|USER|PASS|5)|^curl:'; echo "exit status ${PIPESTATUS[0]}"
> AUTH SSL
< 500 Command "AUTH" not understood.
> AUTH TLS
< 500 Command "AUTH" not understood.
exit status 64
```

The server answers `500` to both `AUTH SSL` and `AUTH TLS`, so curl stops with exit status 64
**before** sending `USER` or `PASS`. That ordering is the whole point of `--ssl-reqd`: a client that
only *prefers* encryption would have fallen back to plain FTP and sent the password anyway, which is
the downgrade problem of section 04.

## The pairs to know

| plain protocol | port | encrypted replacement | port |
|---|---|---|---|
| FTP | 21 | **SFTP** (file transfer over SSH), or FTPS (FTP over TLS) | 22, or 990 / 21 |
| Telnet | 23 | **SSH** | 22 |
| HTTP | 80 | **HTTPS** | 443 |
| LDAP | 389 | **LDAPS**, or LDAP with StartTLS | 636, or 389 |
| SMTP submission | 25, 587 | SMTP with STARTTLS, or implicit TLS | 587, 465 |
| IMAP, POP3 | 143, 110 | IMAPS, POP3S | 993, 995 |

The insecure one should not merely be **available alongside** the secure one: it should be **off**,
or refuse to authenticate, as the LDAP server at the end of this lesson does. A server that offers
both leaves every client one misconfiguration away from the plain version.
