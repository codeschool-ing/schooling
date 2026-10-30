---
title: One card takes the whole page with it
version: 1
---

**An error thrown while React renders a component, with nothing to catch it, removes the whole page.**
Not the component that failed, and not its parent: everything React drew under the root. That is a
deliberate choice, and to see why, start with a small feature written carelessly.

Each course card is going to say when its next session is: the first one this week that is not done
yet. `src/CourseCard.tsx`, with the new line:

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
  const next = sessions.find((s) => !s.done)!
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
      <p>Next: {formatDay(next.date)}</p>
    </Card>
  )
}
```

`find` returns the session it found, or `undefined` when none matches, so TypeScript types `next` as
`Session | undefined` and would refuse `next.date`. **The `!` after the call tells the compiler that
the value is never `undefined`**, and the compiler believes it. Both checks pass:

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 85ms on 18 files with 116 rules using 4 threads.
no errors
```

The page looks right, too, in the week the seed data starts on, where every course has a session
left to do:

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
      - heading "Statistics" [level=2]:
        - button "Statistics"
      - paragraph: 2 sessions · 90 min
      - paragraph: "Next: Wed 21 Oct"
    - article:
      - heading "Spanish" [level=2]:
        - button "Spanish"
      - paragraph: 2 sessions · 60 min
      - paragraph: "Next: Fri 23 Oct"
    - article:
      - heading "Organic chemistry" [level=2]:
        - button "Organic chemistry"
      - paragraph: 1 session · 45 min
      - paragraph: "Next: Thu 22 Oct"
```

Now do what a student of this planner does sooner or later: finish the last statistics session of
the week. Open the course, tick Wednesday's session, and go back:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' --html '#root'
-- click button Statistics
-- click checkbox Wed 21 Oct · 40 min
-- click button Back to courses
Uncaught TypeError: Cannot read properties of undefined (reading 'date')
[warn] %s

%s
 An error occurred in the <CourseCard> component. Consider adding an error boundary to your tree to customize error handling behavior.
Visit https://react.dev/link/error-boundaries to learn more about error boundaries.

<div id="root"></div>
```

`--html '#root'` asked `look` for the element React draws into, and it is empty. **The snapshot is
missing because there is nothing on the page**: no heading, no week buttons, no Spanish card, which
had nothing wrong with it. In a browser it is a white page.

Three lines say what happened. `Uncaught TypeError` is the browser's: the statistics card read
`.date` from `undefined`, because `find` found no session left. The `[warn]` is React's, naming the
component the error came from, `<CourseCard>`, and suggesting the fix this lesson builds. The `%s`
markers come from how React writes to the console: it passes a template with `%s` in it and the
pieces separately. A browser's console puts each piece in its place; `look` prints the template, then
the pieces, and that is why the markers show.

**Why React removes everything**, and not just the broken card: after an error in the middle of a
render, React cannot know what state the rest of the tree is in. It could leave a half-drawn page with
numbers that do not add up, or a button that saves to the wrong course. The React team chose an empty
page over a page that may be lying, and leaves it to you to say which parts of the screen can fail on
their own. That is what an error boundary is.
