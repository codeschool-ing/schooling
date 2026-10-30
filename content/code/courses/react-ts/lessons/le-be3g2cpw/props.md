---
title: Props flow down, and they are read-only
version: 1
---

**Props are the arguments of a component**: the parent writes them as attributes, and the child
receives them as one object. Data in React moves in one direction, from a parent to its children,
and the screen is drawn from the top of the tree down. These two files are the middle of the
planner's tree.

`src/CourseList.tsx` receives every course and the week's sessions, and draws one card per course:

```tsx
import { CourseCard } from './CourseCard'
import type { Course, Session } from './types'

type CourseListProps = {
  courses: Course[]
  sessions: Session[]
}

export function CourseList({ courses, sessions }: CourseListProps) {
  return (
    <section aria-label="Courses">
      {courses.map((course) => (
        <CourseCard
          key={course.id}
          course={course}
          sessions={sessions.filter((s) => s.course === course.id)}
        />
      ))}
    </section>
  )
}
```

`courses.map` turns each course into a `<CourseCard>` element, and the array of elements it returns
is a valid child: React draws them in order. `key={course.id}` tells React which card is which
course, so that it can tell them apart when the list changes; it is not a prop the card can read,
and lesson 8 is about why it has to be an id. Each card receives only its own course's sessions,
filtered here.

`src/CourseCard.tsx` turns one course and its sessions into a line of text:

```tsx
import { Card } from './Card'
import type { Course, Session } from './types'
import { minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
}

export function CourseCard({ course, sessions }: CourseCardProps) {
  const count = sessions.length
  return (
    <Card title={course.name}>
      <p>
        {count} {count === 1 ? 'session' : 'sessions'} · {minutes(sessions)} min
      </p>
    </Card>
  )
}
```

## Destructuring, and what the type says

`function CourseCard({ course, sessions }: CourseCardProps)` takes the props object apart in the
parameter list, as `javascript` lesson 4 taught for any object. The type after the colon is what
makes it safe. **`CourseCardProps` is the component's contract**: a parent that leaves out
`sessions`, or passes a number as `course`, is told so by the compiler, and the section after next
shows that happening. The parameter could equally be written `(props: CourseCardProps)` and read as
`props.course`; destructuring is the habit of most React code, and this course follows it.

## Read-only, by agreement

A component must not change its props. Nothing in the language stops it, and this is what happens
when one does. One line added to `CourseCard`:

```
ana@dev:~/planner$ sed -i 's/^  const count = sessions.length$/  course.name = course.name.toUpperCase()\n  const count = sessions.length/' src/CourseCard.tsx
ana@dev:~/planner$ sed -n 10,13p src/CourseCard.tsx
export function CourseCard({ course, sessions }: CourseCardProps) {
  course.name = course.name.toUpperCase()
  const count = sessions.length
  return (
ana@dev:~/planner$ look http://localhost:5173/
- main:
  - heading "Study planner" [level=1]
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
    - article:
      - heading "STATISTICS" [level=2]
      - paragraph: 2 sessions · 90 min
    - article:
      - heading "SPANISH" [level=2]
      - paragraph: 2 sessions · 60 min
    - article:
      - heading "ORGANIC CHEMISTRY" [level=2]
      - paragraph: 1 session · 45 min
ana@dev:~/planner$ npx tsc -b
ana@dev:~/planner$ sed -i '/toUpperCase/d' src/CourseCard.tsx
```

Every course name on the screen is now in capitals, and the compiler raised no objection, because
`course` is an ordinary object and its type says nothing about who may change it. **The objects
were not copies.** `course` is the very object in `sample.ts`'s array, so the card did not change
what it shows; it changed the data, for every component that reads it, from then on. A second
render would have capitalised what was already capitalised, and a component that adds to a list
each time it renders would grow it on every render.

So the rule is the one React states plainly: **a component, given the same props, returns the same
JSX and changes nothing outside itself.** It is a pure function of its inputs. Lesson 3 shows that
React may call a component more often than you expect, and lesson 4 shows how a component changes
what it shows without changing what it was given. The line came out again with the `sed` at the end
of the transcript.
