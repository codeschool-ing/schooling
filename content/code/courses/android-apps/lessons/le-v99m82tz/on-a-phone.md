---
title: What only a phone shows
version: 1
---

**The dialog belongs to the system, and so does everything around it.** This section describes what
a student meets on a real phone and what an app should expect. **Not run**: no device or emulator was
available when the course was recorded, as lesson 1 section 02 explains, and everything below is
taken from Google's documentation on runtime permissions, read on 30 October 2026.

## The dialog

The system draws it over the app, with the app's name and the buttons for that permission. For
`POST_NOTIFICATIONS` they are *Allow* and *Don't allow*. The app cannot change the wording, add an
explanation inside it, or style it; the explanation belongs in the app, before the request, which
is what section 05's second card is for. Tapping outside the dialog dismisses it without an answer,
and that does not count as a refusal.

## Permissions that grant less than they seem

Some runtime permissions have intermediate answers the planner does not meet but other apps do:

- **Location** can be granted as *approximate* rather than *precise*, and *only while using the
  app* rather than all the time. An app asking for precise location receives approximate if that is
  what the student picked, and has to work with it.
- **Camera, microphone and location** can be granted *only this time*: the permission lasts while the
  app is in use and is withdrawn soon after it leaves the screen.
- **Unused apps** have their runtime permissions reset by Android after some months without being
  opened, so a permission granted last year is not a permission held today.

Each of these is one more reason to check before every use, rather than once.

## Granting and revoking from a terminal

With a phone or an emulator connected, Google's documentation shows how to put a permission in a
known state without the dialog, which is how instrumented tests and manual checks reach each of
section 04's rows:

```sh
adb shell pm grant com.example.planner android.permission.POST_NOTIFICATIONS
adb shell pm revoke com.example.planner android.permission.POST_NOTIFICATIONS
adb shell pm clear-permission-flags com.example.planner android.permission.POST_NOTIFICATIONS user-set user-fixed
```

The third command clears the flags that record the student's refusals, which returns the permission
to "never asked" for testing. **Not run**, like the rest of this section, so no output is shown.

## The store has an opinion too

Google Play asks an app to declare why it uses some permissions, and reviews apps that ask for
sensitive ones. `mobile-fundamentals` lesson 13 covers what the store makes you declare, and lesson
22 of this course reaches the Play Console. A permission the app does not need is a question in
review and a reason for a student to hesitate, so the cheapest permission is the one the planner
never declares.
