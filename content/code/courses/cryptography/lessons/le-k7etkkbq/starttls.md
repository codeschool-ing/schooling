---
title: SSL, TLS, and the two ways to switch a protocol to encryption
version: 1
---

**SSL is the old name of TLS.** Netscape designed SSL 2.0 and 3.0 in the mid-1990s; the IETF took
the protocol over and renamed it TLS 1.0 in 1999. Every SSL version is broken and prohibited, and
nothing in use today speaks it. The name survives in product menus, in OpenSSL's own name and in the
phrase "SSL certificate", which means a TLS certificate: the certificates of lessons 8 and 9 are the
same whichever name is printed on the invoice.

What matters more than the name is **how** a protocol gets into TLS, because there are two ways and
one of them can be undone by an attacker.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two timelines of a connection. Implicit TLS, as LDAPS on port 636: connect, TLS handshake, then the protocol, encrypted from the first byte. STARTTLS, as LDAP on port 389: connect, the protocol starts in clear text, the client asks to upgrade, the TLS handshake follows, then the protocol continues encrypted. The clear-text stretch before the upgrade is where an attacker can strip the offer.\"><defs><marker id=\"tw-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">implicit TLS (LDAPS, 636)</text><rect x=\"20\" y=\"40\" width=\"90\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"65\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">connect</text><rect x=\"110\" y=\"40\" width=\"170\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"195\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">TLS handshake</text><rect x=\"280\" y=\"40\" width=\"420\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"490\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">LDAP bind and queries, encrypted</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">STARTTLS (LDAP, 389)</text><rect x=\"20\" y=\"130\" width=\"90\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"65\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">connect</text><rect x=\"110\" y=\"130\" width=\"170\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"195\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">clear text: StartTLS?</text><rect x=\"280\" y=\"130\" width=\"140\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">TLS handshake</text><rect x=\"420\" y=\"130\" width=\"280\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">bind and queries, encrypted</text><polyline points=\"195,200 195,168\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#tw-ah-amber)\"></polyline><text x=\"195\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">an attacker on the path can remove the offer here</text><text x=\"195\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">unless the client requires TLS (-ZZ, --ssl-reqd)</text></svg>", "caption": "Implicit TLS leaves no clear-text stretch; STARTTLS has one, before the upgrade."}
```

## Implicit TLS: a separate port

The client connects and starts a TLS handshake immediately, before the application protocol says a
word. HTTPS on 443, LDAPS on 636, IMAPS on 993 and SMTP submission on 465 work this way. There is no
moment in which the connection is unencrypted, so there is nothing to strip.

## STARTTLS: an upgrade on the same port

The client connects to the ordinary port, the protocol starts in clear text, and the client sends a
command, `STARTTLS` in SMTP and IMAP, the *StartTLS extended operation* in LDAP, `AUTH TLS` in FTP,
asking to switch. The handshake happens and the protocol continues encrypted. OpenSSL can do the
LDAP version itself:

```
ana@lab:~/lab$ echo | openssl s_client -connect ldap.vereda.example:3389 -starttls ldap -CAfile pki/root.pem -verify_hostname ldap.vereda.example 2>&1 | grep -E '^(New|Verif)'
Verification: OK
Verified peername: ldap.vereda.example
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Verify return code: 0 (ok)
```

The result is the same TLS 1.3 connection as lesson 10, verified against Vereda's root and the
directory's name.

## The weakness of an optional upgrade

Before the upgrade, the conversation is in clear text and nothing protects it. An attacker on the
path can remove the server's offer of STARTTLS, or answer the client's request with an error, and a
client that treats encryption as optional carries on unencrypted, believing the server simply does
not support it. This is a **STARTTLS stripping** attack, and it has been seen against e-mail on real
networks. The defences are all variations on one rule, **make the upgrade mandatory**:

- clients configured to refuse if TLS is not established: `--ssl-reqd` in curl (section 02), `-ZZ` in
  the OpenLDAP tools (next section), `smtp_tls_security_level = encrypt` in Postfix;
- servers that refuse to authenticate before TLS, as Vereda's directory does next;
- for mail between organisations, **MTA-STS** and **DANE**, which publish the fact that a domain
  requires TLS, so that a stripped offer is noticed;
- where a choice exists, **implicit TLS**, which RFC 8314 recommends for mail clients precisely
  because nothing can be stripped.
