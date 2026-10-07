---
title: What an attack surface is
version: 1
---

A threat model asks what can go wrong. An attack surface asks a narrower question first: **where
can anything from outside reach in, and where does anything of ours leave?** Every threat in lesson
3 arrived through one of those places. A map of them is the checklist of where to look, and its
size is one of the few security properties of a design you can count.

The idea was given a formal shape by Michael Howard at Microsoft in the early 2000s, and then by
Pratyusa Manadhata and Jeannette Wing at Carnegie Mellon, who defined a system's attack surface as
three sets:

| | what it is | at the portal |
|---|---|---|
| **entry and exit points** | the methods through which data enters or leaves the system | the sign-in form, the upload, the webhook handler, the pages, the reminder call |
| **channels** | the ways an outsider connects to those points | HTTPS from the internet, HTTPS from the vendors, the clinic network |
| **untrusted data items** | the data an outsider can read or write through them | the uploaded PDFs, the booking fields, the webhook's body |

In a data flow diagram, all three are already drawn. **An entry point is a flow that crosses a
boundary into what you run; an exit point is a flow that crosses out.** That is why the map can be
computed from the model of lesson 2, which this lesson does.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l06-three-sets\" aria-label=\"Manadhata and Wing’s three sets that make up an attack surface, with an example of each at the portal. Entry and exit points: the webhook handler. Channels: HTTPS from the vendors. Untrusted data items: an uploaded PDF.\"><rect x=\"20.0\" y=\"30.0\" width=\"210.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">entry and exit points</text><text x=\"125.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the webhook handler</text><rect x=\"255.0\" y=\"30.0\" width=\"210.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">channels</text><text x=\"360.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">HTTPS from the vendors</text><rect x=\"490.0\" y=\"30.0\" width=\"210.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">untrusted data items</text><text x=\"595.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">an uploaded PDF</text><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">all three are already in the DFD: flows across a boundary, their transport, their data</text></svg>", "caption": "The definition is three lists, and a data flow diagram already holds all of them."}
```

### Surface is not risk

A larger surface means more places to look, not more risk at each one. A read-only page that shows
the clinics' opening hours is part of the surface and almost nobody cares about it. The webhook is
one entry point and decides whether a booking is paid. So the map comes with two questions per
entry: **who can reach it without a credential, and what can it change?** The answers rank the
entries, and the second part of this lesson shrinks the ones at the top.

### The parts nobody draws

The surface is also everything that runs with your system's trust: the libraries the portal
imports, the services it calls, the tools that build and deploy it. None of them appears as a
circle in the DFD, and each is a way for somebody else's mistake to become Vereda's. The section
on dependencies draws them.
