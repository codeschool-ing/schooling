---
title: Jotai: estado em pedaços pequenos
version: 1
---

**O Jotai monta o estado compartilhado a partir de átomos, cada um um valor único com os próprios
inscritos.** Onde o Zustand e o Redux guardam um store e selecionam fatias dele, o Jotai começa pelas
fatias: um componente que lê um átomo renderiza quando esse átomo muda e em nenhum outro momento. É o
`useState` tornado compartilhável, e serve a apps cujo estado compartilhado são muitos valores
independentes.

```
ana@dev:~$ cp -a planner planner-jotai
ana@dev:~/planner-jotai$ npm install jotai@3.0.1

added 2 packages, and audited 32 packages in 646ms

10 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner-jotai$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 39ms on 16 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner-jotai$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep minutes
    - paragraph: 120 of 195 minutes done
```

O `jotai` na 3.0.1. Os átomos, `src/atoms.ts`:

```typescript
import { atom } from 'jotai'
import type { Course, Session } from './types'

export const statusAtom = atom<'loading' | 'ready' | 'failed'>('loading')
export const coursesAtom = atom<Course[]>([])
export const sessionsAtom = atom<Session[]>([])

export const toggleDoneAtom = atom(null, (_get, set, id: string) => {
  set(sessionsAtom, (all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
})
```

Três átomos guardam valores, cada um tipado com o valor que guarda. **O `toggleDoneAtom` não guarda
nada**: um átomo feito com `null` e uma função de escrita é uma ação, e escrever nele atualiza o
`sessionsAtom` com o `map` da aula 4. Átomos são definições; os valores moram num store que o Jotai
mantém, e por padrão um store serve o app inteiro, então nenhum provider é necessário. O do
planejador ainda carrega os dados:

```tsx
import { useSetAtom } from 'jotai'
import { useEffect, type ReactNode } from 'react'
import { coursesAtom, sessionsAtom, statusAtom } from './atoms'
import type { Course, Session } from './types'

// Atoms live in Jotai's default store, so no provider is needed; this one
// only starts the first load.
export function PlannerProvider({ children }: { children: ReactNode }) {
  const setStatus = useSetAtom(statusAtom)
  const setCourses = useSetAtom(coursesAtom)
  const setSessions = useSetAtom(sessionsAtom)
  useEffect(() => {
    fetch('/courses.json')
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json()
      })
      .then((data: { courses: Course[]; sessions: Session[] }) => {
        setCourses(data.courses)
        setSessions(data.sessions)
        setStatus('ready')
      })
      .catch((error) => {
        console.error('could not load the planner:', error.message)
        setStatus('failed')
      })
  }, [setStatus, setCourses, setSessions])
  return children
}
```

```typescript
import { useAtomValue, useSetAtom } from 'jotai'
import { coursesAtom, sessionsAtom, statusAtom, toggleDoneAtom } from './atoms'

export function usePlannerContext() {
  return {
    status: useAtomValue(statusAtom),
    courses: useAtomValue(coursesAtom),
    sessions: useAtomValue(sessionsAtom),
    toggleDone: useSetAtom(toggleDoneAtom),
  }
}
```

O `useAtomValue` lê um átomo e se inscreve nele; o `useSetAtom` devolve só a função que o escreve, e
um componente que só escreve não renderiza quando o átomo muda. A carga foi para o provider como a
busca da aula 5, escrita contra três setters. Os mesmos 120.
