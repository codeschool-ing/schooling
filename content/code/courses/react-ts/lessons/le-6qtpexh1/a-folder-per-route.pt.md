---
title: Uma pasta por rota
version: 1
---

**No Next.js, as pastas dentro de `app/` são as rotas.** A aula 17 escreveu as rotas do React Router
como uma lista no `main.tsx`; aqui a lista é o sistema de arquivos. O `app/page.tsx` é a `/`, e uma
página por curso vai em `app/courses/[courseId]/page.tsx`: os colchetes fazem da pasta um **segmento
dinâmico**, a mesma ideia do `:courseId`, e o valor chega em `params`.

```tsx
import Link from 'next/link'
import { notFound } from 'next/navigation'
import { getPlanner } from '@/lib/planner'
import { formatDay, minutes } from '@/lib/week'

export default async function CoursePage({ params }: PageProps<'/courses/[courseId]'>) {
  const { courseId } = await params
  const { courses, sessions } = await getPlanner()
  const course = courses.find((c) => c.id === courseId)
  if (!course) notFound()

  const own = sessions
    .filter((s) => s.course === course.id)
    .sort((a, b) => a.date.localeCompare(b.date))
  const done = own.filter((s) => s.done)
  return (
    <main>
      <Link href="/">Back to the week</Link>
      <h1>{course.name}</h1>
      <p>
        {minutes(done)} of {minutes(own)} minutes done
      </p>
      <ul>
        {own.map((s) => (
          <li key={s.id}>
            {formatDay(s.date)} · {s.minutes} min{s.done && ' · done'}
          </li>
        ))}
      </ul>
    </main>
  )
}
```

- **`params` é uma promise**, como o `searchParams` da aula 15, e `PageProps<'/courses/[courseId]'>` o
  tipa a partir do nome da pasta: `courseId` é uma string.
- **`notFound()`** para a página e mostra uma página de não encontrado no lugar; a próxima seção lhe dá
  uma própria.
- É um Server Component, então busca e desenha no servidor, como o `Planner`.

```
ana@dev:~/planner-next$ look http://localhost:3000/courses/chemistry --today 2026-10-21 | grep -v '^$'
[HMR] connected
[error] Error: Route "/courses/[courseId]": Next.js encountered uncached data during prerendering.
`fetch(...)` or `connection()` accessed outside of `<Suspense>` prevents the route from being prerendered, blocking the page load and leading to a slower user experience.
Ways to fix this:
  - [stream] Provide a placeholder with `<Suspense fallback={...}>` around the data access
  - [cache] Cache the data access with `"use cache"` (does not apply to `connection()`)
  - [block] Set `export const instant = false` to allow a blocking route
Learn more: https://nextjs.org/docs/messages/blocking-prerender-dynamic
    at getPlanner (about://React/Server/file:///home/ana/planner-next/.next/dev/server/chunks/ssr/%255Broot-of-the-server%255D__0flwiz7kep8nq._.js?20:299:28)
    at CoursePage (about://React/Server/file:///home/ana/planner-next/.next/dev/server/chunks/ssr/%5Broot-of-the-server%5D__0he2qxgnwk032._.js?21:23:170)
    at resolveErrorDev (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2029:105)
    at getOutlinedModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:1568:28)
    at parseModelString (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:1688:50)
    at reviveModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2634:66)
    at reviveModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2637:61)
    at reviveModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2716:112)
    at parseModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2629:16)
    at initializeModelChunk (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:1141:25)
    at resolveModelChunk (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:1039:43)
    at processFullStringRow (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2585:371)
    at processFullBinaryRow (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2507:9)
    at processBinaryChunk (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2614:221)
    at progress (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2801:13)
- main:
  - link "Back to the week":
    - /url: /
  - heading "Organic chemistry" [level=1]
  - paragraph: 60 of 105 minutes done
  - list:
    - listitem: Wed 14 Oct · 60 min · done
    - listitem: Thu 22 Oct · 45 min
- alert
```

