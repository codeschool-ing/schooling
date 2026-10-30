---
title: Focus, and where it goes when something is wrong
version: 1
---

**Focus is which control the keyboard is typing into, and SwiftUI lets the app both read it and move
it.** The property wrapper is `@FocusState`, and Apple's documentation for it describes the two
directions: when focus enters a view marked with `focused(_:equals:)`, the state takes that view's
value, and setting the state from code moves focus to the matching view. Setting it to `nil` takes
focus away from every field, which also dismisses the keyboard. Nothing here was run; it is written
from that documentation, read on 30 October 2026.

## A disabled button tells nobody why

The obvious way to stop a bad session is `.disabled(!draft.problems.isEmpty)` on the Add button. It
works, and it fails the person in front of it: a greyed-out button says *no* and never says *because*.
Somebody who typed `1.5` sees nothing wrong with their screen and a button that does not answer.

The planner does the other thing. **Add is always enabled; tapping it with problems shows them, and
moves focus to the first field that needs attention.** The draft already knows every problem
(section 04), so the screen has only to decide where to point.

```swift
// SessionForm.swift, with focus
import SwiftUI
import PlannerCore

struct SessionForm: View {
    enum Field: Hashable { case minutes }

    let courses: [Course]
    let onAdd: (StudySession) -> Void

    @State private var draft = SessionDraft(date: .now)
    @State private var showProblems = false
    @FocusState private var focused: Field?
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Course") {
                Picker("Course", selection: $draft.courseID) {
                    Text("Choose one").tag(String?.none)
                    ForEach(courses) { course in
                        Text(course.title).tag(Optional(course.id))
                    }
                }
                if showProblems && draft.problems.contains(.noCourse) {
                    Text("Choose the course this session is for.")
                        .foregroundStyle(.red)
                }
            }
            Section("When and how long") {
                DatePicker("Day", selection: $draft.date, displayedComponents: .date)
                TextField("Minutes", text: $draft.minutesText)
                    .keyboardType(.numberPad)
                    .focused($focused, equals: .minutes)
                if showProblems, let message = minutesMessage {
                    Text(message).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("New session")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add", action: add)
            }
        }
    }

    private var minutesMessage: LocalizedStringKey? {
        for problem in draft.problems {
            switch problem {
            case .noMinutes: return "Enter how many minutes."
            case .minutesNotWhole: return "Minutes are a whole number, like 45."
            case .minutesOutOfRange: return "Between 5 and 480 minutes."
            case .noCourse: continue
            }
        }
        return nil
    }

    private func add() {
        if let session = draft.session(id: UUID().uuidString, calendar: calendar) {
            onAdd(session)
            dismiss()
        } else {
            showProblems = true
            if minutesMessage != nil { focused = .minutes }
        }
    }
}
```

**`Field` is an enum even with one case**, because the next field the form gains is a second case
and not a second `Bool`. Apple's documentation for `FocusState` allows either an optional value or a
`Bool`, and the optional is the one that grows.

`showProblems` starts `false` so that a form opened a moment ago is not already shouting "enter how
many minutes" at somebody who has not had the chance. The messages appear after the first tap on Add
and then follow the typing: correct the minutes and the line beneath them goes away on the next
keystroke, because `minutesMessage` is computed from the draft every time the body runs, which lesson
3 explained.

## The message is a sentence, in the person's language

The draft returns values and the screen turns them into words. `minutesMessage` returns a
`LocalizedStringKey`, which a string literal becomes when that is the type asked for, and `Text` looks
a key up in the app's string catalogue, as the literal under the picker does too. So a Portuguese translation
in the catalogue reaches a phone set to Portuguese without changing this code. **Had it returned a
`String`, `Text` would show the English as it is**: Apple's documentation for `Text` says a string
variable is displayed verbatim and only a key is localised. The planner's
messages say what to do — "Enter how many minutes" — rather than what was wrong, because the person
can act on the first.

**Red is not the whole message.** A person who cannot tell red from the text colour still reads the
sentence, which is why there is one. Lesson 19 adds what VoiceOver says when the message appears,
which this version does not yet handle.

## Focus that follows the order of the form

`focused = .minutes` only moves focus when the minutes are wrong. A missing course gets its message
and no focus, because a picker is not typed into and there is no keyboard to bring up. With more text
fields the rule generalises to "focus the first field, in screen order, whose problem is listed",
which is a loop over the cases of `Field` in the order the form shows them.
