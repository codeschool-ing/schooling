---
title: A fronteira do cliente
version: 1
---

**Interatividade precisa de código no navegador, e um Server Component não tem nenhum lá.** Tente fazer
do nome de um curso um botão que registra um clique, com `sed` para a mudança ser uma linha só:

```
ana@dev:~/planner-next$ sed -i 's|<h2>{course.name}</h2>|<h2><button onClick={() => console.log(course.id)}>{course.name}</button></h2>|' app/Planner.tsx && grep -n onClick app/Planner.tsx
29:              <h2><button onClick={() => console.log(course.id)}>{course.name}</button></h2>
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 | sed -n '/Event handlers/,/Client Component\./p;/heading/p'
Uncaught Error: Event handlers cannot be passed to Client Component props.
  <button onClick={function onClick} children=...>
                  ^^^^^^^^^^^^^^^^^^
If you need interactivity, consider converting part of this to a Client Component.
- heading "This page couldn’t load" [level=1]
ana@dev:~/planner-next$ sed -i 's|<h2><button onClick={() => console.log(course.id)}>{course.name}</button></h2>|<h2>{course.name}</h2>|' app/Planner.tsx && grep -c onClick app/Planner.tsx
0
```

A página quebrou: **Event handlers cannot be passed to Client Component props.** O JSX que o servidor
produz precisa viajar até o navegador como dados, e uma função, o `onClick`, não vira dados: é código,
com variáveis em volta, numa máquina que o navegador não alcança. A página virou a página de erro do
Next.js, *This page couldn't load*. O último `sed` devolveu a linha.

**`'use client'` no topo de um arquivo marca a fronteira.** Esse arquivo, e tudo o que ele importa, vai
para o navegador e roda lá; pode usar estado, efeitos e handlers. O planejador da aula 5 mudava de semana
com as setas, e isso precisa de um efeito e de um listener na `window`, então vira um Client Component,
o `app/WeekKeys.tsx`:

```tsx
'use client'

import { useRouter } from 'next/navigation'
import { useEffect } from 'react'
import { addDays } from '@/lib/week'

// The arrow keys move a week, as lesson 5's did. It draws nothing.
export function WeekKeys({ monday }: { monday: string }) {
  const router = useRouter()

  useEffect(() => {
    function onKey(event: KeyboardEvent) {
      if (event.target instanceof HTMLInputElement) return
      if (event.key === 'ArrowLeft') router.push(`/?week=${addDays(monday, -7)}`)
      if (event.key === 'ArrowRight') router.push(`/?week=${addDays(monday, 7)}`)
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [monday, router])

  return null
}
```

O `useRouter` é do Next.js: `router.push` vai para outro endereço sem recarregar a página. O componente
não desenha nada, `return null`, então pode ficar em qualquer lugar. O planejador o renderiza, e ganha
dois links para os mesmos movimentos sem teclado:

```tsx
import Link from 'next/link'
import { getPlanner } from '@/lib/planner'
import { addDays, formatWeek, inWeek, minutes, mondayOf, today } from '@/lib/week'
import { WeekKeys } from './WeekKeys'

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

Os `Link`s são links comuns, desenhados pelo servidor, que funcionam antes de qualquer JavaScript
carregar; o Next.js os deixa mais rápidos quando carrega. O `WeekKeys` é a única parte que precisa do
navegador, e o servidor passa a ele uma string, `monday`.

```
ana@dev:~/planner-next$ npx tsc --noEmit && echo no errors
no errors
```

Aperte a seta para a direita:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --network --do 'press ArrowRight' | grep -v '_next/static' | grep -v '^%c'
net  GET /?week=2026-10-19  200
[HMR] connected
-- press ArrowRight
net  GET /?week=2026-10-26&_rsc=bDxByZpqNar9PdVL  200
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - link "Previous week":
      - /url: /?week=2026-10-19
    - link "Next week":
      - /url: /?week=2026-11-02
  - region "This week":
    - paragraph: Week of 26 Oct 2026
    - paragraph: 0 of 0 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 0 sessions · 0 min
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 0 sessions · 0 min
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 0 sessions · 0 min
- alert
```

**A semana de 26 de outubro, sem carregar página nova.** A requisição depois da tecla não é para
`/api/planner`: é para a própria página, `/?week=2026-10-26`, com `_rsc` acrescentado, que pede ao
servidor os Server Components da semana nova como dados, e não como HTML. O servidor buscou da API,
renderizou o planejador e mandou o resultado; o navegador o encaixou na página que já tinha. Os links
fazem o mesmo:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'click link Previous week' | grep -E 'Week of|minutes done'
    - paragraph: Week of 12 Oct 2026
    - paragraph: 60 of 60 minutes done
```

A semana anterior, com os 60 minutos de química, todos feitos.
