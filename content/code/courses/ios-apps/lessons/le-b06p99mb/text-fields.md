---
title: A text field holds text
version: 1
---

**A `TextField` bound to a `String` holds exactly what is on the screen, and that is why the planner
uses one for the minutes.** SwiftUI offers a second kind, a field bound to a number through a format
style, and it reads as the obvious choice for a number of minutes. This section is about why it is not
the right one here. Nothing in it was run: the behaviour quoted is Apple's documentation for
`TextField`, read on 30 October 2026.

## Two ways to bind a field

```swift
// Minutes, two ways
@State private var minutesText = ""   // what the person typed
@State private var minutes = 30       // a number

TextField("Minutes", text: $minutesText)
TextField("Minutes", value: $minutes, format: .number)
```

The first is a field over a string: every keystroke changes `minutesText`, and the string is whatever
the field shows. The second converts between the text and an `Int` with a format style. Apple's
documentation for `init(_:value:format:prompt:)` says what happens when the conversion fails:

> If `format` can’t perform the conversion, the text field leaves `binding.value` unchanged. If the
> user stops editing the text in an invalid state, the text field updates the field’s text to the last
> known valid value.

**So a field bound to a number can show one thing while the model holds another.** Somebody replaces
`30` with `forty` and taps Add: the field still says `forty`, the binding still says `30`, and a
session of thirty minutes is added that nobody typed. When they leave the field, it quietly turns back
into `30`. Nothing was refused and nothing said why.

That is acceptable for a value with a sensible fallback, like a font size in a settings screen. For a
session somebody is adding, the planner wants the opposite: **keep what was typed, and say plainly why
it is not a session yet.** That is section 04's draft, whose `minutesText` is the first binding above.

## What the field can still be told

Binding to text does not mean accepting any keyboard. These modifiers change how a field is typed into
without changing what it holds, and each is a modifier from Apple's documentation for `View`:

| modifier | what it does for the minutes field |
|---|---|
| `.keyboardType(.numberPad)` | shows a keypad of digits instead of the full keyboard; section 07 deals with the missing return key |
| `.autocorrectionDisabled()` | stops autocorrection proposing a word in a field that wants digits |
| `.textInputAutocapitalization(.never)` | no capital at the start, which matters for a field of codes or names, not for this one |
| `.submitLabel(.done)` | which word the return key shows, on keyboards that have one |

**A number pad is a convenience and not a check.** A hardware keyboard attached to an iPad types
letters into a `.numberPad` field, and so does paste. The draft's `minutesNotWhole` is what refuses
them, which is why it exists even though the keypad has no letters on it.

## The prompt and the label

`TextField("Minutes", text:)` uses its string twice: as the placeholder shown while the field is
empty, and as the label VoiceOver reads. In a `Form` on iOS that placeholder is the only visible label
the field has, and it disappears as soon as somebody types. For a field whose meaning should stay
visible, `LabeledContent` puts a label beside it that does not go away:

```swift
// A label that stays
LabeledContent("Minutes") {
    TextField("30", text: $draft.minutesText)
        .keyboardType(.numberPad)
        .multilineTextAlignment(.trailing)
}
```

Now `Minutes` stays on the left and `30` is only an example, gone once a real number is typed.
