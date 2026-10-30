---
title: What no WebView can reach
version: 1
---

**Some limits are not about polish: they are things the WebView cannot do at all**, because they
happen outside the app's screen, where there is no page. Plugins move most of these to the native
side, and a few stay beyond a wrapped app's reach without serious native work.

| what | where it happens | in a Capacitor app |
|---|---|---|
| a widget on the home screen | a separate small program the system runs | native code, an extension of the app, written in Swift or Kotlin |
| a watch app, a car screen | another device, another interface | native, from scratch |
| work while the app is closed | the system's background scheduler | plugins for specific jobs, under the system's strict limits |
| push notifications | Apple's and Google's push services | a plugin, plus accounts and keys with both |
| a share extension, a keyboard | inside another app | native extension |
| Bluetooth, NFC, a USB device | the system's device interfaces | community plugins, quality varying |
| very long lists, heavy animation | the screen, sixty times a second | possible on the web, and harder than native |

**Read the first column as questions about your app**, not about Capacitor. A study planner wants a
reminder, which lesson 4 gave it, and might want a widget showing today's sessions, which it cannot
have without writing one in Swift and one in Kotlin. Either can be added later, as native code inside
the projects lesson 3 opened, and the rest of the app stays web. **That middle road is real**: many
apps are web screens in a native shell with a few native parts, and the decision is per feature, not
for the whole app.

## Background work is the strictest

The browser in your pocket runs a page while you look at it. A phone app does not get to run when
nobody looks: both systems suspend an app in the background within a short time. They give it only
specific, limited ways to work there, a scheduled task, a location update, a download that the system
finishes for it. That is why lesson 4's reminder was scheduled with the system and not with a timer
in the page. **A design that needs the app to keep running, such as a timer that counts a study
session with the screen off, does not survive on either system** unless it is rebuilt around those limits. The system holds the notification, and the app only works out the time when it is opened
again.
