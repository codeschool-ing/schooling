---
title: Automatic signing, and when to turn it off
version: 1
---

**Xcode can manage the certificate, the App ID, the profile and the device list for you, and for one
developer on one Mac it should.** The setting is the target's *Signing & Capabilities* tab,
*Automatically manage signing*, with a **team** chosen from the accounts signed in to Xcode. Choose
the team, and Xcode creates a development certificate for this Mac if there is none, registers the
App ID for the bundle identifier, registers the device you plug in, and downloads a profile that
covers all of it. Add a capability in the same tab and Xcode adds the entitlement and updates the App
ID. Nothing here was run; it is written from Apple's Xcode help on signing, read on 30 October 2026.

The two errors you will meet most often with it on are both messages about something Xcode cannot do
for you:

- **the bundle identifier is taken**: another team registered it first, and lesson 1 section 07 is
  why it cannot be shared. Choose another identifier.
- **no account for the team**, or the membership has lapsed: sign in again in Xcode's *Accounts*
  settings, or renew, section 02.

## When a team turns it off

Automatic signing assumes Xcode, on this Mac, is the one making the decisions. Two situations break
that assumption:

- **a build server**, which archives the app with no person at the keyboard. It needs a distribution
  certificate and profile installed in advance and named explicitly. `mobile-delivery` lesson 10 is
  about signing inside a pipeline.
- **a team sharing one distribution identity**, where an automatic choice on one person's Mac should
  not revoke or replace what the others use.

Turning it off is *manual signing*: each configuration names a certificate and a profile, and
the profile is created in the developer account by hand, as section 06 described. **Manual signing
is not more secure, it is more explicit.** It trades Xcode's convenience for a written-down choice,
which is what a team with more than one Mac and a build server needs.
