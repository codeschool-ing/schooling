---
title: Escrevendo um hook próprio
version: 1
---

**Um hook próprio é uma função cujo nome começa com `use` e que chama outros hooks.** Esse é o
mecanismo inteiro. Ele deixa um componente entregar um pedaço da sua lógica, estado e efeitos
inclusive, a uma função com nome, e deixa dois componentes compartilharem essa lógica sem
compartilharem estado: cada componente que chama o hook recebe o seu.

O `App` vem acumulando duas preocupações separadas desde a aula 5: carregar os dados do planejador, e
cuidar da semana, com o título e o atalho de teclado. Cada uma vira um hook. O `src/usePlanner.ts`
cuida dos dados:

```typescript
import { useCallback, useEffect, useState } from 'react'
import type { Course, Session } from './types'

type Status = 'loading' | 'ready' | 'failed'

export function usePlanner() {
  const [courses, setCourses] = useState<Course[]>([])
  const [sessions, setSessions] = useState<Session[]>([])
  const [status, setStatus] = useState<Status>('loading')

  useEffect(() => {
    let ignore = false
    fetch('/courses.json')
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json()
      })
      .then((data: { courses: Course[]; sessions: Session[] }) => {
        if (ignore) return
        setCourses(data.courses)
        setSessions(data.sessions)
        setStatus('ready')
      })
      .catch((error) => {
        if (ignore) return
        console.error('could not load the planner:', error.message)
        setStatus('failed')
      })
    return () => {
      ignore = true
    }
  }, [])

  const toggleDone = useCallback((id: string) => {
    setSessions((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }, [])

  return { status, courses, sessions, toggleDone }
}
```

É a busca da aula 5, palavra por palavra, com o `toggleDone` da seção anterior, e devolve as quatro
coisas de que quem chama precisa, num objeto. O `src/useWeek.ts` cuida da semana:

```typescript
import { useEffect, useState } from 'react'
import { addDays, formatWeek, mondayOf, today } from './week'

export function useWeek() {
  const [monday, setMonday] = useState(() => mondayOf(today()))

  useEffect(() => {
    document.title = `Week of ${formatWeek(monday)} · Study planner`
  }, [monday])

  useEffect(() => {
    function onKey(event: KeyboardEvent) {
      if (event.target instanceof HTMLInputElement) return
      if (event.key === 'ArrowLeft') setMonday((m) => addDays(m, -7))
      if (event.key === 'ArrowRight') setMonday((m) => addDays(m, 7))
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  return [monday, setMonday] as const
}
```

Ele devolve um par, como o `useState`, e o `as const` diz ao TypeScript que o par é exatamente uma
string e um setter, nessa ordem, e não um array de qualquer um dos dois. E o `App` fica com o que é de
fato o trabalho dele, decidir qual tela desenhar:

```tsx
import { useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import { usePlanner } from './usePlanner'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

function App() {
  const [monday, setMonday] = useWeek()
  const { status, courses, sessions, toggleDone } = usePlanner()
  const [openId, setOpenId] = useState<string | null>(null)

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <p role="alert">The planner could not be loaded.</p>

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <CourseScreen
          course={open}
          sessions={sessions.filter((s) => s.course === open.id)}
          onToggle={toggleDone}
          onBack={() => setOpenId(null)}
        />
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
```

```
ana@dev:~/planner$ wc -l src/App.tsx src/usePlanner.ts src/useWeek.ts
  43 src/App.tsx
  39 src/usePlanner.ts
  22 src/useWeek.ts
 104 total
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 74ms on 13 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'press ArrowRight' --do 'click button Previous week' --html title | sed -n 1,2p\;9,11p\;\$p
-- press ArrowRight
-- click button Previous week
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
<title>Week of 19 Oct 2026 · Study planner</title>
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep minutes
    - paragraph: 120 of 195 minutes done
```

O `App` foi de 87 linhas para 43, o linter e a checagem de tipos estão limpos, e o planejador se
comporta como antes: a seta andou uma semana e o botão a trouxe de volta, o título acompanhou, e
marcar uma sessão ainda soma 40 minutos. Nada que o usuário vê mudou. **Um hook próprio move código;
ele não muda o que o código faz**, e cada hook dentro dele mantém o lugar na ordem do `App`, porque
chamar `useWeek()` chama os hooks dele, em ordem, no topo do `App`.

```schooling-figure
{"svg": "<svg data-fig=\"custom-hook\" viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"À esquerda, o código do App chama useWeek, usePlanner e useState. À direita, os hooks que o React de fato registra para o App, em ordem: o useState e os dois useEffect do useWeek, depois os três useState do usePlanner, o useEffect da busca e o useCallback, depois o useState do próprio App para openId. Os hooks de um hook próprio são hooks do App, no lugar onde ele é chamado.\"><text x=\"140\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que o código do App diz</text><text x=\"520\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que o React registra para o App</text><rect x=\"30\" y=\"34\" width=\"220\" height=\"68\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">useWeek()</text><line x1=\"252\" y1=\"68.0\" x2=\"368\" y2=\"68.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"368.0,68.0 360.5,71.2 360.5,64.8\" fill=\"var(--phosphor)\"></polygon><text x=\"386\" y=\"44\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"392\" y=\"34\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useState  monday</text><text x=\"386\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"392\" y=\"58\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useEffect title</text><text x=\"386\" y=\"92\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"392\" y=\"82\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useEffect keyboard</text><rect x=\"30\" y=\"106\" width=\"220\" height=\"116\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">usePlanner()</text><line x1=\"252\" y1=\"164.0\" x2=\"368\" y2=\"164.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"368.0,164.0 360.5,167.2 360.5,160.8\" fill=\"var(--amber)\"></polygon><text x=\"386\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"392\" y=\"106\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useState  courses</text><text x=\"386\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">5</text><rect x=\"392\" y=\"130\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useState  sessions</text><text x=\"386\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">6</text><rect x=\"392\" y=\"154\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useState  status</text><text x=\"386\" y=\"188\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">7</text><rect x=\"392\" y=\"178\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useEffect fetch</text><text x=\"386\" y=\"212\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">8</text><rect x=\"392\" y=\"202\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useCallback toggleDone</text><rect x=\"30\" y=\"226\" width=\"220\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">useState(null)</text><line x1=\"252\" y1=\"236.0\" x2=\"368\" y2=\"236.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"368.0,236.0 360.5,239.2 360.5,232.8\" fill=\"var(--wire)\"></polygon><text x=\"386\" y=\"236\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">9</text><rect x=\"392\" y=\"226\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useState  openId</text><text x=\"520\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nove espaços, na ordem das chamadas</text></svg>", "caption": "Um hook próprio acrescenta os hooks dele à lista de quem o chama, onde é chamado."}
```

Duas regras para escrever um, ambas já conhecidas. **O nome começa com `use`**, que é como o linter
sabe que deve conferir as regras dos hooks dentro dele e nos lugares onde é chamado. **Ele devolve o
que quem chama precisa e mais nada**: o `usePlanner` não entrega o `setCourses`, porque nada lá fora
deve substituir a lista de cursos, e a aula 11 troca o miolo inteiro dele por uma biblioteca sem
mudar uma linha do `App`.
