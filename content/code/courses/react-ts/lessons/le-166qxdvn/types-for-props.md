---
title: What a props type promises
version: 1
---

**A component's props type is a contract checked at every place the component is used.** Every
component in this course has had one, since lesson 2: `WeekNav` takes a `monday` that is a string and
an `onChange` that takes one. Break each half of the contract on purpose, with `sed`, and ask the
compiler:

```
ana@dev:~/planner$ sed -i 's/<WeekNav monday={monday}/<WeekNav monday={19}/' src/WeekScreen.tsx && npx tsc -b
src/WeekScreen.tsx(16,16): error TS2322: Type 'number' is not assignable to type 'string'.
ana@dev:~/planner$ sed -i 's/<WeekNav monday={19}/<WeekNav monday={monday}/' src/WeekScreen.tsx && sed -i 's/<WeekNav monday={monday} onChange={setMonday} \/>/<WeekNav monday={monday} \/>/' src/WeekScreen.tsx && npx tsc -b
src/WeekScreen.tsx(9,18): error TS6133: 'setMonday' is declared but its value is never read.
src/WeekScreen.tsx(16,8): error TS2741: Property 'onChange' is missing in type '{ monday: string; }' but required in type 'WeekNavProps'.
ana@dev:~/planner$ sed -i 's/<WeekNav monday={monday} \/>/<WeekNav monday={monday} onChange={setMonday} \/>/' src/WeekScreen.tsx && npx tsc -b && echo no errors
no errors
```

- **A number where a string was promised** is TS2322, at the exact line and column of the prop.
- **A prop left out** is TS2741, which names the missing prop and the type that asked for it. The
  compiler also noticed that `setMonday` is now unused, which is the same mistake seen from the other
  side.

Both would have run in a browser, and both would have been wrong there: a week whose Monday is the
number 19, or week buttons that do nothing when pressed. The third command put the line back.

React's own types cover what a props type usually needs. The ones this course has used, and two more
that a component library uses all the time:

| type | for | used in |
|---|---|---|
| `ReactNode` | anything React can draw: text, elements, `null`, lists of them | `Card`'s `title`, lesson 2 |
| `ComponentProps<'input'>` | every prop an HTML element accepts, `ref` included | `Field`, lesson 14 |
| `(value: string) => void` | a callback, typed by what it receives | `WeekNav`'s `onChange` |
| `ChangeEvent<HTMLInputElement>` | the event an input's `onChange` handler receives | a handler written apart from its JSX |
| `Dispatch<SetStateAction<T>>` | the setter that `useState<T>` returns, passed down as a prop | a child that sets its parent's state |

Two habits make the contract more useful. **Name the type after the component**, `WeekNavProps`, so the
error message points somewhere obvious. And **type what a prop means, not what happens to be passed**:
`monday: string` lets through `'banana'`, which no compiler can catch, but `onChange: (monday: string)
=> void` says exactly what the parent must accept, and that is where most mistakes between components
happen.
