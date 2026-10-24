---
title: Queries, keys e o cache
version: 1
---

**Uma query é uma key e uma função que busca.** A biblioteca chama a função, guarda o que ela devolve
na key, e dá a todo componente que pede aquela key os mesmos dados. Instale na versão que este curso
usa:

```
ana@dev:~/planner$ npm install @tanstack/react-query@5.104.5

added 2 packages, and audited 37 packages in 681ms

14 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

O cache é um objeto só, um `QueryClient`, criado uma vez e passado para baixo por um provider, que vai
por fora do provider do próprio planejador, no `src/main.tsx`:

```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { PlannerProvider } from './PlannerProvider'

const queryClient = new QueryClient()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <PlannerProvider>
        <App />
      </PlannerProvider>
    </QueryClientProvider>
  </StrictMode>,
)
```

Depois o `usePlanner` para de buscar e passa a pedir. Este é ele inteiro agora:

```schooling-example
{"language": "typescript", "file": "src/usePlanner.ts", "parts": [{"code": "import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'\nimport type { Course, Session } from './types'\n", "note": "Os três hooks da biblioteca. Nada do próprio React é mais necessário: nem `useState`, nem `useEffect`."}, {"code": "export type NewSession = Pick<Session, 'course' | 'date' | 'minutes'>\ntype Planner = { courses: Course[]; sessions: Session[] }\ntype Status = 'loading' | 'ready' | 'failed'\n", "note": "A forma de uma sessão nova, como a aula 10 a tinha, e a forma do que a API responde."}, {"code": "async function request<T>(path: string, init?: RequestInit): Promise<T> {\n  const response = await fetch(path, { ...init, headers: { 'content-type': 'application/json' } })\n  if (!response.ok) throw new Error(`HTTP ${response.status} for ${path}`)\n  return response.json()\n}\n", "note": "Uma função pequena para toda requisição: ela manda JSON e transforma qualquer status que não seja 2xx num erro, que é o que diz à biblioteca que uma requisição falhou."}, {"code": "export function usePlanner() {\n  const queryClient = useQueryClient()\n  const planner = useQuery({\n    queryKey: ['planner'],\n    queryFn: () => request<Planner>('/api/planner'),\n  })\n  const refresh = () => queryClient.invalidateQueries({ queryKey: ['planner'] })\n", "note": "**O `useQuery` recebe a key e a função.** A key é um array, e `['planner']` dá nome a este dado em todo o app. O `refresh` diz ao cache que o que está naquela key está desatualizado."}, {"code": "  const toggle = useMutation({\n    mutationFn: (id: string) => {\n      const current = queryClient.getQueryData<Planner>(['planner'])\n      const session = current?.sessions.find((s) => s.id === id)\n      return request(`/api/sessions/${id}`, {\n        method: 'PATCH',\n        body: JSON.stringify({ done: !session?.done }),\n      })\n    },\n    onSuccess: refresh,\n  })\n  const add = useMutation({\n    mutationFn: (session: NewSession) =>\n      request('/api/sessions', { method: 'POST', body: JSON.stringify(session) }),\n    onSuccess: refresh,\n  })\n", "note": "Duas mutações, a palavra da biblioteca para uma requisição que muda algo. Cada uma chama a API e, quando dá certo, faz `refresh` do planejador. O toggle lê o `done` atual da sessão no cache, então não precisa de nada da renderização."}, {"code": "  const status: Status = planner.isPending ? 'loading' : planner.isError ? 'failed' : 'ready'\n  return {\n    status,\n    courses: planner.data?.courses ?? [],\n    sessions: planner.data?.sessions ?? [],\n    toggleDone: toggle.mutate,\n    addSession: add.mutate,\n  }\n}", "note": "As mesmas cinco coisas que o hook da aula 7 devolvia, então nenhum chamador muda. O `isPending` é true até a primeira resposta; o `mutate` é uma função estável, então os leitores do context podem contar com ela."}]}
```

O `App`, o `CourseScreen` e o formulário não mudaram, e a checagem de tipos e o linter concordam. A
página pede o planejador uma vez:

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 88ms on 18 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network | grep -E 'api|courses'
net  GET /api/planner  200
```

**Um `GET /api/planner`, mesmo com strict mode.** O efeito da aula 5 mandava dois, porque o strict
mode o rodava duas vezes e cada execução buscava. A query também rodou duas vezes, e na segunda
encontrou uma requisição da mesma key já em andamento e se juntou a ela. Qualquer número de componentes
pedindo `['planner']` ao mesmo tempo produz uma requisição.

O cache vive enquanto a página vive. Abra um curso e volte, e o planejador é desenhado do cache na
hora; a biblioteca também o busca de novo em segundo plano, porque por padrão ela trata toda resposta
como velha no momento em que chega. Esse padrão, `staleTime: 0`, é o seguro: ele nunca mostra dados
mais velhos que a última montagem ou o último foco sem conferir. Um app que sabe que os dados mudam
pouco põe um `staleTime` maior na query e economiza as requisições.
