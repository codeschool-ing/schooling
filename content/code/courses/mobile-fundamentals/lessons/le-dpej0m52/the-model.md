---
title: The planner's tabs, as a program
version: 1
---

**A navigation library is a data structure with a screen attached, and the data structure is small
enough to write yourself.** The planner gets two tabs, Courses and Week, each with a stack of its own.
The Courses stack can grow to three screens: the list of courses, one course's detail, and the form for
a new session. The Week stack starts at the week's plan and can push one session's detail. This
section writes the rules as a file of plain functions, with no screen, so that the next one can feed it
taps and back presses and print what every stack holds.

**The model is a value, as `planner.ts` is in lesson 1.** A `Nav` says which tab is showing and what
each tab's stack holds, as a list of screen names from the root up. Every function takes one and
returns a new one, and nothing is changed in place. A screen is a string such as `course:sql`, which
is enough to tell the screens apart in a printout. A real app would carry the course's id in a typed
argument, and the toolkits in the last section of this lesson do. Save this as `backstack.ts` in
`~/planner`:

```schooling-example
{"language": "typescript", "file": "backstack.ts", "parts": [{"code": "// backstack.ts: the planner's two tabs, each with a stack of its own\nexport type Tab = \"Courses\" | \"Week\";\nexport type Nav = { tab: Tab; stacks: Record<Tab, string[]> };\n\n// The tab the app opens on. Back returns here before it leaves the app.\nexport const START: Tab = \"Courses\";\n\nexport function start(): Nav {\n  return { tab: START, stacks: { Courses: [\"courses\"], Week: [\"week\"] } };\n}\n", "note": "The whole state of navigation: which tab shows, and one list per tab, root first. `Record<Tab, string[]>` makes TypeScript insist that both tabs have a stack. Each stack starts with its root, and a root is never removed."}, {"code": "// Open a screen: push it onto the stack of the tab that is showing.\nexport function open(nav: Nav, screen: string): Nav {\n  const stack = [...nav.stacks[nav.tab], screen];\n  return { ...nav, stacks: { ...nav.stacks, [nav.tab]: stack } };\n}\n", "note": "Push. Only the stack of the tab showing grows; `[nav.tab]` picks it by name, and the other tab's stack is copied across untouched."}, {"code": "// A tap on a tab. Another tab: show it, with its stack as it was left.\n// The tab already showing: go back to that tab's first screen.\nexport function tap(nav: Nav, tab: Tab): Nav {\n  if (tab !== nav.tab) return { ...nav, tab };\n  return { ...nav, stacks: { ...nav.stacks, [tab]: nav.stacks[tab].slice(0, 1) } };\n}\n", "note": "Switching tabs changes `tab` and nothing else, so each stack waits where it was left. A second tap on the same tab keeps only the root, with `slice(0, 1)`."}, {"code": "// Android's system back. `left` is true when there was nothing to go back to.\nexport function back(nav: Nav): { nav: Nav; left: boolean } {\n  const stack = nav.stacks[nav.tab];\n  if (stack.length > 1) {\n    return { nav: { ...nav, stacks: { ...nav.stacks, [nav.tab]: stack.slice(0, -1) } }, left: false };\n  }\n  if (nav.tab !== START) return { nav: { ...nav, tab: START }, left: false };\n  return { nav, left: true };\n}\n", "note": "Three cases, in order: pop the top screen; at another tab's root, switch to `START`; at the root of `START`, report that the app leaves. The caller learns which happened from `left`, not from comparing states."}, {"code": "// iOS has no system back: the app draws a back button above any screen\n// that has one under it, and draws none at a tab's first screen.\nexport function backButton(nav: Nav): boolean {\n  return nav.stacks[nav.tab].length > 1;\n}", "note": "The iOS half is a question, not a press: whether a back button is drawn at all. At a root there is none, so there is nothing to model beyond this."}]}
```

## What the four rules say

**`open` only ever touches the tab that is showing.** Pushing a course's detail while Courses is
showing grows the Courses stack and leaves Week's alone. That is the whole of "each tab has its own
stack": there is no single list of history, so there is nothing for a tab switch to scramble.

**`tap` is two rules in one function.** A tap on the other tab changes `tab` and nothing else, which
is why the student finds the Courses stack exactly as they left it. A tap on the tab already showing
cuts that tab's stack back to its root with `slice(0, 1)`, the convention the first section of this
lesson described. The root itself is never removed, so a tab always has a screen to show.

**`back` answers two things: the new state, and whether the app is still there.** Three cases, in
order. With more than one screen on the current stack, it pops the top one. At the root of a tab
that is not `START`, it switches to `START`, the way Android's navigation library arranges a bottom
bar. At the root of `START`, there is nothing left inside the app, so it returns the state unchanged
and `left: true`. What happens to the app then is the system's business, not the planner's: since
Android 12 the task moves to the background.

**`backButton` is the iOS half, and it is one comparison.** iOS has no system back, so the only
question is whether the app draws a back button, and it draws one above any screen that has another
screen under it. At a tab's root the answer is `false` and nothing is drawn; there is no press to
model, which is why the file has no iOS version of `back`.

## What it leaves out

**A drawer and a sheet are missing on purpose.** A drawer of destinations behaves like tabs with the
bar hidden, so the same `stacks` would serve it. A sheet sits over the current screen without joining
its stack; adding one would mean a field such as `sheet: string | null` that `back` clears before
it looks at any stack, which is exactly the order Android follows. The planner has two sections and
no sheet, so the model stays at the size of the planner.

**Nothing here knows about Android's predictive back either.** Predictive back changes when the
system asks the question, during the swipe instead of after it, and not what the answer is. The rules
above are the answer, and they are the same whichever way it is asked.
