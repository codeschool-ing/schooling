---
title: The components, against the HTML you know
version: 1
---

**React Native has a short list of built-in components, and almost every screen is made of six of
them.** There is no `<div>`, no `<p>` and no `<button>`: each one is replaced by a component that maps
to a native view on each platform, and that `react-native-web` maps back to HTML in a browser.

| React Native | the nearest HTML | what to know |
|---|---|---|
| `View` | `<div>` | a box; it lays its children out with flexbox and draws no text |
| `Text` | `<span>`, `<p>` | **all text lives in a `Text`**; text directly inside a `View` is an error on a phone |
| `Pressable` | `<button>` | anything that takes a press; it says nothing to a screen reader until it has a `role` |
| `TextInput` | `<input>` | the platform's own field and keyboard; its value is state you keep |
| `FlatList` | a long `<ul>` | draws the visible rows only, and recycles them as the list scrolls |
| `ScrollView` | `<div>` with `overflow: auto` | scrolls everything inside it, all drawn at once; fine for a short screen |
| `Image` | `<img>` | needs a size, or it draws nothing |

**The second row catches every web developer once.** In a browser, text can sit anywhere. In React
Native, a string outside a `<Text>` stops the app on a phone with an error naming the component, while
the web build may show it anyway. The web build being lenient where the phone is strict is a pattern
worth expecting.

## `FlatList` and `ScrollView`

Lesson 6 measured the planner with five thousand sessions and found the cost in drawing everything.
**`FlatList` is React Native's answer to exactly that**: give it the whole array, `data`, a way to name
each item, `keyExtractor`, and a function that draws one row, `renderItem`, and it draws only what fits
on the screen, plus a margin. A `ScrollView` with the same five thousand rows inside it would draw them
all, like the web version did. Use `ScrollView` for a screen that is long because of its content, and
`FlatList` for a screen that is long because of its data.

## No events on everything

A `View` cannot be pressed: only a `Pressable` takes `onPress`. A `TextInput` does not hold its own
value the way an `<input>` does in a plain web page: you give it `value` and change it in
`onChangeText`, which is React's controlled-input pattern, and on a phone it is the only one.
