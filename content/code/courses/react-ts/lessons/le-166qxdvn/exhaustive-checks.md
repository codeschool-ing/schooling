---
title: The case nobody handled
version: 1
---

**A union grows.** One day the planner will learn to work offline, and `PlannerState` will gain a
fourth shape. Every `switch` on `status` then has a case it does not handle, and nothing would say so:
`Root` would return `undefined` for it, which React draws as nothing, and the student would see a
blank page.

The `default` in `Root` is what says so:

```tsx
default: {
  const unhandled: never = planner
  return unhandled
}
```

**`never` is the type with no values.** When every shape has its `case`, nothing can reach `default`,
the planner's type there is `never`, and the assignment is fine. Add a shape, with `sed`, and see:

```
ana@dev:~/planner$ sed -i "s/  | { status: 'loading' }/  | { status: 'loading' }\\n  | { status: 'offline' }/" src/usePlanner.ts && npx tsc -b
src/Root.tsx(20,13): error TS2322: Type '{ toggleDone: UseMutateFunction<unknown, Error, string, unknown>; addSession: UseMutateFunction<unknown, Error, NewSession, unknown>; status: "offline"; }' is not assignable to type 'never'.
ana@dev:~/planner$ sed -i "/  | { status: 'offline' }/d" src/usePlanner.ts && npx tsc -b && echo no errors
no errors
```

**TS2322 in `Root.tsx`**: the `'offline'` shape reached `default`, and it is not `never`. The error is
in the file that must change, at the line that must change, before anything runs. The second command
removed the shape again.

That check only works because of how `stateOf` is written. **TypeScript narrows a variable to what was
assigned to it**: a `const state: PlannerState = …` built from three conditions would be typed as the
three shapes those conditions produce, not as the union it was declared with, and a fourth shape added
to the union would never reach `ReturnType<typeof usePlanner>`. A function with a declared return type
has no such shortcut: whatever it returns, its callers see `PlannerState`, all of it.

The same pattern fits any value that can be one of a fixed set of things: a request that is idle,
pending, done or failed; a form step; a message from a server with a `type` field. **Make the
impossible states impossible to write**, and the compiler checks the possible ones are all handled.
