---
title: What an update may change, by the stores' rules
version: 1
---

**Updating an app without the store is allowed, within limits both stores write down**, and the limits
are about trust rather than technology: the reviewer approved an app, and an update must not turn it into
a different one.

**Apple** allows an app to download code that runs in its own interpreter, which is what a JavaScript bundle is. The condition is that the change does not alter the app's main purpose, does not add features the
reviewer never saw, and does not get round the App Store's review or its payment rules. **Google Play**
forbids an app to update itself, or to download executable code, by any route other than Google Play. It makes an exception for code that runs in a virtual machine or an interpreter, such as JavaScript in a
WebView or in the app's JavaScript engine. *That is a summary of the
Apple Developer Program License Agreement and Google Play's policy on device and network abuse as they
read when this course was written; read the current text before relying on it.*

| change | over the air | a store build |
|---|---|---|
| a bug fix in a screen | yes | not needed |
| a new screen built from components already in the app | yes, if it does not change what the app is | safer, if it is large |
| a text, a colour, an image | yes | not needed |
| a new native library, a new permission | **no**: the installed app does not have it | yes |
| a new purpose: the planner becomes a shop | **no**, whatever the code | yes, and a review of the new app |

## Rolling one out

An update reaches every installed app on its runtime version the next time each one opens, which is
faster than a store build and also faster to do damage. Expo's service sends an update to a **channel**,
`preview` or `production`, so testers see it first; it can send it to a share of users and roll it back.
**A broken update is the one release a person cannot avoid by not updating**, which is why the planner
would ship one only after the same checks as a store build, and lesson 15 comes back to the order in
which changes go out.

Capacitor apps have the same option through third-party services that swap the web files inside the
app, under the same store rules, and lesson 15 names them.
