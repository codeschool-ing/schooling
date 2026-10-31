---
title: React in brief: components, JSX and props
version: 1
---

**React Native is React, and this course assumes no React.** The `javascript` course that comes before
it in the `mobile` track does not reach it, so this section gives the three ideas every screen in the
course is built from. If you have written React for the web, read it for the one difference: the
elements are not HTML.

## A component is a function

A **component** is a function whose name starts with a capital letter and which returns a description
of what to draw. React calls it, takes what it returns, and works out what the screen must become. You
never draw anything yourself; you say what should be there, and React makes it so. Save this as
`src/Greeting.tsx`:

```tsx
// src/Greeting.tsx: a component is a function that returns what to draw.
import { Text } from "react-native";

type Props = { name: string; minutes: number };

export function Greeting({ name, minutes }: Props) {
  const unit = minutes === 1 ? "minute" : "minutes";
  return (
    <Text>
      {name}, you have {minutes} {unit} planned today.
    </Text>
  );
}
```

## JSX is a function call written like markup

The part that looks like HTML is **JSX**, and it is JavaScript. Metro's Babel step turns
`<Text>Hello</Text>` into a call that creates an element: an object saying *a `Text`, with this
content*. Two rules follow from that:

- **Braces put JavaScript inside it.** `{name}` and `{minutes}` above are expressions, evaluated each
  time the component runs. Anything that produces a value goes there: a variable, a sum, a ternary,
  a function call.
- **A component returns one element.** Several siblings are wrapped, in a `View` or in an empty
  fragment, `<>…</>`, which groups them without adding anything to the screen. `App.tsx` uses one in
  the last section of this lesson.

## Props are a component's arguments

`Greeting` receives `{ name, minutes }`. Those are its **props**, passed by whoever uses it, exactly
like the attributes of an HTML tag, and the type `Props` says which ones it accepts. TypeScript then
refuses `<Greeting name="Ana" />` with a missing `minutes` before the app ever runs. Using it looks
like using any other element:

```tsx
<Greeting name="Ana" minutes={45} />
```

A string prop can be written in quotes; anything else, a number included, goes in braces. **A component
never changes its own props.** They belong to its parent, and a component that needs a value it can
change keeps it in state, which the pressable section of this lesson introduces and lesson 9 develops.

## What is different from React on the web

Only the elements. On the web the smallest pieces are `div`, `p`, `img`, `button`, and React DOM turns
them into HTML. **Here the smallest pieces are React Native's components**, `View`, `Text`, `Image`,
`ScrollView`, `Pressable` and a few more, and React Native turns them into native views. `<div>` in a
React Native component is an error, because nothing knows how to draw one. The rest of this lesson is
those components, one at a time.
