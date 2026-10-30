---
title: Asking for the reminder permission in three toolkits
version: 1
---

**Each toolkit asks for a permission with one call, and each returns the answer later, because the
person is looking at a dialog in between.** The three fragments below ask for the planner's
notification permission at the moment the student taps "remind me", and handle the answer. They are
adapted from Android's documentation on requesting permissions, Apple's documentation for
`UNUserNotificationCenter`, and the documentation of Expo's notifications library, and **they were not
compiled or run for this course**. Read them for the shape: check, explain if needed, ask, and act
on the answer.

## Android: an activity result launcher

```kotlin
// Compose: ask for POST_NOTIFICATIONS when the student taps "remind me"
val launcher = rememberLauncherForActivityResult(
    ActivityResultContracts.RequestPermission()
) { granted -> if (granted) scheduleReminder(session) else showRemindersOff() }

Button(onClick = {
    when {
        ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
            == PackageManager.PERMISSION_GRANTED -> scheduleReminder(session)
        activity.shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS) ->
            showWhyReminders()   // the app's own screen; its button calls launcher.launch
        else -> launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
    }
}) { Text("Remind me") }
```

**The `when` is the flow chart of the earlier section, in order.** Granted already: act. In the window
after one refusal: show the app's explanation first. Otherwise: launch the system dialog, and let the
callback at the top receive the answer. Android's documentation notes that the app "cannot customize
the dialog" itself, which is why the explanation is a screen of the app's own.

## iOS: one call, with the answer in a closure

```swift
// SwiftUI: ask for notifications when the student taps "remind me"
Button("Remind me") {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
        if granted {
            scheduleReminder(for: session)
        } else {
            remindersOff = true   // the view then offers a button to Settings
        }
    }
}
// that button opens the app's own page in Settings
openURL(URL(string: UIApplication.openSettingsURLString)!)
```

**There is no rationale branch, because iOS has no second dialog to save.** The first call shows the
dialog; every later call returns the stored answer at once, which is why the same button works before
and after the student decides. When the answer is no, the app shows the planner without reminders and
offers Settings, through the URL Apple's documentation gives for opening an app's own settings.

## React Native: Expo's notifications library

```tsx
// Expo: ask for notifications when the student taps "remind me"
async function remindMe(session: Session) {
  const { status: existing } = await Notifications.getPermissionsAsync();
  let status = existing;
  if (existing !== "granted") {
    status = (await Notifications.requestPermissionsAsync()).status;
  }
  if (status === "granted") {
    await scheduleReminder(session);
  } else {
    setRemindersOff(true);   // the screen then offers Linking.openSettings()
  }
}
```

**Check, ask if not granted, act on the result: the same three steps, in JavaScript.** One library
call covers both platforms, and each platform still applies its own rule underneath. On Android a
second refusal is final and on iOS the first is, whatever the JavaScript says. React Native's own
`PermissionsAndroid` module exposes Android's rationale directly, and its `Linking.openSettings()`
opens the app's page in Settings on either platform.

| | Android | iOS | React Native with Expo |
|---|---|---|---|
| check | `checkSelfPermission` | the stored answer, returned by the request | `getPermissionsAsync` |
| explain first | `shouldShowRequestPermissionRationale` | before the only ask | `PermissionsAndroid`, on Android |
| ask | `launcher.launch(...)` | `requestAuthorization` | `requestPermissionsAsync` |
| after the final no | an intent to the app's details | `openSettingsURLString` | `Linking.openSettings()` |

Whichever route you take at the fork, its course comes back to this: lesson 20 of `android-apps` on
runtime permissions and the flow when the user says no twice, lesson 18 of `ios-apps` on privacy
strings and permissions, or lesson 13 of `react-native` on permissions beside the camera and files.
