---
title: The bug an index key makes
version: 1
---

**An index key ties state to a position, so when the items move, the state stays behind.** It is easy
to miss because the list itself always looks right: React draws each item's text from the data. Only
what the items do not get from the data, what was typed or ticked or focused, stays put.

A temporary `CourseScreen` makes it visible. Each session gets a field for a note, which keeps what you
type in the DOM, as an uncontrolled input does, and a button reverses the order. The key is the index:

```tsx
import { useEffect, useRef, useState } from 'react'
import type { Course, Session } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  sessions: Session[]
  onToggle: (id: string) => void
  onBack: () => void
}

// For lesson 8 only: a note beside each session, and a button that reverses
// the order. The key is the session's position, which is the mistake.
export function CourseScreen({ course, sessions, onToggle, onBack }: CourseScreenProps) {
  const heading = useRef<HTMLHeadingElement>(null)
  useEffect(() => {
    heading.current?.focus()
  }, [])
  const [newestFirst, setNewestFirst] = useState(false)

  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  if (newestFirst) sorted.reverse()
  return (
    <>
      <button type="button" onClick={onBack}>
        Back to courses
      </button>
      <h1 ref={heading} tabIndex={-1}>
        {course.name}
      </h1>
      <button type="button" onClick={() => setNewestFirst(!newestFirst)}>
        Reverse the order
      </button>
      <ul>
        {sorted.map((s, index) => (
          <li key={index}>
            <label>
              <input type="checkbox" checked={s.done} onChange={() => onToggle(s.id)} />
              {formatDay(s.date)} · {s.minutes} min
            </label>
            <input aria-label={`Note for ${formatDay(s.date)}`} />
          </li>
        ))}
      </ul>
    </>
  )
}
```

Type a note against the session of Monday the 19th, then reverse:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Note for Mon 19 Oct=read chapter 3' | sed -n '/list:/,$p'
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
      - textbox "Note for Mon 19 Oct": read chapter 3
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
      - textbox "Note for Wed 21 Oct"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Note for Mon 19 Oct=read chapter 3' --do 'click button Reverse the order' | sed -n '/list:/,$p'
  - list:
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
      - textbox "Note for Wed 21 Oct": read chapter 3
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
      - textbox "Note for Mon 19 Oct"
```

**After reversing, the note says "read chapter 3" beside Wednesday the 21st.** The sessions moved; the
note did not. React compared the two renders by key: key `0` was there before and is there now, so the
first `<li>` was kept, with its input and the text in it, and only the parts drawn from the data, the
date, the minutes and the checkbox's state, were updated to the session now first in the array. The
field's label changed too, so a screen reader would announce "Note for Wed 21 Oct, read chapter 3", a
note that nobody wrote for that session.

With the session's id as the key:

```
ana@dev:~/planner$ sed -i 's|<li key={index}>|<li key={s.id}>|; s|sorted.map((s, index) =>|sorted.map((s) =>|' src/CourseScreen.tsx
ana@dev:~/planner$ grep -n "<li key" src/CourseScreen.tsx
36:          <li key={s.id}>
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Note for Mon 19 Oct=read chapter 3' --do 'click button Reverse the order' | sed -n '/list:/,$p'
  - list:
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
      - textbox "Note for Wed 21 Oct"
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
      - textbox "Note for Mon 19 Oct": read chapter 3
ana@dev:~/planner$ cp /tmp/CourseScreen.tsx src/CourseScreen.tsx
```

The note moved with Monday's session to the second row, because key `s1` identified the same `<li>`
before and after. **Nothing else changed in the code.** The last command put the real `CourseScreen`
back.

The bug needs three things at once: an index key, items that change order or are inserted, and state
inside the items that is not drawn from the data. Lists that have all three are common: a list of
editable rows, a list of cards that can be expanded, a list with a focused item. The id key costs
nothing in the lists that do not, so it is the only habit worth having.
