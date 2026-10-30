---
title: The planner's first real screen
version: 1
---

**The pieces of this lesson, put together, make the screen the planner opens on**: a heading with the
app's icon, the week's total, and every course as a button that says how many sessions it holds.
Pressing one opens it, which for now only says which course is open; lesson 8 gives it a screen of its
own. Save this as `src/PlanScreen.tsx`:

```schooling-example
{"language": "tsx", "file": "src/PlanScreen.tsx", "parts": [{"code": "// src/PlanScreen.tsx: the planner's first screen, built from the core components.\nimport { useState } from \"react\";\nimport { Image, ScrollView, Text, View } from \"react-native\";\nimport { CourseRow } from \"./CourseRow\";\nimport { mondayOf, weekTotal, type Plan } from \"./planner\";\n", "note": "`useState` is the one piece of React state on this screen. The components come from `react-native`, the rules from lesson 3's `src/planner.ts`, unchanged."}, {"code": "type Props = { plan: Plan; today: string };\n", "note": "The screen takes the plan and the date as props rather than reading them itself, so a test can hand it any plan and any day."}, {"code": "export function PlanScreen({ plan, today }: Props) {\n  const [open, setOpen] = useState<string | null>(null);\n  const total = weekTotal(plan, mondayOf(today));\n  const course = plan.courses.find((c) => c.id === open);\n  return (\n    <ScrollView contentContainerStyle={{ padding: 24, paddingTop: 64 }}>", "note": "Everything computed here is recomputed on each render, from the props and the state: the total, and the course that is open, if any. The whole screen scrolls, with its padding on the content."}, {"code": "      <View style={{ flexDirection: \"row\", alignItems: \"center\", gap: 12 }}>\n        <Image source={require(\"../assets/icon.png\")} style={{ width: 40, height: 40 }} aria-hidden />\n        <Text role=\"heading\" style={{ fontSize: 24, fontWeight: \"700\" }}>\n          Study planner\n        </Text>\n      </View>", "note": "A row: the icon and the heading side by side. The icon is decorative, so `aria-hidden`; the heading has `role=\"heading\"`, which a screen reader uses to find it."}, {"code": "      <Text style={{ marginVertical: 12 }}>\n        This week: {total.done} of {total.planned} minutes done\n      </Text>", "note": "The total, as one `Text` with the numbers in braces, so it is one sentence to a screen reader."}, {"code": "      <View role=\"list\">\n        {plan.courses.map((c) => (\n          <View role=\"listitem\" key={c.id}>\n            <CourseRow\n              course={c}\n              sessions={plan.sessions.filter((s) => s.course === c.id).length}\n              onOpen={setOpen}\n            />\n          </View>\n        ))}\n      </View>", "note": "The list. `role=\"list\"` and `role=\"listitem\"` let a screen reader say *list, three items*. `map` turns each course into an element, and `key` tells React which element is which course from one render to the next; lesson 7 explains why it must be the id."}, {"code": "      {course && <Text role=\"status\" style={{ marginTop: 12 }}>Open: {course.name}</Text>}\n    </ScrollView>\n  );\n}", "note": "Shown only when a course is open. `role=\"status\"` makes a screen reader announce it when it appears, without moving the user's place."}]}
```

`App.tsx` becomes small: it passes the data and today's date to the screen, and adds the status bar.
Replace it with:

```tsx
// App.tsx: the planner's root, which only hands the data to the first screen.
import { StatusBar } from "expo-status-bar";
import data from "./src/courses.json";
import { PlanScreen } from "./src/PlanScreen";
import type { Plan } from "./src/planner";
import { today } from "./src/today";

const plan: Plan = data;

export default function App() {
  return (
    <>
      <PlanScreen plan={plan} today={today()} />
      <StatusBar style="auto" />
    </>
  );
}
```

## Checked in a test

The test reads the screen the way a screen reader does, by role and by name. Save it as
`__tests__/PlanScreen.test.tsx`:

```tsx
// __tests__/PlanScreen.test.tsx: the screen, read the way a screen reader reads it.
import { fireEvent, render, screen } from "@testing-library/react-native";
import data from "../src/courses.json";
import { PlanScreen } from "../src/PlanScreen";
import type { Plan } from "../src/planner";

const plan: Plan = data;

test("every course is a button named for what it holds", async () => {
  await render(<PlanScreen plan={plan} today="2026-10-21" />);
  expect(screen.getAllByRole("button")).toHaveLength(3);
  expect(screen.getByRole("button", { name: "Spanish A2 2 sessions planned" })).toBeOnTheScreen();
});

test("pressing a course opens it", async () => {
  await render(<PlanScreen plan={plan} today="2026-10-21" />);
  await fireEvent.press(screen.getByRole("button", { name: /Guitar/ }));
  expect(screen.getByRole("status")).toHaveTextContent("Open: Guitar");
});
```

`getByRole("button", { name: … })` finds the button whose accessible name is exactly that text,
which is the text inside it joined with spaces. If somebody later wraps the course name in a `View`
with no role, or turns the row into something that is not a button, this fails, and says which
element it could not find. `fireEvent.press` presses it, as a finger would, and the status line that
appears is found by its role.

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npm test

> planner@1.0.0 test
> jest

PASS __tests__/planner.test.ts
PASS __tests__/PlanScreen.test.tsx
PASS __tests__/App.test.tsx

Test Suites: 3 passed, 3 total
Tests:       7 passed, 7 total
Snapshots:   0 total
Time:        1.117 s, estimated 2 s
Ran all test suites.
```

## Checked in a browser

Export the web build again, serve it as in lesson 3, and read it:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/?today=2026-10-21'
- heading "Study planner" [level=1]
- text: "This week: 75 of 125 minutes done"
- list:
  - listitem:
    - button "Spanish A2 2 sessions planned"
  - listitem:
    - button "Statistics 2 sessions planned"
  - listitem:
    - button "Guitar 2 sessions planned"
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/?today=2026-10-21' --click 'Guitar 2 sessions planned'
- heading "Study planner" [level=1]
- text: "This week: 75 of 125 minutes done"
- list:
  - listitem:
    - button "Spanish A2 2 sessions planned"
  - listitem:
    - button "Statistics 2 sessions planned"
  - listitem:
    - button "Guitar 2 sessions planned"
- status: "Open: Guitar"
```

Compare this with lesson 3's single run of text. **There is structure now**: a heading, a list of three
items, and in each a button whose name is everything a person needs to decide whether to press it. The
icon is not in the tree at all, which is what `aria-hidden` asked for. The second command pressed
*Guitar*, and the status line that appeared is read as a `status`, which a screen reader announces
without moving the user's place.

**The week's total is still plain text**, the line between the heading and the list. That is correct
for now. It is a fact the screen states, not something to press or to jump to; lesson 9 makes it
change when a session is marked done, and lesson 11 makes sure a screen reader hears that it did.
