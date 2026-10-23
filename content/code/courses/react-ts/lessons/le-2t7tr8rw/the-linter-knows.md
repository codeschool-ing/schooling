---
title: The linter knows the rules
version: 1
---

**Both rules can be checked by reading the code, without running it, and the template's linter does
it.** Oxlint, which `npm run lint` runs, has the rule from the React team's own ESLint plugin under
the name `react-hooks/rules-of-hooks`, and the template's `.oxlintrc.json` sets it to `error`. It
found the hook after the early `return` in the last section, and it finds a hook hidden inside an
expression just as easily:

```
ana@dev:~/planner$ sed -i 's|^  const \[showLeft, setShowLeft\] = useState(false)$|  const [showLeft, setShowLeft] = sessions.length > 0 ? useState(false) : [false, () => {}]|' src/WeekSummary.tsx
ana@dev:~/planner$ sed -n 10,12p src/WeekSummary.tsx
export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
  const [showLeft, setShowLeft] = sessions.length > 0 ? useState(false) : [false, () => {}]
  if (sessions.length === 0) {
ana@dev:~/planner$ npm run lint 2>&1 | head -n 12

> planner@0.0.0 lint
> oxlint


  x react-hooks(rules-of-hooks): React Hook "useState" is called conditionally. React Hooks must be called in the exact same order in every component render.
    ,-[src/WeekSummary.tsx:11:57]
 10 | export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
 11 |   const [showLeft, setShowLeft] = sessions.length > 0 ? useState(false) : [false, () => {}]
    :                                   ^^^^^^^^^|^^^^^^^^^   ^^^^^^^|^^^^^^^
    :                                            |                   `-- This Hook call is not reachable on every render path.
    :                                            `-- Only one side of this conditional expression calls the Hook.
ana@dev:~/planner$ cp /tmp/WeekSummary.tsx src/WeekSummary.tsx
```

`sessions.length > 0 ? useState(false) : [false, () => {}]` is an attempt to call a hook only when
there is something to show, written so that it looks like a single line rather than an `if`. The
linter is not reading lines. It points at both halves of the expression and says which half calls the
hook.

**Treat this rule's error as a compile error.** A component that breaks it may work today, for the
data you happen to test with, and break when the data changes shape; the last two sections are both
that. Lesson 23 makes the linter part of the commands run before every commit, so that a
`rules-of-hooks` error never reaches the main branch, and shows the same rule in ESLint for a project
that uses that instead.

The linter has a second hook rule, `exhaustive-deps`, which lesson 5 met as a warning about the
title. It is a warning rather than an error, by the template's choice, because there are rare cases
where the right array is not the one it suggests. Those cases are rare enough that the safe habit is
to treat the warning as an error too, and to write a comment where you decide otherwise. The next
section is the commonest reason it fires.
