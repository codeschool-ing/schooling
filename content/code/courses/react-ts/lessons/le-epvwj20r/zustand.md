---
title: Zustand: a store and a hook
version: 1
---

**Zustand is a store outside React, created with one function, and read with a hook that takes a
selector.** It is the smallest of the three libraries here, and the one this course would choose for
the planner if it needed one. To compare them fairly, each library gets its own copy of the planner,
made from the project as it is now, and replaces the same two files. Zustand first:

```
ana@dev:~$ cp -a planner planner-zustand
ana@dev:~/planner-zustand$ npm install zustand@5.0.16

added 2 packages, and audited 32 packages in 739ms

10 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner-zustand$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 65ms on 16 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner-zustand$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep minutes
    - paragraph: 120 of 195 minutes done
```

The copy installed `zustand` at 5.0.16, pinned by the project's `.npmrc`, and the planner was
unchanged except for three files. The store, `src/store.ts`:

```typescript
import { create } from 'zustand'
import type { Course, Session } from './types'

type PlannerStore = {
  status: 'loading' | 'ready' | 'failed'
  courses: Course[]
  sessions: Session[]
  load: () => Promise<void>
  toggleDone: (id: string) => void
}

export const usePlannerStore = create<PlannerStore>()((set) => ({
  status: 'loading',
  courses: [],
  sessions: [],
  load: async () => {
    try {
      const response = await fetch('/courses.json')
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const data: { courses: Course[]; sessions: Session[] } = await response.json()
      set({ status: 'ready', courses: data.courses, sessions: data.sessions })
    } catch (error) {
      console.error('could not load the planner:', (error as Error).message)
      set({ status: 'failed' })
    }
  },
  toggleDone: (id) =>
    set((state) => ({
      sessions: state.sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s)),
    })),
}))
```

`create` takes a function that receives `set` and returns the initial state, with the actions that
change it beside the data. **`set` merges what you give it into the state**, so `toggleDone` returns
only `sessions`, built with lesson 4's `map`: Zustand compares with `Object.is` too, so the rule about
replacing rather than mutating is the same. `load` is an ordinary async function that calls `set`
when the data arrives.

The store needs no provider, because it is a module-level object; `src/PlannerProvider.tsx` keeps
its name only to start the first load:

```tsx
import { useEffect, type ReactNode } from 'react'
import { usePlannerStore } from './store'

// The store needs no provider; this one only starts the first load.
export function PlannerProvider({ children }: { children: ReactNode }) {
  useEffect(() => {
    usePlannerStore.getState().load()
  }, [])
  return children
}
```

And `src/plannerContext.ts` reads the store with a selector:

```typescript
import { useShallow } from 'zustand/shallow'
import { usePlannerStore } from './store'

export function usePlannerContext() {
  return usePlannerStore(
    useShallow((state) => ({
      status: state.status,
      courses: state.courses,
      sessions: state.sessions,
      toggleDone: state.toggleDone,
    })),
  )
}
```

**The selector is the point.** `usePlannerStore((state) => state.status)` would re-render its
component only when `status` changed. This hook returns four values at once, so it builds a new object
on every call, and `useShallow` compares that object field by field instead of by identity; without
it, every store change would look like a change to this component. `App` and `CourseScreen` did not
change at all, and ticking a session gives the same 120.
