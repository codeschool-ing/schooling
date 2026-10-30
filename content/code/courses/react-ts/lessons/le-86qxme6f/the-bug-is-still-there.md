---
title: The bug is still there
version: 1
---

**A boundary decides what a failure looks like. It does not make the failure go away**, and the
statistics card still fails every time somebody finishes a week. The fix is in `CourseCard`, and it
starts by taking away the `!`, the one character that asked the compiler not to check:

```
ana@dev:~/planner$ sed -i 's/(s) => !s.done)!/(s) => !s.done)/' src/CourseCard.tsx && npx tsc -b
src/CourseCard.tsx(24,27): error TS18048: 'next' is possibly 'undefined'.
```

**TS18048: `'next' is possibly 'undefined'`.** With the `!` gone, TypeScript is back to knowing what
`find` returns, and it points at the line that crashed the page, before anything has run. That is the
error the `!` had silenced. The question it asks is a real one: what should the card say when the
week has nothing left? Answer it in the card:

```tsx
import { Card } from './Card'
import type { Course, Session } from './types'
import { formatDay, minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
  onOpen: (id: string) => void
}

export function CourseCard({ course, sessions, onOpen }: CourseCardProps) {
  const count = sessions.length
  const next = sessions.find((s) => !s.done)
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
      <p>{next ? `Next: ${formatDay(next.date)}` : 'Nothing left this week'}</p>
    </Card>
  )
}
```

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 64ms on 19 files with 116 rules using 4 threads.
no errors
```

Tick the last statistics session again:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep -E 'heading|paragraph'
  - heading "Study planner" [level=1]
    - paragraph: Week of 19 Oct 2026
    - paragraph: 120 of 195 minutes done
      - heading "Statistics" [level=2]:
      - paragraph: 2 sessions · 90 min
      - paragraph: Nothing left this week
      - heading "Spanish" [level=2]:
      - paragraph: 2 sessions · 60 min
      - paragraph: "Next: Fri 23 Oct"
      - heading "Organic chemistry" [level=2]:
      - paragraph: 1 session · 45 min
      - paragraph: "Next: Thu 22 Oct"
```

The statistics card says *Nothing left this week*, and the week before, which failed on all three
cards, now gives a console with nothing in it:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Previous week' --quiet
-- click button Previous week
```

Treat **a non-null assertion `!` as a claim you have to be able to defend**: that this value cannot be
`undefined`, here, for every input this code will ever see. "The data I tested with always has one" is
not a defence, and it is exactly how this bug was written. Lesson 19 has more on letting TypeScript
carry that kind of fact for you.

Keep both boundaries anyway. Every bug that reaches users was one somebody did not know about, and the
next one will not announce itself either: the boundaries are there so that it costs one card, or one
screen with a sentence on it, rather than a white page.
