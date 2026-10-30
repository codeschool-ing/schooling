---
title: Development, ad hoc and the App Store
version: 1
---

**There is no single "signed iOS build": there are several, and each answers a different question
about where the app may run.** The certificate and the profile change with the answer.

| | certificate | profile | runs on |
|---|---|---|---|
| **development** | Apple Development, one per developer | development | the team's registered devices, with a debugger attached |
| **ad hoc** | Apple Distribution, one for the team | ad hoc | up to 100 registered devices per product family a year, without the store |
| **App Store and TestFlight** | Apple Distribution | App Store | any device, once Apple has re-signed it |
| **enterprise** | an in-house distribution certificate | in-house | a company's own devices, with a separate, stricter program |

**A development certificate belongs to a person; a distribution certificate belongs to the team.**
Apple's portal even appends the computer's name to a development certificate, so you can tell
"Ana's MacBook" from "Ana's office Mac". A team has few distribution certificates and shares them,
which is exactly what makes them dangerous to lose and awkward to share.

## The 100 devices

Ad hoc builds run only on devices whose identifiers are registered in the account, and Apple
allows 100 per product family per membership year: 100 iPhones, 100 iPads, and so on. **Removing
a device does not give the slot back until the next membership year**, when the account holder is
offered a reset. A team that registers every phone it meets runs out in the spring. Lesson 7's
TestFlight exists largely because of this: testers there need no registration at all.

## What expiry does to each

The date on a certificate matters differently depending on what was signed with it. Apple's
documentation is specific, and worth reading word by word:

- **An App Store app keeps working when the distribution certificate expires**, provided the
  membership is current. You can no longer upload new builds signed with it, and builds uploaded
  but not yet submitted may be marked *Invalid Binary* if the certificate was revoked.
- **An ad hoc or development build stops launching** when its profile expires. The testers' copies
  simply refuse to open.
- **A lapsed membership** removes your apps from the store; people who already installed them can
  still use them.

So expiry rarely breaks the people using your app. **It breaks you**: the release build that
signed fine yesterday fails this morning, the day before a launch.

## The three platforms side by side

| | Android | iOS | React Native |
|---|---|---|---|
| a build for your own phone | debug key, made automatically | development certificate and profile | the platform's, per platform |
| a build for testers outside the store | any APK signed with your key | ad hoc, registered devices only | per platform; Expo can share an ad hoc build by link |
| the store build | an `.aab` signed with the upload key | an archive signed with the distribution certificate | both |
