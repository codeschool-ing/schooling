---
title: The chain Apple checks
version: 1
---

**On Android you are your own authority; on iOS, Apple is, and an app runs only when Apple has
signed for every link in a chain.** Lesson 1 made a key that nobody vouched for, and the phone was
satisfied as long as updates matched it. An iPhone asks more: who signed the app, whether Apple
issued that person's certificate, which app it is, what it is allowed to do, and on which devices
it may run. *Everything in this lesson happens on a Mac with Xcode, and none of it was run for
this course; it is read from Apple's developer documentation, October 2026.*

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-chain\" aria-label=\"Three inputs feed a provisioning profile. The certificate says who signs, and its private key stays on the Mac that made it. The App ID says which app, by bundle identifier, and with which capabilities. The device list says where a development or ad hoc build may run; an App Store profile has none. The profile, signed by Apple, is embedded in the signed app, and every part of it carries an expiry date except the App ID.\"><defs><marker id=\"l02-chain-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"220\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"130\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">certificate</text><text x=\"130\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">who signs</text><text x=\"130\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">private key on one Mac</text><path d=\"M240 58 L300 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-chain-ah-paper-dim)\"></path><rect x=\"20\" y=\"108\" width=\"220\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">App ID</text><text x=\"130\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">which app:</text><text x=\"130\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">com.example.planner</text><text x=\"130\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and its capabilities</text><path d=\"M240 146 L300 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-chain-ah-paper-dim)\"></path><rect x=\"20\" y=\"196\" width=\"220\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"130\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">devices</text><text x=\"130\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">where it may run</text><text x=\"130\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(none for the App Store)</text><path d=\"M240 234 L300 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-chain-ah-paper-dim)\"></path><rect x=\"302\" y=\"104\" width=\"200\" height=\"92\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"402\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">provisioning profile</text><text x=\"402\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">signed by Apple</text><text x=\"402\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">embedded in the app</text><path d=\"M502 150 L556 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-chain-ah-paper-dim)\"></path><rect x=\"558\" y=\"124\" width=\"142\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"629.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the signed app</text><rect x=\"470\" y=\"248\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"500\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">has an expiry date</text></svg>", "caption": "Every box with a dashed edge has a date on it. The App ID is the only link that never expires."}
```

## The four links

**The certificate says who.** You make a private key on your Mac and send Apple a **certificate
signing request**, which carries the public half. Apple returns a certificate binding that public
key to your team. The private key never leaves the Mac that made it, and that is the part people
lose: a certificate in the developer portal is useless without the key in some Mac's keychain.

**The App ID says which app.** It is the **bundle identifier**, such as `com.example.planner`,
registered in your account, plus the **capabilities** the app uses: push notifications, iCloud,
Sign in with Apple. It plays the role the package name plays on Android, and it cannot change
after the app is published either.

**The entitlements say what the app may do.** They are a list baked into the signature: this app
may receive push notifications, may share a keychain group, may use this iCloud container. A
capability turned on in the App ID and missing from the entitlements, or the reverse, is a
signing error at build time or a feature that silently does nothing at run time.

**The provisioning profile ties them together.** It is a file, signed by Apple, saying: *apps
signed by these certificates, with this App ID and these entitlements, may run on these devices*
— or, for the App Store, on any device once Apple has re-signed them. Xcode embeds it in the app
as `embedded.mobileprovision`.

## Why the chain, and not just a key

Android lets anybody install anything they choose to trust; iOS lets nothing run that Apple did
not sign. The chain is how Apple delegates: it signs your certificate, your certificate signs the
app, and the profile says which of your apps may do what. **Everything Apple signed can expire or
be revoked, which is the one property Android's self-made keys do not have**, and section "Watching
the expiry" is about living with it.

And there is a top to the chain that is not yours either: Apple's own intermediate certificate,
the Worldwide Developer Relations certificate, has an expiry date as well. The one in use since
January 2021 expires on 20 February 2030.
