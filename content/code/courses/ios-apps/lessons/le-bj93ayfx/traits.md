---
title: Traits, what an element is and does
version: 1
---

**A trait tells VoiceOver what kind of thing an element is, and VoiceOver says the trait after the
label.** A `Button` is read as *Add session, button*; a heading as *This week, heading*. The person
learns what they can do with an element from that one word, and they move around by it: VoiceOver's
rotor can jump from heading to heading, which is how a long screen is skimmed by ear. Nothing in
this section was run; it is written from Apple's documentation for `AccessibilityTraits` and the
modifiers that add and remove them, read on 30 October 2026.

**Use the control that already has the trait before adding one by hand.** The commonest defect is a
`Text` or an `Image` with `onTapGesture`: it does something when tapped and VoiceOver has no idea,
so it is read as text and nobody knows it can be activated. A `Button` carries `.isButton`, takes
the VoiceOver double-tap, works with a keyboard and a switch control, and highlights when pressed.

```swift
// WeekHeader.swift
import SwiftUI

struct WeekHeader: View {
    let title: String
    var showAll: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button("Show all", action: showAll)
        }
    }
}
```

`.font(.headline)` makes the text look like a heading and tells VoiceOver nothing. **The trait is
what makes it one** to a person who cannot see the weight of the font.

## The traits the planner uses

| trait | where in the planner | what VoiceOver adds |
|---|---|---|
| `.isHeader` | the week's title, each course's name on its screen | *heading*, and a stop for the rotor |
| `.isButton` | every `Button`, without asking | *button* |
| `.isSelected` | the course currently open in a list that shows the choice | *selected* |
| `.updatesFrequently` | a timer for a session in progress | reads the new value as it changes |

`.isSelected` is a state, so it goes on and off with the selection, `accessibilityAddTraits` when
it is chosen and `accessibilityRemoveTraits` when it is not. A trait the element does not have is a
promise it cannot keep: a row marked `.isButton` that does nothing when double-tapped is worse than
no trait, because the person tries and nothing happens.

## Actions without a gesture

Swiping a row to delete it is a gesture somebody using VoiceOver may never discover. SwiftUI's
`swipeActions` on a list row are offered to VoiceOver as **custom actions** automatically: the
person swipes up or down with one finger to hear them. An action that exists only as a custom drag
or a long press needs to be given the same way, with `.accessibilityAction(named:)`, so that every
person reaches every action by one path or another.
