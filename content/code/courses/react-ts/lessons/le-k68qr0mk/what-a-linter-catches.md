---
title: What a linter catches
version: 1
---

**A linter reads code without running it and points at patterns that are usually mistakes.** The planner
has had one since lesson 1: `create-vite` set it up with **Oxlint**, a linter written in Rust, and
`npm run lint` has run it after every change. Lesson 6 met it refusing a hook called conditionally.

This lesson changes the project's own files, so first the planner becomes a git repository, which the
last section needs and which makes every change below a diff you can read:

```
ana@dev:~/planner$ git init -q && git add -A && git commit -q -m "The planner, as lesson 22 left it" && git log --format=%s
The planner, as lesson 22 left it
```

Now a mistake from lesson 7: reading a ref while the component renders. The `sed` adds one line that
logs the heading's ref in the middle of `CourseScreen`:

```
ana@dev:~/planner$ sed -i 's|^  const heading = useRef<HTMLHeadingElement>(null)$|&\n  console.log(heading.current)|' src/CourseScreen.tsx && sed -n '17,18p' src/CourseScreen.tsx
  const heading = useRef<HTMLHeadingElement>(null)
  console.log(heading.current)
ana@dev:~/planner$ npm run lint

> planner@0.0.0 lint
> oxlint


  ! react(refs): Cannot access refs during render
    ,-[src/CourseScreen.tsx:18:15]
 17 |   const heading = useRef<HTMLHeadingElement>(null)
 18 |   console.log(heading.current)
    :               ^^^^^^^|^^^^^^^
    :                      `-- Passing a ref to a function may read its value during render
 19 |   useEffect(() => {
    `----
  help: React refs are values that are not needed for rendering. Refs should only be accessed outside of render, such as in event handlers or effects. Accessing a ref value (the `current` property) during render can cause your component not to update as expected
  note: React Compiler skipped optimizing this component or hook. Additional guidance: https://react.dev/reference/eslint-plugin-react-hooks/lints/refs

Found 1 warning and 0 errors.
Finished in 88ms on 36 files with 116 rules using 4 threads.
```

**`react(refs)`: Cannot access refs during render.** Oxlint points at the exact expression, explains
why in the `help` line, and adds what it costs on top: *React Compiler skipped optimizing this
component*. This rule is one of the React Compiler's own checks, and Oxlint runs it. It is a warning
here, not an error, so `npm run lint` still succeeded: a warning tells you, and an error stops you.

A linter is not the compiler. TypeScript found nothing wrong with that line, because nothing is wrong
with its types: `heading.current` is an `HTMLHeadingElement | null`, and logging one is allowed. What is
wrong is when it runs, and that is a fact about React, which is what a React linter knows.
