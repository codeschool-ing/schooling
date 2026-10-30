---
title: Labels, roles and grouping, in three spellings
version: 1
---

**Most of an accessible screen comes free from the platform's own components, and the rest is a
handful of declarations on the controls you build yourself.** A `Text` is read as its words; a
standard button, checkbox or switch already declares its role and its state. Android's documentation
says you "do not need to provide a contentDescription for Text composables", and the same holds on
iOS and in React Native. What needs writing is the label of anything that shows a picture instead of
words, the role and state of anything you drew yourself, and the grouping of things that belong
together.

## One session row, three times

The planner's week shows each session as a row: the course, the date and length, and a tick that
marks it done. Heard naively, that is three or four elements per row, and a screen reader user
swipes through all of them to reach the next session. The better row is **one element** that reads
the session as a sentence, says it is a checkbox, says whether it is checked, and toggles on a
double tap.

The three fragments below make that row on each platform. They are adapted from each platform's
accessibility documentation, Android's on Compose semantics, Apple's on SwiftUI, and React Native's
on its accessibility properties, and **they were not compiled or run for this course**. Read them
for the shape, not the syntax: each one does the same four things.

```kotlin
// Compose: toggleable makes the row one element, with the checkbox role and its state
Row(
    Modifier.toggleable(
        value = session.done,
        role = Role.Checkbox,
        onValueChange = { onMarkDone(session.id) },
    )
) {
    Text(course.title)
    Text("${session.date}, ${session.minutes} minutes")
    Checkbox(checked = session.done, onCheckedChange = null)
}
```

```swift
// SwiftUI: combine the children into one element, then say what it is and how it is
HStack {
    Text(course.title)
    Text("\(session.date), \(session.minutes) minutes")
    Image(systemName: session.done ? "checkmark.circle.fill" : "circle")
}
.accessibilityElement(children: .combine)
.accessibilityAddTraits(.isButton)
.accessibilityValue(session.done ? "done" : "not done")
.onTapGesture { markDone(session.id) }
```

```tsx
// React Native: one Pressable, with its label, role and state declared on it
<Pressable
  onPress={() => markDone(session.id)}
  accessibilityLabel={`${course.title}, ${session.date}, ${session.minutes} minutes`}
  accessibilityRole="checkbox"
  accessibilityState={{ checked: session.done }}
>
  <Text>{course.title}</Text>
  <Text>{session.minutes} min</Text>
</Pressable>
```

**Grouping is spelled three ways and means one thing.** In Compose, a clickable or toggleable
modifier merges what is inside it, and `Modifier.semantics(mergeDescendants = true)` does the same for
a row that is not clickable; Android's documentation says the accessibility services then "focus on
the whole container at once". In SwiftUI, `.accessibilityElement(children: .combine)` merges the
children's properties into one new element. In React Native, a view marked `accessible={true}` is one
element for VoiceOver and TalkBack, and its touchable components are accessible by default.

**Role and state are where the three differ most in name.** Compose sets `role = Role.Checkbox` and
takes the state from `value`; Android's documentation adds a `stateDescription` for when "checked"
and "not checked" are not the right words. SwiftUI adds a trait, `.isButton`, and puts the state in
the value. React Native writes `accessibilityRole="checkbox"` and `accessibilityState={{ checked }}`.

## Labels that help, and labels that do not

**A label names the purpose, in the words of the screen, and never the look.** "Mark SQL on Friday
done" helps. "Green tick icon" describes pixels the user cannot see and says nothing about what
happens. "Mark done button" repeats the role, so the user hears "button" twice. And seven rows all
labelled "mark done" are seven identical sounds: Android's documentation asks that each description
be unique, which is why the planner's label carries the course and the date.

**Decoration says nothing at all.** A drawing beside the week's total that adds no information should
be hidden from the screen reader, so that the user does not spend a swipe on it: `contentDescription
= null` on a Compose `Image`, `.accessibilityHidden(true)` in SwiftUI. The HIG asks for the same:
exclude "purely decorative images", out of "respect for people's time".

**A hint is for what the label and role leave unclear**, and most controls need none. A checkbox that
toggles is clear from its role. A row that opens the session's details on a double tap might carry
"opens the session". React Native's documentation notes that VoiceOver reads a hint only when the
user has hints turned on, so nothing essential may live in a hint alone.

The declarations above are the whole of it for a screen reader. The next sections turn to the
users who see the screen, but not well, and tap it, but not precisely.