A página apareceu, com os 60 de 105 minutos de química, e o Cache Components reclamou de novo, como na
aula 15: o `fetch` não tem nada a mostrar enquanto espera. A aula 15 envolveu o planejador num
`Suspense` à mão. Numa pasta de rota há um arquivo para isso, o **`loading.tsx`**:

```tsx
export default function Loading() {
  return <p>Loading the course…</p>
}
```

O Next.js envolve a página da pasta num `Suspense` cuja reserva é este componente, então ele aparece
enquanto os dados da página chegam, e numa navegação até a página enquanto a próxima é buscada.

```
ana@dev:~/planner-next$ look http://localhost:3000/courses/chemistry --today 2026-10-21 | grep -v '^$'
[HMR] connected
- main:
  - link "Back to the week":
    - /url: /
  - heading "Organic chemistry" [level=1]
  - paragraph: 60 of 105 minutes done
  - list:
    - listitem: Wed 14 Oct · 60 min · done
    - listitem: Thu 22 Oct · 45 min
- alert
```

Nenhuma reclamação agora. A semana ganha links para cada curso, numa lista nova no `app/Planner.tsx`:

```tsx
import Link from 'next/link'
import { getPlanner } from '@/lib/planner'
import { addDays, formatWeek, inWeek, minutes, mondayOf, today } from '@/lib/week'
import { AddSession } from './AddSession'
import { SessionList } from './SessionList'
import { WeekKeys } from './WeekKeys'

type PlannerProps = {
  searchParams: PageProps<'/'>['searchParams']
}

export async function Planner({ searchParams }: PlannerProps) {
  const { week } = await searchParams
  const monday = mondayOf(typeof week === 'string' ? week : today())
  const { courses, sessions } = await getPlanner()

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  const done = thisWeek.filter((s) => s.done)
  return (
    <>
      <nav aria-label="Week">
        <Link href={`/?week=${addDays(monday, -7)}`}>Previous week</Link>{' '}
        <Link href={`/?week=${addDays(monday, 7)}`}>Next week</Link>
      </nav>
      <WeekKeys monday={monday} />
      <section aria-label="This week">
        <p>Week of {formatWeek(monday)}</p>
        <p>
          {minutes(done)} of {minutes(thisWeek)} minutes done
        </p>
      </section>
      <nav aria-label="Courses">
        <ul>
          {courses.map((c) => (
            <li key={c.id}>
              <Link href={`/courses/${c.id}`}>{c.name}</Link>
            </li>
          ))}
        </ul>
      </nav>
      <SessionList sessions={thisWeek} courses={courses} />
      <AddSession courses={courses} />
    </>
  )
}
```

```
ana@dev:~/planner-next$ look 'http://localhost:3000/?week=2026-10-19' --today 2026-10-21 --network --do 'click link Spanish' | grep -E 'GET /courses|_rsc|^-- |heading|paragraph'
-- click link Spanish
net  GET /courses/spanish?_rsc=bDxByZpqNar9PdVL  200
  - heading "Spanish" [level=1]
  - paragraph: 30 of 60 minutes done
```

O `next/link` fez o que o `Link` do React Router fazia: o clique buscou `/courses/spanish` como dados de
Server Component, a requisição `_rsc` da aula 15, e desenhou o curso sem carregar uma página.

**Os arquivos especiais** de uma pasta de rota, que o Next.js liga pelo nome:

| arquivo | o que é |
|---|---|
| `page.tsx` | a tela da rota; uma pasta sem ele não é rota |
| `layout.tsx` | desenhado em volta das páginas abaixo dele, e mantido nas navegações entre elas |
| `loading.tsx` | a reserva de um `Suspense` em volta da página |
| `not-found.tsx` | o que o `notFound()` mostra |
| `error.tsx` | um error boundary em volta da página |
