---
title: What each platform gives you for it
version: 1
---

**Android and iOS each keep a small amount of UI state for the app, outside its process, and give it
back after a kill; React Native has nothing of the kind, so the app writes it down itself.** The three
fragments below save the same thing, the minutes typed into the planner's new-session form. They are
adapted from each platform's documentation and **were not compiled or run for this course**: read
them to recognise the mechanism, not to copy it into a project.

## Android: saved state

**Compose's `rememberSaveable` is `remember` that survives a rebuild and a kill.** A value kept with
`remember` lives in memory and is gone after either; the saveable version is written into the saved
state the system holds, and read back when the screen is created again:

```kotlin
@Composable
fun SessionForm() {
    var minutes by rememberSaveable { mutableStateOf("") }
    TextField(value = minutes, onValueChange = { minutes = it })
}
```

**A ViewModel reaches the same store through `SavedStateHandle`.** The ViewModel itself dies with
the process, as the previous section's table says; the handle is a small map that the system saves
for it and hands to the new ViewModel after a kill:

```kotlin
class CourseViewModel(private val saved: SavedStateHandle) : ViewModel() {
    val courseId: String? get() = saved["courseId"]
    fun open(id: String) { saved["courseId"] = id }
}
```

Android's guide adds one detail that matters to lesson 4's rule: saved state APIs "only save data
written to it when the Activity is stopped". The save happens at `onStop`, on the way to the
background, which is the last moment the app is sure to be told anything.

## iOS: scene storage

**SwiftUI's `@SceneStorage` is a property kept per scene and restored by the system.** Apple's
documentation says it works "very similar to State, except its initial value is restored by the
system if it was previously saved":

```swift
struct SessionForm: View {
    @SceneStorage("draftMinutes") private var minutes = ""

    var body: some View {
        TextField("Minutes", text: $minutes)
    }
}
```

The same page sets its limits, and they are the same limits Android puts on saved state. The data
should be "lightweight"; model data "should not be stored in SceneStorage". It is not for sensitive
data. "The system makes no guarantees as to when and how often the data will be persisted". And if
the scene is explicitly destroyed, for example when its snapshot is removed from the switcher on
iPadOS, "the data is also destroyed", which is the user closing the screen on purpose.

## React Native: write it yourself

**React Native has no saved state of its own.** Its JavaScript keeps running through a rotation, as
the previous section said, but when the process is killed every variable goes, and nothing gives them
back. The app writes the UI state to storage on the way to the background, with the same `AppState`
listener lesson 4 used, and reads it on the next launch. A key-value store from a community library,
such as AsyncStorage, is the common place:

```tsx
useEffect(() => {
  const sub = AppState.addEventListener("change", (next) => {
    if (next === "background") {
      AsyncStorage.setItem("ui", JSON.stringify({ courseId, minutes }));
    }
  });
  return () => sub.remove();
}, [courseId, minutes]);
```

**Storage the app writes itself survives everything, including the user closing the app on
purpose.** That is more than platform saved state does, and it moves a decision onto the developer:
clear the saved draft when the form is submitted, and decide whether a draft that is days old should
still be offered. The `react-native` course compares the stores in its lesson 14, if you take that
route.

## Three tools, one shape

| | where the state is kept | what clears it | how big it may be |
|---|---|---|---|
| Android saved state | by the system, outside the process | the user finishing the screen | small: the next section measures it |
| iOS `@SceneStorage` | by the system, per scene | the scene being destroyed | "lightweight" |
| React Native | wherever the app writes it | only the app | whatever the app allows, which is the danger |

**All three keep the same kind of thing**: the id of what was open, a number for where the user was,
and the strings of an unfinished form. None of them is meant for the plan itself. The next section
runs that shape on your computer, kill included.
