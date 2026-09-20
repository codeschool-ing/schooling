---
title: Where the addresses come from
version: 1
---

Every device on a network needs a number, the way every house on a street needs one. There are
two kinds of number in a home, and confusing them is behind most of the questions people ask
about IP addresses.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 306\" role=\"img\" aria-label=\"A diagram of a home network. At the top, the street, carrying one public address. Below it the router, holding the address one nine two dot one six eight dot zero dot one. Four lines run from the router down to a laptop, a phone, a television and a printer, each with its own private address ending in fourteen, fifteen, twenty-two and thirty.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">One address outside, many inside</text><rect x=\"24\" y=\"40\" width=\"672\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the street</text><text x=\"676\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">187.4.22.91</text><path d=\"M360 80 L360 118\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><rect x=\"260\" y=\"118\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"133\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the router</text><text x=\"280\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">192.168.0.1</text><text x=\"24\" y=\"180\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">inside the house, reachable from nowhere else</text><path d=\"M360 162 L360 196 L102 196 L102 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><rect x=\"24\" y=\"214\" width=\"156\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"229\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">laptop</text><text x=\"40\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">192.168.0.14</text><path d=\"M360 162 L360 196 L274 196 L274 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><rect x=\"196\" y=\"214\" width=\"156\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"212\" y=\"229\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">phone</text><text x=\"212\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">192.168.0.15</text><path d=\"M360 162 L360 196 L446 196 L446 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><rect x=\"368\" y=\"214\" width=\"156\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"384\" y=\"229\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">television</text><text x=\"384\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">192.168.0.22</text><path d=\"M360 162 L360 196 L618 196 L618 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><rect x=\"540\" y=\"214\" width=\"156\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"556\" y=\"229\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">printer</text><text x=\"556\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">192.168.0.30</text><text x=\"24\" y=\"286\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The house next door is using the same four numbers, and no packet has ever confused the two.</text></svg>", "caption": "The router is the only device in the house with an address on each side. Everything else has one address and no idea there is another side."}
```

## One address outside, many inside

Your provider gives your line **one public address** — the one the rest of the internet can reach.
Inside the house, the router hands out **private addresses**, from ranges reserved for exactly
this purpose and reachable from nowhere else:

- `192.168.0.0` to `192.168.255.255` — by far the most common at home;
- `10.0.0.0` to `10.255.255.255` — common in offices and on some providers' boxes;
- `172.16.0.0` to `172.31.255.255` — the one nobody remembers.

**Every house on your road is using the same numbers**, and that is fine, because those numbers
never leave the house. `192.168.0.14` in your flat and `192.168.0.14` next door are two different
machines that will never hear of each other.

The router is what makes this work. When your laptop asks for a page, the router replaces the
private address with the public one on the way out, writes down that it did so, and puts the
private address back on the answer coming in. That translation is why one address can serve
twenty devices, and it is the reason a device inside can start a conversation with the outside
while the outside cannot start one with a device inside.

## DHCP, which is the handing out

Nobody types these numbers. **DHCP** is the service — running on the router — that answers a
device saying *I am new here, what is my address?* with an address, a validity period, and the
two other things a device needs: which address is the router itself, and which address answers
name questions.

The validity period is called a **lease**, and it is why an address can change. A phone that has
been away for a week comes back and may be given a different number, which is harmless for a
phone and is not harmless for a printer.

**So some things want a fixed address:** a printer, a network drive, a camera, anything another
device is configured to find by number. The right way to fix one is a **DHCP reservation** on the
router — *this device always gets this address* — rather than typing a fixed address into the
device itself. The reservation keeps the router informed; a hand-typed address is a number the
router does not know it must avoid.

## DNS, in one paragraph

Nothing on a network is found by name. **DNS** is the service that turns `codeschool.ing` into an
address, and it runs somewhere upstream — usually at your provider, sometimes at a public
resolver like Cloudflare's `1.1.1.1` or Google's `8.8.8.8`.

It is worth knowing because of a specific symptom: **when DNS fails, everything looks broken and
nothing is.** The line works, the router works, the Wi-Fi works, and every name fails to resolve,
so every browser says it cannot find the site. Testing an address directly — a page that answers
on its number — separates the two in about ten seconds.
