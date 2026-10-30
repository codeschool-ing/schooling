---
title: What the stores make you declare
version: 1
---

**Both stores require a declaration of what the app collects, and the declaration has to match
what the app and every library inside it actually do.** It is a form, and the temptation is to fill
it in as a form: tick what sounds right, move on. Both stores treat a wrong answer as a policy
violation, and both count data collected by a library you added as data your app collects.

*This section is written from Google's and Apple's documentation as it stood in October 2026. No
form was filled in and no app was submitted for this course: both need a paid developer account,
which this course does not ask for. The forms change; read the current pages before you
submit.*

## What counts as collecting

The two stores agree on the line that matters most here: **data that is processed only on the
device and never sent off it is not collected.** An offline-first planner gains from that directly.
Sessions kept in the local database and never synced would not be declared. The moment the outbox
sends them to the planner's server, they are collected, and they go on the form.

## Google Play: the Data safety section

Every app on Google Play has a Data safety section on its store page, filled in through a form in
Play Console. For each **data type** the app collects or shares, from a fixed list (personal info,
health and fitness, app activity, device or other IDs, and the rest), the form asks:

- whether it is **collected** (sent off the device) or **shared** (passed to a third party);
- whether collecting it is **required or optional** for the person;
- the **purposes**: app functionality, analytics, personalisation, account management, and others;
- two security practices: whether data is **encrypted in transit**, and whether the person can ask
  for it to be **deleted**.

Google also requires an app that lets people create an account to let them **delete it**, from
inside the app and from a web page, and the form asks for that page's address.

## Apple: App Privacy details and the privacy manifest

On the App Store the same facts appear as the **App Privacy** details, the "privacy nutrition
label", entered in App Store Connect. Apple's categories are similar (contact info, health and
fitness, user content, identifiers, usage data, diagnostics), and for each one it asks two more
questions: whether the data is **linked to the person's identity**, and whether it is used for
**tracking**, Apple's word for combining it with other companies' data for advertising.

Since May 2024 an app also carries a **privacy manifest**, a file named `PrivacyInfo.xcprivacy`.
It states the same collected data types in a form Xcode can check, and it gives a reason for each
**required-reason API** the app calls: interfaces that could be used to fingerprint a device. Two
of them are in this course: `UserDefaults`, from lesson 2, and the free disk space the planner
checked in lesson 18. A planner's manifest would carry entries like these:

```xml
<key>NSPrivacyAccessedAPITypes</key>
<array>
  <dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array><string>CA92.1</string></array>
  </dict>
  <dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array><string>E174.1</string></array>
  </dict>
</array>
```

`CA92.1` is the reason "the app reads defaults it wrote itself", and `E174.1` is "checking there is
room before writing files", which is exactly what lesson 18's `statfs` did. *The reason codes are
copied from Apple's list of required-reason APIs; the manifest was not built or validated here.*
Apple also asks for an in-app way to delete an account, under its review guideline 5.1.1(v).

## Filling them in honestly

The forms are easier, and more honest, when they are filled in from a list rather than from
memory. The table in the last section is that list for the planner: what it keeps, and whether it
needs it. Every library the app adds gets the same row, from its own documentation, because a crash
reporter that sends the device's model, or an analytics kit that sends an identifier, is collecting
on the app's behalf. And the list is reviewed at each release, since one new library can make last
month's answers false.
