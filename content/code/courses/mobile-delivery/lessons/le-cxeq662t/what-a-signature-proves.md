---
title: What a signature proves, and what it does not
version: 1
---

**A common belief is that the signature proves the app is safe, or that Google vouched for it.
It proves neither.** An Android signature is made with a key you generated yourself, on a
certificate you signed yourself; no authority stands behind it. What it proves is narrower and
more useful: **every version of this app was signed by the holder of the same key.**

That narrow fact is what the system leans on. When an update arrives, Android compares the
certificate on the new package with the one on the installed app. If they match, the update
replaces the app and keeps its data. If they differ, the install is refused, and no setting on
the phone overrides it. A stranger can publish an app that looks like yours. They cannot publish
an *update* to yours.

## The key is the app

Two things together make an Android app the same app across its whole life: the **package name**
in the manifest and the **signing key**. Change either and the system sees a different app. A new
package name is a new listing with no reviews and no installs; a new key on the same package name
is an update every phone refuses.

| what changes | what a phone with the old version does |
|---|---|
| the code, the version, the icon | installs the update and keeps the data |
| the signing key | refuses the update: the signatures do not match |
| the package name | installs a second, separate app beside the first |

**This is why a lost key used to end an app.** Before Google Play held keys for developers, losing
the keystore file, or its password, meant the app could never be updated again. The only way out
was a new package name, a new listing, and asking every user to uninstall the old app and find the
new one. Some never did. Section "Play App Signing" below is how that stopped being the usual end.

## Two things a key also decides

**Permissions between your own apps.** A permission declared with `signature` protection is
granted only to apps signed with the same key. Two apps from the same developer can share data
that way, and an app signed by somebody else cannot ask for it.

**Which services believe it is your app.** Google's own services identify an app by its package
name *and* the SHA-256 fingerprint of its signing certificate. A sign-in that works in a debug
build and fails in the release is, more often than not, a fingerprint registered for the debug key
and not for the release one. Android Studio signs debug builds with an automatically generated
debug key in `~/.android/debug.keystore`, which is different on every computer and is never what
the store receives.

## The same idea on the other two

| | Android | iOS | React Native |
|---|---|---|---|
| who issues the certificate | you, with `keytool` | Apple, from a request you make | each platform, as above: the JavaScript is inside a native app |
| what the store checks | the same key signs every update | the build was signed by your team's distribution certificate | both, one per platform |
| what a phone checks | the signature matches the installed app | Apple's signature on the app | both, one per platform |

Lesson 2 is the iOS half, which works differently enough to need its own lesson: there, Apple is
the authority, and certificates expire every year.
