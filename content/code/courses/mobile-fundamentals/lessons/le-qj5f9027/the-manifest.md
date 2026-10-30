---
title: The privacy manifest, the reasons Apple asks for, and asking to track
version: 1
---

**On iOS the form has a second half that lives inside the app: a file called `PrivacyInfo.xcprivacy`,
the privacy manifest.** The App Store form is filled in by a person, once per release. The manifest is
a property list built into the app and into each third-party SDK, and Apple's documentation on
privacy manifest files says it records two things: the types of data the app or SDK collects, and the
*required reason APIs* it uses. Xcode can gather every manifest in an app into one privacy report, so
the person filling in the form starts from what the code says rather than from memory.

## Required reasons: APIs that could fingerprint

**Some ordinary APIs can also be used to identify a device, so Apple asks for the reason each one is
used.** Apple's documentation on describing the use of required reason APIs says such APIs "have the
potential of being misused to access device signals to try to identify the device or user, also known
as fingerprinting", and that fingerprinting is not allowed whether or not the person gave permission
to track. As read on 30 October 2026, the categories it lists are file timestamps, system boot time,
disk space, active keyboards and user defaults. An app that uses one declares the category and one or
more approved reasons, each a short code with a sentence of meaning, and may use the API for those
reasons only. The same page says that from 1 May 2024, apps that do not describe their use of these
APIs "aren't accepted by App Store Connect".

**The planner on iOS would meet exactly one of them.** Keeping a small setting, such as whether
reminders are on, in `UserDefaults` is the user defaults category, and the reason for data only the
app itself reads and writes is `CA92.1`. Its whole manifest would be this, adapted from Apple's
documentation and **not built or submitted for this course**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- PrivacyInfo.xcprivacy: the planner collects nothing and tracks nothing -->
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**Two empty arrays carry most of the meaning.** `NSPrivacyTracking` is `false` and there are no tracking
domains, because the planner tracks nobody; `NSPrivacyCollectedDataTypes` is empty, because nothing
leaves the phone. A manifest is short when an app is modest, and it gets long exactly as fast as the
app's appetite for data grows.

**Each SDK brings its own manifest, and the app's does not cover it.** Apple's documentation on data
use in privacy manifests says third-party SDKs "need to provide their own privacy manifest files", and
the required-reasons page says an SDK cannot rely on the app's manifest to report its own use of those
APIs. The privacy report is the sum. Adding an analytics SDK adds its manifest to the sum, and that is
often the first moment a team sees, in one place, what the library collects.

## Asking to track

**An iOS app that tracks has to ask first, with a dialog of its own and a sentence of its own.**
Apple's documentation for the App Tracking Transparency framework says an app needs it "if it collects
data about people and shares it with other companies to track them across apps and websites". The app
adds an `NSUserTrackingUsageDescription` purpose string, like the ones in lesson 12, and calls
`requestTrackingAuthorization` to show the request. The privacy manifest's `NSPrivacyTrackingDomains`
lists the domains the app contacts to track, and the manifest documentation says that if the person has
not granted tracking, requests to those domains fail.

**Android has no single equivalent, and the Data safety form carries the weight there.** Since
Android 14, Android's developer guide to the form notes, details of an app's location data practices
appear in the system's location permission dialog itself, so the declaration reaches the person at
the moment they decide, not only on the store page.

For the planner, none of this section asks for anything beyond the short file above: it does not
track, so it never shows the tracking dialog, and it declares one API reason. That is the cheapest
privacy work an app can have, and the next two sections show it was a choice.
