---
title: ACME, or how a machine proves it controls a name
version: 1
---

Certificates used to be bought for a year or two, installed by hand, and forgotten until the day they
expired and took the site down with them. **ACME**, the *Automatic Certificate Management
Environment* (RFC 8555), replaced that with a protocol a program can follow on its own. Let's
Encrypt built it, issues certificates through it for free, and makes them valid for 90 days on
purpose: short enough that nobody can renew by hand, so everybody automates.

A conversation with an ACME server has five steps:

1. **an account.** The client makes a key pair and registers its public half; every later request is
   signed with it.
2. **an order** for one or more names.
3. **a challenge per name**, which the client has to meet to prove it controls the name.
4. **validation.** The CA checks the challenge from its own side.
5. **finalisation.** The client sends a certificate signing request with the server's public key, and
   downloads the certificate.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"A sequence between certbot on the web server and the ACME server. Certbot registers an account, places an order for ipelivros.example, and receives a challenge token. It writes the token under /.well-known/acme-challenge on the web server. The ACME server fetches that URL over HTTP from the outside. Certbot then sends a signing request and downloads the certificate.\"><defs><marker id=\"fac-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"10\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">certbot, on your server</text><rect x=\"470\" y=\"10\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ACME server (CA)</text><line x1=\"130\" y1=\"50\" x2=\"130\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"570\" y1=\"50\" x2=\"570\" y2=\"290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"132\" y1=\"75\" x2=\"568\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fac-ah)\"></line><text x=\"350\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1. new account (public key)</text><line x1=\"132\" y1=\"110\" x2=\"568\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fac-ah)\"></line><text x=\"350\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2. new order: ipelivros.example</text><line x1=\"568\" y1=\"145\" x2=\"132\" y2=\"145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fac-ah)\"></line><text x=\"350\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. challenge: serve token T over HTTP</text><line x1=\"132\" y1=\"240\" x2=\"568\" y2=\"240\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fac-ah)\"></line><text x=\"350\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5. CSR, then download the certificate</text><rect x=\"160\" y=\"165\" width=\"160\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">/.well-known/acme-challenge/T</text><path d=\"M 568 182 L 322 182\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#fac-ah)\"></path><text x=\"445\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">4. GET over port 80</text><text x=\"350\" y=\"275\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the CA checks control of the name, and nothing else</text></svg>", "caption": "The five steps of an ACME order with an HTTP-01 challenge. Step 4 is the only check the CA makes."}
```

## The challenges

The challenge is the whole point, because it is the only thing the CA checks. There are three kinds:

| challenge | the client proves control by | needs |
|---|---|---|
| **HTTP-01** | serving a given token at `http://<name>/.well-known/acme-challenge/<token>` | port 80 reachable from the internet |
| **DNS-01** | publishing a given token in a TXT record at `_acme-challenge.<name>` | an API to change the domain's DNS |
| **TLS-ALPN-01** | answering a special TLS handshake on port 443 | port 443 reachable, and a server that speaks it |

**HTTP-01 is the default and the easiest**, and it is the one this lesson uses: the web server is
already answering on port 80 and only has to serve one more small file. **DNS-01 is the only one
that can issue a wildcard**, `*.ipelivros.example`, and the only one that works for a machine nobody
on the internet can reach, such as a server inside a company's network. Its cost is that the machine
asking for certificates needs credentials that can change the domain's DNS, which is a powerful
secret to keep on a web server.

## Why this lesson does not use Let's Encrypt

Let's Encrypt checks the challenge **from the internet**, so the name has to be a real domain, in
public DNS, pointing at a machine the internet can reach on port 80. The server you built in lesson 1
is a virtual machine on your computer with names that exist only in its own `/etc/hosts`. No public CA
can issue for it, and that is the system working as intended.

So the next sections use **Pebble**, which Let's Encrypt wrote for testing ACME clients. It speaks
the same protocol, `certbot` talks to it unchanged, and it checks the challenge by connecting to the
name exactly as Let's Encrypt would; the difference is that its root is not trusted by anybody until
you tell your machine to trust it. Everything in this lesson works the same against Let's Encrypt
with a real domain, with a couple of arguments removed, and each section that uses one says so.
