---
title: Zustand: um store e um hook
version: 1
---

**O Zustand é um store fora do React, criado com uma função, e lido com um hook que recebe um
seletor.** É a menor das três bibliotecas aqui, e a que este curso escolheria para o planejador se ele
precisasse de uma. Para compará-las com justiça, cada biblioteca ganha uma cópia própria do
planejador, feita a partir do projeto como está agora, e substitui os mesmos dois arquivos. Zustand
primeiro:

```
ana@dev:~$ cp -a planner planner-zustand
ana@dev:~/planner-zustand$ npm install zustand@5.0.16

added 2 packages, and audited 32 packages in 739ms

10 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner-zustand$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 65ms on 16 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner-zustand$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep minutes
    - paragraph: 120 of 195 minutes done
```

A cópia instalou o `zustand` na 5.0.16, fixado pelo `.npmrc` do projeto, e o planejador ficou igual
exceto por três arquivos. O store, `src/store.ts`:

```typescript
import { create } from 'zustand'
import type { Course, Session } from './types'

type PlannerStore = {
  status: 'loading' | 'ready' | 'failed'
  courses: Course[]
  sessions: Session[]
  load: () => Promise<void>
  toggleDone: (id: string) => void
}

export const usePlannerStore = create<PlannerStore>()((set) => ({
  status: 'loading',
  courses: [],
  sessions: [],
  load: async () => {
    try {
      const response = await fetch('/courses.json')
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const data: { courses: Course[]; sessions: Session[] } = await response.json()
      set({ status: 'ready', courses: data.courses, sessions: data.sessions })
    } catch (error) {
      console.error('could not load the planner:', (error as Error).message)
      set({ status: 'failed' })
    }
  },
  toggleDone: (id) =>
    set((state) => ({
      sessions: state.sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s)),
    })),
}))
```

O `create` recebe uma função que recebe o `set` e devolve o estado inicial, com as ações que o mudam
ao lado dos dados. **O `set` mescla o que você lhe dá no estado**, então o `toggleDone` devolve só
`sessions`, montado com o `map` da aula 4: o Zustand também compara com `Object.is`, então a regra de
substituir em vez de mutar é a mesma. O `load` é uma função assíncrona comum que chama o `set` quando
os dados chegam.

O store não precisa de provider, porque é um objeto no nível do módulo; o `src/PlannerProvider.tsx`
mantém o nome só para iniciar a primeira carga:

```tsx
import { useEffect, type ReactNode } from 'react'
import { usePlannerStore } from './store'

// The store needs no provider; this one only starts the first load.
export function PlannerProvider({ children }: { children: ReactNode }) {
  useEffect(() => {
    usePlannerStore.getState().load()
  }, [])
  return children
}
```

E o `src/plannerContext.ts` lê o store com um seletor:

```typescript
import { useShallow } from 'zustand/shallow'
import { usePlannerStore } from './store'

export function usePlannerContext() {
  return usePlannerStore(
    useShallow((state) => ({
      status: state.status,
      courses: state.courses,
      sessions: state.sessions,
      toggleDone: state.toggleDone,
    })),
  )
}
```

**O seletor é o ponto.** `usePlannerStore((state) => state.status)` renderizaria o componente de novo
só quando `status` mudasse. Este hook devolve quatro valores de uma vez, então monta um objeto novo a
cada chamada, e o `useShallow` compara esse objeto campo a campo em vez de por identidade; sem ele,
toda mudança no store pareceria uma mudança para este componente. O `App` e o `CourseScreen` não
mudaram nada, e marcar uma sessão dá os mesmos 120.
