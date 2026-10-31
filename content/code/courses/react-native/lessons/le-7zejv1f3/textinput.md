---
title: TextInput, which always gives you a string
version: 1
---

**`TextInput` is React Native's text field**, a native `EditText` on Android and a `UITextField` on iOS.
It is controlled the way the rest of React is: the screen keeps the text in state, passes it as `value`,
and replaces it in `onChangeText`, which receives the new text on every keystroke.

```tsx
const [minutes, setMinutes] = useState("");
<TextInput value={minutes} onChangeText={setMinutes} keyboardType="number-pad" />;
```

## Always a string

**`keyboardType="number-pad"` changes the keyboard, not the value.** What arrives in `onChangeText` is a
string, `"25"`, and on a phone with an external keyboard, or after a paste, it can be `"25 min"` or
`"2.5"`. So the planner's form keeps both fields as strings in a draft and turns the minutes into a
number only when it saves, after checking it. Converting on every keystroke loses what the person typed
the moment it stops being a number, which makes correcting a typo impossible.

## The props that matter on a phone

| prop | what it changes |
|---|---|
| `keyboardType` | which keyboard appears: `number-pad`, `email-address`, `numbers-and-punctuation`, … |
| `autoComplete` | what the system may offer to fill in; `off` for a date it cannot know |
| `returnKeyType` | the label of the keyboard's return key: `next`, `done`, `send` |
| `onSubmitEditing` | what pressing that key does |
| `secureTextEntry` | dots instead of characters, for a password |
| `aria-label` | the field's accessible name |

**A placeholder is not a label.** It disappears the moment the person types, it is often too faint to
read, and screen readers treat it inconsistently. Each of the planner's fields has a visible `Text`
above it saying what it is, and an `aria-label` saying the same thing to assistive technology, which is
also how the tests find it: `getByLabelText("Date")`.

## Dates, honestly

The date field takes text in the form `YYYY-MM-DD`, which is clumsy on a phone. A real app would use a
date picker, which on each platform is a different native control, and the community library
`@react-native-community/datetimepicker` wraps both. *It was not added here*: its picker has no web
build, and the course's browser runs would lose the form. The validation that follows works the same
whatever fills the field.
