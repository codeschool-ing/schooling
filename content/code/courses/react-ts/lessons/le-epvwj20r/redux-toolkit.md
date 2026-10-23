---
title: Redux Toolkit: actions, reducers and a store
version: 1
---

**Redux keeps all the app's shared state in one store, and changes it only by dispatching actions
that pure functions, reducers, turn into the next state.** It is the oldest of the three and the one a
React job is most likely to have already, usually through Redux Toolkit, the official way to write it
now. It is also the one with the most to write:

```
ana@dev:~$ cp -a planner planner-redux
ana@dev:~/planner-redux$ npm install @reduxjs/toolkit@2.13.0 react-redux@9.3.0

added 11 packages, and audited 41 packages in 912ms

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner-redux$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 28ms on 16 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner-redux$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep minutes
    - paragraph: 120 of 195 minutes done
```

Two packages, `@reduxjs/toolkit` at 2.13.0 and `react-redux` at 9.3.0, and the store,
`src/store.ts`:

```typescript
import { configureStore, createAsyncThunk, createSlice, type PayloadAction } from '@reduxjs/toolkit'
import { useDispatch, useSelector } from 'react-redux'
import type { Course, Session } from './types'

type PlannerState = {
  status: 'loading' | 'ready' | 'failed'
  courses: Course[]
  sessions: Session[]
}

export const load = createAsyncThunk('planner/load', async () => {
  const response = await fetch('/courses.json')
  if (!response.ok) throw new Error(`HTTP ${response.status}`)
  return (await response.json()) as { courses: Course[]; sessions: Session[] }
})

const planner = createSlice({
  name: 'planner',
  initialState: { status: 'loading', courses: [], sessions: [] } as PlannerState,
  reducers: {
    toggleDone(state, action: PayloadAction<string>) {
      const session = state.sessions.find((s) => s.id === action.payload)
      if (session) session.done = !session.done
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(load.fulfilled, (state, action) => {
        state.status = 'ready'
        state.courses = action.payload.courses
        state.sessions = action.payload.sessions
      })
      .addCase(load.rejected, (state, action) => {
        console.error('could not load the planner:', action.error.message)
        state.status = 'failed'
      })
  },
})

export const { toggleDone } = planner.actions
export const store = configureStore({ reducer: { planner: planner.reducer } })

type RootState = ReturnType<typeof store.getState>
export const useAppDispatch = useDispatch.withTypes<typeof store.dispatch>()
export const useAppSelector = useSelector.withTypes<RootState>()
```

- **`createAsyncThunk`** wraps the fetch, and dispatching it produces actions for its start, success
  and failure, which the slice's `extraReducers` turn into state.
- **`createSlice`** holds the state's shape and its reducers, and generates an action creator for
  each: `toggleDone` here.
- **The reducer changes `session.done` in place**, which lesson 4 called a mistake. In Redux Toolkit it
  is not: the reducer receives a draft from Immer, a library that records the changes made to the draft
  and produces a new object with them applied. The state you get is still a new object, as lesson 4
  requires; the mutation is only the syntax. It works inside `createSlice` and nowhere else.
- **`withTypes`** makes typed versions of the two hooks, so every selector knows the shape of the state.

The provider here is real, Redux's `<Provider>`, and it dispatches the load:

```tsx
import { useEffect, type ReactNode } from 'react'
import { Provider } from 'react-redux'
import { load, store } from './store'

export function PlannerProvider({ children }: { children: ReactNode }) {
  useEffect(() => {
    store.dispatch(load())
  }, [])
  return <Provider store={store}>{children}</Provider>
}
```

```typescript
import { useCallback } from 'react'
import { toggleDone, useAppDispatch, useAppSelector } from './store'

export function usePlannerContext() {
  const { status, courses, sessions } = useAppSelector((state) => state.planner)
  const dispatch = useAppDispatch()
  const toggle = useCallback((id: string) => dispatch(toggleDone(id)), [dispatch])
  return { status, courses, sessions, toggleDone: toggle }
}
```

`useAppSelector` subscribes to a slice of the store, re-rendering only when that slice changes; it
returns `state.planner`, the whole slice, which changes when any field in it does. The dispatching
function is wrapped in `useCallback` from lesson 7 so that callers receive a stable `toggleDone`.
The result is the same 120, from forty-five lines of store.
