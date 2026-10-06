---
title: IPsec, encryption at the network layer
version: 1
---

**IPsec encrypts and authenticates IP packets themselves, between two hosts or two gateways, so that
every application whose traffic crosses that path is protected without knowing it.** TLS lives
inside one application's connection; IPsec lives in the operating system's network stack. It is the
classic technology behind site-to-site VPNs, such as Vereda's clinics connecting to head office over
the internet, and behind many remote-access VPNs.

**This section has no capture.** The kernel the course was recorded on does not provide IPsec's ESP
transform inside the lab's network namespaces, and the course does not show output it could not run.
What follows is the protocol as its standards describe it.

## The pieces

- **ESP**, *Encapsulating Security Payload*, is the part that protects packets. Each packet carries a
  **SPI**, a number saying which security association applies, a sequence number against replay, the
  encrypted payload and an integrity tag. Modern configurations use AES-GCM, the authenticated mode of
  lesson 1. (**AH**, *Authentication Header*, authenticates without encrypting; it is rarely deployed
  because ESP does both and AH breaks behind NAT.)
- **IKEv2**, *Internet Key Exchange*, is the handshake that sets up the keys. It is lesson 7 again: an
  ephemeral Diffie-Hellman exchange for forward secrecy, authenticated with certificates or a
  pre-shared key, producing the keys ESP uses. It runs on UDP 500, and on UDP 4500 when NAT is in the
  way.
- A **security association** (SA) is the agreed set of keys and algorithms for one direction of
  traffic between two peers. IKE creates them, rekeys them before they wear out, and deletes them.

## Two modes

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Two packet layouts. Transport mode: the original IP header, then an ESP header, then the encrypted TCP header and data, then the ESP trailer and tag. Tunnel mode: a new outer IP header between the two gateways, an ESP header, then the whole original packet encrypted, including its IP header, then the ESP trailer and tag.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">transport mode</text><rect x=\"20\" y=\"36\" width=\"128\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"84.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IP header</text><rect x=\"150\" y=\"36\" width=\"88\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"194.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ESP</text><rect x=\"240\" y=\"36\" width=\"328\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"404.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">TCP header + data</text><rect x=\"570\" y=\"36\" width=\"128\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"634.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ESP tag</text><text x=\"20\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tunnel mode</text><rect x=\"20\" y=\"126\" width=\"128\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"84.0\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new IP header</text><rect x=\"150\" y=\"126\" width=\"68\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"184.0\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ESP</text><rect x=\"220\" y=\"126\" width=\"118\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"279.0\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">original IP</text><rect x=\"340\" y=\"126\" width=\"228\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"454.0\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">TCP header + data</text><rect x=\"570\" y=\"126\" width=\"128\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"634.0\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ESP tag</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the observer sees only the two gateways</text></svg>", "caption": "Red travels in clear text; blue is encrypted. The tag covers the ESP header and everything encrypted."}
```

**Transport mode** protects the payload of a packet between two hosts and keeps the original IP
header, so the endpoints are visible. **Tunnel mode** encrypts the **entire** original packet and wraps
it in a new one between two gateways, so an observer on the internet sees only the two gateways
talking: not which machines inside each office are communicating, nor on which ports. Site-to-site
VPNs use tunnel mode.

## What a defender checks

- **IKEv2, not IKEv1**, which had a weaker design and a common misconfiguration ("aggressive mode")
  that exposed a hash of the pre-shared key to anybody who asked;
- **certificates rather than a pre-shared key**, or at least a long random one: a weak shared key can
  be guessed offline, the lesson 5 problem in another form;
- **AES-GCM with a Diffie-Hellman group of at least 2048 bits, or an elliptic curve**, and no DES,
  3DES or MD5 left in the proposals for compatibility with a device nobody remembers;
- WireGuard, a newer VPN protocol, makes most of these choices fixed: X25519, ChaCha20-Poly1305,
  BLAKE2s, keys instead of passwords. Fewer options means fewer ways to configure it badly.
