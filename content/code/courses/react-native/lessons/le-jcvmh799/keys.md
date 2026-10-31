---
title: Keys, and the row that inherits its neighbour's state
version: 1
---

**A key tells React which element is which from one render to the next.** When the list changes, React
matches the new elements to the old ones by key: same key, same component, and its state comes along.
Get the key wrong, and the state goes to whichever row now has that key.

## A key that is a position

The commonest wrong key is the index, `key={i}`, because it is always there and it silences the warning
about missing keys. This test shows what it costs. Each row keeps a piece of state of its own, whether it
has been opened; the test opens *statistics*, then removes *spanish*, the first row, and prints the rows.
Save it as `__tests__/keys.test.tsx`:

```tsx
// __tests__/keys.test.tsx: what a key that is a position does when a row goes away.
import { fireEvent, render, screen } from "@testing-library/react-native";
import { useState } from "react";
import { Pressable, Text, View } from "react-native";

function Row({ name }: { name: string }) {
  const [open, setOpen] = useState(false); // state that belongs to this row
  return (
    <Pressable role="button" onPress={() => setOpen(true)}>
      <Text>
        {name}
        {open ? " (open)" : ""}
      </Text>
    </Pressable>
  );
}

function List({ names, byIndex }: { names: string[]; byIndex: boolean }) {
  return <View>{names.map((n, i) => <Row key={byIndex ? i : n} name={n} />)}</View>;
}

for (const byIndex of [true, false]) {
  test(`keyed by ${byIndex ? "index" : "id"}`, async () => {
    const names = ["spanish", "statistics", "guitar"];
    const view = await render(<List names={names} byIndex={byIndex} />);
    await fireEvent.press(screen.getByText("statistics"));
    await view.rerender(<List names={names.slice(1)} byIndex={byIndex} />); // spanish removed
    const rows = screen.getAllByText(/spanish|statistics|guitar/);
    console.log(`by ${byIndex ? "index" : "id"}:`, rows.map((t) => [t.props.children].flat().join("")).join(", "));
  });
}
```

```
ana@dev:~/planner$ npx jest keys
  console.log
    by index: statistics, guitar (open)

      at Object.log (__tests__/keys.test.tsx:29:13)

  console.log
    by id: statistics (open), guitar

      at Object.log (__tests__/keys.test.tsx:29:13)

PASS __tests__/keys.test.tsx
  ✓ keyed by index (137 ms)
  ✓ keyed by id (8 ms)

Test Suites: 1 passed, 1 total
Tests:       2 passed, 2 total
Snapshots:   0 total
Time:        0.646 s, estimated 1 s
Ran all test suites matching keys.
```

**Keyed by index, *guitar* is now open, and nobody opened it.** Before the removal *statistics* had key 1
and *guitar* key 2. After it, *statistics* has key 0 and *guitar* key 1, so React gave key 1's state,
*open*, to *guitar*, and *statistics*, now under key 0, took over *spanish*'s closed state. Keyed by the
id, each row keeps its own.

In this test the state is a word. In an app it is a half-typed note, a checkbox, a playing video, or a
scroll position, and it appears on the wrong item with no error anywhere.

## The key is the id

**Use the item's stable id**, the one the data already carries, which in the planner is `id` on every
course and every session. A FlatList asks for it through `keyExtractor`; a `map` takes it as `key`. Two
rules for choosing:

- **It must not change** while the item exists. A name is not a key: rename the course and React thinks
  it is a different one.
- **It must be unique in the list.** Two items with one key are one item, as far as React can tell.

This is the same rule this platform's own data follows: the planner's sessions point at their course by
`id`, never by name, so renaming *Spanish A2* changes nothing that joins to it. A key is a join between
two renders.

## When the data has no id

Give it one, when it is created, and keep it. `addSession` in `src/planner.ts` does exactly that, with
`s` and a number. An index is acceptable only for a list that never changes order and never loses an
item in the middle, which is rarer than it looks and is not a property anybody checks.
