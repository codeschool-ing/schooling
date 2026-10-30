---
title: Building in the cloud with EAS
version: 1
---

**EAS Build is Expo's service that builds the native app for you**, on its own machines: Linux ones for
Android and Macs for iOS. You run one command, it uploads the project, runs `prebuild` and the native
build there, signs the result with credentials it keeps for you, and hands back an Android package or
an iOS one. **It is how many people publish to the App Store without owning a Mac**, the route lesson 1
mentioned.

*Nothing in this section was run for this course. EAS needs an Expo account and a person to accept its
terms, and the recording machine could not reach Expo's servers. The commands and the file come from
Expo's documentation for EAS Build.*

## `eas.json`

The builds are described in `eas.json`, beside `app.json`, as named **profiles**. `npx eas-cli build:configure`
writes a first one after you log in; this is the shape of it, with the three profiles almost every project
ends up with:

```json
{
  "cli": { "version": ">= 25.3.0", "appVersionSource": "remote" },
  "build": {
    "development": { "developmentClient": true, "distribution": "internal" },
    "preview": { "distribution": "internal", "android": { "buildType": "apk" } },
    "production": { "autoIncrement": true }
  }
}
```

- **`development`** builds the development build of the first section, with the developer menu in it,
  for your own phones.
- **`preview`** builds a release-like app for testers, installed straight from a link; on Android an APK,
  which a phone installs directly, rather than the bundle the store wants.
- **`production`** builds what goes to the stores. `autoIncrement` raises the build number on every
  build, and `appVersionSource: "remote"` keeps that number on Expo's side, so two people building do not
  both make build 12. Lesson 15 is about those numbers.

## The commands

```sh
npx eas-cli@25.3.0 login
npx eas-cli@25.3.0 build --platform android --profile preview
npx eas-cli@25.3.0 build --platform ios --profile production
```

The first iOS build asks for your Apple Developer account and offers to create the signing certificate
and the provisioning profile in it, which lesson 14 explains; Expo then keeps them for later builds.
**The free plan has a monthly allowance of builds and a queue**, on terms Expo sets and changes, and the
paid plans buy more of both.

`eas build --local` runs the same build on your own computer instead, which needs everything a native
build needs: the Android SDK of lesson 3, and for iOS a Mac with Xcode. It is how a team that does not
want its code on somebody else's machine still uses the same profiles.
