---
title: memo, and what makes it work
version: 1
---

**`memo` wraps a component so that React skips it when its props have not changed.** Before rendering
a memoised component, React compares each new prop with the old one, with `Object.is`; if every one is
the same, it reuses the last result and does not call the component at all. Wrap `SessionRow`, with a
`sed` that changes its first and last lines:

```
ana@dev:~/planner$ sed -i 's/^export function SessionRow(/export const SessionRow = memo(function SessionRow(/; s/^import { Profiler } from .react./import { memo, Profiler } from '\''react'\''/' src/SessionRow.tsx && sed -i '$s/^}$/})/' src/SessionRow.tsx && cat src/SessionRow.tsx
import { memo, Profiler } from 'react'
import { logRender } from './logRender'
import type { Session } from './types'
import { formatDay } from './week'

type SessionRowProps = {
  session: Session
  onToggle: (id: string) => void
}

export const SessionRow = memo(function SessionRow({ session, onToggle }: SessionRowProps) {
  return (
    <Profiler id={`row ${session.id}`} onRender={logRender}>
      <label>
        <input type="checkbox" checked={session.done} onChange={() => onToggle(session.id)} />
        {formatDay(session.date)} · {session.minutes} min
      </label>
    </Profiler>
  )
})
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 99ms on 31 files with 116 rules using 4 threads.
no errors
```

Open the dialog again:

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click button Plan a session'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click button Plan a session
```

**Nothing drawn after the click.** `CourseScreen` and `List` still re-rendered, but each row received
the same `session` object and the same `onToggle` function, so React skipped both. Tick Wednesday:

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click checkbox Wed 21 Oct · 40 min'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click checkbox Wed 21 Oct · 40 min
drawn: row s2 (update)
```

**One row drawn, once: the one whose session changed.** Monday's row was skipped through both of the
planner's changes. That is the promise lesson 4 made, when it said that replacing one object and
keeping the rest would let lesson 21's `memo` skip what did not change.

Two things kept the props the same, and neither is an accident:

- **The session objects.** After the `PATCH`, React Query fetched the whole planner again, and JSON
  from a server is always new objects. React Query compares the new answer with the cached one and
  **keeps the old object wherever nothing in it changed**, which it calls structural sharing. Monday's
  session is the same object as before the refetch; Wednesday's is new.
- **`toggleDone`.** It is React Query's `mutate`, which is the same function on every render, as
  lesson 11 noted.

```schooling-figure
{"svg": "<svg data-fig=\"skip\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Ticking Wednesday's session with SessionRow memoised. CourseScreen and List render again. Row s1 receives the same session object and the same onToggle, so React compares, finds nothing changed, and skips it. Row s2 receives a new session object, done true, so it is drawn.\"><rect x=\"270\" y=\"14\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseScreen</text><rect x=\"270\" y=\"64\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">List</text><line x1=\"360\" y1=\"44\" x2=\"360\" y2=\"64\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"90\" y=\"130\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"205.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SessionRow · s1</text><text x=\"205.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">same session, same onToggle</text><rect x=\"400\" y=\"130\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"515.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SessionRow · s2</text><text x=\"515.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a new session: done true</text><line x1=\"360\" y1=\"94\" x2=\"205\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"360\" y1=\"94\" x2=\"515\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"205\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">skipped</text><text x=\"515\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">drawn</text></svg>", "caption": "memo compares each prop; the same object is a skipped render."}
```
