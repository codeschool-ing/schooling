---
title: What a certificate says, and how a host gets one
version: 1
---

**A TLS certificate is a signed statement that a public key belongs to a name, and HTTPS is only as
good as the browser's reasons to believe the signature.** It does not say the site is safe, honest or
yours to trust; it says that whoever answers for `example.com` holds the private key matching the one in
the certificate, and that an authority the browser trusts checked that before signing.

The common picture is the padlock as a seal of approval. It is a much narrower promise: **the connection
is to the name in the address bar, and nobody in between can read or change it.** A phishing site with a
perfectly valid certificate for its own lookalike name gets the same padlock.

## What is in one

| field | holds |
|---|---|
| subject alternative names | the names the certificate is valid for: `example.com`, `www.example.com` |
| issuer | the authority that signed it |
| validity | a start and an end date; browsers refuse it outside them |
| public key | the half of the key pair the server proves it holds the other half of |
| signature | the issuer's, over everything above |

The browser checks the signature against an authority in its own trusted list, through any intermediate
certificates the server sends, and checks that the name it asked for is among the subject alternative
names. A certificate for `www.example.com` does not cover `example.com`; each name the site answers on
must be listed.

## How a host gets one in seconds

Every host in this course obtains certificates automatically, from authorities such as Let's Encrypt,
through a protocol called **ACME**. The authority's question is always the same, *do you control this
name?*, and there are two ways to answer:

- **HTTP-01**: the authority asks for a file at `http://example.com/.well-known/acme-challenge/<token>`,
  and the host, which the name already points at, serves the expected contents. This is why the DNS
  records come first: until the name points at the host, the host cannot answer the question.
- **DNS-01**: the authority asks for a `TXT` record at `_acme-challenge.example.com`. A host that runs
  your DNS can create it; this is the only way to get a certificate for a wildcard name such as
  `*.example.com`.

**Certificates expire, and their lifetimes keep getting shorter.** Let's Encrypt issues them for 90 days,
and the browsers' and authorities' joint rules have scheduled the maximum for any certificate to shrink
year by year, to 47 days in 2029. Short lifetimes are only bearable because renewal is automatic, which is
the strongest reason to let the host manage certificates rather than uploading one by hand.

## Where this lesson goes next

A public authority will not sign anything for a name that is not on the internet. So the rest of this
lesson does what organisations do for internal names: it creates **an authority of its own**, signs a
certificate for `planner.test` with it, and tells `curl` to trust that authority, and nothing else. The
host first learns to speak HTTPS, in the next section.
