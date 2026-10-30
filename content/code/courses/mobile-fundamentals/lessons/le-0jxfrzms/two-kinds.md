---
title: What needs a permission, and when it is granted
version: 1
---

**A permission is the system standing between an app and something that belongs to the person:
their location, camera, contacts, photos, or their attention through a notification.** The common
picture is a list of boxes the person ticks while installing, after which the app may do anything.
That picture is a decade out of date on both platforms. Most permissions that matter are asked for
while the app runs, one at a time, and the person can say no to each, or change their mind later.

## Android: two kinds, decided by risk

**Android sorts permissions by how much they can hurt the person, and only the risky kind is asked
for.** Android's documentation on permissions names the two that matter to most apps:

| | install-time | runtime |
|---|---|---|
| what it guards | access that barely affects privacy, such as the network | private data and sensitive hardware: location, camera, microphone, contacts |
| who grants it | the system, when the app is installed | the person, in a dialog, while the app runs |
| what the person sees | a notice on the store's page for the app | a system dialog naming the app and the access |
| Android's other name | *normal* (and *signature*, for apps signed together) | *dangerous* |

An app declares both kinds in its manifest with `<uses-permission>`. Declaring a runtime permission
does not grant it; it only makes it possible to ask. Android's documentation says to check a runtime
permission before every use, because the person can revoke it in Settings at any time, and the system
sometimes revokes it on its own.

**Notifications joined the runtime kind in Android 13.** Android's documentation on the notification
permission says that on a device running Android 13 or higher, a newly installed app's notifications
are off by default, and it must ask for `POST_NOTIFICATIONS` before it may send one. For the planner,
which reminds a student of a session, that permission is the one this lesson is about.

## iOS: one kind, and a sentence of yours

**On iOS nothing sensitive is granted at install; the first use asks.** When an app first tries to
reach the camera, the location or the photo library, the system shows a dialog, and the app supplies
one line of it: the *purpose string*, a sentence saying why. It lives in the app's `Info.plist` under
a key per resource, such as `NSCameraUsageDescription`.

**That sentence is not optional, and its absence is not polite either.** Apple's documentation on
requesting access to protected resources says that without a valid purpose string, attempts to use
the resource fail "and might cause your app to crash", and its documentation on capturing media is
blunter: without the key, "the system terminates your app". App Review rejects an app whose code
reaches a protected resource without one. The string has to be accurate and specific, Apple says, and
it is shown in the person's language, so it is translated like any other text.

Notifications ask in the same way, through their own call rather than a key: Apple's documentation
for `requestAuthorization` says the first call prompts the person, the system stores the answer, and
"subsequent calls to this method don't prompt the person again".

## What the planner needs

**The planner needs one runtime permission, and it is worth noticing how little that is.** It stores
its plan on the device, which needs no permission at all (lesson 16 says where). It reaches the
network, which on Android is an install-time permission and on iOS needs none. It sends a reminder
before a session, which needs the notification permission on both. It does not need location,
contacts, the camera or the photo library, and so it never asks for them.

That last sentence is a decision rather than a fact about the planner, and lesson 13 makes it
deliberately: every permission an app holds is data it could collect, and a store asks you to declare
what you collect. A permission you never request is a question you never have to answer, on a dialog
or on a form.
