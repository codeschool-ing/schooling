---
title: Provisioning profiles, the permission slip
version: 1
---

**A provisioning profile is a file, signed by Apple, that says this app, signed by these
certificates, may run on these devices and use these entitlements.** The certificate says who you
are. The profile says what you are allowed to do with that identity, and the device checks it at
install. Nothing in this section was run; it is written from Apple's account help on provisioning
profiles, read on 30 October 2026.

A development profile holds four things, and Apple's page *Create a development provisioning
profile* asks for them in order:

1. **an App ID**, the team identifier and the bundle identifier of lesson 1 section 07;
2. **one or more development certificates**, the people allowed to sign this app;
3. **one or more registered devices**, by their unique identifier, up to the limits of section 02;
4. **the entitlements** the App ID was registered with, which section 07 checks against.

It also carries an **expiry date**, and an expired profile is the commonest reason a build that worked
yesterday will not install today. A distribution profile for the App Store names no devices: the
store installs on every device, after its own review.

## The kinds

| profile | for | names devices? |
|---|---|---|
| iOS App Development | running from Xcode on your registered devices | yes |
| Ad Hoc | handing a build to registered testers without the store | yes |
| App Store Connect | uploading for TestFlight and the App Store | no |

**A profile is a signed property list, and you can read it.** On a Mac,
`security cms -D -i profile.mobileprovision` strips the signature and prints the plist inside, with
its `ExpirationDate`, `Entitlements`, `ProvisionedDevices` and `TeamIdentifier`. That command was not
run for this course; it is the first one to type when a signing error makes no sense, because it shows
what the profile actually says rather than what you think it says.

Profiles live on the Mac in Xcode's own directory, and Xcode downloads them from your account. With
automatic signing, section 08, you rarely see one at all, until one expires.
