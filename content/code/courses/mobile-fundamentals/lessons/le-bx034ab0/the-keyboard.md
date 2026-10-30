---
title: The keyboard, the largest inset of all
version: 1
---

**When a text field takes focus, the on-screen keyboard slides up over the bottom of the window,
and whatever was there is covered unless the layout moves it.** No other inset is as large or
changes as suddenly: the status bar is a strip, the gesture handle a sliver, and in this lesson's
example the keyboard takes 300 of a portrait screen's 844 units. Android calls it the IME, the input method
editor, and reports it as the `ime` inset; SwiftUI treats it as a safe area region of its own,
`.keyboard`, which Apple's documentation describes as the area matching the current extent of any
software keyboard over the view.

The common belief is that the system moves the field into view by itself. Sometimes it does,
partly. **The field the user is typing in is the easy half; the button below it is the half that
gets lost.** The planner's new-session form has a title field and, under it, the add-session
button. With the keyboard up, the field may be scrolled into view and the button, which the
student needs next, stays behind the keys.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l09-keyboard\" aria-label=\"Two diagrams of the planner's new-session form with the keyboard up. On the left the form keeps its place: the title field is visible but the Add session button is under the keyboard. On the right the content area ends at the top of the keyboard, so the form sits above it and the button is visible.\"><text x=\"170\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">the layout ignores the keyboard</text><text x=\"550\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">the keyboard is treated as an inset</text><rect x=\"80\" y=\"30\" width=\"180\" height=\"290\" rx=\"22\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></rect><rect x=\"86\" y=\"210\" width=\"168\" height=\"104\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">keyboard</text><rect x=\"96\" y=\"172\" width=\"148\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"106\" y=\"187.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Title</text><rect x=\"120\" y=\"228\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"170\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">covered</text><rect x=\"460\" y=\"30\" width=\"180\" height=\"290\" rx=\"22\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></rect><rect x=\"466\" y=\"210\" width=\"168\" height=\"104\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">keyboard</text><rect x=\"476\" y=\"120\" width=\"148\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"486\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Title</text><rect x=\"500\" y=\"166\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Add session</text></svg>", "caption": "The field is often brought into view; the button under it is what gets lost. Treating the keyboard as one more bottom inset moves the form's bottom edge to the top of the keys."}
```

## Two fixes, and they are the same idea

| fix | what happens | when it fits |
|---|---|---|
| shrink the window's content area | the layout is laid out again in the space above the keyboard, so a button at the bottom moves up with it | a short form whose last control should sit just above the keys |
| scroll | the content stays its height and becomes scrollable, and the focused field, or the next control, is scrolled into view | a long form that cannot fit above the keyboard at all |

**Both treat the keyboard as one more inset at the bottom**, larger than the gesture bar while it
is up and gone when it closes. The form's bottom edge becomes the top of the keyboard, or the
safe area's bottom when there is no keyboard, whichever is higher. The last section of this lesson
computes exactly that.

## In three spellings

The fragments below keep the planner's form and its button above the keyboard. They are adapted
from each platform's documentation, and **they were not compiled or run for this course**.

```kotlin
// Compose: pad the form by the keyboard's inset, and let it scroll
Column(
    Modifier.fillMaxSize()
        .imePadding()
        .verticalScroll(rememberScrollState())
) {
    OutlinedTextField(value = title, onValueChange = { title = it })
    Button(onClick = save) { Text("Add session") }
}
```

```swift
// SwiftUI: the keyboard is a safe area region, avoided by default
ScrollView {
    VStack {
        TextField("Title", text: $title)
        Button("Add session", action: save)
    }
}
// .ignoresSafeArea(.keyboard) would let the keyboard cover it again
```

```tsx
// React Native: a container that resizes or pads itself for the keyboard
<KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : "height"} style={{ flex: 1 }}>
  <ScrollView keyboardShouldPersistTaps="handled">
    <TextInput value={title} onChangeText={setTitle} />
    <Pressable onPress={save}><Text>Add session</Text></Pressable>
  </ScrollView>
</KeyboardAvoidingView>
```

**The defaults differ again, in the same direction as the safe area.** SwiftUI avoids the
keyboard unless told not to. Compose pads for it when asked with `imePadding()`.
React Native's documentation for `KeyboardAvoidingView` says it adjusts its height, position or
bottom padding to the keyboard's height. It also says that the two platforms respond differently to its `behavior`
setting and that setting it is recommended on both, which is why its own example
chooses `padding` on iOS and `height` on Android.

## What to test

Lesson 8 asked for each layout to be looked at in several windows. **The keyboard adds one more
state to each of them**, and it is the one most often left untested, because a developer at a
desk who types on a real keyboard may never see the on-screen one. On a
phone, in portrait and in landscape, with the keyboard up: is the field visible, is the next
control reachable, and does the screen go back to how it was when the keyboard closes?
