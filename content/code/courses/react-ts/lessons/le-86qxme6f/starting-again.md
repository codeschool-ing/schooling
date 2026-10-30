---
title: Starting again
version: 1
---

**A boundary that has failed stays failed until it is unmounted.** Its state says `failed: true`, and
nothing in it changes that state back. To see what that means, go to a week where the planner has
nothing left to do, the week before:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Previous week' --quiet | grep -c 'ErrorBoundary:'
3
```

`--quiet` printed only the console, and `grep -c` counted the boundaries that reported: three. That
week has no sessions for statistics or Spanish and only a finished one for chemistry, so `find` comes
back empty on every card and every card shows its fallback. So far, so correct. Now come back to this
week, where the cards worked a moment ago:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Previous week' --do 'click button Next week' | grep -E 'heading|paragraph'
  - heading "Study planner" [level=1]
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
      - heading "Statistics" [level=2]
      - paragraph: This course could not be shown.
      - heading "Spanish" [level=2]
      - paragraph: This course could not be shown.
      - heading "Organic chemistry" [level=2]
      - paragraph: This course could not be shown.
```

The summary moved back to the week of 19 October and says 80 of 195, but **all three cards still say
they could not be shown**, although nothing is wrong with this week's data. Lesson 3 explains it: a
component keeps its state for as long as it stays at the same position with the same key. The
boundaries are keyed by course id, the course ids did not change, and so each boundary kept the
`failed: true` it had a week ago.

The way out is the same rule used on purpose. **A new key is a new component, with fresh state**, and
the list should start fresh whenever the week changes. In `src/App.tsx`, the only change is the
`key` on `CourseList`:

```tsx
import { useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import { usePlannerContext } from './plannerContext'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

function App() {
  const [monday, setMonday] = useWeek()
  const { status, courses, sessions } = usePlannerContext()
  const [openId, setOpenId] = useState<string | null>(null)

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <p role="alert">The planner could not be loaded.</p>

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <CourseScreen course={open} onBack={() => setOpenId(null)} />
      </main>
    )
  }

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList key={monday} courses={courses} sessions={thisWeek} onOpen={setOpenId} />
    </main>
  )
}

export default App
```

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Previous week' --do 'click button Next week' | grep -E 'heading|paragraph'
  - heading "Study planner" [level=1]
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
      - heading "Statistics" [level=2]:
      - paragraph: 2 sessions · 90 min
      - paragraph: "Next: Wed 21 Oct"
      - heading "Spanish" [level=2]:
      - paragraph: 2 sessions · 60 min
      - paragraph: "Next: Fri 23 Oct"
      - heading "Organic chemistry" [level=2]:
      - paragraph: 1 session · 45 min
      - paragraph: "Next: Thu 22 Oct"
```

The same two clicks, and this week's cards are back. Each week now gets a list of its own, built from
nothing, and a boundary that failed on another week is gone with that week's list.

```schooling-figure
{"svg": "<svg data-fig=\"reset\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two rows, each going from the week of 12 October to the week of 19 October. Top row, boundaries keyed by course id: in the week of 12 October the boundary fails, and in the week of 19 October it is the same boundary, still failed. Bottom row, the list keyed by the week: the week of 12 October has its own list, which fails; the week of 19 October gets a new list with new boundaries, and its cards draw.\"><text x=\"20\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">key={course.id}</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"57.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">week of 12 Oct</text><text x=\"120.0\" y=\"72.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">failed: true</text><line x1=\"222\" y1=\"65\" x2=\"298\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,65.0 290.5,68.2 290.5,61.8\" fill=\"var(--wire)\"></polygon><text x=\"260\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Next week</text><rect x=\"300\" y=\"40\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"410.0\" y=\"57.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">week of 19 Oct</text><text x=\"410.0\" y=\"72.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">failed: true</text><text x=\"410\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the same boundary</text><text x=\"540\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">still the fallback</text><text x=\"20\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">key={monday}</text><rect x=\"20\" y=\"135\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"152.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">week of 12 Oct</text><text x=\"120.0\" y=\"167.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">failed: true</text><line x1=\"222\" y1=\"160\" x2=\"298\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,160.0 290.5,163.2 290.5,156.8\" fill=\"var(--wire)\"></polygon><text x=\"260\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Next week</text><rect x=\"300\" y=\"135\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"410.0\" y=\"152.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">week of 19 Oct</text><text x=\"410.0\" y=\"167.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">failed: false</text><text x=\"410\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a new boundary</text><text x=\"540\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the cards draw</text></svg>", "caption": "A boundary keeps its failure while its key stays; a new key starts it fresh."}
```

Choosing the key is choosing **what counts as a new attempt**. The week is right here because it is
what changes the data a card is drawn from. Many projects use the `react-error-boundary` package
instead of writing the class, and its `resetKeys` prop is the same idea: a list of values which, when
any one of them changes, puts the boundary back to rendering its children.

A "Try again" button inside the card's fallback would be the other way to reset, and here it would be
a button that cannot work: trying again renders the same card from the same data, and it fails the
same way. A retry is only worth offering when something may have changed in between, such as a server
that was down. The last section of this lesson has one.
