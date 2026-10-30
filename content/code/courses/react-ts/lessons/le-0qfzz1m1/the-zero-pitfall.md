---
title: The zero that appears from nowhere
version: 1
---

**`count && <p>…</p>` draws a `0` when `count` is zero.** The expression `a && b` returns `a` when `a`
is falsy, and `0` is falsy, so the whole expression is the number `0`, and React draws numbers. It is
the most common surprise with `&&`, and it is invisible in testing until somebody's data has a zero.

Here is a version of `CourseCard` that hides its line when a course has no sessions in the week:

```tsx
import { Card } from './Card'
import type { Course, Session } from './types'
import { minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
  onOpen: (id: string) => void
}

// For lesson 8 only: the line is drawn only when there are sessions.
export function CourseCard({ course, sessions, onOpen }: CourseCardProps) {
  const count = sessions.length
  const title = (
    <button type="button" onClick={() => onOpen(course.id)}>
      {course.name}
    </button>
  )
  return (
    <Card title={title}>
      {count && (
        <p>
          {count} {count === 1 ? 'session' : 'sessions'} · {minutes(sessions)} min
        </p>
      )}
    </Card>
  )
}
```

In the week of 19 October every course has sessions, so every line is drawn and nothing looks wrong.
The next week has none:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Next week' | sed -n '/region "Courses"/,$p'
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]:
        - button "Statistics"
      - text: "0"
    - article:
      - heading "Spanish" [level=2]:
        - button "Spanish"
      - text: "0"
    - article:
      - heading "Organic chemistry" [level=2]:
        - button "Organic chemistry"
      - text: "0"
ana@dev:~/planner$ sed -i 's|^      {count && ($|      {count > 0 \&\& (|' src/CourseCard.tsx
ana@dev:~/planner$ grep -n "count > 0" src/CourseCard.tsx
21:      {count > 0 && (
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Next week' | sed -n '/region "Courses"/,$p'
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]:
        - button "Statistics"
    - article:
      - heading "Spanish" [level=2]:
        - button "Spanish"
    - article:
      - heading "Organic chemistry" [level=2]:
        - button "Organic chemistry"
ana@dev:~/planner$ cp /tmp/CourseCard.tsx src/CourseCard.tsx
```

**Three cards, each with a stray `0` under its name.** For a screen reader it is worse than a
blemish: the card is announced as "Statistics, button, 0". The fix is to give `&&` a boolean, so the
false case is `false` and draws nothing; the `sed` turned `count &&` into `count > 0 &&`, and the second
`look` shows the cards with no line at all.

The rule that prevents it: **the left side of `&&` in JSX is always a boolean.** `count > 0`,
`items.length > 0`, `Boolean(value)`, or a ternary with `null` on the other side. Strings have a
milder version of the same problem, because `''` is falsy and React draws it as an empty text node,
which at least shows nothing.

This version of `CourseCard` was a demonstration, not a change: the planner's first screen shows
"0 sessions · 0 min" for an empty week, in all four courses of the fork, and the `cp` put that version
back.
