---
title: There is no goodbye, so save on the way out
version: 1
---

**Being killed in the background sends no callback, on any platform, so whatever must survive has to
be saved on the way to the background, while the app is still being told things.** That is the rule
this lesson exists to give you, and everything before this section is the evidence for it: Android's
reference says a stopped process may be killed "without another line of its code being executed",
Apple's says to expect a background app to terminate, and React Native has no value for a process
that no longer exists.

## The wrong place to save

**The common mistake is to save when the app closes**, in `onDestroy`, in `applicationWillTerminate`,
or in a cleanup function that runs when the root component unmounts. Each of those runs in some
situations, which is why the mistake survives testing: a developer who closes the app by hand sees
the save happen. None of them runs when the system kills a suspended app to free memory, which is how
most apps actually end. The user meets the bug a week later, on a phone with less memory, after a
long call.

## The right place

| platform | the last moment the app is sure to hear | what the documentation says to do there |
|---|---|---|
| Android | `onStop` | heavy shutdown work, since `onPause` is too brief |
| iOS | `.background`, and `.inactive` before it | save user data on deactivation; free memory on entering the background |
| React Native | `AppState` changing to `background` | the same moment, reported to JavaScript |

Here is the planner saving a half-typed session at that moment in each of the three. These fragments
are adapted from each platform's documentation and **were not compiled or run for this course**; they
are here so that you recognise the same rule in three spellings.

Android, in an Activity, in Kotlin:

```kotlin
override fun onStop() {
    super.onStop()
    // No longer visible: from here the process may die without a word.
    drafts.save(currentDraft)
}
```

iOS, in a SwiftUI view, in Swift:

```swift
.onChange(of: scenePhase) {
    if scenePhase == .background {
        // From here iOS may suspend the app, and then terminate it.
        drafts.save(currentDraft)
    }
}
```

React Native, in a component, in TypeScript:

```tsx
useEffect(() => {
  const sub = AppState.addEventListener("change", (next) => {
    // The last value this code is sure to see before a kill.
    if (next === "background") drafts.save(currentDraft);
  });
  return () => sub.remove();
}, []);
```

**The three are one idea.** Each one watches for the move into the background and writes the draft
somewhere that outlives the process. On iOS, Apple's guide goes one step earlier and asks for user
data to be saved on deactivation, the move to `.inactive`; an app that saves there too loses
nothing if the background step is cut short.

## Save quickly, and save little

**The time on the way out is short and not yours to extend.** Android's guide calls `onPause` "very
brief", and Apple's reference gives `applicationWillTerminate`, the one goodbye that sometimes does
run, "approximately five seconds" to finish. A save that has to upload a file or rewrite a large
database is in the wrong place; it belongs in work the system agrees to run, which is lesson 15's
subject. What fits on the way out is small: which course was open, what the user had typed, where
the list was scrolled to.

**And what is saved has to come back.** Writing the draft is half of the job; lesson 5 is the other
half, putting it back on the screen after a launch that, to the app, looks like the first one ever.
It also asks which things deserve saving at all, because some state belongs on disk for good, some
only until the user returns, and some can simply be thrown away.
