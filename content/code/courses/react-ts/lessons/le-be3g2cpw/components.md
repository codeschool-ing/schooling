---
title: A component is a function that returns elements
version: 1
---

**A component is a function whose name starts with a capital letter and which returns JSX.** It
can take one argument, an object of props, which the next section is about. That is the whole
definition; there is no class to extend and no registration step. `WeekSummary` was one. `App` is
another, and it is the one `main.tsx` renders. Replace the template's `src/App.tsx` with the
planner's:

```tsx
import { CourseList } from './CourseList'
import { courses, sessions } from './sample'
import { inWeek } from './week'
import { WeekSummary } from './WeekSummary'

// Until lesson 4 lets you move between weeks, the planner shows this one.
const MONDAY = '2026-10-19'

function App() {
  const thisWeek = sessions.filter((s) => inWeek(s.date, MONDAY))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekSummary monday={MONDAY} sessions={thisWeek} />
      <CourseList courses={courses} sessions={thisWeek} />
    </main>
  )
}

export default App
```

`App` filters the sessions down to one week and hands what it computed to two components: the
`WeekSummary` you have, and a `CourseList` that the next section writes. Until `CourseList.tsx`
exists, Vite's overlay says it cannot resolve the import, which is the failure from lesson 1 and is
expected now.

`export default` is what `main.tsx` expects, because the template imported `App` without braces.
Every other component in this course uses a **named export**, `export function CourseList`, and is
imported with braces. A named export cannot be renamed by accident on the way in, and an editor can
find every place that uses it.

## Why the capital letter matters

To JSX, the first letter of a tag decides what it is. **Lowercase is an HTML element, passed to
the call as a string; a capital letter is a component, passed as the function itself.** Write a
component's name in lowercase and JSX hands React the string `"courseCard"`, which React dutifully
asks the browser to create. Once the screen is complete, at the end of the section "Children and
composition", this is what that one-letter mistake produces:

```
ana@dev:~/planner$ sed -i 's/<CourseCard$/<courseCard/' src/CourseList.tsx
ana@dev:~/planner$ grep -n courseCard src/CourseList.tsx
13:        <courseCard
ana@dev:~/planner$ look http://localhost:5173/ 2>&1 | head -n 8
[error] <%s /> is using incorrect casing. Use PascalCase for React components, or lowercase for HTML elements. courseCard
[error] The tag <%s> is unrecognized in this browser. If you meant to render a React component, start its name with an uppercase letter. courseCard
[error] <%s /> is using incorrect casing. Use PascalCase for React components, or lowercase for HTML elements. courseCard
[error] <%s /> is using incorrect casing. Use PascalCase for React components, or lowercase for HTML elements. courseCard
- main:
  - heading "Study planner" [level=1]
  - region "This week":
    - paragraph: Week of 19 Oct 2026
ana@dev:~/planner$ sed -i 's/<courseCard$/<CourseCard/' src/CourseList.tsx
```

React noticed and said so twice, once for the casing and once because the browser does not know a
`<courseCard>` element; the second message even says what you meant. The page still drew, with the
three cards missing: an unknown element renders as an empty box, and the props passed to it went
nowhere. **Read the console on every change**, because a mistake like this one fails quietly on the
page and loudly only there.

## One component per job

The planner's first screen is now five components, and each does one thing:

```schooling-figure
{"svg": "<svg data-fig=\"tree\" viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The first screen as a tree. App at the top passes monday and sessions to WeekSummary, and courses and sessions to CourseList. CourseList draws three CourseCards, each given one course and its sessions. Each CourseCard draws a Card with a title and children. Arrows point down only.\"><rect x=\"300\" y=\"14\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">App</text><rect x=\"80\" y=\"100\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">WeekSummary</text><rect x=\"470\" y=\"100\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">CourseList</text><line x1=\"330\" y1=\"44\" x2=\"170\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"170.0,100.0 176.0,94.5 178.1,100.5\" fill=\"var(--wire)\"></polygon><line x1=\"390\" y1=\"44\" x2=\"550\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"550.0,100.0 541.9,100.5 544.0,94.5\" fill=\"var(--wire)\"></polygon><text x=\"150\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">monday, sessions</text><text x=\"570\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">courses, sessions</text><rect x=\"270\" y=\"186\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">CourseCard</text><line x1=\"550\" y1=\"130\" x2=\"330\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"330.0,186.0 336.5,181.0 338.1,187.3\" fill=\"var(--wire)\"></polygon><rect x=\"290\" y=\"256\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Card</text><line x1=\"330\" y1=\"216\" x2=\"330\" y2=\"256\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"330.0,256.0 326.8,248.5 333.2,248.5\" fill=\"var(--wire)\"></polygon><rect x=\"410\" y=\"186\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">CourseCard</text><line x1=\"550\" y1=\"130\" x2=\"470\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"470.0,186.0 474.3,179.1 478.0,184.3\" fill=\"var(--wire)\"></polygon><rect x=\"430\" y=\"256\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Card</text><line x1=\"470\" y1=\"216\" x2=\"470\" y2=\"256\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"470.0,256.0 466.8,248.5 473.2,248.5\" fill=\"var(--wire)\"></polygon><rect x=\"550\" y=\"186\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">CourseCard</text><line x1=\"550\" y1=\"130\" x2=\"610\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"610.0,186.0 602.3,183.2 606.7,178.5\" fill=\"var(--wire)\"></polygon><rect x=\"570\" y=\"256\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Card</text><line x1=\"610\" y1=\"216\" x2=\"610\" y2=\"256\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"610.0,256.0 606.8,248.5 613.2,248.5\" fill=\"var(--wire)\"></polygon><text x=\"380\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">course, sessions</text><text x=\"258\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">title, children</text><text x=\"60\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one per course</text><line x1=\"150\" y1=\"200\" x2=\"262\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line></svg>", "caption": "Props travel down the tree, from the component that has the data to the ones that draw it."}
```

`App` decides which sessions are in the week. `WeekSummary` adds them up. `CourseList` walks the
courses. `CourseCard` describes one course, and `Card` draws a frame around anything. None of them
knows how the others work inside; each knows only what it is given. That is what makes it possible
to change the frame without reading the arithmetic, and lesson 4 will move the week into state
without touching `CourseCard` at all.
