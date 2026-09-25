---
title: SMTP, typed by hand
version: 1
---

SMTP, the Simple Mail Transfer Protocol, is as plain as FTP and HTTP: commands, and replies with a
three-digit code. From the office's mail server, a message can be delivered to `example.net` by typing
it, which is exactly what the server itself does:

```
ana@mail:~$ nc -C mail.example.net 25
220 mail.example.net ESMTP
EHLO mail.example.com
250-mail.example.net
250-PIPELINING
250-SIZE 10240000
250-VRFY
250-ETRN
250-STARTTLS
250-ENHANCEDSTATUSCODES
250-8BITMIME
250-DSN
250-SMTPUTF8
250 CHUNKING
MAIL FROM:<ana@example.com>
250 2.1.0 Ok
RCPT TO:<bruno@example.net>
250 2.1.5 Ok
DATA
354 End data with <CR><LF>.<CR><LF>
From: Ana <ana@example.com>
To: Bruno <bruno@example.net>
Subject: Delivery on Monday

The boxes arrive on Monday.
.
250 2.0.0 Ok: queued as 4CC9CD859D
QUIT
221 2.0.0 Bye
```

`EHLO` introduces the sender and gets the list of what the server supports. `MAIL FROM` and `RCPT TO`
give the sender and the recipient, and each gets `250 Ok`. `DATA` is followed by the message itself,
headers first, a blank line, the text, and a line with only a full stop to end it. `250 2.0.0 Ok:
queued` means the server has taken responsibility for it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The envelope and the letter. The envelope is the SMTP commands: MAIL FROM, which says where to send a bounce and is what SPF checks, and RCPT TO, which is where the server delivers the message. The letter is the headers inside DATA: From, which is what the reader sees as the sender, and To and Subject. The headers are only text, written by whoever sent the message, and nothing in SMTP itself makes them agree with the envelope.\"><defs><marker id=\"ev-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"340\" height=\"190\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"22\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the envelope: SMTP commands</text><rect x=\"370\" y=\"20\" width=\"340\" height=\"190\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"382\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the letter: headers inside DATA</text><text x=\"22\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">MAIL FROM:&lt;ana@example.com&gt;</text><text x=\"22\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">who to bounce to, and what SPF checks</text><text x=\"22\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">RCPT TO:&lt;bruno@example.net&gt;</text><text x=\"22\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">where the server delivers it</text><text x=\"382\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">From: Ana &lt;ana@example.com&gt;</text><text x=\"382\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the reader sees as the sender</text><text x=\"382\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">To: Bruno &lt;bruno@example.net&gt;</text><text x=\"382\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Subject: Order 2231</text><text x=\"382\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">only text, written by whoever sent it</text></svg>", "caption": "Servers route by the envelope; people read the letter. Nothing in SMTP makes the two agree, which is the gap SPF, DKIM and DMARC exist to close."}
```

**There are two senders in that session, and they are different things.** `MAIL FROM` and `RCPT TO`
are the envelope: servers route and bounce by them. `From:` and `To:` inside `DATA` are the letter:
text the recipient's program shows, written by whoever sent the message. SMTP does not check that the
two agree, and never did. Anybody who can reach a mail server can type any `From:` at all, and
sections 08 to 10 are how a receiving server finds out.
