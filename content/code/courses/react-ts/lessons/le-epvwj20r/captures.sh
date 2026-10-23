#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 8's captures.sh
#
# Starts from ~/planner as lesson 8 left it. What is STAGED rather than typed:
# the files ana wrote, put below and shown in the lesson; the three copies of
# the planner, ~/planner-zustand, ~/planner-redux and ~/planner-jotai, made
# with the `cp -a` the lesson shows; and the page's date, Wednesday 21
# October 2026, set with --today. Each copy is served on 5173 in turn.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-0qfzz1m1
L='look http://localhost:5173/ --today 2026-10-21'
TICK="--do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses'"

block context
put src/plannerContext.ts <<'TS'
import { createContext, use } from 'react'
import type { usePlanner } from './usePlanner'

export type Planner = ReturnType<typeof usePlanner>

export const PlannerContext = createContext<Planner | null>(null)

export function usePlannerContext(): Planner {
  const planner = use(PlannerContext)
  if (planner === null) {
    throw new Error('usePlannerContext must be called inside <PlannerProvider>')
  }
  return planner
}
TS
put src/PlannerProvider.tsx <<'TSX'
import type { ReactNode } from 'react'
import { PlannerContext } from './plannerContext'
import { usePlanner } from './usePlanner'

export function PlannerProvider({ children }: { children: ReactNode }) {
  const planner = usePlanner()
  return <PlannerContext value={planner}>{children}</PlannerContext>
}
TSX
put src/main.tsx <<'TSX'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { PlannerProvider } from './PlannerProvider'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <PlannerProvider>
      <App />
    </PlannerProvider>
  </StrictMode>,
)
TSX
put src/CourseScreen.tsx <<'TSX'
import { useEffect, useRef } from 'react'
import { usePlannerContext } from './plannerContext'
import type { Course } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  onBack: () => void
}

export function CourseScreen({ course, onBack }: CourseScreenProps) {
  const { sessions, toggleDone } = usePlannerContext()
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
    </>
  )
}
TSX
put src/App.tsx <<'TSX'
import { useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import { usePlannerContext } from './plannerContext'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

function App() {
  const [monday, setMonday] = useWeek()
  const { status, courses, sessions } = usePlannerContext()
  const [openId, setOpenId] = useState<string | null>(null)

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <p role="alert">The planner could not be loaded.</p>

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <CourseScreen course={open} onBack={() => setOpenId(null)} />
      </main>
    )
  }

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList courses={courses} sessions={thisWeek} onOpen={setOpenId} />
    </main>
  )
}

export default App
TSX
on 'npm run lint && npx tsc -b && echo no errors'
serve 5173 npm run dev
on "$L $TICK | grep minutes"

block outside
on 'cp src/main.tsx /tmp/main.tsx'
on "sed -i '/PlannerProvider>\$/d' src/main.tsx"
on "$L 2>&1 | grep -m 1 '^Uncaught'"
on 'cp /tmp/main.tsx src/main.tsx'
stop
lab save after-$(basename "$PWD")

block zustand
CWD=
on 'cp -a planner planner-zustand'
CWD=planner-zustand
on 'npm install zustand@5.0.16'
put src/store.ts <<'TS'
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
TS
put src/PlannerProvider.tsx <<'TSX'
import { useEffect, type ReactNode } from 'react'
import { usePlannerStore } from './store'

// The store needs no provider; this one only starts the first load.
export function PlannerProvider({ children }: { children: ReactNode }) {
  useEffect(() => {
    usePlannerStore.getState().load()
  }, [])
  return children
}
TSX
put src/plannerContext.ts <<'TS'
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
TS
on 'npm run lint && npx tsc -b && echo no errors'
serve 5173 npm run dev
on "$L $TICK | grep minutes"
stop

block redux
CWD=
on 'cp -a planner planner-redux'
CWD=planner-redux
on 'npm install @reduxjs/toolkit@2.13.0 react-redux@9.3.0'
put src/store.ts <<'TS'
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
TS
put src/PlannerProvider.tsx <<'TSX'
import { useEffect, type ReactNode } from 'react'
import { Provider } from 'react-redux'
import { load, store } from './store'

export function PlannerProvider({ children }: { children: ReactNode }) {
  useEffect(() => {
    store.dispatch(load())
  }, [])
  return <Provider store={store}>{children}</Provider>
}
TSX
put src/plannerContext.ts <<'TS'
import { useCallback } from 'react'
import { toggleDone, useAppDispatch, useAppSelector } from './store'

export function usePlannerContext() {
  const { status, courses, sessions } = useAppSelector((state) => state.planner)
  const dispatch = useAppDispatch()
  const toggle = useCallback((id: string) => dispatch(toggleDone(id)), [dispatch])
  return { status, courses, sessions, toggleDone: toggle }
}
TS
on 'npm run lint && npx tsc -b && echo no errors'
serve 5173 npm run dev
on "$L $TICK | grep minutes"
stop

block jotai
CWD=
on 'cp -a planner planner-jotai'
CWD=planner-jotai
on 'npm install jotai@3.0.1'
put src/atoms.ts <<'TS'
import { atom } from 'jotai'
import type { Course, Session } from './types'

export const statusAtom = atom<'loading' | 'ready' | 'failed'>('loading')
export const coursesAtom = atom<Course[]>([])
export const sessionsAtom = atom<Session[]>([])

export const toggleDoneAtom = atom(null, (_get, set, id: string) => {
  set(sessionsAtom, (all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
})
TS
put src/PlannerProvider.tsx <<'TSX'
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
TSX
put src/plannerContext.ts <<'TS'
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
TS
on 'npm run lint && npx tsc -b && echo no errors'
serve 5173 npm run dev
on "$L $TICK | grep minutes"
stop

block sizes
CWD=
on 'wc -l planner/src/plannerContext.ts planner/src/PlannerProvider.tsx planner-*/src/store.ts planner-*/src/atoms.ts planner-*/src/plannerContext.ts planner-*/src/PlannerProvider.tsx'
on 'cd planner-zustand && npm ls zustand; cd ../planner-redux && npm ls @reduxjs/toolkit react-redux; cd ../planner-jotai && npm ls jotai'
lab exec ana 'rm -rf ~/planner-zustand ~/planner-redux ~/planner-jotai'
CWD=planner
finish
