---
title: Enterprise, a key for each person
version: 1
---

A shared passphrase has three problems no algorithm fixes. When somebody leaves, **everybody's devices
need the new one**. The log cannot say who was connected, only that a device knew the secret. And the
secret is on a sticky note somewhere, because two hundred people had to type it.

WPA2-Enterprise and WPA3-Enterprise replace the passphrase with **802.1X**: each person signs in with
their own credentials, and the AP only lets them on when a server says yes. Three parties take part.

| role in 802.1X | who plays it | what it does |
|---|---|---|
| supplicant | the client's operating system | presents credentials |
| authenticator | the access point | relays, and enforces the verdict |
| authentication server | a RADIUS server | checks the credentials against a directory |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 420\" role=\"img\" aria-label=\"A sequence between three parties: a client, the supplicant; an access point, the authenticator; and a RADIUS server, the authentication server. Between client and AP, EAP travels over the air in EAPOL; between AP and server, RADIUS travels on the wire over UDP 1812. 1: the client associates and the port passes EAP and nothing else. 2: the AP asks who it is. 3: an identity, relayed by the AP to the server. 4: a TLS tunnel, in which the client checks the server&#x27;s certificate. 5: a password or a client certificate, inside TLS. 6: the server tells the AP to accept, with a key for this session and a VLAN. 7: the four-way handshake between client and AP, and then the port opens.\"><defs><marker id=\"dx-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"180\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client</text><text x=\"110\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">supplicant</text><path d=\"M110 80 L110 410\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"260\" y=\"14\" width=\"180\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">access point</text><text x=\"350\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">authenticator</text><path d=\"M350 80 L350 410\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"500\" y=\"14\" width=\"180\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">RADIUS server</text><text x=\"590\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">authentication server</text><path d=\"M590 80 L590 410\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"230\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">over the air: EAP in EAPOL</text><text x=\"470\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">on the wire: RADIUS, UDP 1812</text><text x=\"230.0\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1  associate: the port passes EAP and nothing else</text><path d=\"M110 130 L344 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#dx-ah)\"></path><text x=\"230.0\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2  EAP: who are you?</text><path d=\"M350 172 L116 172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#dx-ah)\"></path><text x=\"350.0\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3  an identity, relayed by the AP</text><path d=\"M110 214 L584 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#dx-ah)\"></path><text x=\"350.0\" y=\"247\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4  TLS: the client checks the server's certificate</text><path d=\"M590 256 L116 256\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#dx-ah)\"></path><text x=\"350.0\" y=\"289\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5  password or client certificate, inside TLS</text><path d=\"M110 298 L584 298\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#dx-ah)\"></path><text x=\"470.0\" y=\"331\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">6  accept: a key for this session, and a VLAN</text><path d=\"M590 340 L356 340\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#dx-ah)\"></path><text x=\"230.0\" y=\"373\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">7  four-way handshake, then the port opens</text><path d=\"M350 382 L116 382\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#dx-ah)\"></path></svg>", "caption": "802.1X with a TLS-based EAP method such as PEAP, EAP-TTLS or EAP-TLS. The AP never sees the password: it relays, waits for the server's verdict and receives a key made for this one session."}
```

Until the verdict arrives, **the AP lets EAP through and nothing else**: no DHCP, no DNS, no traffic of
any kind. EAP, the Extensible Authentication Protocol, is only an envelope. Between client and AP it
travels in EAPOL frames; between AP and server it travels inside RADIUS, over UDP 1812. What goes in the
envelope is the **EAP method**, and three cover nearly every network:

| method | the client proves itself with | what it needs |
|---|---|---|
| EAP-TLS | its own certificate | a certificate on every device, so a PKI and device management |
| PEAP (with MSCHAPv2 inside) | a username and password | a server certificate |
| EAP-TTLS | a username and password, or another inner method | a server certificate |

**EAP-TLS is the strongest, because there is no password to steal.** PEAP is the most common, because
the users already have passwords. Both begin the same way: the server shows its certificate and a TLS
tunnel is built, and the password only travels inside it.

## The setting that matters most

**A client must check the RADIUS server's certificate**: that it was issued by the certificate authority
you chose and that it names your server. A client that accepts any certificate will build its TLS tunnel
with any network that broadcasts the same SSID and run the exchange with it. Checking the certificate is
what makes the tunnel lead to the right place. It belongs in the configuration pushed to every managed
device, not in a dialogue box a user clicks through on the first day.

## What the server sends back

When the credentials are right, the server answers with an Access-Accept that carries **key material
made for this one session**. The AP uses it as the PMK, and the four-way handshake of the section on
WPA2 runs as usual. Two things follow:

- every person has a different key, so a colleague on the same SSID cannot read your traffic, even
  with a recording of your handshake;
- removing one person is one change: disable their account and the next authentication fails. The
  RADIUS accounting records, on UDP 1813, also say who was connected, when, and from which AP.

The accept can also carry a **VLAN** (RFC 3580 defines the attributes). One SSID can then put staff on
one VLAN and contractors on another, with the firewall between them deciding what each may reach. That is
how one SSID serves many groups without paying the airtime of many SSIDs.

## The price

A RADIUS server is now in the path of every new connection. **If it is down, nobody new gets on**, so it
is run in pairs, the kind of dependency lesson 14 is about. And devices that cannot do 802.1X, printers
and sensors mostly, go on a separate SSID with a passphrase and a VLAN of their own.
