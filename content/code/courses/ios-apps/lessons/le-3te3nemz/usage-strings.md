---
title: A usage string, the sentence iOS shows for you
version: 1
---

**An app cannot open the camera, read the location or see the photo library until the person
holding the phone says yes, and iOS asks the question, not the app.** The app supplies one
sentence for each kind of access, its **usage description**, and the system puts that sentence in
the alert it draws. Apple's documentation for `NSCameraUsageDescription`, read on 30 October 2026,
says the key "is required if your app uses APIs that access the device's camera". Without it the
app does not get a refused alert: iOS stops the app at the moment it asks.

The belief to drop is that the alert is the app's own screen, to word and style as it likes. The
app writes one string and calls one method. Everything else, the title, the two buttons, when the
alert appears and whether it ever appears again, belongs to iOS. **It asks once.** Apple's guide
to requesting location authorisation puts it plainly: after the first prompt "the system stores
your app's authorization status and doesn't prompt again". A person who taps *Don't Allow* is not
asked a second time, and section 07 is about what the app does then.

## What the sentence has to say

The sentence says **what the app will do with the access**, in terms of something the person
wants. *Planner needs camera access* is a fact about the app. *Planner uses the camera to photograph
your notes and attach them to a study session* is a reason, and it is what App Review reads too:
guideline 5.1.1 of the App Review Guidelines, last updated on 16 October 2026 and read for this
course on 30 October, says "Ensure your purpose strings clearly and completely describe your use of
the data". Lesson 22 reads the rest of that guideline.

The planner gets one new feature in this lesson, a photo of your notes attached to a session, and
with it one key. The rest of the file is lesson 1's. Save it as `Info.plist` in `~/privacy`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Info.plist -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Planner</string>
    <key>CFBundleExecutable</key>
    <string>Planner</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.planner</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>MinimumOSVersion</key>
    <string>17.0</string>
    <key>NSCameraUsageDescription</key>
    <string>Planner uses the camera to photograph your notes and attach them to a study session.</string>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
</dict>
</plist>
```

Each usage key is a plain string in `Info.plist`, and in a project made by a current Xcode you type
it in the target's *Info* tab, as lesson 1 section 08 describes. **The string is localised like
any other text the app shows**: a Portuguese phone shows the Portuguese sentence, from the app's
string catalogue, and a missing translation falls back to the development language.

| what the code touches | the key `Info.plist` needs |
|---|---|
| the camera | `NSCameraUsageDescription` |
| location while the app is in use | `NSLocationWhenInUseUsageDescription` |
| location at any time | `NSLocationAlwaysAndWhenInUseUsageDescription`, and the one above |
| saving into the photo library | `NSPhotoLibraryAddUsageDescription` |
| reading the whole photo library | `NSPhotoLibraryUsageDescription` |
| tracking, through App Tracking Transparency | `NSUserTrackingUsageDescription` |

Sections 03 to 05 take the four the planner might want and say which of them it needs, and the
answer for three of them is none. **The cheapest permission is the one you never ask for.**
