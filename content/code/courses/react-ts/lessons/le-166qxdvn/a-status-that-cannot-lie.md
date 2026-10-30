---
title: A status that cannot lie
version: 1
---

**`usePlanner` has returned five things since lesson 11, and three of them could contradict each
other.** While the planner was loading, `courses` was an empty array, so a screen that forgot to check
`status` would say *no courses* when the truth was *not known yet*. And `retry` existed in every state,
although it only means something after a failure.

TypeScript can say which fields belong to which status, with a **discriminated union**: a type that is
one of several shapes, each with the same field, `status`, holding a different literal. `src/usePlanner.ts`:

```ts
import {
  queryOptions,
  useMutation,
  useQuery,
  useQueryClient,
  type UseQueryResult,
} from '@tanstack/react-query'
import type { Course, Session } from './types'

export type NewSession = Pick<Session, 'course' | 'date' | 'minutes'>
type Planner = { courses: Course[]; sessions: Session[] }

// What the planner can be, one shape per status: there are courses only when
// it is ready, and a way to retry only when it failed.
export type PlannerState =
  | { status: 'loading' }
  | { status: 'failed'; retry: () => void; retrying: boolean }
  | { status: 'ready'; courses: Course[]; sessions: Session[] }

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(path, { ...init, headers: { 'content-type': 'application/json' } })
  if (!response.ok) throw new Error(`HTTP ${response.status} for ${path}`)
  return response.json()
}

export const plannerQuery = queryOptions({
  queryKey: ['planner'],
  queryFn: () => request<Planner>('/api/planner'),
})

function stateOf(planner: UseQueryResult<Planner>): PlannerState {
  if (planner.isPending) return { status: 'loading' }
  if (planner.isError) {
    return { status: 'failed', retry: planner.refetch, retrying: planner.isFetching }
  }
  return { status: 'ready', courses: planner.data.courses, sessions: planner.data.sessions }
}

export function usePlanner() {
  const queryClient = useQueryClient()
  const planner = useQuery(plannerQuery)
  const refresh = () => queryClient.invalidateQueries({ queryKey: ['planner'] })

  const toggle = useMutation({
    mutationFn: (id: string) => {
      const current = queryClient.getQueryData(plannerQuery.queryKey)
      const session = current?.sessions.find((s) => s.id === id)
      return request(`/api/sessions/${id}`, {
        method: 'PATCH',
        body: JSON.stringify({ done: !session?.done }),
      })
    },
    onSuccess: refresh,
  })
  const add = useMutation({
    mutationFn: (session: NewSession) =>
      request('/api/sessions', { method: 'POST', body: JSON.stringify(session) }),
    onSuccess: refresh,
  })

  return { ...stateOf(planner), toggleDone: toggle.mutate, addSession: add.mutate }
}
```

- **`PlannerState` is three shapes.** Only `'ready'` has `courses` and `sessions`; only `'failed'` has
  `retry`. There is no way to write a planner that is loading and has courses, because no shape has
  both.
- **`stateOf` builds the right shape for the query's state**, and its declared return type,
  `PlannerState`, is what makes the next section work: the next section says why.
- **The two actions are spread on to every shape**, so a form can add a session whatever the status.

The compiler now refuses every place that read a field without asking which shape it had:

```
ana@dev:~/planner$ npx tsc -b
src/CourseScreen.tsx(12,11): error TS2339: Property 'sessions' does not exist on type '{ toggleDone: UseMutateFunction<unknown, Error, string, unknown>; addSession: UseMutateFunction<unknown, Error, NewSession, unknown>; status: "loading"; } | { ...; } | { ...; }'.
src/CourseScreen.tsx(21,14): error TS7006: Parameter 's' implicitly has an 'any' type.
src/CourseScreen.tsx(22,12): error TS7006: Parameter 'a' implicitly has an 'any' type.
src/CourseScreen.tsx(22,15): error TS7006: Parameter 'b' implicitly has an 'any' type.
src/CourseScreen.tsx(33,24): error TS7006: Parameter 's' implicitly has an 'any' type.
src/LoadFailed.tsx(4,11): error TS2339: Property 'retry' does not exist on type '{ toggleDone: UseMutateFunction<unknown, Error, string, unknown>; addSession: UseMutateFunction<unknown, Error, NewSession, unknown>; status: "loading"; } | { ...; } | { ...; }'.
src/LoadFailed.tsx(4,18): error TS2339: Property 'retrying' does not exist on type '{ toggleDone: UseMutateFunction<unknown, Error, string, unknown>; addSession: UseMutateFunction<unknown, Error, NewSession, unknown>; status: "loading"; } | { ...; } | { ...; }'.
src/WeekScreen.tsx(10,11): error TS2339: Property 'courses' does not exist on type '{ toggleDone: UseMutateFunction<unknown, Error, string, unknown>; addSession: UseMutateFunction<unknown, Error, NewSession, unknown>; status: "loading"; } | { ...; } | { ...; }'.
src/WeekScreen.tsx(10,20): error TS2339: Property 'sessions' does not exist on type '{ toggleDone: UseMutateFunction<unknown, Error, string, unknown>; addSession: UseMutateFunction<unknown, Error, NewSession, unknown>; status: "loading"; } | { ...; } | { ...; }'.
src/WeekScreen.tsx(12,37): error TS7006: Parameter 's' implicitly has an 'any' type.
```

Each `TS2339` is the old contradiction, found. `WeekScreen` reads `courses`, `CourseScreen` reads
`sessions`, `LoadFailed` reads `retry`, and none of them checked the status first. The `TS7006`s follow
from those: once `sessions` has no type, neither does the `s` that `filter` hands each session. The
union did not create these bugs. They were there already, held off by `Root` drawing each screen at the
right moment, and the compiler had no way to know that.

```schooling-figure
{"svg": "<svg data-fig=\"union\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Before: one shape with status, courses, sessions, retry and retrying all present at once, so a loading planner could carry an empty courses list. After: three shapes. Loading has only status. Failed has status, retry and retrying. Ready has status, courses and sessions. Every shape also has the two actions.\"><text x=\"105\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">before</text><rect x=\"20\" y=\"36\" width=\"170\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">status</text><text x=\"105.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">courses: []</text><text x=\"105.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sessions: []</text><text x=\"105.0\" y=\"125.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">retry</text><text x=\"105.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">retrying</text><text x=\"105\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">every field, always</text><text x=\"470\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">after</text><rect x=\"240\" y=\"36\" width=\"145\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"312.5\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">status: 'loading'</text><rect x=\"400\" y=\"36\" width=\"145\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"472.5\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">status: 'failed'</text><text x=\"472.5\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">retry</text><text x=\"472.5\" y=\"105.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">retrying</text><rect x=\"560\" y=\"36\" width=\"145\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"632.5\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">status: 'ready'</text><text x=\"632.5\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">courses</text><text x=\"632.5\" y=\"105.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">sessions</text><text x=\"470\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+ toggleDone · addSession</text><text x=\"470\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a field exists only where it means something</text></svg>", "caption": "Each status carries only the fields that mean something in it."}
```
