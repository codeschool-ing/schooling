---
title: One small screen, three times
version: 1
---

**The same piece of the planner, written in each of the track's three routes, shows how close they
are in shape and how far apart they are in everything else.** The piece is one line and one button:
the week's total, "120 of 180 minutes done", and a "Mark done" button under it. These three
fragments are adapted from the style of each toolkit's documentation, and **they were not compiled
or run for this course**: there is no Android SDK, no Xcode and no phone on the machine the lessons
were recorded on. Read them to recognise one idea in three spellings.

Jetpack Compose, in Kotlin:

```kotlin
@Composable
fun WeekLine(total: WeekTotal, onMarkDone: () -> Unit) {
    Column {
        Text("${total.done} of ${total.planned} minutes done")
        Button(onClick = onMarkDone) { Text("Mark done") }
    }
}
```

SwiftUI, in Swift:

```swift
struct WeekLine: View {
    let total: WeekTotal
    let onMarkDone: () -> Void

    var body: some View {
        VStack {
            Text("\(total.done) of \(total.planned) minutes done")
            Button("Mark done", action: onMarkDone)
        }
    }
}
```

React Native, in TypeScript:

```tsx
function WeekLine({ total, onMarkDone }: Props) {
  return (
    <View>
      <Text>{total.done} of {total.planned} minutes done</Text>
      <Button title="Mark done" onPress={onMarkDone} />
    </View>
  );
}
```

## What is the same

**All three are a function of the data.** Each takes a `total` and something to call when the button
is pressed, and describes what the screen should look like for that total. None of them changes the
text by hand when the number changes: the toolkit draws the line again from the new total. That
shape, the screen as a function of state, is shared by Compose, SwiftUI and React, and it is why a
developer who learns one can read the other two without starting from nothing.

**All three stack a text above a button**, with `Column`, `VStack` and `View`. Lesson 8 is about how
those stacks stretch when the screen changes size.

## What is not

**The language, and with it everything the screen stands on.** `WeekTotal` in the Kotlin fragment is
a Kotlin class and in the Swift fragment a Swift struct, and each has to be computed by a
`weekTotal` written in that language. The React Native fragment is the only one that can import
lesson 1's `weekTotal` from `planner.ts` as it is, because it is the only one that runs JavaScript.
A Kotlin Multiplatform team would write `weekTotal` once in Kotlin and hand the result to both the
Compose fragment and the SwiftUI one. A Flutter version would be a Dart widget with the same shape,
and `react-native` lesson 22 shows what one looks like.

**And what the button is when it reaches the screen.** The Compose button is a Material button, the
SwiftUI one an iOS button, and React Native's `Button` becomes whichever of the two the phone it runs
on has. Lesson 18 lays the two design guides side by side.
