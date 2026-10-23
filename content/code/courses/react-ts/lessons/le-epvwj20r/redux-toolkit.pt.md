---
title: Redux Toolkit: ações, reducers e um store
version: 1
---

**O Redux guarda todo o estado compartilhado do app num store só, e o muda apenas despachando ações
que funções puras, os reducers, transformam no estado seguinte.** É a mais antiga das três e a que um
emprego com React tem mais chance de já ter, quase sempre pelo Redux Toolkit, o jeito oficial de
escrevê-lo hoje. Também é a que pede mais escrita:

```
ana@dev:~$ cp -a planner planner-redux
ana@dev:~/planner-redux$ npm install @reduxjs/toolkit@2.13.0 react-redux@9.3.0

added 11 packages, and audited 41 packages in 912ms

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner-redux$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 28ms on 16 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner-redux$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep minutes
    - paragraph: 120 of 195 minutes done
```

Dois pacotes, `@reduxjs/toolkit` na 2.13.0 e `react-redux` na 9.3.0, e o store, `src/store.ts`:

```typescript
import { configureStore, createAsyncThunk, createSlice, type PayloadAction } from '@reduxjs/toolkit'
import { useDispatch, useSelector } from 'react-redux'
import type { Course, Session } from './types'

type PlannerState = {
  status: 'loading' | 'ready' | 'failed'
  courses: Course[]
  sessions: Session[]
}

export const load = createAsyncThunk('planner/load', async () => {
  const response = await fetch('/courses.json')
  if (!response.ok) throw new Error(`HTTP ${response.status}`)
  return (await response.json()) as { courses: Course[]; sessions: Session[] }
})

const planner = createSlice({
  name: 'planner',
  initialState: { status: 'loading', courses: [], sessions: [] } as PlannerState,
  reducers: {
    toggleDone(state, action: PayloadAction<string>) {
      const session = state.sessions.find((s) => s.id === action.payload)
      if (session) session.done = !session.done
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(load.fulfilled, (state, action) => {
        state.status = 'ready'
        state.courses = action.payload.courses
        state.sessions = action.payload.sessions
      })
      .addCase(load.rejected, (state, action) => {
        console.error('could not load the planner:', action.error.message)
        state.status = 'failed'
      })
  },
})

export const { toggleDone } = planner.actions
export const store = configureStore({ reducer: { planner: planner.reducer } })

type RootState = ReturnType<typeof store.getState>
export const useAppDispatch = useDispatch.withTypes<typeof store.dispatch>()
export const useAppSelector = useSelector.withTypes<RootState>()
```

- **`createAsyncThunk`** envolve a busca, e despachá-lo produz ações de início, sucesso e falha, que os
  `extraReducers` da slice transformam em estado.
- **`createSlice`** guarda a forma do estado e os reducers, e gera um criador de ação para cada um:
  aqui, o `toggleDone`.
- **O reducer muda `session.done` no lugar**, o que a aula 4 chamou de erro. No Redux Toolkit não é: o
  reducer recebe um rascunho do Immer, uma biblioteca que registra as mudanças feitas no rascunho e
  produz um objeto novo com elas aplicadas. O estado que você recebe continua sendo um objeto novo,
  como a aula 4 exige; a mutação é só a sintaxe. Funciona dentro do `createSlice` e em nenhum outro
  lugar.
- **`withTypes`** cria versões tipadas dos dois hooks, para que todo seletor conheça a forma do
  estado.

Aqui o provider é de verdade, o `<Provider>` do Redux, e ele despacha a carga:

```tsx
import { useEffect, type ReactNode } from 'react'
import { Provider } from 'react-redux'
import { load, store } from './store'

export function PlannerProvider({ children }: { children: ReactNode }) {
  useEffect(() => {
    store.dispatch(load())
  }, [])
  return <Provider store={store}>{children}</Provider>
}
```

```typescript
import { useCallback } from 'react'
import { toggleDone, useAppDispatch, useAppSelector } from './store'

export function usePlannerContext() {
  const { status, courses, sessions } = useAppSelector((state) => state.planner)
  const dispatch = useAppDispatch()
  const toggle = useCallback((id: string) => dispatch(toggleDone(id)), [dispatch])
  return { status, courses, sessions, toggleDone: toggle }
}
```

O `useAppSelector` se inscreve numa fatia do store, renderizando de novo só quando ela muda; ele
devolve `state.planner`, a slice inteira, que muda quando qualquer campo dela muda. A função de
despacho é envolvida no `useCallback` da aula 7 para que quem chama receba um `toggleDone` estável. O
resultado são os mesmos 120, a partir de quarenta e cinco linhas de store.
