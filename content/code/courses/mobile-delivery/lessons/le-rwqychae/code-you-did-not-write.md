---
title: Code you did not write
version: 1
---

**The form asks about everything the app sends, and a library sends on your behalf.** A crash
reporter sends stack traces and device models; an analytics library sends events and an install
identifier; an advertising library sends far more. Apple's documentation says it in one line: you
declare the practices of the **third-party partners whose code you integrate**, as well as your own.
Not knowing what a library sends is not an answer either store accepts.

## Finding out what a library sends

1. **Read its own privacy documentation.** Every serious SDK publishes a page listing what it
   collects, often already mapped to Apple's and Google's categories. Firebase, Sentry and the rest
   all do.
2. **Read its configuration.** Most collect less if asked: a crash reporter can be told not to send
   the user's identifier; an analytics library can be told not to collect the advertising ID.
3. **Watch the traffic.** A proxy on your desk shows what the debug build sends and where. What you
   see there is the ground truth the form describes; lesson 12 builds a tiny collector that shows
   what a crash report carries.

## Apple's privacy manifest

Apple introduced the **privacy manifest** in 2023: a file named `PrivacyInfo.xcprivacy` inside an
app or an SDK, declaring what data it collects and why it calls certain APIs. Xcode combines the
manifests of the app and its libraries into one **privacy report**, which you read before filling
the form. Apple also lists commonly used SDKs that must ship a manifest, and a signature when they
come as compiled binaries; an app that adds one of them without those is refused at upload.

The manifest also covers **required reason APIs**: a handful of system APIs, such as reading a
file's timestamp or the free disk space, that can be used to fingerprint a device. Calling one
requires declaring one of Apple's listed reasons for doing so.

```xml
<!-- PrivacyInfo.xcprivacy: the planner reads UserDefaults for its own settings -->
<dict>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>CA92.1</string></array>
    </dict>
  </array>
</dict>
```

`CA92.1` is the code Apple's list gives for reading and writing information that only the app
itself can reach. *Not run: the manifest is read by Xcode on a Mac, and the reason codes are on
Apple's page for required reason APIs.*

## On Android and in React Native

Android has no manifest of this kind; the Data safety form is the declaration, and Google expects
it to cover your SDKs. Google publishes an **SDK index** that says which libraries have a Data
safety guide. In a React Native app, the native libraries under `ios/` and `android/` are what
collect, so the same work is done for each, and Expo's config plugins can write the privacy
manifest into the iOS project for you.
