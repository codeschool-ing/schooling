---
title: Portals, for what has to live elsewhere
version: 1
---

**`createPortal` renders children into a DOM node of your choice**, outside the element their
component would normally draw into, while they stay where they are in the React tree. The planner has
a use for one: after the dialog closes, nothing on the screen says the session was saved. A short
message should say so, in a corner of the window, and be announced to a screen reader.

`src/StatusMessage.tsx` is the whole component:

```tsx
import { createPortal } from 'react-dom'

export function StatusMessage({ message }: { message: string }) {
  return createPortal(
    <div role="status" className="status-message">
      {message}
    </div>,
    document.body,
  )
}
```

and a few lines of style at the end of `src/index.css` put it in the corner:

```css

.status-message:not(:empty) {
  position: fixed;
  bottom: 1rem;
  left: 1rem;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  background: Canvas;
  border: 1px solid #8888;
}
```

The course screen keeps the message in state, sets it when the form reports a session, and
**renders `StatusMessage` always**, with an empty message until there is something to say:

```tsx
import { useEffect, useRef, useState } from 'react'
import { AddSessionForm } from './AddSessionForm'
import { Dialog } from './Dialog'
import { usePlannerContext } from './plannerContext'
import { StatusMessage } from './StatusMessage'
import type { Course } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  onBack: () => void
}

export function CourseScreen({ course, onBack }: CourseScreenProps) {
  const { sessions, toggleDone } = usePlannerContext()
  const [planning, setPlanning] = useState(false)
  const [message, setMessage] = useState('')
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
        <AddSessionForm
          course={course.id}
          onAdded={(s) => {
            setPlanning(false)
            setMessage(`Planned ${formatDay(s.date)} · ${s.minutes} min.`)
          }}
        />
      </Dialog>
      <StatusMessage message={message} />
    </>
  )
}
```

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 79ms on 23 files with 116 rules using 4 threads.
no errors
```

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click button Plan a session' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' --html 'body > [role=status]' | sed -n '/^-- click button Add/,$p'
-- click button Add session
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
    - listitem:
      - checkbox "Sat 24 Oct · 45 min"
      - text: Sat 24 Oct · 45 min
  - button "Plan a session"
- status: Planned Sat 24 Oct · 45 min.
<div role="status" class="status-message">Planned Sat 24 Oct · 45 min.</div>
```

The snapshot has a `status` after `main`, not inside it, and the HTML printed after it is the element
itself: `body > [role=status]` matched, so it is a child of `<body>`. Where it lives, with the page
just opened and nothing planned yet:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --html 'body' | grep -o '<div role="status"[^>]*>'
<div role="status" class="status-message">
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --html '#root' | grep -c 'role="status"'
0
```

Found under `<body>`, and not once under `#root`, although `CourseScreen`, which renders it, is
inside `#root`.

```schooling-figure
{"svg": "<svg data-fig=\"portal\" viewBox=\"0 0 720 245\" role=\"img\" aria-label=\"Two trees side by side. In the React tree, StatusMessage is a child of CourseScreen, inside App, so it reads the same contexts and its events bubble to CourseScreen. In the DOM tree, body holds the root div, which holds the page, and the status div is a separate child of body, next to the root.\"><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">the React tree</text><rect x=\"90\" y=\"36\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><rect x=\"90\" y=\"96\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseScreen</text><rect x=\"90\" y=\"156\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">StatusMessage</text><line x1=\"170\" y1=\"66\" x2=\"170\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"170\" y1=\"126\" x2=\"170\" y2=\"156\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"170\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">contexts, events: through its React parents</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">the DOM</text><rect x=\"460\" y=\"36\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;body&gt;</text><rect x=\"380\" y=\"96\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;div id=root&gt;</text><rect x=\"380\" y=\"156\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;main&gt; …</text><rect x=\"560\" y=\"96\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&lt;div role=status&gt;</text><line x1=\"540\" y1=\"66\" x2=\"455\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"540\" y1=\"66\" x2=\"635\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"455\" y1=\"126\" x2=\"455\" y2=\"156\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><path d=\"M 252 171 C 420 230 650 215 635 128\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><polygon points=\"635.0,128.0 638.9,135.1 632.6,135.8\" fill=\"var(--amber)\"></polygon><text x=\"560\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">position: fixed from &lt;body&gt;, whatever the CSS above</text></svg>", "caption": "A portal moves the element in the DOM and leaves it in place in React."}
```

**Why a portal, here.** The message is placed with `position: fixed`, relative to the window. That
works from anywhere, until some ancestor gets a `transform`, a `filter` or a `contain` property: then
`fixed` is relative to that ancestor instead, and the message moves with it, or is cut off at its
edges. Nothing above the course screen has one today; a card animation next year might. A child of
`<body>` has no such ancestors, and **the portal makes the message independent of whatever the rest of
the page's CSS becomes**.

**Why the region is always rendered.** A screen reader announces changes to a `role="status"` region
it already knows about; a region that appears with its text already inside may not be announced at
all. So the empty `div` is there from the start, and only its text changes. `:not(:empty)` in the CSS
keeps it invisible while there is nothing in it.

**What a portal does not change** is the React tree. `StatusMessage` is still a child of
`CourseScreen`: it reads the same contexts, and **an event inside a portal bubbles to its React
parents**, not to its DOM ones. A click handler on an element around `<StatusMessage />` would hear a
click on the message, although in the DOM the two are nowhere near each other.

**When a portal is not needed.** The dialog in this lesson has none, because `showModal()` puts the
dialog in the browser's **top layer**, above every stacking context, whatever its ancestors' CSS. The
`popover` attribute does the same for menus and tooltips. Portals remain the tool for what neither
covers: messages like this one, and libraries written before the top layer existed.
