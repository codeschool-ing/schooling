---
title: Download size and install size
version: 1
---

**An app has two sizes, and they answer different questions.** The **download size** is what
travels over the network to the phone, compressed; it decides how long the install takes and how
much of somebody's data plan it costs. The **install size** is what the app occupies on the phone
once unpacked, and it grows as the app stores data; it decides whether the app is the one deleted
when the phone is full.

## What the stores enforce and show

- **Google Play limits an app bundle's compressed download to 200 MB**, according to Android's
  documentation on reducing app size, read in October 2026. Larger apps deliver the rest through
  Play Feature Delivery and Play Asset Delivery, after installation.
- **Apple limits an app's uncompressed size to 4 GB**, per App Store Connect's reference on build
  sizes. On the phone, an iPhone's settings let the person choose to be asked before a large app
  downloads over mobile data.
- **Both stores show the size on the listing**, lesson 4's page, beside the rating and the
  screenshots, so it is read before the decision.

Android's documentation says it plainly: people often avoid downloading apps that seem too large,
**particularly in emerging markets**, where devices have less storage and data costs more. For a
study planner aimed at students in Brazil, that is the audience, not an edge case.

## What makes an app large

| what | why it grows | the cure |
|---|---|---|
| images | one copy per screen density, each larger | ship per density, which the next section measures; vector drawables where they fit |
| native libraries | one copy per processor architecture | ship per architecture; app bundles do this |
| code | libraries pulled in for one function | R8 removes what nothing uses, lesson 13 |
| fonts, sounds, models | added once, kept forever | download them on demand, after install |

## The same question on three platforms

A Kotlin app's size is measured from its app bundle with the tool of the next section. A Swift app's
is reported by Xcode's **App Thinning Size Report**, which lists the size of each device variant the
App Store will make; Apple slices per device in the same spirit. A React Native app carries both,
plus the JavaScript bundle and the Hermes engine, which is why its smallest size starts higher than a
native app's.
