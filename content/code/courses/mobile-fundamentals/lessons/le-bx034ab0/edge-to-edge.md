---
title: Edge to edge, and who applies the insets
version: 1
---

**On iOS the toolkit keeps content in the safe area unless the app says otherwise; on a recent
Android the app draws edge to edge and is responsible for the insets itself.** That one difference
explains most inset bugs that appear on one platform and not the other.

## Android: edge to edge is now the rule

Android's documentation on insets states the change plainly. On Android 14, API level 34, and
lower, an app's interface is not drawn under the system bars and the display cutout by default.
**On Android 15, API level 35, and higher, an app that targets SDK 35 is drawn under them**, and
the documentation marks it as enforced: an app that was not edge to edge before may have parts of
its screen hidden until it handles the insets. Android 16's behaviour changes, read on 30 October
2026, close the way out: an app targeting API level 36 can no longer opt out of edge to edge when
it runs on Android 16.

So an Android app built today handles the insets, and **Compose gives it the tools**: modifiers
such as `safeDrawingPadding()` and `imePadding()` that pad a layout by an inset, and the Material 3
`Scaffold`, which the documentation says can reduce the work. The second mistake of the previous
section lives here: padding by hand what a component has already padded.

## iOS: the safe area by default, and leaving it on purpose

SwiftUI starts from the other end. **Apple's documentation for `ignoresSafeArea` says that by
default the layout system sizes and positions views to avoid certain safe areas**, so that system
content such as the software keyboard or the edges of the device does not cover them. The app
does nothing to stay safe; it writes `ignoresSafeArea` when a view, typically a background, should
extend into those regions. `safeAreaInset` goes the other way, and adds a view of the app's own,
such as a bar of buttons, to the safe area's edge, so the rest of the content keeps clear of it as
it keeps clear of the system's.

## React Native: a library that reports the insets

React Native's own `SafeAreaView` is marked deprecated in its documentation, which points to the
**`react-native-safe-area-context` library** instead. Its `SafeAreaView` is a view with the insets
applied as padding, with an `edges` list for the sides it should apply them to, and its
`useSafeAreaInsets()` hook returns the four numbers `{ top, right, bottom, left }` for code that
places things by hand. Its documentation adds a warning worth keeping: the values are not updated
synchronously, so a rotation can show them a moment late.

## The same screen in three spellings

The fragments below draw the planner's course screen with its background to the edges and its
list and add-session button inside the safe area. They are adapted from each platform's
documentation, and **they were not compiled or run for this course**.

```kotlin
// Compose: draw to the edges, pad the content by the safe drawing insets
Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.surface)) {
    Column(Modifier.fillMaxSize().safeDrawingPadding()) {
        SessionList(Modifier.weight(1f))
        AddSessionButton()
    }
}
```

```swift
// SwiftUI: content is kept in the safe area; only the background leaves it
ZStack {
    Color(.systemBackground).ignoresSafeArea()
    VStack {
        SessionList()
        AddSessionButton()
    }
}
```

```tsx
// React Native: the library pads the content by the insets it reports
<View style={{ flex: 1, backgroundColor: "#fff" }}>
  <SafeAreaView style={{ flex: 1 }} edges={["top", "bottom", "left", "right"]}>
    <SessionList />
    <AddSessionButton />
  </SafeAreaView>
</View>
```

**Read side by side, the defaults are visible.** The Kotlin fragment has to ask for the padding;
the Swift one has to ask to leave it; the React Native one has to bring in a library that knows
the numbers. The intent is identical in all three: the background goes everywhere, and the things a
student reads or taps stay where nothing covers them.
