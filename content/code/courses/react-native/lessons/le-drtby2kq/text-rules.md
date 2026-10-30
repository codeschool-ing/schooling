---
title: The string that is not inside a Text
version: 1
---

**On the web, text can sit directly in a `<div>`. In React Native it cannot**, and the error that
says so is the first one every newcomer meets. It is worth meeting on purpose, in a test, where it
costs nothing.

## Making the error

Save this as `__tests__/bare-string.test.tsx`. It renders one string straight inside a `View`:

```tsx
// __tests__/bare-string.test.tsx: what happens to a string outside <Text>.
import { render } from "@testing-library/react-native";
import { View } from "react-native";

test("a string straight inside a View", async () => {
  await render(<View>This week</View>);
});
```

Run only that file; Jest takes a part of a file name and runs the files that match:

```
ana@dev:~/planner$ npx jest bare-string 2>&1 | grep -E "Invariant|Tests:"
    Invariant Violation: Text strings must be rendered within a <Text> component. Detected attempt to render "This week" string within a <View> component.
Tests:       1 failed, 1 total
```

The message names the string and the component it was found in, which is most of the work of fixing
it. On a phone the same mistake fills the screen with the red error box of lesson 18, in development.
**The check lives only in the development renderer**: React Native's production renderer skips it, so
a release build does not stop with this message, and what it does instead is nothing to rely on. A
native `View` has nowhere to put text. Catch it in development, where it is loud.

Delete the file; it was there to fail:

```sh
rm __tests__/bare-string.test.tsx
```

## Where it hides

Nobody writes `<View>This week</View>` on purpose. The error turns up in three shapes that look
innocent:

| what you wrote | why it is a string in a View |
|---|---|
| `{count && <Text>{count} sessions</Text>}` | when `count` is `0`, the expression is `0`, and React renders that number as text |
| a stray space or a `.` after an element on its own line | JSX keeps text that sits between two elements on one line |
| `{course.name}` directly in a `View` | the name is a string, and only a `Text` can hold it |

**The first is the one that reaches production**, because it works in every test where the count is
not zero. Write `{count > 0 && …}`, which is `false` rather than `0` when the condition fails, and React
renders `false` as nothing.

## Text is also where fonts are

A consequence of the same rule: a `View` has no font. `color`, `fontSize` and `fontFamily` set on a
`View` do nothing to the `Text` inside it, because text does not inherit through boxes, only through
nested `Text`. Lesson 5 comes back to this as the CSS that does not exist here.
