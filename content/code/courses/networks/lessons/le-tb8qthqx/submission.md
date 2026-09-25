---
title: Sending as a person: port 587
version: 1
---

A server that delivered anything, to anywhere, for anybody, would be an **open relay**, and spammers find
those within hours. The office's server takes mail for its own domain from anyone, but passes mail on
to other domains only for people who have logged in:

```
ana@laptop:~$ swaks --to bruno@example.net --from ana@example.com --server mail.example.com --quit-after RCPT
=== Trying mail.example.com:25...
=== Connected to mail.example.com.
<-  220 mail.example.com ESMTP
 -> EHLO laptop
<-  250-mail.example.com
<-  250-PIPELINING
<-  250-SIZE 10240000
<-  250-VRFY
<-  250-ETRN
<-  250-STARTTLS
<-  250-ENHANCEDSTATUSCODES
<-  250-8BITMIME
<-  250-DSN
<-  250-SMTPUTF8
<-  250 CHUNKING
 -> MAIL FROM:<ana@example.com>
<-  250 2.1.0 Ok
 -> RCPT TO:<bruno@example.net>
<** 554 5.7.1 <bruno@example.net>: Relay access denied
 -> QUIT
<-  221 2.0.0 Bye
=== Connection closed with remote host.
```

`554 5.7.1 Relay access denied`: the laptop had not logged in, and `example.net` is not this server's
domain. A mail program sends to **port 587**, submission, which is for people rather than for servers,
and requires a password over TLS:

```
ana@laptop:~$ cat order.txt
Date: Fri, 25 Sep 2026 10:02:00 -0300
Message-ID: <order-2231@example.com>
From: Ana <ana@example.com>
To: Bruno <bruno@example.net>
Subject: Order 2231

Hello Bruno, can you confirm order 2231?
ana@laptop:~$ curl -sS -v --url smtp://mail.example.com:587/laptop.example.com --ssl-reqd --user ana:office-2026 --mail-from ana@example.com --mail-rcpt bruno@example.net -T order.txt 2>&1 | grep -E "^[<>] " | grep -vE "^< 250-(PIPELINING|SIZE|VRFY|ETRN|ENHANCEDSTATUSCODES|8BITMIME|DSN|SMTPUTF8|CHUNKING)"
< 220 mail.example.com ESMTP
> EHLO laptop.example.com
< 250-mail.example.com
< 250-STARTTLS
< 250 CHUNKING
> STARTTLS
< 220 2.0.0 Ready to start TLS
> EHLO laptop.example.com
< 250-mail.example.com
< 250-AUTH PLAIN LOGIN
< 250 CHUNKING
> AUTH PLAIN
< 334 
> AGFuYQBvZmZpY2UtMjAyNg==
< 235 2.7.0 Authentication successful
> MAIL FROM:<ana@example.com> SIZE=202
< 250 2.1.0 Ok
> RCPT TO:<bruno@example.net>
< 250 2.1.5 Ok
> DATA
< 354 End data with <CR><LF>.<CR><LF>
< 250 2.0.0 Ok: queued as 1C7E3D83F3
ana@laptop:~$ echo AGFuYQBvZmZpY2UtMjAyNg== | base64 -d | tr "\0" " "; echo
 ana office-2026
```

`STARTTLS` and `220 Ready to start TLS` turned the connection encrypted, the same upgrade as FTPS's
`AUTH`. Only then did the server offer `AUTH PLAIN LOGIN`. curl answered with one line of base64, and
the server said `235 Authentication successful`.

**Base64 is an encoding, not encryption**: decoding it gives back the user and the password, as the
last command shows. That is fine inside TLS and a disaster without it, which is why port 587 refuses to
authenticate before `STARTTLS`. Port 465 does the same job with TLS from the first byte, and many
providers offer it instead.
