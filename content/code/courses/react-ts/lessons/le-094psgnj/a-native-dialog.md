---
title: A native dialog, opened from React
version: 1
---

**The `<dialog>` element is the browser's own dialog**, and `showModal()` opens it as a modal one: on
top of everything, with the rest of the page made inert, so that nothing behind it can be clicked,
reached with Tab or read by a screen reader until it closes. React renders the element; a ref and an
effect call the method. All of it is `src/Dialog.tsx`:

```tsx
import { useEffect, useId, useRef, type ReactNode } from 'react'

type DialogProps = {
  open: boolean
  title: string
  onClose: () => void
  children: ReactNode
}

export function Dialog({ open, title, onClose, children }: DialogProps) {
  const ref = useRef<HTMLDialogElement>(null)
  const titleId = useId()

  useEffect(() => {
    const dialog = ref.current
    if (!dialog) return
    if (open && !dialog.open) dialog.showModal()
    if (!open && dialog.open) dialog.close()
  }, [open])

  return (
    <dialog ref={ref} aria-labelledby={titleId} onClose={onClose}>
      <h2 id={titleId}>{title}</h2>
      {children}
      <button type="button" onClick={onClose}>
        Close
      </button>
    </dialog>
  )
}
```

- **`open` is a prop, and the effect makes the element agree with it.** When the prop says open and
  the dialog is not, it calls `showModal()`; when the prop says closed and the dialog is open, it
  calls `close()`. Checking `dialog.open` first means strict mode's second run of the effect finds the
  dialog already open and leaves it alone.
- **`onClose` is the dialog's own `close` event.** The browser fires it however the dialog closed:
  the Close button, the effect's `close()`, or the **Escape key**, which closes a modal dialog
  without any code of yours. The parent hears about every one, and its state never says open while
  the dialog is shut.
- **`aria-labelledby` names the dialog** after its heading, with an id from `useId`, as lesson 10 did
  for the form's errors.

In `src/CourseScreen.tsx`, the form moves into a dialog, opened by a button:

```tsx
import { useEffect, useRef, useState } from 'react'
import { AddSessionForm } from './AddSessionForm'
import { Dialog } from './Dialog'
import { usePlannerContext } from './plannerContext'
import type { Course } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  onBack: () => void
}

export function CourseScreen({ course, onBack }: CourseScreenProps) {
  const { sessions, toggleDone } = usePlannerContext()
  const [planning, setPlanning] = useState(false)
  const heading = useRef<HTMLHeadingElement>(null)
  useEffect(() => {
    heading.current?.focus()
  }, [])

  const sorted = sessions
    .filter((s) => s.course === course.id)
    .sort((a, b) => a.date.localeCompare(b.date))
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
                <input type="checkbox" checked={s.done} onChange={() => toggleDone(s.id)} />
                {formatDay(s.date)} · {s.minutes} min
              </label>
            </li>
          ))}
        </ul>
      )}
      <button type="button" onClick={() => setPlanning(true)}>
        Plan a session
      </button>
      <Dialog open={planning} title="Plan a session" onClose={() => setPlanning(false)}>
        <AddSessionForm course={course.id} onAdded={() => setPlanning(false)} />
      </Dialog>
    </>
  )
}
```

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 77ms on 22 files with 116 rules using 4 threads.
no errors
```

The course screen first, with the dialog closed:

```
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
  - button "Plan a session"
```

**No form, and no dialog in the snapshot.** A closed `<dialog>` is in the page but not shown, and not
announced either. Press *Plan a session*:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click button Plan a session'
-- click button Statistics
-- click button Plan a session
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
  - button "Plan a session"
  - dialog "Plan a session":
    - heading "Plan a session" [level=2]
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
    - button "Close"
```

`dialog "Plan a session"`, named by its heading, with the form and a Close button inside. `look` still
lists the page behind it, because it reads every element in the page; in a browser, that part is now
inert. Escape, then:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click button Plan a session' --do 'press Escape' | grep -E 'dialog|button'
-- click button Statistics
-- click button Plan a session
  - button "Back to courses"
  - button "Plan a session"
```

The dialog has gone from the snapshot, and the state agrees: Escape fired `close`, and `onClose` set
`planning` back to `false`.

```schooling-figure
{"svg": "<svg data-fig=\"dialog-sync\" viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Two directions between React and the dialog. From React: the planning state becomes true, the effect runs and calls showModal on the element in the ref. From the browser: Escape or the Close button closes the dialog, the close event fires, onClose sets planning to false, and the effect finds the dialog already closed.\"><rect x=\"20\" y=\"70\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"92.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">planning</text><text x=\"110.0\" y=\"107.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">true / false</text><rect x=\"520\" y=\"70\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"92.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">&lt;dialog&gt;</text><text x=\"610.0\" y=\"107.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">ref.current</text><line x1=\"202\" y1=\"86\" x2=\"518\" y2=\"86\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"518.0,86.0 510.5,89.2 510.5,82.8\" fill=\"var(--phosphor)\"></polygon><text x=\"360\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">useEffect → showModal() / close()</text><line x1=\"518\" y1=\"116\" x2=\"202\" y2=\"116\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"202.0,116.0 209.5,112.8 209.5,119.2\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">close event → onClose()</text><text x=\"610\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Escape, Close button</text><text x=\"110\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">React's state</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the browser owns how a modal dialog behaves</text></svg>", "caption": "The prop asks for open or closed; the close event reports what the browser did."}
```

**What the browser did that this code never mentions:**

- When the dialog opened, **the focus went into it**, to the first field, Date.
- When it closed, by Escape or by the Close button, **the focus went back to *Plan a session***, the
  button that had it before.
- While it was open, **nothing behind it could be clicked**.

Those three were checked in a browser while this lesson was written, and they are what a keyboard or
screen reader user needs from a dialog. Each one is code a hand-made dialog of `<div>`s would have to
carry, and test, itself.
