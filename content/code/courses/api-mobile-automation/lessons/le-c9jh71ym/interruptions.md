---
title: Interruptions
version: 1
---

**A phone interrupts the app in front of it all day, and almost every interruption is one of the
state changes of section 04 wearing a different coat.** A call takes the screen and gives it back.
The notification shade slides over the app. The keyboard rises and covers half of it. A person
switches the phone to the dark theme at nine in the evening. Testing each one as its own case
multiplies the suite. Testing each by the state it causes keeps it small.

## The common ones, and how to cause them

| interruption | what happens to the app | cause it on the emulator | from Appium |
|---|---|---|---|
| **a call arrives** | the call screen covers it; it goes to the background until the call ends | `adb emu gsm call 5551234`, then `adb emu gsm cancel 5551234` | `mobile: gsmCall`, `{ phoneNumber, action: 'call' }`, then `'cancel'` |
| **the notification shade** | stays underneath, without the focus, until the shade closes | `adb shell cmd statusbar expand-notifications`, then `collapse` | `mobile: openNotifications` |
| **Home, another app, back** | the background, perhaps a process death | section 04 | section 04 |
| **the screen locks** | stopped until it is unlocked | `adb shell input keyevent KEYCODE_POWER` | `mobile: lock`, `mobile: unlock` |
| **the dark theme, the font size, the language** | destroyed and recreated, like a rotation | `adb shell cmd uimode night yes`; `adb shell settings put system font_scale 1.3` | `mobile: shell`, with the same commands |
| **the back button** | the screen in front is finished; from the list, the app leaves | `adb shell input keyevent KEYCODE_BACK` | `driver.back()` |
| **the keyboard** | half the screen covered while a field has the focus | tap a text field | `mobile: isKeyboardShown`, `mobile: hideKeyboard` |

`adb emu` sends a command to the emulator's own console, so the call exists only on an emulator. A
real phone needs a real call. **None of these was run for this course**, for the reason the rest of
the lesson gives.

## Which deserve a test

Tickets answers the table in three ways, and that is the useful way to read it:

- Everything that recreates the activity is one case. Rotation, dark theme, font size and
  language reach the same code, so the defect of section 05 appears under all four. One test with
  `recreate()` or a rotation covers the class. Write that test once per screen.
- Everything that sends the app away is the background and, sometimes, a process death. A call, a lock and the Home button differ to a person and not to Tickets. The two tests of section
  05 cover them.
- What stays on screen is a check of layout, not of state. The shade and the keyboard cover the
  app without changing it. The keyboard matters where there is a field, and Tickets has none, so
  there is nothing to test today. In an app with a form, the case is the submit button hidden under
  the keyboard on the smallest screen of lesson 20's matrix. Espresso's `closeSoftKeyboard()` or
  Appium's `hideKeyboard` belongs in the test before the tap.

**The back button deserves its own line in a test plan**, because it is the interruption a person
causes on purpose. From the show's screen it should return to the list as it was, rows and banner, without a new load.
From the list it leaves the app. That is a finished activity, which Android does not restore, so
the next start is a cold one. Espresso's `pressBack()` and Appium's
`driver.back()` press it.

**And a call is still worth one manual pass per release.** An incoming call over a screen that is
halfway through a payment is the interruption a person remembers. It is cheaper to try on an
emulator for a minute than to automate a telephone.
