---
title: The second screen, and where its state lives
version: 1
---

**State goes in the closest component that every reader of it sits under.** The planner now needs two
more pieces: which course is open, and the sessions themselves, because ticking one off changes the
data. Both are read by the first screen and the second, so both go in `App`, above both. Moving state
up to a shared parent like this is called **lifting state up**, and the components below receive it
as props and ask for changes through functions, as `WeekNav` already does.

The course's name becomes a button that opens it. `Card`'s title was a string; it becomes any
`ReactNode`, so that a parent can put a button in it. Save `src/Card.tsx`:

```tsx
import type { ReactNode } from 'react'

type CardProps = {
  title: ReactNode
  children: ReactNode
}

export function Card({ title, children }: CardProps) {
  return (
    <article className="card">
      <h2>{title}</h2>
      {children}
    </article>
  )
}
```

`src/CourseCard.tsx` builds the button and hands it to `Card` as the title. The button calls `onOpen`
with the course's id, and `onOpen` is a new prop:

```tsx
import { Card } from './Card'
import type { Course, Session } from './types'
import { minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
  onOpen: (id: string) => void
}

export function CourseCard({ course, sessions, onOpen }: CourseCardProps) {
  const count = sessions.length
  const title = (
    <button type="button" onClick={() => onOpen(course.id)}>
      {course.name}
    </button>
  )
  return (
    <Card title={title}>
      <p>
        {count} {count === 1 ? 'session' : 'sessions'} · {minutes(sessions)} min
      </p>
    </Card>
  )
}
```

`src/CourseList.tsx` passes `onOpen` through to every card:

```tsx
import { CourseCard } from './CourseCard'
import type { Course, Session } from './types'

type CourseListProps = {
  courses: Course[]
  sessions: Session[]
  onOpen: (id: string) => void
}

export function CourseList({ courses, sessions, onOpen }: CourseListProps) {
  return (
    <section aria-label="Courses">
      {courses.map((course) => (
        <CourseCard
          key={course.id}
          course={course}
          sessions={sessions.filter((s) => s.course === course.id)}
          onOpen={onOpen}
        />
      ))}
    </section>
  )
}
```

The second screen is new, `src/CourseScreen.tsx`. It lists one course's sessions in date order, each
with a checkbox, and a button back:

```tsx
import type { Course, Session } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  sessions: Session[]
  onToggle: (id: string) => void
  onBack: () => void
}

export function CourseScreen({ course, sessions, onToggle, onBack }: CourseScreenProps) {
  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  return (
    <>
      <button type="button" onClick={onBack}>
        Back to courses
      </button>
      <h1>{course.name}</h1>
      <ul>
        {sorted.map((s) => (
          <li key={s.id}>
            <label>
              <input type="checkbox" checked={s.done} onChange={() => onToggle(s.id)} />
              {formatDay(s.date)} · {s.minutes} min
            </label>
          </li>
        ))}
      </ul>
    </>
  )
}
```

`[...sessions].sort(…)` copies the array before sorting it, because `sort` sorts in place and these
sessions belong to `App`. Each checkbox is **controlled**: `checked` comes from the data, and
`onChange` asks `App` to change the data, so the box shows what the state says and nothing else.
Lesson 10 is about inputs of this kind.

And `App` holds the three pieces of state and decides which screen to draw:

```tsx
import { useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import { courses, sessions as initialSessions } from './sample'
import { inWeek, mondayOf, today } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

function App() {
  const [monday, setMonday] = useState(() => mondayOf(today()))
  const [sessions, setSessions] = useState(initialSessions)
  const [openId, setOpenId] = useState<string | null>(null)

  function toggleDone(id: string) {
    setSessions((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <CourseScreen
          course={open}
          sessions={sessions.filter((s) => s.course === open.id)}
          onToggle={toggleDone}
          onBack={() => setOpenId(null)}
        />
      </main>
    )
  }

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList courses={courses} sessions={thisWeek} onOpen={setOpenId} />
    </main>
  )
}

export default App
```

`sessions as initialSessions` renames the import, so that `sessions` can be the state. `openId` is
`string | null`, with `null` for "no course open", and the type has to be written because React
cannot guess it from `null`. **When a course is open, `App` returns early** with the second screen,
and nothing of the first is drawn. `toggleDone` uses the updater form from two sections back, and
builds a new array with one new object in it; the next section shows why it has to.

```schooling-figure
{"svg": "<svg data-fig=\"lifted\" viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"App holds three pieces of state: monday, sessions and openId. Values go down as props to WeekNav, WeekSummary, CourseList and CourseScreen. Requests for change come back up as function calls: onChange from WeekNav, onOpen from the course cards, onToggle and onBack from CourseScreen. The totals in WeekSummary are computed from the props, not stored.\"><rect x=\"220\" y=\"14\" width=\"280\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"38.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">App</text><text x=\"360.0\" y=\"53.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">monday · sessions · openId</text><rect x=\"20\" y=\"170\" width=\"155\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"97.5\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekNav</text><line x1=\"50\" y1=\"80\" x2=\"50\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"50.0,168.0 46.8,160.5 53.2,160.5\" fill=\"var(--phosphor)\"></polygon><line x1=\"145\" y1=\"168\" x2=\"145\" y2=\"80\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"145.0,80.0 148.2,87.5 141.8,87.5\" fill=\"var(--amber)\"></polygon><text x=\"139\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">onChange</text><rect x=\"195\" y=\"170\" width=\"155\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272.5\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekSummary</text><line x1=\"225\" y1=\"80\" x2=\"225\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"225.0,168.0 221.8,160.5 228.2,160.5\" fill=\"var(--phosphor)\"></polygon><rect x=\"370\" y=\"170\" width=\"155\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"447.5\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseList</text><line x1=\"400\" y1=\"80\" x2=\"400\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"400.0,168.0 396.8,160.5 403.2,160.5\" fill=\"var(--phosphor)\"></polygon><line x1=\"495\" y1=\"168\" x2=\"495\" y2=\"80\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"495.0,80.0 498.2,87.5 491.8,87.5\" fill=\"var(--amber)\"></polygon><text x=\"489\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">onOpen</text><rect x=\"545\" y=\"170\" width=\"155\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"622.5\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseScreen</text><line x1=\"575\" y1=\"80\" x2=\"575\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"575.0,168.0 571.8,160.5 578.2,160.5\" fill=\"var(--phosphor)\"></polygon><line x1=\"670\" y1=\"168\" x2=\"670\" y2=\"80\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"670.0,80.0 673.2,87.5 666.8,87.5\" fill=\"var(--amber)\"></polygon><text x=\"664\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">onToggle, onBack</text><text x=\"272\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">computes the totals from its props</text><text x=\"20\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">down: values as props</text><text x=\"380\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">up: requests as calls</text></svg>", "caption": "Values go down as props; requests for change come up as calls."}
```

## Ticking a session off

```
ana@dev:~/planner$ npx tsc -b && echo no errors
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 | sed -n 9,13p
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]:
        - button "Statistics"
      - paragraph: 2 sessions · 90 min
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics'
-- click button Statistics
- main:
  - button "Back to courses"
  - heading "Statistics" [level=1]
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | sed -n 6,13p
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 120 of 195 minutes done
  - region "Courses":
    - article:
```

The course's heading now holds a button, and the snapshot shows both. On the second screen, the two
Statistics sessions are checkboxes, named by their labels, and the 19th is already done. The last
`look` opens Statistics, ticks the 21st and goes back, and the summary says **120 of 195**: the 80
there were, plus the 40 just done. Nothing was told to update the summary. It computed the total
from `sessions`, and `sessions` had changed.
