---
title: The keyboard, and the field it covers
version: 1
---

**The keyboard takes up to half of an iPhone's screen, and a form has to work with it in the way.**
Three things go wrong with it, and SwiftUI has an answer to each: the keyboard covers the field being
typed into, it has no key to finish with, and it will not go away. Nothing here was run; it is written
from Apple's documentation for the modifiers named, as it stood on 30 October 2026.

## The field it covers

SwiftUI treats the keyboard as part of the **safe area**, the region content is laid out to avoid,
alongside the status bar and the home indicator. Apple's documentation for `SafeAreaRegions` lists
`keyboard` as one of the regions, "the current extent of any software keyboard". So when the keyboard rises, the form's content gets less height. A `Form` scrolls, so the field being
typed into can be brought above the keyboard. That SwiftUI does this for the focused row is its
behaviour on iOS, and this course did not see it run. It is one reason the planner's form is a `Form` and not a `VStack` of
fields: a plain stack taller than what is left does not scroll, and its lower fields stay under the
keyboard.

The opposite, a background that should run under the keyboard, is `.ignoresSafeArea(.keyboard)` on that
background, and nothing else.

## A key to finish with

A full keyboard has a return key, and `.onSubmit` runs when it is pressed; `.submitLabel` chooses the
word on it, `Done`, `Next`, `Go`. **The number pad from section 03 has no return key at all**, so a
person who has typed `45` has nothing to press. The answer is a toolbar placed on the keyboard:

```swift
// SessionForm.swift, the keyboard's own toolbar
.toolbar {
    ToolbarItem(placement: .confirmationAction) {
        Button("Add", action: add)
    }
    ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button("Done") { focused = nil }
    }
}
```

Apple's documentation for `ToolbarItemPlacement.keyboard` says such items sit above the software
keyboard when it is showing, and at the bottom of the screen when a hardware keyboard is attached
instead. `Spacer()` pushes `Done` to the trailing edge of that bar. **`focused = nil`
is the whole implementation of `Done`**: section 06's `@FocusState` moves focus off every field, and
with nothing to type into the keyboard goes away.

## Going away when scrolled

A person who wants to see the rest of the form drags it, and the keyboard is in the way of that too.
`.scrollDismissesKeyboard(_:)` decides what a scroll does to it. Apple's documentation for it gives the
default: since iOS 16, scrollable content dismisses the keyboard when a scroll begins, except a
`TextEditor`, which dismisses it interactively, following the finger. The planner keeps the default and
writes nothing.

## The finished screen

Put together, `SessionForm` is section 06's code with the `.toolbar` above in place of its own. Its
behaviour, all of which comes from the documentation quoted in this lesson and none of which was seen
on a screen for the course:

| the person | the form |
|---|---|
| opens it | the date is today, the minutes are empty, no message is shown |
| types `forty` and taps Add | the minutes line says "Minutes are a whole number, like 45." and focus stays in the field |
| fixes it to `40` | the message goes on the next keystroke |
| taps Done | the keyboard goes away |
| taps Add | `draft.session(…)` returns a session for the day shown in the picker, and the sheet closes |

Every row of that table that is about **what is accepted** is a row the tests in section 04 hold. The
rows about where focus goes and when the keyboard moves are the screen's, and lesson 20's UI tests are
where those are checked, on a Mac.
