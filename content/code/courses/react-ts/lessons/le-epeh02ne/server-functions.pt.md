---
title: Uma função que o navegador chama no servidor
version: 1
---

**Uma Server Function é uma função `async` num arquivo que começa com `'use server'`.** Ela roda no
servidor, e um Client Component, ou um formulário, pode chamá-la como se fosse local: o framework
transforma a chamada numa requisição, roda a função e devolve o resultado. A aula 15 a encontrou numa
mensagem de erro, como o único tipo de função que pode atravessar a fronteira.

O planejador em Next.js mostra a semana mas não consegue mudá-la. Uma sessão deveria poder ser marcada
como feita, e a mudança precisa chegar à API. O `app/actions.ts`:

```ts
'use server'

import { refresh } from 'next/cache'

// Server Functions. The browser calls them; they run here, on the server.

export async function setDone(id: string, done: boolean) {
  const response = await fetch(`http://localhost:3001/api/sessions/${id}`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ done }),
  })
  if (!response.ok) throw new Error(`HTTP ${response.status} from the planner API`)
  refresh()
}
```

É o mesmo `PATCH` que o planejador do Vite manda, com um acréscimo: o **`refresh()`** diz ao Next.js
que a página de onde veio esta chamada está desatualizada, então a resposta à chamada leva a página
renderizada de novo, com a nova resposta da API dentro. É a invalidação da aula 11, no servidor.

Cada sessão da semana vira um formulário cuja ação é essa função. O `app/SessionList.tsx`:

```tsx
import type { Course, Session } from '@/lib/types'
import { formatDay } from '@/lib/week'
import { setDone } from './actions'

type SessionListProps = {
  sessions: Session[]
  courses: Course[]
}

export function SessionList({ sessions, courses }: SessionListProps) {
  const name = (id: string) => courses.find((c) => c.id === id)?.name ?? id
  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  return (
    <section aria-labelledby="sessions-heading">
      <h2 id="sessions-heading">Sessions this week</h2>
      <ul>
        {sorted.map((s) => (
          <li key={s.id}>
            <form action={setDone.bind(null, s.id, !s.done)}>
              <button type="submit" aria-pressed={s.done}>
                {formatDay(s.date)} · {name(s.course)} · {s.minutes} min
              </button>
            </form>
          </li>
        ))}
      </ul>
    </section>
  )
}
```

- **`setDone.bind(null, s.id, !s.done)`** cria uma versão da função com os dois argumentos já
  preenchidos. O formulário a chama sem mais nada, e os argumentos viajam com a requisição.
- **O botão é um alternador**, `aria-pressed`, com o nome da própria sessão. Um leitor de tela o anuncia
  como *pressionado* quando a sessão está feita, que é o sentido da caixa de marcação com o
  comportamento de um botão.
- **Não há `'use client'`.** A lista é um Server Component, e um formulário cuja ação é uma Server
  Function não precisa de JavaScript seu no navegador: antes de o código da página carregar, o navegador
  o envia do jeito que formulários sempre foram enviados.

O `Planner` perde os cartões de curso para dar espaço, e renderiza a lista:

```tsx
import Link from 'next/link'
import { getPlanner } from '@/lib/planner'
import { addDays, formatWeek, inWeek, minutes, mondayOf, today } from '@/lib/week'
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
      <SessionList sessions={thisWeek} courses={courses} />
    </>
  )
}
```

```
ana@dev:~/planner-next$ npx tsc --noEmit && echo no errors
no errors
```

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 | sed -n '/This week/,$p'
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Sessions this week":
    - heading "Sessions this week" [level=2]
    - list:
      - listitem:
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
      - listitem:
        - button "Tue 20 Oct · Spanish · 30 min" [pressed]
      - listitem:
        - button "Wed 21 Oct · Statistics · 40 min"
      - listitem:
        - button "Thu 22 Oct · Organic chemistry · 45 min"
      - listitem:
        - button "Fri 23 Oct · Spanish · 30 min"
- alert
```

As duas sessões já feitas estão `[pressed]`. Aperte a de quarta:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --network --do 'click button Wed 21 Oct · Statistics · 40 min' | grep -E 'POST|minutes done|Statistics'
-- click button Wed 21 Oct · Statistics · 40 min
net  POST /?week=2026-10-19  200
    - paragraph: 120 of 195 minutes done
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
        - button "Wed 21 Oct · Statistics · 40 min" [pressed]
```

**Uma requisição, um `POST` para o endereço da própria página**, e a página voltou com a quarta
pressionada e a semana em 120 minutos. O terminal da API mostra o resto da história:

```
----- the API terminal
planner API on http://localhost:3001
GET /api/planner
GET /api/planner
GET /api/planner
GET /api/planner
PATCH /api/sessions/s2
GET /api/planner
```

Cada renderização da página pergunta à API uma vez, então os primeiros `GET`s são as visitas até aqui.
Depois vem o **`PATCH`**, do `setDone`, e **mais um `GET`**: esse é o `refresh()`, a página renderizada
de novo no servidor, com os dados novos, dentro da resposta ao `POST`. O navegador não pediu mais nada.

```schooling-figure
{"svg": "<svg data-fig=\"round-trip\" viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Um toque no botão de uma sessão. O navegador envia o formulário ao endereço da página. No servidor, o setDone manda PATCH à API, depois o refresh renderiza a página de novo, o que manda GET à API. A resposta ao POST traz a página nova, e o navegador a encaixa.\"><rect x=\"20\" y=\"60\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"82.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o navegador</text><text x=\"90.0\" y=\"97.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">POST /?week=…</text><rect x=\"240\" y=\"30\" width=\"220\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o servidor Next.js</text><rect x=\"256\" y=\"62\" width=\"188\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">setDone('s2', true)</text><rect x=\"256\" y=\"104\" width=\"188\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">refresh() → Planner</text><rect x=\"560\" y=\"60\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">API :3001</text><text x=\"630.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PATCH · GET</text><line x1=\"162\" y1=\"80\" x2=\"238\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"238.0,80.0 230.5,83.2 230.5,76.8\" fill=\"var(--phosphor)\"></polygon><line x1=\"446\" y1=\"77\" x2=\"558\" y2=\"77\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,77.0 550.5,80.2 550.5,73.8\" fill=\"var(--amber)\"></polygon><line x1=\"446\" y1=\"119\" x2=\"558\" y2=\"103\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,103.0 551.0,107.2 550.1,100.9\" fill=\"var(--amber)\"></polygon><line x1=\"238\" y1=\"104\" x2=\"162\" y2=\"104\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"162.0,104.0 169.5,100.8 169.5,107.2\" fill=\"var(--amber)\"></polygon><text x=\"200\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a página nova</text><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o navegador faz uma requisição; a API é consultada duas vezes, pelo servidor</text></svg>", "caption": "Uma requisição do navegador; o servidor faz o resto e responde com a página.", "same": ["POST /?week=…"]}
```
