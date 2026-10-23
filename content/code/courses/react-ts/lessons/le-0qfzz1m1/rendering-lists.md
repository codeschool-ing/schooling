---
title: A list is an array of elements
version: 1
---

**React has no loop syntax. A list is an array of elements, and the way to get one is `map`.** JSX
accepts an array anywhere it accepts a child, and draws its items in order. The planner has two lists
already, and both are this shape:

```tsx
{courses.map((course) => (
  <CourseCard key={course.id} course={course} … />
))}
```

Everything else about lists is ordinary JavaScript before the `map`. **Filter, sort and slice the
data first, then map what is left**, which is what `CourseScreen` does with `[...sessions].sort(…)` and
what `App` does with the week. Doing the work in the data keeps the JSX a plain description of what is
drawn, and lesson 4 already said why the sort copies first.

## What React asks of a list

Every element in an array needs a `key`, and React says so when one is missing. Take the key off the
course cards:

```
ana@dev:~/planner$ sed -i '/^          key={course.id}$/d' src/CourseList.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet
[error] Each child in a list should have a unique "key" prop.%s%s See https://react.dev/link/warning-keys for more information. 

Check the render method of `CourseList`. 
ana@dev:~/planner$ npm run lint 2>&1 | grep -A 1 "jsx-key"
  ! react(jsx-key): Missing "key" prop for element in iterator.
    ,-[src/CourseList.tsx:13:16]
ana@dev:~/planner$ sed -i 's|^          course={course}$|          key={course.id}\n&|' src/CourseList.tsx
ana@dev:~/planner$ grep -n "key=" src/CourseList.tsx
15:          key={course.id}
```

The page still drew, and the console has the error, with the component to look at. The linter found it
before anything ran: `jsx-key`, "Missing `key` prop for element in iterator". The last two commands put
the key back. **A missing key is not a crash; it is React telling you it is about to guess**, and the
next two sections show what a wrong guess costs.

The same applies to anything that produces an array of elements: `filter(…).map(…)`, `Array.from`,
or a list built in a loop and pushed into an array. If it ends up as an array of elements, each needs
a key.
