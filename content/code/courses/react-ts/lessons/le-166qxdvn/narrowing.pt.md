---
title: Estreitando, uma vez e num lugar só
version: 1
---

**Conferir o discriminante estreita o tipo.** Dentro de `if (planner.status === 'ready')`, o TypeScript
sabe que o planejador é a forma pronta, e `planner.courses` é um `Course[]`. A pergunta é onde a
conferência fica, e a resposta que o planejador já tinha é o `Root`: ele só desenha as telas quando o
planejador está pronto. Então a conferência fica uma vez no `Root`, e mais uma num hook pequeno para as
telas que ele desenha, o `src/plannerContext.ts`:

```ts
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

// For the screens Root draws, which it draws only once the planner is ready.
export function useReadyPlanner() {
  const planner = usePlannerContext()
  if (planner.status !== 'ready') {
    throw new Error(`useReadyPlanner was called while the planner is ${planner.status}`)
  }
  return planner
}
```

**O `useReadyPlanner` estreita lançando.** Depois do `if`, a única forma que sobra é a `'ready'`, então o
que ele devolve tem `courses` e `sessions`, tipados. Se uma tela o chamasse antes de o `Root` conferir, o
erro diria isso na hora, em vez de uma tela desenhar em silêncio uma semana vazia.

O `LoadFailed` para de ler o contexto e recebe o que precisa como props, o `src/LoadFailed.tsx`:

```tsx
type LoadFailedProps = {
  retry: () => void
  retrying: boolean
}

export function LoadFailed({ retry, retrying }: LoadFailedProps) {
  return (
    <main>
      <h1>Study planner</h1>
      <div role="alert">
        <p>The planner could not be loaded. The server did not answer.</p>
      </div>
      <button type="button" onClick={() => retry()} disabled={retrying}>
        {retrying ? 'Trying again…' : 'Try again'}
      </button>
    </main>
  )
}
```

e o `Root` faz um `switch` no status, o `src/Root.tsx`:

```tsx
import { Outlet } from 'react-router'
import { LoadFailed } from './LoadFailed'
import { usePlannerContext } from './plannerContext'

// Every screen of the planner is drawn inside this one, where <Outlet /> is.
export function Root() {
  const planner = usePlannerContext()
  switch (planner.status) {
    case 'loading':
      return <p>Loading the planner…</p>
    case 'failed':
      return <LoadFailed retry={planner.retry} retrying={planner.retrying} />
    case 'ready':
      return (
        <main>
          <Outlet />
        </main>
      )
    default: {
      const unhandled: never = planner
      return unhandled
    }
  }
}
```

Em cada `case`, o planejador tem a forma daquele caso: `planner.retry` compila em `'failed'` e não
compilaria em `'loading'`. O `default` é o assunto da próxima seção. As telas trocam o import e a chamada:

```
ana@dev:~/planner$ sed -i 's/usePlannerContext/useReadyPlanner/g' src/WeekScreen.tsx src/CourseScreen.tsx && grep -n 'ReadyPlanner' src/WeekScreen.tsx src/CourseScreen.tsx
src/WeekScreen.tsx:2:import { useReadyPlanner } from './plannerContext'
src/WeekScreen.tsx:10:  const { courses, sessions } = useReadyPlanner()
src/CourseScreen.tsx:6:import { useReadyPlanner } from './plannerContext'
src/CourseScreen.tsx:12:  const { sessions, toggleDone } = useReadyPlanner()
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 75ms on 27 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 | grep -E 'Week of|minutes done'
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'wait 9000' | grep -E 'alert|paragraph|button'
  - alert:
    - paragraph: The planner could not be loaded. The server did not answer.
  - button "Try again"
```

O compilador fica satisfeito, o lint também, e o planejador se comporta como antes: a semana com os 80 de
195 minutos, e com a API parada, o alerta e o botão, agora desenhados a partir de props.
