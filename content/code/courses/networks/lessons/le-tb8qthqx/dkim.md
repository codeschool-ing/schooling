---
title: DKIM: a signature on the message
version: 1
---

**DKIM**, DomainKeys Identified Mail, signs the message itself. Ana's server added the
`DKIM-Signature` header of section 05 with a private key only it holds; the public half is in DNS,
under a **selector**, here `mail`:

```
ana@laptop:~$ dig +short TXT mail._domainkey.example.com | cut -c1-90
"v=DKIM1; h=sha256; k=rsa; " "p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAt70LTRYeLMru+u
ana@netmail:~$ sudo doveadm fetch -u bruno hdr.authentication-results subject "Order 2231"
hdr.authentication-results: mail.example.net; dmarc=pass (p=reject dis=none) header.from=example.com
mail.example.net; spf=pass smtp.mailfrom=example.com
mail.example.net;
        dkim=pass (2048-bit key; unprotected) header.d=example.com header.i=@example.com header.a=rsa-sha256 header.s=mail header.b=IH1t6O+8;
        dkim-atps=neutral
```

The signature says who signed, `d=example.com`, with which key, `s=mail`, which headers it covers,
`h=Date:From:To:Subject`, and a hash of the body, `bh=`. Bruno's server fetched
`mail._domainkey.example.com`, checked the signature against it, and wrote `dkim=pass (2048-bit key)`.

Because the signature travels inside the message, **DKIM survives forwarding**, which is where SPF
fails. It breaks if the signed parts change on the way, such as a mailing list adding a footer to the
text. A domain can publish several selectors at once, one per service that sends for it, which is how a
company signs its own mail and its newsletter provider's too.
