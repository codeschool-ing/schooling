---
title: Something has to change
version: 1
---

**A screen that never changes is rendered once and forgotten.** To see how React redraws, the planner
needs something that changes, and lesson 1 promised it: buttons to move from one week to the next.
This section adds them. It uses one hook, `useState`, which lesson 4 explains properly; here it
matters only as the thing that tells React to draw again.

First, a way to know which week today is in. Add this to the end of `src/week.ts`:

```typescript

export function today(): string {
  const d = new Date()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${d.getFullYear()}-${month}-${day}`
}
```

It reads the computer's own date, in the computer's own time zone, which is what "today" means to the
person looking at the screen. Then a component with the two buttons, `src/WeekNav.tsx`:

```tsx
import { addDays } from './week'

type WeekNavProps = {
  monday: string
  onChange: (monday: string) => void
}

export function WeekNav({ monday, onChange }: WeekNavProps) {
  return (
    <nav aria-label="Week">
      <button type="button" onClick={() => onChange(addDays(monday, -7))}>
        Previous week
      </button>
      <button type="button" onClick={() => onChange(addDays(monday, 7))}>
        Next week
      </button>
    </nav>
  )
}
```

`WeekNav` does not know where the week is kept. **It receives the current Monday and a function to
call with a new one**, and that is how a child asks its parent for a change: the parent passes the
function down as a prop, like any other value. `onClick` takes a function too, and the browser calls
it when the button is pressed. And `App` keeps the week:

```tsx
import { useState } from 'react'
import { CourseList } from './CourseList'
import { courses, sessions } from './sample'
import { inWeek, mondayOf, today } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

function App() {
  const [monday, setMonday] = useState(() => mondayOf(today()))
  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList courses={courses} sessions={thisWeek} />
    </main>
  )
}

export default App
```

`useState(() => mondayOf(today()))` gives `App` a value that survives between renders, starting at
this week's Monday, and a function, `setMonday`, that replaces it. `App` hands `setMonday` to
`WeekNav` as `onChange`. Pressing "Next week" calls it with the Monday seven days on, React notices,
and the screen is drawn again:

```
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
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Next week'
-- click button Next week
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - region "This week":
    - paragraph: Week of 26 Oct 2026
    - paragraph: 0 of 0 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 0 sessions · 0 min
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 0 sessions · 0 min
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 0 sessions · 0 min
ana@dev:~/planner$ npx tsc -b && echo no errors
no errors
```

The week of 26 October has no sessions, so every number is zero, and "Previous week" brings the 19th
back. In your own browser the planner opens on the week you are living in, which is probably empty;
two or three presses of a button take you to the data. **The rest of this lesson is about what
happened between the click and the new numbers.**
