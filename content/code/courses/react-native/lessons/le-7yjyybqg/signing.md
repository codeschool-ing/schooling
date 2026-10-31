---
title: What a signature proves
version: 1
---

**Every Android and iOS app is signed, and the signature is its identity.** A phone refuses to install an
app with no signature, and it accepts an update only when the update is signed by the same key as the app
already installed. That rule is what stops anybody from shipping an "update" to your app: without your key,
they cannot.

The two platforms do it differently.

**Android signs with a key you make.** It lives in a *keystore*, a file protected by a password, and its
certificate is self-signed: no authority vouches for it, it only has to be the same key every time. Google
Play adds one layer, **Play App Signing**:

- You sign what you upload with an **upload key**, which is yours.
- Play checks that signature, removes it, and signs the app it delivers with an **app signing key** that
  Google keeps.

So the key phones see is Google's, and the key you could lose is only the upload key, which Play can replace
when you ask. *Before Play App Signing, losing the key meant the app could never be updated again; it is
still worth not finding out how replacing one goes.*

**iOS signs with a certificate Apple issues**, through a paid Apple Developer account. A build needs two
things: a **distribution certificate**, which says who you are, and a **provisioning profile**, which says
which app, with which capabilities (lesson 16's push is one), may be signed with it. Xcode makes and renews
both, which is part of why iOS builds need a Mac, or a service that has one. The last section is that
service.
