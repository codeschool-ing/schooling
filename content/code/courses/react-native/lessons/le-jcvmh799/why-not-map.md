---
title: Why a map in a ScrollView stops working
version: 1
---

**Lesson 4 drew the planner's courses with `map` inside a `ScrollView`, and for three courses that is
right.** A list that grows, sessions over a term, messages, search results, cannot be drawn that way,
and the reason is a number you can measure.

Save this test as `__tests__/virtual.test.tsx`. It draws a thousand rows twice, once each way, and
counts how many rows each one actually created:

```tsx
// __tests__/virtual.test.tsx: a thousand rows, drawn by a ScrollView and by a FlatList.
import { render, screen } from "@testing-library/react-native";
import { FlatList, ScrollView, Text } from "react-native";

const rows = Array.from({ length: 1000 }, (_, i) => ({ id: `r${i}`, label: `Row ${i}` }));

test("a ScrollView creates every row", async () => {
  await render(
    <ScrollView>
      {rows.map((r) => (
        <Text key={r.id}>{r.label}</Text>
      ))}
    </ScrollView>,
  );
  console.log("ScrollView rows created:", screen.queryAllByText(/^Row /).length);
});

test("a FlatList creates the first screenful", async () => {
  await render(<FlatList data={rows} keyExtractor={(r) => r.id} renderItem={({ item }) => <Text>{item.label}</Text>} />);
  console.log("FlatList rows created:", screen.queryAllByText(/^Row /).length);
});
```

Run it:

```
ana@dev:~/planner$ npx jest virtual
  console.log
    ScrollView rows created: 1000

      at Object.log (__tests__/virtual.test.tsx:15:11)

  console.log
    FlatList rows created: 10

      at Object.log (__tests__/virtual.test.tsx:20:11)

PASS __tests__/virtual.test.tsx
  ✓ a ScrollView creates every row (436 ms)
  ✓ a FlatList creates the first screenful (36 ms)

Test Suites: 1 passed, 1 total
Tests:       2 passed, 2 total
Snapshots:   0 total
Time:        0.994 s, estimated 1 s
Ran all test suites matching virtual.
```

**The ScrollView created all thousand.** Each is a `Text`, so each is a native view, created and laid out
before the first frame, and kept in memory for as long as the screen is open, whether anybody ever
scrolls to it. On a phone that is the delay before the screen appears, and the memory that does not come
back. **The FlatList created ten**: enough to fill a screen, the default of its `initialNumToRender`.

## What a FlatList is

`FlatList` takes the data as an array and a function that draws one item, and decides itself which items
need to exist. It renders those near the visible area, and as the person scrolls it renders the ones
coming into view and unmounts the ones that went far out of it. A list of ten thousand sessions costs
about what a list of thirty does.

The next sections are the three props every FlatList needs, why the key must be an id, how the window of
rendered items is sized, and what to do when the items come in groups.
