---
title: State belongs to a position in the tree
version: 1
---

**React keeps a component's state for as long as the same component sits in the same position of the
tree.** It does not attach state to a variable, or to the data a component draws; it attaches it to a
place. To see it, the cards need some state of their own. One last temporary component,
`src/Probe.tsx`, is a button that counts its presses:

```tsx
import { useState } from 'react'

// For lesson 3 only: a button that remembers how often it was pressed.
export function Probe({ name }: { name: string }) {
  const [count, setCount] = useState(0)
  return (
    <button type="button" onClick={() => setCount(count + 1)}>
      {name} pressed {count}
    </button>
  )
}
```

The instrumentation of the last two sections comes out, and `Card` draws a `Probe` under its
children:

```
ana@dev:~/planner$ sed -i '/rendered/d; /watch/d' src/*.tsx src/main.tsx
ana@dev:~/planner$ sed -i 's|^      {children}$|      {children}\n      <Probe name={title} />|; 1i import { Probe } from "./Probe"' src/Card.tsx
ana@dev:~/planner$ cat src/Card.tsx
import { Probe } from "./Probe"
import type { ReactNode } from 'react'

type CardProps = {
  title: string
  children: ReactNode
}

export function Card({ title, children }: CardProps) {
  return (
    <article className="card">
      <h2>{title}</h2>
      {children}
      <Probe name={title} />
    </article>
  )
}
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics pressed 0' --do 'click button Statistics pressed 1' --do 'click button Next week' 2>&1 | tail -n 12
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 0 sessions · 0 min
      - button "Statistics pressed 2"
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 0 sessions · 0 min
      - button "Spanish pressed 0"
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 0 sessions · 0 min
      - button "Organic chemistry pressed 0"
```

`look` pressed the Statistics probe twice and then "Next week", and the tail of the snapshot is the
course list afterwards. **The new week has different numbers, and the Statistics probe still says
2.** The click rendered every card again, with new props, and React kept each `Probe`'s count,
because after the render the first card's `Probe` was still a `Probe`, still inside the first
`Card`, still inside the first `CourseCard`. Same type, same position: same component, same state.

## Changing the position on purpose

`key` tells React which item is which in a list, and lesson 2 gave each `CourseCard` the course's id.
It works on any element, and it does more than tell siblings apart: **a different key is a different
component**, so React discards the old one, state and DOM nodes together, and starts a new one. Give
`CourseList` the week's Monday as its key:

```
ana@dev:~/planner$ sed -i 's|<CourseList courses|<CourseList key={monday} courses|' src/App.tsx
ana@dev:~/planner$ grep -n "<CourseList" src/App.tsx
16:      <CourseList key={monday} courses={courses} sessions={thisWeek} />
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics pressed 0' --do 'click button Statistics pressed 1' --do 'click button Next week' 2>&1 | tail -n 12
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 0 sessions · 0 min
      - button "Statistics pressed 0"
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 0 sessions · 0 min
      - button "Spanish pressed 0"
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 0 sessions · 0 min
      - button "Organic chemistry pressed 0"
```

Same presses, same click, and every probe is back at `0`. The key changed from `2026-10-19` to
`2026-10-26`, so React treated the course list of the new week as a list it had never seen, and every
component under it was created again from nothing.

