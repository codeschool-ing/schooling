---
title: Which defect shows up where
version: 1
---

**Before choosing where to test, name the defect you are afraid of; the table then says where it
can be seen.** A tester who asks "does it work on a real device?" asks too broadly to get a useful
answer. "Does the reminder survive a Xiaomi's battery saver?" has one, and it is a particular phone.

*Shows* means the defect appears as it would for a user. *If set up* means the tool can show it once
you configure it to, and only as well as the imitation. *Hides* means it will not appear there at
all.

| the defect | emulator | iOS simulator | real device |
|---|---|---|---|
| a wrong field from the API on screen | shows | shows | shows |
| a layout broken on a small screen | shows, any size | shows, the sizes Apple lists | only that phone's size |
| text cut off in Portuguese | shows | shows | shows |
| plain HTTP refused by the platform | shows | shows | shows |
| the permission prompt and its denied path | shows | shows | shows |
| the app losing its list after being killed in the background | shows (lesson 21) | shows | shows |
| a request failing when the network drops | if set up (lesson 22) | if set up | shows, the real way |
| a crash when memory runs short | if set up, with less memory | hides | shows on a phone with little |
| slow scrolling on a cheap phone | hides | hides | shows on that phone |
| a reminder never firing on one brand | hides | not this platform | only that brand |
| a drawing glitch on one family of GPUs | hides | hides | only those phones |
| reading a QR code with the camera | if set up, a drawn scene | hides | shows |
| a position that drifts indoors | hides | hides | shows |
| an app that will not install, signed wrong | not this platform | hides | shows |

Read down the last column and it says *shows* everywhere, which is the argument for real devices.
Read across the first six rows and the emulator and the simulator say *shows* too, which is the
argument for doing most of the work on them: **those rows are most of the defects a team finds**,
and they are found faster where a device resets in a second.

## Reporting a defect from a device

When a defect appears only on a real phone, the report has to say which phone, because the next
person will try on another one and see nothing. `manual-testing` taught the shape of a defect
report; for a device it carries the maker, the model, the Android version and the build of the app.
On Android all of them are in *Settings › About phone*, and adb reads them off a connected phone
without anyone typing them:

```sh
adb shell getprop ro.product.manufacturer
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
adb shell getprop ro.build.fingerprint
```

The last one names the exact build of the maker's Android, which is what decides whether the next
phone of the same model behaves the same. These commands need a device, and the recording machine
had none, so their answers are not shown. On an iPhone the same facts are in *Settings › General ›
About*.
