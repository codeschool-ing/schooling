---
title: DMARC: tying it to the From line
version: 1
---

SPF proves something about the envelope and DKIM about a signing domain, and neither looks at the
`From:` a person reads. DMARC does: it passes when SPF or DKIM passed **for the same domain as the
`From:` header**, and the domain's record says what to do when it does not.

```
ana@laptop:~$ dig +short TXT _dmarc.example.net
"v=DMARC1; p=reject; rua=mailto:dmarc@example.net"
ana@home:~$ swaks --to ana@example.com --from bruno@example.net --server mail.example.com --header "Subject: Invoice overdue" --body "Please pay to the new account."
=== Trying mail.example.com:25...
=== Connected to mail.example.com.
<-  220 mail.example.com ESMTP
 -> EHLO home
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
 -> MAIL FROM:<bruno@example.net>
<-  250 2.1.0 Ok
 -> RCPT TO:<ana@example.com>
<-  250 2.1.5 Ok
 -> DATA
<-  354 End data with <CR><LF>.<CR><LF>
 -> Date: Fri, 25 Sep 2026 15:47:04 -0300
 -> To: ana@example.com
 -> From: bruno@example.net
 -> Subject: Invoice overdue
 -> Message-Id: <20260925154704.101257@home>
 -> X-Mailer: swaks v20240103.0 jetmore.org/john/code/swaks/
 -> 
 -> Please pay to the new account.
 -> 
 -> 
 -> .
<** 550 5.7.1 rejected by DMARC policy for example.net
 -> QUIT
<-  221 2.0.0 Bye
=== Connection closed with remote host.
```

`p=reject` tells receivers to refuse what fails. From `home`, somebody sent Ana a message claiming to be
from Bruno, asking her to pay an invoice to a new account: the envelope and the `From:` both said
`example.net`, and the connection came from `198.51.100.77`. SPF failed, because that address is not
`example.net`'s mail server, and there was no DKIM signature. DMARC failed, and Ana's server answered
`550 5.7.1 rejected by DMARC policy for example.net`. The message never reached her.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The three checks a receiving server makes. A message arrives claiming to be From bruno@example.net. SPF asks whether the address it came from is allowed by example.net&#x27;s SPF record. DKIM asks whether a signature on it checks out against example.net&#x27;s public key in DNS. DMARC asks whether either of those passed for the domain in the From header; if one did, the message is delivered, and if neither did, the server applies example.net&#x27;s policy, here reject, and answers 550.\"><defs><marker id=\"ck-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a message arrives claiming From: bruno@example.net</text><rect x=\"40\" y=\"40\" width=\"640\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SPF</text><text x=\"140\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">is the sending address allowed by example.net?</text><path d=\"M360 82 L360 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><rect x=\"40\" y=\"98\" width=\"640\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">DKIM</text><text x=\"140\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">does a signature check out against example.net&#x27;s key?</text><path d=\"M360 140 L360 154\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><rect x=\"40\" y=\"156\" width=\"640\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">DMARC</text><text x=\"140\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">did either pass, for the From domain? if not, apply p=reject</text><path d=\"M250 208 L180 226\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><text x=\"170\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">deliver</text><path d=\"M470 208 L540 226\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><text x=\"550\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">550: rejected</text></svg>", "caption": "SPF and DKIM each prove something about a domain; DMARC ties that proof to the From line people read, and says what to do when it is missing."}
```

A domain moves towards `reject` in steps: `p=none` only asks for reports, sent daily to the `rua=`
address, which show every server sending in the domain's name; `p=quarantine` sends failures to spam;
`p=reject` refuses them. Starting at `reject` blocks the newsletter service nobody remembered to add to
SPF. Never publishing DMARC at all leaves the domain free for anybody to forge.
