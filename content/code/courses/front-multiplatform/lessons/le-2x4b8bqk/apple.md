---
title: Apple's chain, read rather than run
version: 1
---

**This section is read, not practised**: everything in it happens in Xcode and in Apple's developer website,
on a Mac, with a paid membership of the Apple Developer Program, and none of it ran for this course. It comes
from Apple's documentation and Capacitor's, and it is here so that the words mean something when you meet
them.

Apple's signing has more parts than Android's because Apple decides, for every app, **which devices may run
it**. Four things meet:

| piece | what it is | where it comes from |
|---|---|---|
| **certificate** | your signing identity: a key pair on your Mac, and a certificate Apple issued for its public half | Xcode, or the Certificates page of the developer website |
| **App ID** | the bundle identifier, registered, with the capabilities the app uses, such as notifications | the Identifiers page; `com.example.studyplanner` for the planner |
| **device list** | the iPhones a development or ad hoc build may run on | registered by their identifiers |
| **provisioning profile** | a file Apple signs that joins the three: this certificate may sign this app for these devices, or for the store | generated from the other three |

**Xcode's automatic signing does all four for you**: in the project's **Signing & Capabilities** tab, tick
**Automatically manage signing** and choose your team, and Xcode creates the certificate, registers the App ID
and fetches the profiles. Manual signing, with each piece chosen by hand, is what larger teams and CI services
use, because a CI machine has no Apple account signed in to it.

A build for the store is signed with a **distribution** certificate and an **App Store** profile, and then
**Product, Archive** and **Distribute App** of lesson 13 upload it to App Store Connect. From there it reaches
testers through **TestFlight**, and everybody else through review and the App Store.

**The private key of the certificate is on the Mac that created it.** Exported from Keychain Access as a
`.p12` file, with a password, it is what another Mac or a CI service needs to sign as you, and it deserves
the care of the Android keystore: two backups, never in a repository.

## The Mac app, outside the store

A Mac app handed out as a `.dmg` is signed with a **Developer ID** certificate and then **notarised**: uploaded
to Apple with `xcrun notarytool submit`, scanned, and given a ticket that `xcrun stapler staple` attaches to the
app. Gatekeeper, the part of macOS that checks downloads, opens a notarised app with no warning. Electron's
packager and Tauri's both run these steps when they are given the certificate and an Apple ID; each one's
documentation has a page on it.
