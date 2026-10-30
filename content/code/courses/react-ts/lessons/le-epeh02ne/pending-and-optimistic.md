---
title: While the server works
version: 1
---

**A Server Function takes as long as the server takes, and until now the screen said nothing while it
did.** Restart the API with `DELAY=2000`, so that every request waits two seconds, and press
Wednesday's session again:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'click button Wed 21 Oct · Statistics · 40 min' | grep -E 'minutes done|Statistics'
-- click button Wed 21 Oct · Statistics · 40 min
    - paragraph: 80 of 195 minutes done
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
        - button "Wed 21 Oct · Statistics · 40 min"
    - option "Statistics" [selected]
```

This is the page about a third of a second after the click: **nothing has changed**. The `PATCH` waits
two seconds and the `GET` from `refresh()` waits two more, so for four seconds the button does nothing
visible, and a user presses it again. React has two hooks for that wait.

**`useTransition`** returns a flag, `isPending`, and a function, `startTransition`. An `async` function
passed to `startTransition` is an **Action**: React marks everything it starts as one piece of work, and
the flag stays true until it has finished, the server's answer included.

**`useOptimistic`** shows a value as though the change had already worked. It takes the real value, the
prop that comes from the server, and returns a copy you may set during an Action. When the Action
finishes, the copy is dropped and the real value shows again, whatever it is by then.

Both go into a Client Component for one session, `app/SessionToggle.tsx`:

```tsx
'use client'

import { useOptimistic, useTransition } from 'react'
import { setDone } from './actions'

type SessionToggleProps = {
  id: string
  done: boolean
  label: string
}

export function SessionToggle({ id, done, label }: SessionToggleProps) {
  const [shownDone, setShownDone] = useOptimistic(done)
  const [saving, startTransition] = useTransition()

  function toggle() {
    startTransition(async () => {
      setShownDone(!shownDone)
      await setDone(id, !shownDone)
    })
  }

  return (
    <button type="button" aria-pressed={shownDone} onClick={toggle}>
      {label}
      {saving && ' · saving…'}
    </button>
  )
}
```

On a click, inside the Action, it sets the optimistic value first, which shows at once, and then waits
for the server. `saving` adds *· saving…* to the button's name for as long as that takes. The list hands
each session to it instead of drawing a form:

```tsx
import type { Course, Session } from '@/lib/types'
import { formatDay } from '@/lib/week'
import { SessionToggle } from './SessionToggle'

type SessionListProps = {
  sessions: Session[]
  courses: Course[]
}

export function SessionList({ sessions, courses }: SessionListProps) {
  const name = (id: string) => courses.find((c) => c.id === id)?.name ?? id
  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  return (
    <section aria-labelledby="sessions-heading">
      <h2 id="sessions-heading">Sessions this week</h2>
      <ul>
        {sorted.map((s) => (
          <li key={s.id}>
            <SessionToggle
              id={s.id}
              done={s.done}
              label={`${formatDay(s.date)} · ${name(s.course)} · ${s.minutes} min`}
            />
          </li>
        ))}
      </ul>
    </section>
  )
}
```

```
ana@dev:~/planner-next$ npx tsc --noEmit && echo no errors
no errors
```

The same moment as before, a third of a second after the click:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'click button Wed 21 Oct · Statistics · 40 min' | grep -E 'minutes done|Statistics'
-- click button Wed 21 Oct · Statistics · 40 min
    - paragraph: 80 of 195 minutes done
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
        - button "Wed 21 Oct · Statistics · 40 min · saving…" [pressed]
    - option "Statistics" [selected]
```

**Pressed, and saying it is saving**, although the server has not answered: the summary still says 80,
because it is drawn from the server's data and that has not changed yet. Six seconds later:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 6000' | grep -E 'minutes done|Statistics'
-- click button Wed 21 Oct · Statistics · 40 min
    - paragraph: 120 of 195 minutes done
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
        - button "Wed 21 Oct · Statistics · 40 min" [pressed]
    - option "Statistics" [selected]
```

The server's answer has arrived, with 120 minutes and Wednesday pressed. The optimistic copy was
dropped and the real value is the same, so nothing on the button moved: it was right from the start.

```schooling-figure
{"svg": "<svg data-fig=\"optimistic\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two timelines of the button's pressed state. Success: at the click the shown value becomes pressed, while the server value is still not pressed; after four seconds the server says pressed and the shown value follows it, unchanged. Failure: the shown value becomes pressed at the click; when the Action ends with nothing saved, the shown value returns to the server's, not pressed, and an alert says why.\"><text x=\"20\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">it worked</text><rect x=\"120\" y=\"40\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">not pressed</text><line x1=\"252\" y1=\"58\" x2=\"278\" y2=\"58\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"278.0,58.0 270.5,61.2 270.5,54.8\" fill=\"var(--wire)\"></polygon><rect x=\"280\" y=\"40\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"385.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pressed · saving…</text><line x1=\"492\" y1=\"58\" x2=\"518\" y2=\"58\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"518.0,58.0 510.5,61.2 510.5,54.8\" fill=\"var(--wire)\"></polygon><rect x=\"520\" y=\"40\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">server: pressed</text><text x=\"385\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the optimistic copy, during the Action</text><text x=\"20\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">it failed</text><rect x=\"120\" y=\"135\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">not pressed</text><line x1=\"252\" y1=\"153\" x2=\"278\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"278.0,153.0 270.5,156.2 270.5,149.8\" fill=\"var(--wire)\"></polygon><rect x=\"280\" y=\"135\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"385.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pressed · saving…</text><line x1=\"492\" y1=\"153\" x2=\"518\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"518.0,153.0 510.5,156.2 510.5,149.8\" fill=\"var(--wire)\"></polygon><rect x=\"520\" y=\"135\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">server: not pressed + alert</text><text x=\"385\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the optimistic copy, during the Action</text><text x=\"185\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">click</text></svg>", "caption": "During the Action the copy shows; after it, the server's value does."}
```

**What an optimistic update promises**: that the change will very probably work, so showing it early is
honest. A toggle on your own planner is a good case. A payment is not: showing *paid* before the bank has
answered tells the user something that may be false, and they may close the page on it.
