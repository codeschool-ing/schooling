---
title: What stretches, what stays, and what turns
version: 1
---

**Inside one size class, a layout bends rather than switches: some things take whatever space
there is, and some keep their size whatever happens.** The usual mistake runs in one of two
directions. Either everything is given a fixed size, designed on one phone, and the layout leaves a
blank band down the side of a wider window or cuts its last column off on a narrower one. Or
everything stretches, and a line of text runs the full width of a landscape tablet, which nobody
can read.

## Three kinds of size

| kind | what it does | in the planner |
|---|---|---|
| fill | takes the space the parent gives it | the session list, the width of the course title |
| fixed, in dp or points | keeps its size on every window | the 48 dp touch targets, the 24 dp icons, the gap between rows |
| fill, up to a limit | stretches until a maximum, then stops and centres | the form for a new session, the paragraphs of a course's description |

**The third kind is the one beginners leave out.** A text field that is 300 dp wide on a phone is
fine; the same field at 1200 dp, on a tablet in landscape, asks the eye to travel across the whole
screen to read one line. Capping its width keeps it readable and leaves the rest of the window for
something else, which in the next section is a second pane.

The fragments below give the new-session form all three kinds: the form fills its window up to
600 units and stays centred past that, and the button inside it keeps its 48. They are adapted
from each platform's documentation, and **they were not compiled or run for this course**.

```kotlin
// Compose: fill the width, but never more than 600 dp; the button keeps its size
Column(Modifier.fillMaxWidth().widthIn(max = 600.dp).padding(16.dp)) {
    OutlinedTextField(value = title, onValueChange = { title = it }, modifier = Modifier.fillMaxWidth())
    Button(onClick = save, modifier = Modifier.heightIn(min = 48.dp)) { Text("Add session") }
}
```

```swift
// SwiftUI: as wide as the window allows, up to 600 points, centred
VStack(alignment: .leading) {
    TextField("Title", text: $title)
    Button("Add session", action: save).frame(minHeight: 48)
}
.padding(16)
.frame(maxWidth: 600)
.frame(maxWidth: .infinity)
```

```tsx
// React Native: flexbox, with a maximum width and the content centred
<View style={{ width: "100%", maxWidth: 600, alignSelf: "center", padding: 16 }}>
  <TextInput value={title} onChangeText={setTitle} />
  <Pressable onPress={save} style={{ minHeight: 48 }}>
    <Text>Add session</Text>
  </Pressable>
</View>
```

**None of the three names a device or an orientation.** They describe how the form behaves at any
width, which is why the same code is right in portrait, in landscape and in half of a split
screen.

## Turning the phone

Orientation is the change every user makes, and it is just a change of window: width and height
swap. Three things are worth checking when it happens, and none of them needs a separate landscape
layout:

- the content still fits the short side. A phone in landscape is compact in height, by Android's
  table, so a screen that stacks a header, a form and a button can run out of room, and has to
  scroll;
- nothing important sits where a hand holds the phone, or under the notch, which in landscape is
  at the side. Lesson 9 is about those regions;
- the state survives. Typing half a session's title and turning the phone must not lose the half,
  and on Android the screen is rebuilt for the rotation, as lesson 4 described.

**An app can refuse to turn**, and some should: a camera viewfinder, a game designed for one
shape. For a list of study sessions it is a way to avoid three checks at the cost of every user
who reads in landscape, and as the previous sections showed, a locked orientation still meets
split screens and resizable windows.
