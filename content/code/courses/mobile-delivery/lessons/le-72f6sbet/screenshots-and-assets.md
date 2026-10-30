---
title: Screenshots, the icon, and the sizes that are refused
version: 1
---

**The pictures sell the app, and each store refuses the wrong size at upload, before anybody has
looked at them.** People decide from the first two or three screenshots, often without scrolling,
so those are the ones worth the most thought.

## Apple

App Store Connect asks for between **one and ten screenshots per device size**, as JPEG or PNG.
For the iPhone, the largest required size is the one that matters: Apple scales it down for
smaller iPhones when the interface is the same on all of them. The accepted portrait sizes for the
large iPhone display include **1320 × 2868** and **1290 × 2796** pixels; a picture of any other
size is refused when you drop it on the page. An iPad build needs iPad screenshots too.

**App previews** are short videos in the same slots, played without sound by default. The
**icon** comes from the app itself, from the asset catalogue in the build, and not from the
listing.

## Google

Google Play asks for at least two phone screenshots and accepts up to eight, as JPEG or 24-bit PNG
with no transparency. Each side must be between **320 and 3840 pixels**, and the long side no more
than **twice** the short one. On top of those, the listing carries two assets of its own: a **512 ×
512 icon**, uploaded separately from the one inside the app, and a **1024 × 500 feature graphic**,
the banner shown at the top of the page and in promotions. *Google's figures are from its 2025
help; the recording machine could not reach it.*

## What a screenshot should show

- **The app doing its job, not the app's splash screen.** The planner's first picture is the week
  with sessions in it and a total, because that is the thing a person wants.
- **One idea per picture, with a caption that says it.** Most listings put a short line of text
  above the phone; a person reads that and not the interface.
- **Real-looking data, invented on purpose.** Screenshots are public: a teammate's name, a real
  e-mail or a customer's data in one is a privacy problem, and lesson 5 is about the form that asks
  about it.
- **The same pictures in every language, with the captions translated.** A Portuguese page with
  English captions tells the visitor the app was not made for them.

## Generated, not hand-made

Taking twenty screenshots by hand for every language and every release is how listings go stale.
Each platform can produce them from tests: Xcode UI tests driven by **fastlane snapshot** on iOS,
**fastlane screengrab** or Compose screenshot tests on Android, and Maestro flows for React Native.
Lesson 11 runs Fastlane. What the store receives is then a folder of files, which is the subject
of section "The listing as files".
