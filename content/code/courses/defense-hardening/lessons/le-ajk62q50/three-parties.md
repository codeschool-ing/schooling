---
title: 802.1X, and the three parties to a login
version: 1
---

**IEEE 802.1X makes a device log in to the port before the port carries anything else.** Where a MAC
filter checks an address the device chose, 802.1X asks for a credential the network issued: a
certificate and its private key, or a username and password. Until the device proves it holds one,
the port forwards a single kind of frame, the login conversation itself.

Three parties take part, and their names are worth learning because every product uses them:

| | who it is | in the lab |
|---|---|---|
| **supplicant** | the device asking to join, and the software on it that answers | `wpa_supplicant` on `desk` |
| **authenticator** | the switch port (or Wi-Fi access point) that holds the door | `hostapd` on `sw`, on `port-desk` |
| **authentication server** | the server that checks the credential and says yes or no | normally a RADIUS server; here, `hostapd`'s own |

The conversation is **EAP**, the Extensible Authentication Protocol, which carries one of many
methods inside it. Between the supplicant and the authenticator, EAP travels in **EAPOL** frames, EAP
over LAN, with an Ethernet type of its own, `0x888e`, sent to a reserved address no bridge forwards.
Between the authenticator and the server it travels inside **RADIUS**. The authenticator mostly passes
messages along: the decision is the server's, and the switch only opens or keeps closed the port.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l04-three-parties\" aria-label=\"The three parties of 802.1X. On the left the supplicant, desk, running wpa_supplicant. In the middle the authenticator, the switch port port-desk, with two paths through it: one that carries only EAPOL frames and is always open, and one for all other traffic that stays closed until the login succeeds. On the right the authentication server, normally RADIUS. EAP travels in EAPOL between desk and the port, and inside RADIUS between the port and the server. The server answers accept or reject, and only then does the port open.\"><defs><marker id=\"l04-three-parties-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l04-three-parties-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"80.0\" width=\"150.0\" height=\"90.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">supplicant</text><text x=\"95.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">desk</text><text x=\"95.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">wpa_supplicant</text><rect x=\"280.0\" y=\"50.0\" width=\"170.0\" height=\"170.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"365.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">authenticator</text><text x=\"365.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">port-desk</text><rect x=\"295.0\" y=\"110.0\" width=\"140.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">EAPOL: always open</text><rect x=\"295.0\" y=\"160.0\" width=\"140.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"365.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the rest: closed</text><text x=\"365.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">until the server accepts</text><rect x=\"560.0\" y=\"80.0\" width=\"140.0\" height=\"90.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">authentication</text><text x=\"630.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">server</text><text x=\"630.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">RADIUS</text><path d=\"M170.0 120.0 L295.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l04-three-parties-dh-ah-phosphor)\" marker-start=\"url(#l04-three-parties-dh-ah-phosphor)\"></path><text x=\"232.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">EAP in EAPOL</text><path d=\"M450.0 120.0 L560.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l04-three-parties-dh-ah-paper-dim)\" marker-start=\"url(#l04-three-parties-dh-ah-paper-dim)\"></path><text x=\"505.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">EAP in RADIUS</text><text x=\"630.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">accept or reject</text><text x=\"360.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in the lab, hostapd plays both the port and the server</text></svg>", "caption": "The port carries the login and nothing else until the server says yes."}
```

## The port's two states

Until a login succeeds, the port is **unauthorised**: EAPOL frames pass, so the device can log in,
and nothing else does. After a success it is **authorised**, and the device's traffic flows. A logoff
from the device, a link going down, or a timer for re-authentication closes it again.

## Which method

The method decides what the credential is, and the difference matters:

- **EAP-TLS**: both sides present certificates. The device proves it holds a private key that the
  network's certificate authority signed, and the device checks the server's certificate the same
  way. There is no password to guess, phish or reuse, which is why it is the strongest choice, and it
  is the one the next section builds. Its cost is issuing and renewing a certificate per device.
- **PEAP** with MSCHAPv2, or **EAP-TTLS**: the server presents a certificate, and the device sends a
  username and password through the encrypted tunnel. Easier to deploy, and only as strong as the
  passwords, and as the device's check of the server's certificate: a supplicant that accepts any
  certificate will hand its password to whatever answers on the port.

In both, **the supplicant must check the server.** A login that proves the device to the network and
not the network to the device is half a login.