```schooling-figure
{"svg": "<svg data-fig=\"identity\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two cases side by side. On the left, after Next week the first CourseCard still holds a Card that holds a Probe at the same place, so React keeps its count of 2. On the right, CourseList has the key 2026-10-19 before and 2026-10-26 after; a different key is a different component, so the whole subtree is created again and the count is 0.\"><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">same position: kept</text><text x=\"100\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">before</text><rect x=\"30\" y=\"58\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseList</text><line x1=\"100\" y1=\"84\" x2=\"100\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"100.0,98.0 96.8,90.5 103.2,90.5\" fill=\"var(--wire)\"></polygon><rect x=\"30\" y=\"98\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseCard</text><line x1=\"100\" y1=\"124\" x2=\"100\" y2=\"138\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"100.0,138.0 96.8,130.5 103.2,130.5\" fill=\"var(--wire)\"></polygon><rect x=\"30\" y=\"138\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Card</text><line x1=\"100\" y1=\"164\" x2=\"100\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"100.0,178.0 96.8,170.5 103.2,170.5\" fill=\"var(--wire)\"></polygon><rect x=\"30\" y=\"178\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Probe · 2</text><text x=\"270\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after</text><rect x=\"200\" y=\"58\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseList</text><line x1=\"270\" y1=\"84\" x2=\"270\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"270.0,98.0 266.8,90.5 273.2,90.5\" fill=\"var(--wire)\"></polygon><rect x=\"200\" y=\"98\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseCard</text><line x1=\"270\" y1=\"124\" x2=\"270\" y2=\"138\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"270.0,138.0 266.8,130.5 273.2,130.5\" fill=\"var(--wire)\"></polygon><rect x=\"200\" y=\"138\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Card</text><line x1=\"270\" y1=\"164\" x2=\"270\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"270.0,178.0 266.8,170.5 273.2,170.5\" fill=\"var(--wire)\"></polygon><rect x=\"200\" y=\"178\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Probe · 2</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">new key: started again</text><text x=\"460\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">before</text><rect x=\"390\" y=\"58\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">key=2026-10-19</text><line x1=\"460\" y1=\"84\" x2=\"460\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"460.0,98.0 456.8,90.5 463.2,90.5\" fill=\"var(--wire)\"></polygon><rect x=\"390\" y=\"98\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseCard</text><line x1=\"460\" y1=\"124\" x2=\"460\" y2=\"138\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"460.0,138.0 456.8,130.5 463.2,130.5\" fill=\"var(--wire)\"></polygon><rect x=\"390\" y=\"138\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Card</text><line x1=\"460\" y1=\"164\" x2=\"460\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"460.0,178.0 456.8,170.5 463.2,170.5\" fill=\"var(--wire)\"></polygon><rect x=\"390\" y=\"178\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Probe · 2</text><text x=\"630\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after</text><rect x=\"560\" y=\"58\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">key=2026-10-26</text><line x1=\"630\" y1=\"84\" x2=\"630\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"630.0,98.0 626.8,90.5 633.2,90.5\" fill=\"var(--wire)\"></polygon><rect x=\"560\" y=\"98\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseCard</text><line x1=\"630\" y1=\"124\" x2=\"630\" y2=\"138\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"630.0,138.0 626.8,130.5 633.2,130.5\" fill=\"var(--wire)\"></polygon><rect x=\"560\" y=\"138\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Card</text><line x1=\"630\" y1=\"164\" x2=\"630\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"630.0,178.0 626.8,170.5 633.2,170.5\" fill=\"var(--wire)\"></polygon><rect x=\"560\" y=\"178\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Probe · 0</text></svg>", "caption": "Same type at the same position keeps its state; a new key starts again."}
```

That is a tool, not an accident. A form that should start empty when the user switches to a different
record is the classic use: give it the record's id as its key, and switching records resets it
without a line of code to clear each field. The opposite mistake is lesson 8's subject: a list whose
keys do not follow its items, so that state stays at a position while the item it belonged to moves.

## Putting things back

Everything temporary goes, and strict mode returns:

```
ana@dev:~/planner$ sed -i 's| key={monday}||' src/App.tsx
ana@dev:~/planner$ sed -i '/Probe/d' src/Card.tsx
ana@dev:~/planner$ rm src/Probe.tsx src/rendered.ts src/watch.ts
ana@dev:~/planner$ sed -i 's/^import { createRoot }/import { StrictMode } from '"'"'react'"'"'\n&/; s/^  <>$/  <StrictMode>/; s/^  <\/>,$/  <\/StrictMode>,/' src/main.tsx
ana@dev:~/planner$ cat src/main.tsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
ana@dev:~/planner$ npx tsc -b && echo no errors
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 2 sessions · 90 min
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 2 sessions · 60 min
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 1 session · 45 min
```

The planner after this lesson is lesson 2's planner plus `today`, `WeekNav` and one piece of state.
