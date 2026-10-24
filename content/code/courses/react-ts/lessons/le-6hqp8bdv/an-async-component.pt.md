---
title: Um componente que roda no servidor
version: 1
---

**Um Server Component pode ser uma função `async`**, e fazer `await` do que precisa antes de devolver o
JSX. Não há efeito, nem estado de carregamento próprio, nem requisição do navegador: os dados são
buscados onde o componente roda, no servidor. Na pasta `app/` do Next.js, todo componente é um Server
Component a menos que o arquivo dele diga o contrário.

O planejador em Next.js reaproveita o que pode do planejador do Vite: os tipos, a aritmética de datas
da aula 3 e a folha de estilo:

```
ana@dev:~/planner-next$ mkdir lib && cp ../planner/src/types.ts ../planner/src/week.ts lib/ && cp ../planner/src/index.css app/globals.css && ls lib app
app:
globals.css
layout.tsx
page.tsx

lib:
types.ts
week.ts
```

Depois, uma função que pergunta à API, o `lib/planner.ts`:

```ts
import type { Course, Session } from './types'

export type Planner = { courses: Course[]; sessions: Session[] }

// Asks the planner's API, from lesson 11, for everything it holds.
export async function getPlanner(): Promise<Planner> {
  const response = await fetch('http://localhost:3001/api/planner')
  if (!response.ok) throw new Error(`HTTP ${response.status} from the planner API`)
  return response.json()
}
```

Este `fetch` roda no Node.js, no servidor, então pode nomear `localhost:3001` diretamente: sem proxy, e
sem que o endereço precise ser conhecido por um navegador. O layout raiz, `app/layout.tsx`, ganha o
título do planejador e importa a folha de estilo:

```tsx
import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Study planner',
}

export default function RootLayout({ children }: LayoutProps<'/'>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
```

O componente que desenha a semana, `app/Planner.tsx`:

```tsx
import { getPlanner } from '@/lib/planner'
import { formatWeek, inWeek, minutes, mondayOf, today } from '@/lib/week'

type PlannerProps = {
  searchParams: PageProps<'/'>['searchParams']
}

export async function Planner({ searchParams }: PlannerProps) {
  const { week } = await searchParams
  const monday = mondayOf(typeof week === 'string' ? week : today())
  const { courses, sessions } = await getPlanner()
  console.log(`Planner: week of ${monday}, ${sessions.length} sessions`)

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  const done = thisWeek.filter((s) => s.done)
  return (
    <>
      <section aria-label="This week">
        <p>Week of {formatWeek(monday)}</p>
        <p>
          {minutes(done)} of {minutes(thisWeek)} minutes done
        </p>
      </section>
      <section aria-label="Courses">
        {courses.map((course) => {
          const own = thisWeek.filter((s) => s.course === course.id)
          return (
            <article key={course.id} className="card">
              <h2>{course.name}</h2>
              <p>
                {own.length} {own.length === 1 ? 'session' : 'sessions'} · {minutes(own)} min
              </p>
            </article>
          )
        })}
      </section>
    </>
  )
}
```

Ele lê a semana do endereço, `?week=2026-10-19`, e não de um estado, porque um Server Component não tem
estado: roda uma vez por requisição e some. **`searchParams` é uma promise** nesta versão do Next.js, e
o componente faz await dela. `PageProps<'/'>` é um tipo que o Next.js gera para cada rota, com o formato
certo dos `searchParams` daquela rota. O `console.log` está lá para mostrar onde este código roda.

E a página, `app/page.tsx`, desenha o título e o planejador:

```tsx
import { Planner } from './Planner'

export default function Page({ searchParams }: PageProps<'/'>) {
  return (
    <main>
      <h1>Study planner</h1>
      <Planner searchParams={searchParams} />
    </main>
  )
}
```

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 | grep -v '^$'
[HMR] connected
%c%s%c Planner: week of 2026-10-19, 6 sessions background: #e6e6e6;background: light-dark(rgba(0,0,0,0.1), rgba(255,255,255,0.25));color: #000000;color: light-dark(#000000, #ffffff);border-radius: 2px  Server  
[error] Error: Route "/": Next.js encountered uncached data during prerendering.
`fetch(...)` or `connection()` accessed outside of `<Suspense>` prevents the route from being prerendered, blocking the page load and leading to a slower user experience.
Ways to fix this:
  - [stream] Provide a placeholder with `<Suspense fallback={...}>` around the data access
  - [cache] Cache the data access with `"use cache"` (does not apply to `connection()`)
  - [block] Set `export const instant = false` to allow a blocking route
Learn more: https://nextjs.org/docs/messages/blocking-prerender-dynamic
    at getPlanner (about://React/Server/file:///home/ana/planner-next/.next/dev/server/chunks/ssr/%255Broot-of-the-server%255D__12kpotjuv4lhr._.js?id=%255Bproject%255D/lib/planner.ts+%255Bapp-rsc%255D+(ecmascript)?16:9:28)
    at Planner (about://React/Server/file:///home/ana/planner-next/.next/dev/server/chunks/ssr/%255Broot-of-the-server%255D__12kpotjuv4lhr._.js?id=%255Bproject%255D/app/Planner.tsx+%255Bapp-rsc%255D+(ecmascript)?17:17:170)
    at Page (about://React/Server/file:///home/ana/planner-next/.next/dev/server/chunks/ssr/%255Broot-of-the-server%255D__12kpotjuv4lhr._.js?id=%255Bproject%255D/app/page.tsx+%255Bapp-rsc%255D+(ecmascript)?18:22:264)
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
  - heading "Study planner" [level=1]
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 2 sessions · 90 min
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 2 sessions · 60 min
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 1 session · 45 min
- alert
```

A página apareceu: a semana, os 80 de 195 minutos, os três cursos. **E o Next.js imprimiu um erro mesmo
assim**, que é o Cache Components em ação. Com ele ligado, o Next.js tenta montar cada página com
antecedência como uma casca estática, e o que não pode ser conhecido com antecedência, como um `fetch`
cuja resposta pode mudar, precisa dizer o que mostrar até chegar. Uma página que não diz faria o
navegador esperar por ela inteira, e a mensagem nomeia três saídas. A primeira, `[stream]`, é a
ferramenta da aula 13, agora no servidor: `Suspense`, com uma reserva.

```tsx
import { Suspense } from 'react'
import { Planner } from './Planner'

export default function Page({ searchParams }: PageProps<'/'>) {
  return (
    <main>
      <h1>Study planner</h1>
      <Suspense fallback={<p>Loading the planner…</p>}>
        <Planner searchParams={searchParams} />
      </Suspense>
    </main>
  )
}
```

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --network | grep -v '_next/static'
net  GET /?week=2026-10-19  200
[HMR] connected
%c%s%c Planner: week of 2026-10-19, 6 sessions background: #e6e6e6;background: light-dark(rgba(0,0,0,0.1), rgba(255,255,255,0.25));color: #000000;color: light-dark(#000000, #ffffff);border-radius: 2px  Server  
- main:
  - heading "Study planner" [level=1]
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 2 sessions · 90 min
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 2 sessions · 60 min
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 1 session · 45 min
- alert
```

Nenhum erro agora. E olhe a rede: **uma requisição, da página**, e nada para `/api/planner` (o `grep`
escondeu só os arquivos JavaScript do próprio Next.js). O navegador nunca pediu os dados, porque os
dados vieram dentro da página.
