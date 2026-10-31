---
title: Asking which platform this is
version: 1
---

**`Platform.OS` says which platform the code is running on**: `"ios"`, `"android"` or `"web"`, and a
few others for platforms outside this course. It is a constant for the life of the app, so reading it
anywhere is free, and a branch on it is ordinary JavaScript:

```tsx
import { Platform } from "react-native";

const label = Platform.OS === "ios" ? "Done" : "Save";
```

`Platform.Version` adds the version of the operating system: the Android API level as a number, 36 on
Android 16, or the iOS version as a string, such as `"18.2"`. Code that depends on a feature a newer
system added checks it, which on Android is common enough that the comparison has a shape:

```tsx
if (Platform.OS === "android" && Platform.Version >= 33) {
  // Android 13 and later ask for permission before showing notifications: lesson 16
}
```

## Use it rarely

**Every branch on the platform is a place the two apps differ, and each one needs testing twice.** Most
of the planner has none: its rules, its list, its bar and its colours are the same on both. The places
that legitimately differ are few, and they are the subject of the rest of this lesson: how something
looks where the platforms draw it differently, how something behaves where their conventions differ,
and an API that exists on one and not the other.

A branch that exists only because something looked wrong on one phone deserves a second look before it
stays. It is often a layout that relied on a default, which the other platform does not share, and
setting the value explicitly fixes both without a branch.

## The web is a platform too

The planner's web build answers `"web"`. That matters in two ways. A branch written as `Platform.OS ===
"ios" ? a : b` sends the web down the Android path, which may or may not be right; and a library that
works on both phones may not work in a browser at all. The next section's `Platform.select` has a
`default` for exactly this, and the planner uses it.
