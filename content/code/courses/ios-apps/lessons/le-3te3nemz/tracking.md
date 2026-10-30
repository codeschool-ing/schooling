---
title: Tracking, and the alert the planner never shows
version: 1
---

**Tracking has a narrow meaning on iOS, and it is not "collecting data".** Apple defines it as
linking data from your app with data from other companies' apps and websites, for advertising or
for advertising measurement, or sharing it with a data broker. An app that does that has to ask
first, through the **App Tracking Transparency** framework, and its alert carries the string in
`NSUserTrackingUsageDescription`. Nothing here was run; it is written from Apple's documentation for
that key and for `ATTrackingManager`, read on 30 October 2026.

The documentation for the key is blunt about what happens without it: "Your app crashes if it
attempts to use the AppTrackingTransparency framework without including the key". And guideline
5.1.2(i) adds that "you must receive explicit permission from users via the App Tracking
Transparency APIs to track their activity".

```swift
// Tracking.swift: the request, for an app that tracks
import AppTrackingTransparency

func askToTrack() async -> Bool {
    await ATTrackingManager.requestTrackingAuthorization() == .authorized
}
```

## The planner does not track

The planner keeps the plan on the phone and, from lesson 12, on its own server. It sends nothing to
an advertising network and links nothing with anybody else's data. **So it never calls this, it has
no `NSUserTrackingUsageDescription`, and its privacy manifest says `NSPrivacyTracking` is false.**
Section 06 checks that the two agree.

The failure to avoid is the third-party SDK nobody read. An analytics or advertising library added
for one feature can track on the app's behalf, and the app is answerable for it: Apple's privacy
manifest documentation asks every such SDK to ship a manifest of its own, which Xcode combines with
the app's into one report. **Read an SDK's manifest before adding it**, the same way you read a
licence.
