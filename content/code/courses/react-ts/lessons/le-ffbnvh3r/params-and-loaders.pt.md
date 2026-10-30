---
title: Um parâmetro, e os dados de que ele precisa
version: 1
---

**Uma rota com parâmetro precisa transformar o valor em algo para desenhar.** Para `/courses/spanish`,
isso significa achar o curso chamado `spanish`, e a rota pode fazer isso antes de a tela ser desenhada,
num **loader**: uma função que o roteador chama com os parâmetros, cujo resultado a tela lê.

O loader precisa dos dados do planejador, e os dados moram no cache do React Query. Um loader roda fora
do React, então não pode chamar um hook; ele precisa do próprio cache, que vai para um módulo próprio, o
`src/queryClient.ts`:

```ts
import { QueryClient } from '@tanstack/react-query'

// The one cache, shared by the components and by the router's loaders.
export const queryClient = new QueryClient()
```

O `main.tsx` o importa de lá. A query em si ganha um nome no `src/usePlanner.ts`, para o hook e o loader
pedirem exatamente a mesma coisa:

```ts
import { queryOptions, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import type { Course, Session } from './types'

export type NewSession = Pick<Session, 'course' | 'date' | 'minutes'>
type Planner = { courses: Course[]; sessions: Session[] }
type Status = 'loading' | 'ready' | 'failed'

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(path, { ...init, headers: { 'content-type': 'application/json' } })
  if (!response.ok) throw new Error(`HTTP ${response.status} for ${path}`)
  return response.json()
}

export const plannerQuery = queryOptions({
  queryKey: ['planner'],
  queryFn: () => request<Planner>('/api/planner'),
})

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

  const status: Status = planner.isPending ? 'loading' : planner.isError ? 'failed' : 'ready'
  return {
    status,
    retrying: planner.isFetching,
    retry: planner.refetch,
    courses: planner.data?.courses ?? [],
    sessions: planner.data?.sessions ?? [],
    toggleDone: toggle.mutate,
    addSession: add.mutate,
  }
}
```

O `queryOptions` junta a key e a função, e **o `plannerQuery` passa a ser o único lugar onde elas são
escritas**: `useQuery(plannerQuery)` no hook, e `getQueryData(plannerQuery.queryKey)`, que de quebra sabe
o tipo dos dados. Depois o loader, `src/courseLoader.ts`:

```ts
import { data, type LoaderFunctionArgs } from 'react-router'
import { queryClient } from './queryClient'
import { plannerQuery } from './usePlanner'

// Runs before the course screen is drawn: the course named in the address has
// to exist, or the screen is never drawn at all.
export async function courseLoader({ params }: LoaderFunctionArgs) {
  const planner = await queryClient.ensureQueryData(plannerQuery)
  const course = planner.courses.find((c) => c.id === params.courseId)
  if (!course) throw data(`There is no course called “${params.courseId}”.`, { status: 404 })
  return course
}
```

- **`params.courseId`** é o `:courseId` do caminho da rota, como string.
- **`ensureQueryData`** devolve o planejador em cache se houver um, e o busca se não houver, então vir da
  semana não custa requisição, e abrir o endereço diretamente custa uma.
- **O que ele devolve é o que a tela recebe**: o curso. O que ele lança é assunto de uma seção adiante.

A tela do curso, `src/CourseScreen.tsx`, não recebe mais props:

```tsx
import { useEffect, useRef, useState } from 'react'
import { Link, useLoaderData } from 'react-router'
import { AddSessionForm } from './AddSessionForm'
import type { courseLoader } from './courseLoader'
import { Dialog } from './Dialog'
import { usePlannerContext } from './plannerContext'
import { StatusMessage } from './StatusMessage'
import { formatDay } from './week'

export function CourseScreen() {
  const course = useLoaderData<typeof courseLoader>()
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
      <Link to="/">Back to courses</Link>
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

O `useLoaderData<typeof courseLoader>()` devolve o resultado do loader com o tipo do loader, um `Course`.
*Back to courses* é um link para `/` em vez de um botão com callback. Agora abra um curso pelo endereço,
sem passar pela semana antes:

```
ana@dev:~/planner$ look http://localhost:5173/courses/spanish --today 2026-10-21
- main:
  - link "Back to courses":
    - /url: /
  - heading "Spanish" [level=1]
  - list:
    - listitem:
      - checkbox "Tue 20 Oct · 30 min" [checked]
      - text: Tue 20 Oct · 30 min
    - listitem:
      - checkbox "Fri 23 Oct · 30 min"
      - text: Fri 23 Oct · 30 min
  - button "Plan a session"
- status
```

**Espanhol, direto.** Numa primeira carga o loader precisa terminar antes de qualquer coisa ser desenhada,
e o **`hydrateFallbackElement`** do `main.tsx` é o que aparece enquanto isso; sem ele, o React Router avisa
no console que não tinha nada para mostrar. Da semana, pelo link:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network --do 'click link Statistics' | grep -E 'CourseScreen|api|^-- |heading'
net  GET /api/planner  200
-- click link Statistics
net  GET /src/CourseScreen.tsx  200
  - heading "Statistics" [level=1]
```

Depois do clique, **nenhuma requisição de página e nenhuma à API**: o roteador mudou o endereço sozinho,
o loader achou o planejador já em cache, e a única coisa buscada foi o código da tela do curso, que a
penúltima seção explica. Voltando:

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --do 'click link Back to courses' | grep -E 'heading'
  - heading "Study planner" [level=1]
      - heading "Statistics" [level=2]:
      - heading "Spanish" [level=2]:
      - heading "Organic chemistry" [level=2]:
```

A semana, com os três cartões. Num navegador, o botão Voltar faz o mesmo, porque cada tela agora tem um
lugar no histórico.

```schooling-figure
{"svg": "<svg data-fig=\"routes\" viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A árvore de rotas. A rota em barra desenha o Root, com um ErrorBoundary, RouteError. No Outlet do Root vão os filhos: a rota índice, WeekScreen, para a própria barra, e courses barra dois-pontos courseId, cujo loader, courseLoader, roda primeiro e cujo componente, CourseScreen, é carregado sob demanda. Embaixo, três endereços e o que cada um desenha: barra desenha Root e WeekScreen; barra courses barra spanish desenha Root e CourseScreen; barra courses barra latin desenha RouteError.\"><rect x=\"250\" y=\"14\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">path: '/'</text><text x=\"360.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Root · ErrorBoundary</text><rect x=\"60\" y=\"100\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">index</text><text x=\"170.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">WeekScreen</text><rect x=\"400\" y=\"100\" width=\"280\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">courses/:courseId</text><text x=\"540.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">courseLoader → lazy CourseScreen</text><line x1=\"360\" y1=\"58\" x2=\"170\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"360\" y1=\"58\" x2=\"540\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;Outlet /&gt;</text><text x=\"60\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/</text><text x=\"240\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">→</text><text x=\"270\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Root + WeekScreen</text><text x=\"60\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/courses/spanish</text><text x=\"240\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">→</text><text x=\"270\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Root + CourseScreen</text><text x=\"60\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/courses/latin</text><text x=\"240\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">→</text><text x=\"270\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o loader lança 404 → RouteError</text></svg>", "caption": "O endereço escolhe um ramo; o loader pode recusá-lo antes de qualquer coisa ser desenhada.", "same": ["Root + WeekScreen", "Root + CourseScreen"]}
```
