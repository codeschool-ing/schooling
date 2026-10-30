---
title: Why iOS runs only signed code
version: 1
---

**An iPhone runs no code that Apple's chain of trust has not vouched for.** Every app, every
framework inside it and every extension is signed, and iOS checks the signature before it runs a
single instruction. On a Mac you can run a program you compiled yourself; on an iPhone you cannot,
and that difference is the whole reason this lesson exists. Nothing here was run: it is written from
Apple's *Platform Security Guide* and its documentation for code signing, read on 30 October 2026.

A signature answers three questions at once:

- **Who made this?** The signing certificate names a developer, and the certificate was issued by
  Apple, so the name is one Apple checked when the membership was bought.
- **Has it changed since?** The signature covers every file in the app. Change one byte and the
  signature no longer matches, so iOS refuses to launch it. This is what makes an app from the App
  Store the same app the developer uploaded.
- **What is it allowed to do?** The entitlements of section 07 are part of the signed content, so an
  app cannot give itself access to iCloud or to push notifications after the fact.

**The belief to drop is that signing is a step at the end.** It is checked at every install on a
device, during development as much as for the store. A free Personal Team, from section 02, signs
too: Xcode makes a development certificate and a profile for you, which is why your own phone runs
your own app for seven days at a time.

## Three pieces, one question each

Signing is three files that people tend to blur together, and every signing error is one of them
missing, expired or mismatched:

| piece | what it is | the question it answers |
|---|---|---|
| **certificate** | your public key, signed by Apple, with your private key kept on your Mac | who signed this? |
| **provisioning profile** | a file signed by Apple naming an App ID, certificates, devices and entitlements | may this app, signed by them, run here and do this? |
| **entitlements** | the permissions the app claims, inside its signature | what does it want to do? |

Sections 04 and 05 take the certificate, section 06 the profile, section 07 the entitlements, and
section 08 the button in Xcode that manages all three for you.
