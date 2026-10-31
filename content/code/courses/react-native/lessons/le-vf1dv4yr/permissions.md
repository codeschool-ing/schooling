---
title: Permissions, asked at the moment and answered three ways
version: 1
---

**A phone guards what is private about the person holding it**: the camera, the microphone, where they
are, their contacts, their photos, whether the app may interrupt them with a notification. An app gets
none of these by being installed. It gets each one in two steps, and both have to happen:

1. **Declared**, when the app is built. The Android manifest lists every permission the app might ever
   ask for, and iOS's `Info.plist` carries a sentence for each one, which the system shows when it asks.
   An app that asks for something it never declared is refused on Android and closed on iOS.
2. **Granted**, by the person, while the app runs. The system shows its own dialog, which the app
   cannot style, word or skip.

## When to ask

**Ask at the moment the person does something that needs it, and never at launch.** Somebody who has
just pressed *Take a photo* knows why the planner wants the camera. Somebody who opened the app for the
first time and is met by three dialogs in a row does not, and says no to all of them. The second reason
is stricter: the system will not keep asking for you.

- **iOS asks once.** After the first answer, asking again returns that answer at once, with no dialog.
- **Android asks twice.** Refuse a second time and the system stops showing the dialog for that app.

After that, only the person can change their mind, in the phone's Settings. The app's job is to know
which situation it is in.

## Three answers

Every Expo library that needs a permission answers the request with the same kind of object. Its
`granted` says yes or no, and its `canAskAgain` says whether a refusal is final:

| `granted` | `canAskAgain` | what it means | what the app does |
|---|---|---|---|
| `true` | — | allowed | goes on |
| `false` | `true` | refused this time | says what is lost, offers another way, and may ask next time |
| `false` | `false` | refused for good, or forbidden by the device's owner | explains, and offers a way to Settings |

There is also `status`, which is `"granted"`, `"denied"` or `"undetermined"` (never asked), and a
`getCameraPermissionsAsync()` beside every `request…`, which reads the answer without asking. It is
useful for drawing a screen differently before the person has pressed anything.

## What needs no permission at all

**Choosing a photo from the library does not.** Both platforms now have a system photo picker, which
runs outside your app: the person browses their photos in the system's own screen, and your app receives
only the ones they chose. Since the app never sees the rest of the library, there is nothing to grant.
A permission for the photo library is for an app that reads the library itself, a gallery or a backup
tool, and the planner is neither. *Even those may receive partial access, the photos the person picked
in a later dialog, which the response reports as `accessPrivileges: "limited"`; the planner never asks,
so this course did not see one.*
