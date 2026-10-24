---
title: Um status que não mente
version: 1
---

**O `usePlanner` devolve cinco coisas desde a aula 11, e três delas podiam se contradizer.** Enquanto o
planejador carregava, `courses` era um array vazio, então uma tela que esquecesse de conferir o `status`
diria *nenhum curso* quando a verdade era *ainda não se sabe*. E o `retry` existia em todo estado, embora
só signifique algo depois de uma falha.

O TypeScript consegue dizer que campos pertencem a que status, com uma **união discriminada**: um tipo que
é uma de várias formas, cada uma com o mesmo campo, `status`, guardando um literal diferente. O
`src/usePlanner.ts`:

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

- **`PlannerState` são três formas.** Só a `'ready'` tem `courses` e `sessions`; só a `'failed'` tem
  `retry`. Não há como escrever um planejador que esteja carregando e tenha cursos, porque nenhuma forma
  tem os dois.
- **`stateOf` monta a forma certa para o estado da query**, e o tipo de retorno declarado dela,
  `PlannerState`, é o que faz a próxima seção funcionar: a próxima seção diz por quê.
- **As duas ações são espalhadas em toda forma**, então um formulário pode acrescentar uma sessão seja qual
  for o status.

O compilador agora recusa todo lugar que lia um campo sem perguntar que forma tinha:

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

Cada `TS2339` é a contradição antiga, encontrada. O `WeekScreen` lê `courses`, o `CourseScreen` lê
`sessions`, o `LoadFailed` lê `retry`, e nenhum deles conferia o status antes. Os `TS7006` vêm daí: quando
o `sessions` fica sem tipo, o `s` que o `filter` entrega a cada sessão também fica. A união não criou esses
defeitos. Eles já estavam lá, contidos pelo `Root` desenhando cada tela no momento certo, e o compilador
não tinha como saber disso.

```schooling-figure
{"svg": "<svg data-fig=\"union\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Antes: uma forma com status, courses, sessions, retry e retrying todos presentes ao mesmo tempo, então um planejador carregando podia levar uma lista de cursos vazia. Depois: três formas. Loading tem só status. Failed tem status, retry e retrying. Ready tem status, courses e sessions. Toda forma também tem as duas ações.\"><text x=\"105\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">antes</text><rect x=\"20\" y=\"36\" width=\"170\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">status</text><text x=\"105.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">courses: []</text><text x=\"105.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sessions: []</text><text x=\"105.0\" y=\"125.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">retry</text><text x=\"105.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">retrying</text><text x=\"105\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">todo campo, sempre</text><text x=\"470\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">depois</text><rect x=\"240\" y=\"36\" width=\"145\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"312.5\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">status: 'loading'</text><rect x=\"400\" y=\"36\" width=\"145\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"472.5\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">status: 'failed'</text><text x=\"472.5\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">retry</text><text x=\"472.5\" y=\"105.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">retrying</text><rect x=\"560\" y=\"36\" width=\"145\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"632.5\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">status: 'ready'</text><text x=\"632.5\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">courses</text><text x=\"632.5\" y=\"105.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">sessions</text><text x=\"470\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+ toggleDone · addSession</text><text x=\"470\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um campo só existe onde faz sentido</text></svg>", "caption": "Cada status carrega só os campos que fazem sentido nele."}
```
