---
title: An empty list is a screen too
version: 1
---

**A list with nothing in it should say so.** An empty `<ul>` draws nothing, and a screen that draws
nothing cannot be told apart from a screen that failed, or one that has not loaded yet; lesson 5 made
the same point about waiting. The planner's course screen is the one place a list can be empty and
nothing else on the screen explains it: a course with no sessions planned. This is
`src/CourseScreen.tsx` with that case:

```tsx
import { useEffect, useRef } from 'react'
import type { Course, Session } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  sessions: Session[]
  onToggle: (id: string) => void
  onBack: () => void
}

export function CourseScreen({ course, sessions, onToggle, onBack }: CourseScreenProps) {
  const heading = useRef<HTMLHeadingElement>(null)
  useEffect(() => {
    heading.current?.focus()
  }, [])

  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  return (
    <>
      <button type="button" onClick={onBack}>
        Back to courses
      </button>
      <h1 ref={heading} tabIndex={-1}>
        {course.name}
      </h1>
      {sorted.length === 0 ? (
        <p>No sessions planned for this course yet.</p>
      ) : (
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
      )}
    </>
  )
}
```

A ternary chooses between the sentence and the list, and the sentence says what is empty and, by
naming "yet", that this is a state the user can change; lesson 10 adds the form that changes it. Every
course in `courses.json` has sessions, so to see it, one more course goes into the file for a moment,
with a line of Node that reads the JSON, adds Latin and writes it back:

```
ana@dev:~/planner$ node -e "const f='public/courses.json', d=JSON.parse(require('fs').readFileSync(f)); d.courses.push({id:'latin', name:'Latin'}); require('fs').writeFileSync(f, JSON.stringify(d, null, 2))"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Latin'
-- click button Latin
- main:
  - button "Back to courses"
  - heading "Latin" [level=1]
  - paragraph: No sessions planned for this course yet.
ana@dev:~/planner$ cp /tmp/courses.json public/courses.json
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 65ms on 13 files with 116 rules using 4 threads.
no errors
```

The empty course opens on the sentence, under the heading that has the focus. The `cp` put the data
back, and the linter and the type check are clean.

What an empty state should say depends on why the list is empty, and a good one answers the question
the user would ask next:

| why it is empty | what the screen says |
|---|---|
| nothing was ever added | that it is empty, and how to add the first one |
| a filter or a search excluded everything | that nothing matches, and how to clear the filter |
| it is still loading | that it is loading: a different screen, as in lesson 5 |
| it failed to load | that it failed, and what to do: lesson 12 |

The planner has the first and the last two. It has no filters, so the second does not arise here.
