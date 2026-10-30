---
title: A ref to a DOM element, and where focus goes
version: 1
---

**A ref is also how a component reaches the DOM element it rendered.** Give an element a `ref`
attribute, and after the commit React puts the element into the ref's `current`. The planner needs
this for a reason that has nothing to do with React and everything to do with the person using it.

When "Statistics" is pressed, the course list goes and the course screen arrives. The button that had
the keyboard's focus no longer exists. Where does focus go? Pressing Tab answers:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'press Tab' --quiet --html ':focus'
-- click button Statistics
-- press Tab
<button type="button">Back to courses</button>
```

Focus fell back to the start of the page, so Tab landed on "Back to courses", the first thing there.
For a mouse user that is invisible. **For a keyboard or screen-reader user it is a page that changed
without saying so**: nothing was announced, and their place is wherever the browser left it. WCAG
asks that focus moves in an order that preserves meaning, and the established answer for a screen
change in an app like this is to move focus to the new screen's heading.

This is `src/CourseScreen.tsx` doing that:

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

- **`useRef<HTMLHeadingElement>(null)`** makes a ref that will hold the `<h1>`; the type says what
  kind of element, and `null` is its value until the commit.
- **`ref={heading}`** on the `<h1>` is where React puts the element.
- **`tabIndex={-1}`** makes a heading focusable from code without adding it to the Tab order: a
  heading is not something a user should land on by pressing Tab.
- **The effect** focuses it after the commit, once, when the screen first appears. `?.` covers the
  case where the element is not there, which in this component never happens and costs nothing to
  allow for.

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --quiet --html ':focus'
-- click button Statistics
<h1 tabindex="-1">Statistics</h1>
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'press Tab' --quiet --html ':focus'
-- click button Statistics
-- press Tab
<input type="checkbox" checked="">
```

Focus is now on the heading, so a screen reader announces "Statistics, heading level 1" as the
screen arrives, and Tab continues from there into the first checkbox. Lesson 14 returns to refs for
the cases this one does not cover: a ref to another component, and focus inside a dialog.
