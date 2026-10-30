---
title: Certificates, and the chain that ends at Apple
version: 1
---

**A signing certificate is a public key with a name attached, signed by somebody whose signature the
device already trusts.** You keep the private key; Apple signs the public half and the name; anybody
holding the certificate can then check that a signature was made by the matching private key, and
that Apple vouched for whose key it is. Nothing in this section was run: the certificate types come
from Apple's *Certificates overview*, read on 30 October 2026. Section 05 runs the same mechanism on
a certificate authority made for the purpose, which is the part that runs anywhere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l21-chain\" aria-label=\"The chain of trust behind a signing certificate, drawn top to bottom. At the top, Apple&#x27;s root certificate, built into every Apple device. It signs the Worldwide Developer Relations intermediate certificate. That signs your Apple Development certificate, which holds your public key and your name. Your private key stays on your Mac, outside the chain, and signs the app. A device checks the app&#x27;s signature against your certificate and walks up the chain to the root it already trusts. A Mac missing the intermediate cannot complete the walk.\"><defs><marker id=\"l21-chain-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l21-chain-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l21-chain-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l21-chain-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"300\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Apple Root CA</text><text x=\"190\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">built into every device</text><rect x=\"40\" y=\"110\" width=\"300\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Apple WWDR intermediate</text><text x=\"190\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the link people forget</text><rect x=\"40\" y=\"200\" width=\"300\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Apple Development: you</text><text x=\"190\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your public key and name</text><path d=\"M190 80 L190 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-chain-ah-phosphor)\"></path><text x=\"240\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">signs</text><path d=\"M190 170 L190 198\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-chain-ah-amber)\"></path><text x=\"240\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">signs</text><rect x=\"430\" y=\"200\" width=\"260\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"560\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">your private key</text><text x=\"560\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on your Mac, never sent</text><rect x=\"430\" y=\"60\" width=\"260\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Planner.app</text><text x=\"560\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">signed, every file</text><path d=\"M560 198 L560 122\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-chain-ah-amber)\"></path><text x=\"608\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">signs the app</text><path d=\"M428 90 C 380 90, 370 225, 342 228\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l21-chain-ah-paper-dim)\"></path><text x=\"388\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">checked against</text></svg>", "caption": "A device trusts the root and walks down to your certificate; your private key signs and is never part of the chain."}
```

**The chain has three links, and the middle one is the one people forget.** Apple's root certificate
is built into every Apple device. It signs Apple's **Worldwide Developer Relations** intermediate
certificate, the WWDR certificate, and the intermediate signs yours. A Mac that has your certificate
but not the current WWDR intermediate cannot complete the chain, so signing with it fails until the intermediate is installed;
Apple's account help keeps a page of the intermediates for exactly that case. Section
05 shows what that failure looks like from `openssl`.

## The two you use

Apple's overview lists more than twenty types. An iOS app needs two of them, and the page says what
separates them:

- **Apple Development**, to "run an iOS, iPadOS, macOS, tvOS, visionOS, watchOS app on devices".
  Development certificates "belong to individuals", and Apple appends the computer's name to tell
  them apart.
- **Apple Distribution**, to distribute on registered devices or "submit it to App Store Connect".
  Distribution certificates "belong to the team", one of each type per team, and only the Account
  Holder or an Admin can create them.

**The private key is the certificate's only secret, and it never leaves your Mac unless you export
it.** Losing it means making a new certificate; sharing it means somebody else can sign as you.
Apple's overview is direct about this: "Do not share Apple Certificates outside of your
organization." A distribution certificate is the team's, so a team shares it through Xcode's
account settings rather than by sending a file around, and revokes it in the developer account the
day it is exposed.
