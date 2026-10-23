---
title: Jotai: state in small pieces
version: 1
---

**Jotai builds shared state from atoms, each a single value with its own subscribers.** Where Zustand
and Redux keep one store and select slices out of it, Jotai starts from the slices: a component that
reads one atom renders when that atom changes and at no other time. It is `useState` made shareable,
and it fits apps whose shared state is many independent values.

```
ana@dev:~$ cp -a planner planner-jotai
ana@dev:~/planner-jotai$ npm install jotai@3.0.1

added 2 packages, and audited 32 packages in 646ms

10 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner-jotai$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 39ms on 16 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner-jotai$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep minutes
    - paragraph: 120 of 195 minutes done
```

`jotai` at 3.0.1. The atoms, `src/atoms.ts`:

```typescript
import { atom } from 'jotai'
import type { Course, Session } from './types'

export const statusAtom = atom<'loading' | 'ready' | 'failed'>('loading')
export const coursesAtom = atom<Course[]>([])
export const sessionsAtom = atom<Session[]>([])

export const toggleDoneAtom = atom(null, (_get, set, id: string) => {
  set(sessionsAtom, (all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
})
```

Three atoms hold values, each typed with the value it holds. **`toggleDoneAtom` holds nothing**: an
atom made with `null` and a write function is an action, and writing to it updates `sessionsAtom` with
lesson 4's `map`. Atoms are definitions; the values live in a store Jotai keeps, and by default one
store serves the whole app, so no provider is needed. The planner's still loads the data:

```tsx
import { useSetAtom } from 'jotai'
import { useEffect, type ReactNode } from 'react'
import { coursesAtom, sessionsAtom, statusAtom } from './atoms'
import type { Course, Session } from './types'

// Atoms live in Jotai's default store, so no provider is needed; this one
// only starts the first load.
export function PlannerProvider({ children }: { children: ReactNode }) {
  const setStatus = useSetAtom(statusAtom)
  const setCourses = useSetAtom(coursesAtom)
  const setSessions = useSetAtom(sessionsAtom)
  useEffect(() => {
    fetch('/courses.json')
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json()
      })
      .then((data: { courses: Course[]; sessions: Session[] }) => {
        setCourses(data.courses)
        setSessions(data.sessions)
        setStatus('ready')
      })
      .catch((error) => {
        console.error('could not load the planner:', error.message)
        setStatus('failed')
      })
  }, [setStatus, setCourses, setSessions])
  return children
}
```

```typescript
import { useAtomValue, useSetAtom } from 'jotai'
import { coursesAtom, sessionsAtom, statusAtom, toggleDoneAtom } from './atoms'

export function usePlannerContext() {
  return {
    status: useAtomValue(statusAtom),
    courses: useAtomValue(coursesAtom),
    sessions: useAtomValue(sessionsAtom),
    toggleDone: useSetAtom(toggleDoneAtom),
  }
}
```

`useAtomValue` reads an atom and subscribes to it; `useSetAtom` returns only the function that writes
one, and a component that only writes does not render when the atom changes. The load moved into the
provider as lesson 5's fetch, written against three setters. Same 120.
