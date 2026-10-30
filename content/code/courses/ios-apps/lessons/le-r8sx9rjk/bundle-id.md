---
title: The bundle identifier, the one name that cannot change
version: 1
---

**An app's bundle identifier is its identity to iOS and to the App Store, and once a build has been
uploaded to App Store Connect it can never change.** It is a string in reverse-DNS form, `com.example.planner`, built from a
domain you control written backwards and a name for the app. iOS uses it to tell apps apart: two
apps with the same identifier are the same app, and installing the second replaces the first.

The belief to drop is that the identifier is a label like the app's name. The name under the icon
is `CFBundleDisplayName`, and you can change it with every release. The identifier is closer to a
primary key: the App Store record, the app's data on every phone it is installed on, its keychain
entries, its push notification registration and its iCloud containers all hang from it. **Rename an
app and nothing moves. Change the identifier and you have published a different app**, with no
reviews, no users and none of their data.

## The rules

Apple's documentation for `CFBundleIdentifier`, read on 30 October 2026, states them, and section 08
checks a file against the first:

- letters `A` to `Z` and `a` to `z`, digits, hyphens and periods, and nothing else;
- reverse-DNS order, from the most general part to the most specific;
- it is case-insensitive, in the documentation's own words, so `com.example.Planner` and
  `com.example.planner` are one identifier and case can never tell two apps apart.

`com.example.planner` uses `example.com`, a domain reserved for examples. **For an app of your own,
use a domain you own**, written backwards. If you have none, a name that starts with your own
surname or your account name is a safe convention, and the App Store refuses an identifier somebody
else has already registered.

## Where it is written, and where it travels

In Xcode the identifier is the app target's *Bundle Identifier* field, which writes the build
setting `PRODUCT_BUNDLE_IDENTIFIER`, and the build copies it into `Info.plist` as
`CFBundleIdentifier`. The test targets get identifiers of their own, derived from the app's by
appending a suffix. An **app extension** — a widget, a share extension — must have an identifier
that starts with the app's, `com.example.planner.widget`, because that prefix is how iOS knows the
extension belongs to the app.

When lesson 21 signs the app, the identifier is joined by a **team identifier**, ten characters Apple
assigns to your developer account, and the two together are the app's **App ID**:
`ABCDE12345.com.example.planner`. That is why the same identifier cannot be registered by two
accounts, and why a signing error so often turns out to be an identifier typed slightly differently
in two places.
