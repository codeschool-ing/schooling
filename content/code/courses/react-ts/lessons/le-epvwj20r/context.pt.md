---
title: Context: um valor que qualquer componente abaixo consegue ler
version: 1
---

**O context deixa um componente disponibilizar um valor para tudo abaixo dele na árvore, sem
passá-lo pelos componentes do meio.** Três peças: um objeto de context, um provider que põe um valor
nele para uma subárvore, e um hook que lê o valor do provider mais próximo. O React 19 deixou duas
delas mais curtas do que os tutoriais antigos mostram.

O context e o hook vão num arquivo sem componentes, `src/plannerContext.ts`:

```typescript
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
```

- **`createContext<Planner | null>(null)`** cria o objeto de context. O argumento é o valor que um
  componente lê quando não há provider acima dele, e `null` aqui quer dizer "sem planejador", o que o
  hook transforma em erro.
- **`ReturnType<typeof usePlanner>`** dá nome ao tipo do que o `usePlanner` devolve, então o tipo do
  context acompanha o do hook sem ser escrito duas vezes. `import type` basta, porque só o tipo é
  usado.
- **`use(PlannerContext)`** o lê. O `use` é do React 19; `useContext(PlannerContext)` faz o mesmo e é
  o que a maior parte do código escrito antes de 2025 diz.

O provider é um componente, então ganha um arquivo próprio, `src/PlannerProvider.tsx`:

```tsx
import type { ReactNode } from 'react'
import { PlannerContext } from './plannerContext'
import { usePlanner } from './usePlanner'

export function PlannerProvider({ children }: { children: ReactNode }) {
  const planner = usePlanner()
  return <PlannerContext value={planner}>{children}</PlannerContext>
}
```

**`<PlannerContext value={…}>` é o provider**; antes do React 19 ele era escrito
`<PlannerContext.Provider value={…}>`, o que ainda funciona. O `PlannerProvider` chama o `usePlanner`
uma vez e põe o que ele devolve no context para tudo lá dentro. Ele vai em volta do `App`, no
`src/main.tsx`:

```tsx
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
```

Dois arquivos em vez de um, porque a regra `only-export-components` do linter avisa sobre um arquivo
que exporta um componente e mais alguma coisa: o fast refresh do Vite, que troca um componente editado
na página que está rodando, só consegue fazer isso num arquivo que não exporta nada além de
componentes. Um arquivo por tipo mantém o aviso longe e o fast refresh funcionando.

## Lendo

O `CourseScreen` deixa de receber as sessões e o `onToggle`, e lê os dois do context; ele filtra as
sessões do próprio curso, já que ninguém mais as entrega:

```tsx
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
```

E o `App` lê o planejador do mesmo jeito, então o `usePlanner` é chamado num lugar só, o provider:

```tsx
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
```

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 68ms on 15 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep minutes
    - paragraph: 120 of 195 minutes done
```

Limpo, e o planejador se comporta como antes. O erro do hook é o motivo de ele conferir o `null`:
renderize o `App` sem o provider, o que o `sed` faz apagando as duas linhas que o abrem e fecham, e o
hook diz exatamente o que está errado em vez de falhar depois com `undefined`:

```
ana@dev:~/planner$ cp src/main.tsx /tmp/main.tsx
ana@dev:~/planner$ sed -i '/PlannerProvider>$/d' src/main.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 2>&1 | grep -m 1 '^Uncaught'
Uncaught Error: usePlannerContext must be called inside <PlannerProvider>
ana@dev:~/planner$ cp /tmp/main.tsx src/main.tsx
```
