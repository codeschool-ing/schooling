---
title: Pondo os dados em cache, e o que isso custa
version: 1
---

**`'use cache'` no topo de uma função guarda em cache o que ela devolve**, e com o Cache Components é o
jeito de dizer que um dado pode ser reaproveitado. O `lib/planner.ts`:

```ts
import { cacheLife, cacheTag } from 'next/cache'
import type { Course, Session } from './types'

export type Planner = { courses: Course[]; sessions: Session[] }

// Asks the planner's API, from lesson 11, for everything it holds. The answer
// is cached, tagged 'planner', so that a change can say it is out of date.
export async function getPlanner(): Promise<Planner> {
  'use cache'
  cacheTag('planner')
  cacheLife('hours')
  const response = await fetch('http://localhost:3001/api/planner')
  if (!response.ok) throw new Error(`HTTP ${response.status} from the planner API`)
  return response.json()
}
```

- **`'use cache'`** dentro da função guarda o resultado dela. Os argumentos, aqui nenhum, fazem parte da
  chave, então uma função com argumento guarda uma entrada por valor.
- **`cacheTag('planner')`** dá nome à entrada, para que uma mudança possa marcá-la como velha pelo nome. A
  próxima seção faz isso.
- **`cacheLife('hours')`** diz por quanto tempo ela pode ser reaproveitada. O perfil `hours`, da tabela do
  próprio Next.js, serve a entrada por até uma hora, depois a busca de novo ao fundo, e a descarta depois
  de um dia sem uso.

A página do curso agora pode ser feita antes para cada curso, se o build souber quais cursos existem. O
`generateStaticParams` conta a ele, e um `sed` o põe acima do componente da página:

```
ana@dev:~/planner-next$ sed -i '/^export default async function CoursePage/i export async function generateStaticParams() {\n  const { courses } = await getPlanner()\n  return courses.map((c) => ({ courseId: c.id }))\n}\n' 'app/courses/[courseId]/page.tsx' && sed -n '1,12p' 'app/courses/[courseId]/page.tsx'
import Link from 'next/link'
import { notFound } from 'next/navigation'
import { getPlanner } from '@/lib/planner'
import { formatDay, minutes } from '@/lib/week'

export async function generateStaticParams() {
  const { courses } = await getPlanner()
  return courses.map((c) => ({ courseId: c.id }))
}

export default async function CoursePage({ params }: PageProps<'/courses/[courseId]'>) {
  const { courseId } = await params
ana@dev:~/planner-next$ npm run build | sed -n "/^Route/,\$p"
Route (app)
┌ ◐ /
├ ○ /_not-found
└   /courses/[courseId]
  ├ ◐ /courses/[courseId]
  ├ ○ /courses/statistics
  ├ ○ /courses/spanish
  └ ○ /courses/chemistry


○  (Static)             prerendered as static content
◐  (Partial Prerender)  prerendered as static HTML with dynamic server-streamed content
```

**Três páginas estáticas novas**, `○ /courses/statistics`, `spanish` e `chemistry`: o build chamou o
`generateStaticParams`, renderizou cada curso com o planejador em cache e gravou o resultado num arquivo.
`/courses/[courseId]` continua sendo prerender parcial, para um curso acrescentado depois do build:
`latin` ainda seria procurado a cada requisição, e ainda não acharia nada.

O que isso custa é o assunto desta seção inteira. Inicie o servidor de produção, leia a página de
química, mude os dados **pelas costas do Next.js**, com `curl` direto na API, e leia a página de novo:

```
ana@dev:~/planner-next$ curl -s http://localhost:3000/courses/chemistry | sed 's/<!-- -->//g' | grep -o '[0-9]* of [0-9]* minutes done'
60 of 105 minutes done
ana@dev:~/planner-next$ curl -s -X PATCH http://localhost:3001/api/sessions/s6 -H 'content-type: application/json' -d '{"done":true}'; echo
{"id":"s6","course":"chemistry","date":"2026-10-22","minutes":45,"done":true}
ana@dev:~/planner-next$ curl -s http://localhost:3000/courses/chemistry | sed 's/<!-- -->//g' | grep -o '[0-9]* of [0-9]* minutes done'
60 of 105 minutes done
```

**60 de 105, antes e depois.** A API diz que a sessão de quinta está feita, e a página não: ela foi feita
a partir do planejador em cache, e a entrada ainda tem uma hora de vida. Nada está quebrado; é o cache
fazendo o que mandaram. Todo cache é uma promessa de que uma resposta um pouco velha é aceitável, e o
`cacheLife` é quanto tempo é "um pouco". Para a mudança de outra pessoa, uma hora pode servir. Para a
sua, não serve, e a próxima seção mostra por quê.
