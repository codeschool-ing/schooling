---
title: Uma saída quando o servidor não responde
version: 1
---

**Uma reserva vale o que deixa o usuário fazer em seguida.** A aula 11 deixou o planejador, quando o
servidor não respondia, numa frase só: *The planner could not be loaded*. Verdade, e um beco sem saída.
Uma requisição que falhou é o caso em que tentar de novo pode dar certo, porque o servidor pode voltar
um momento depois, então este é o lugar de um botão.

A query já sabe tentar de novo: o `useQuery` devolve `refetch`, que roda a requisição de novo, com as
novas tentativas, e `isFetching`, que é true enquanto ela roda. O `usePlanner` repassa os dois, como
`retry` e `retrying`:

```ts
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import type { Course, Session } from './types'

export type NewSession = Pick<Session, 'course' | 'date' | 'minutes'>
type Planner = { courses: Course[]; sessions: Session[] }
type Status = 'loading' | 'ready' | 'failed'

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(path, { ...init, headers: { 'content-type': 'application/json' } })
  if (!response.ok) throw new Error(`HTTP ${response.status} for ${path}`)
  return response.json()
}

export function usePlanner() {
  const queryClient = useQueryClient()
  const planner = useQuery({
    queryKey: ['planner'],
    queryFn: () => request<Planner>('/api/planner'),
  })
  const refresh = () => queryClient.invalidateQueries({ queryKey: ['planner'] })

  const toggle = useMutation({
    mutationFn: (id: string) => {
      const current = queryClient.getQueryData<Planner>(['planner'])
      const session = current?.sessions.find((s) => s.id === id)
      return request(`/api/sessions/${id}`, {
        method: 'PATCH',
        body: JSON.stringify({ done: !session?.done }),
      })
    },
    onSuccess: refresh,
  })
  const add = useMutation({
    mutationFn: (session: NewSession) =>
      request('/api/sessions', { method: 'POST', body: JSON.stringify(session) }),
    onSuccess: refresh,
  })

  const status: Status = planner.isPending ? 'loading' : planner.isError ? 'failed' : 'ready'
  return {
    status,
    retrying: planner.isFetching,
    retry: planner.refetch,
    courses: planner.data?.courses ?? [],
    sessions: planner.data?.sessions ?? [],
    toggleDone: toggle.mutate,
    addSession: add.mutate,
  }
}
```

A tela da falha é um componente próprio, o `src/LoadFailed.tsx`:

```tsx
import { usePlannerContext } from './plannerContext'

export function LoadFailed() {
  const { retry, retrying } = usePlannerContext()
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

- A frase diz o que aconteceu com palavras sobre as quais o usuário pode agir. *The server did not
  answer* diz que o problema não está do lado dele, e é a única coisa que este código sabe com certeza.
- O `role="alert"` fica na mensagem e não no botão, para um leitor de tela anunciar a frase quando ela
  aparece e não ler um botão como parte de um anúncio.
- Enquanto a requisição roda, o botão diz *Trying again…* e fica desabilitado, então um segundo clique
  não começa uma segunda requisição, e o usuário vê que algo está acontecendo.
- `onClick={() => retry()}` e não `onClick={retry}`: a arrow function impede que o evento de clique
  seja passado ao `refetch`, que recebe um objeto de opções como argumento.

O `App.tsx` muda em dois lugares, o import e a linha que desenhava o alerta, e dois comandos `sed`
fazem os dois. O `head` mostra o resultado:

```
ana@dev:~/planner$ sed -i 's|return <p role="alert">The planner could not be loaded.</p>|return <LoadFailed />|' src/App.tsx && sed -i "3a import { LoadFailed } from './LoadFailed'" src/App.tsx && head -n 18 src/App.tsx
import { useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import { LoadFailed } from './LoadFailed'
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
  if (status === 'failed') return <LoadFailed />
```

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 57ms on 20 files with 116 rules using 4 threads.
no errors
```

Pare o servidor da API e abra a página:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'wait 9000'
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
-- wait 9000
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
- main:
  - heading "Study planner" [level=1]
  - alert:
    - paragraph: The planner could not be loaded. The server did not answer.
  - button "Try again"
```

As quatro tentativas da aula 11, e depois a tela nova, com a frase dentro do alerta e o botão depois
dele. Agora a sequência inteira: a mesma página, com o servidor da API iniciado de novo doze segundos
depois de a página abrir, enquanto o alerta está na tela, e então o botão apertado:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network --do 'wait 9000' --do 'wait 4000' --do 'click button Try again' | grep -E 'api|^-- |alert|Try|paragraph'
net  GET /api/planner  502
-- wait 9000
net  GET /api/planner  502
net  GET /api/planner  502
net  GET /api/planner  502
-- wait 4000
-- click button Try again
net  GET /api/planner  200
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
      - paragraph: 2 sessions · 90 min
      - paragraph: "Next: Wed 21 Oct"
      - paragraph: 2 sessions · 60 min
      - paragraph: "Next: Fri 23 Oct"
      - paragraph: 1 session · 45 min
      - paragraph: "Next: Thu 22 Oct"
```

Quatro `502` enquanto o servidor estava fora, depois nada até o clique, depois **um `200` e o
planejador inteiro**. O usuário não recarregou nada, não perdeu nada e não precisou saber o que é
recarregar.

Esta falha não é assunto de error boundary, e vale manter a diferença clara. Uma requisição que falha é
um evento esperado: a query a relata como `isError`, e o componente que pediu desenha a tela para ela.
Um boundary é para o que ninguém esperava, uma exceção no meio de uma renderização. O React Query pode
ser instruído a lançar os erros no boundary mais próximo, com a opção `throwOnError`, e alguns projetos
preferem um lugar só para toda falha; mas aí a reserva do boundary é a tela que precisa do botão de
tentar de novo, e ela também precisa saber como reiniciar a query.
