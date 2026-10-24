---
title: Telas com endereço
version: 1
---

**O planejador do Vite tem duas telas e um endereço.** Desde a aula 4, qual tela aparece é um pedaço de
estado, `openId`, então um curso não pode ir para os favoritos, recarregar sempre cai na semana, e o botão
Voltar do navegador sai do planejador em vez de fechar o curso. Um **roteador** resolve os três fazendo do
endereço o estado: cada tela tem um caminho, e o roteador desenha a que o endereço nomeia.

O React não tem roteador próprio; o **React Router** é o que a maioria dos projetos React usa, e o que esta
aula instala:

```
ana@dev:~/planner$ npm install react-router@8.5.0

added 3 packages, and audited 40 packages in 961ms

14 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

A versão 8 tem um pacote para a web, `react-router`, com o `RouterProvider` em `react-router/dom`. Código
mais antigo importa de `react-router-dom`, um pacote que a versão 8 não tem mais. A biblioteca tem três
jeitos de ser usada, e esta aula usa o do meio, o **modo de dados**: as rotas são uma lista de objetos,
criada uma vez, e cada uma pode dizer o que carregar antes de ser desenhada.

O roteador é criado no `src/main.tsx`, e substitui o `<App />`:

```tsx
import { QueryClientProvider } from '@tanstack/react-query'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { createBrowserRouter } from 'react-router'
import { RouterProvider } from 'react-router/dom'
import './index.css'
import { courseLoader } from './courseLoader'
import { ErrorBoundary } from './ErrorBoundary'
import { PlannerProvider } from './PlannerProvider'
import { queryClient } from './queryClient'
import { Root } from './Root'
import { RouteError } from './RouteError'
import { WeekScreen } from './WeekScreen'

const router = createBrowserRouter([
  {
    path: '/',
    Component: Root,
    ErrorBoundary: RouteError,
    hydrateFallbackElement: <p>Loading the planner…</p>,
    children: [
      { index: true, Component: WeekScreen },
      {
        path: 'courses/:courseId',
        loader: courseLoader,
        lazy: async () => ({ Component: (await import('./CourseScreen')).CourseScreen }),
      },
    ],
  },
])

const crashed = (
  <main>
    <h1>Study planner</h1>
    <p role="alert">Something went wrong, and the planner stopped. Reload the page to start again.</p>
  </main>
)

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ErrorBoundary fallback={crashed}>
      <QueryClientProvider client={queryClient}>
        <PlannerProvider>
          <RouterProvider router={router} />
        </PlannerProvider>
      </QueryClientProvider>
    </ErrorBoundary>
  </StrictMode>,
)
```

Leia a lista como uma árvore. **A rota em `/` é um layout**: o `Component` dela, `Root`, é desenhado para
todo endereço abaixo de `/`, e os `children` são desenhados dentro dele. A **rota índice** é o filho da
própria `/`, a semana. **`courses/:courseId`** é a tela do curso, e `:courseId` é um parâmetro: combina
com qualquer segmento, `/courses/spanish` ou `/courses/statistics`, e o roteador entrega o valor à rota.
As outras propriedades, `loader`, `lazy`, `ErrorBoundary` e `hydrateFallbackElement`, são o assunto das
seções seguintes.

O `src/Root.tsx`, o layout:

```tsx
import { Outlet } from 'react-router'
import { LoadFailed } from './LoadFailed'
import { usePlannerContext } from './plannerContext'

// Every screen of the planner is drawn inside this one, where <Outlet /> is.
export function Root() {
  const { status } = usePlannerContext()
  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <LoadFailed />
  return (
    <main>
      <Outlet />
    </main>
  )
}
```

**`<Outlet />` é onde o filho correspondente é desenhado.** As telas de carregamento e de falha que o
`App` tinha vêm para cá, para toda tela esperar o planejador do mesmo jeito. A tela da semana é o que
sobra do `App`, então o arquivo é renomeado:

```
ana@dev:~/planner$ mv src/App.tsx src/WeekScreen.tsx
```

e perde o estado do curso aberto, com as telas de carregamento e o `<main>`:

```tsx
import { CourseList } from './CourseList'
import { usePlannerContext } from './plannerContext'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

export function WeekScreen() {
  const [monday, setMonday] = useWeek()
  const { courses, sessions } = usePlannerContext()

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList key={monday} courses={courses} sessions={thisWeek} />
    </>
  )
}
```

A lista não passa mais um `onOpen` para baixo, `src/CourseList.tsx`:

```tsx
import { Card } from './Card'
import { CourseCard } from './CourseCard'
import { ErrorBoundary } from './ErrorBoundary'
import type { Course, Session } from './types'

type CourseListProps = {
  courses: Course[]
  sessions: Session[]
}

export function CourseList({ courses, sessions }: CourseListProps) {
  return (
    <section aria-label="Courses">
      {courses.map((course) => (
        <ErrorBoundary
          key={course.id}
          fallback={
            <Card title={course.name}>
              <p>This course could not be shown.</p>
            </Card>
          }
        >
          <CourseCard course={course} sessions={sessions.filter((s) => s.course === course.id)} />
        </ErrorBoundary>
      ))}
    </section>
  )
}
```

e o título de cada cartão vira um **link**, `src/CourseCard.tsx`:

```tsx
import { Link } from 'react-router'
import { Card } from './Card'
import type { Course, Session } from './types'
import { formatDay, minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
}

export function CourseCard({ course, sessions }: CourseCardProps) {
  const count = sessions.length
  const next = sessions.find((s) => !s.done)
  return (
    <Card title={<Link to={`/courses/${course.id}`}>{course.name}</Link>}>
      <p>
        {count} {count === 1 ? 'session' : 'sessions'} · {minutes(sessions)} min
      </p>
      <p>{next ? `Next: ${formatDay(next.date)}` : 'Nothing left this week'}</p>
    </Card>
  )
}
```

O `<Link to>` desenha um `<a href>` comum, então um link pode ser aberto numa aba nova, copiado ou ir
para os favoritos como qualquer outro. Clicado normalmente, o roteador muda o endereço com a API de
histórico do navegador e desenha a tela nova, sem pedir uma página ao servidor.

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 82ms on 27 files with 116 rules using 4 threads.
no errors
```

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 | sed -n '/region "Courses"/,$p' | head -n 8
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]:
        - link "Statistics":
          - /url: /courses/statistics
      - paragraph: 2 sessions · 90 min
      - paragraph: "Next: Wed 21 Oct"
    - article:
```

O nome do curso agora é um link, `/url: /courses/statistics`. A próxima seção faz esse endereço funcionar
sozinho.
