---
title: A segunda tela, e onde mora o estado dela
version: 1
---

**O estado vai no componente mais próximo sob o qual estão todos os que o leem.** O planejador agora
precisa de mais dois pedaços: qual curso está aberto, e as próprias sessões, porque marcar uma como
feita muda os dados. Os dois são lidos pela primeira tela e pela segunda, então os dois vão no `App`,
acima das duas. Levar o estado para cima até um pai comum assim se chama **lifting state up**, e os
componentes de baixo o recebem como props e pedem mudanças por meio de funções, como o `WeekNav` já
faz.

O nome do curso vira um botão que o abre. O título do `Card` era uma string; ele passa a ser
qualquer `ReactNode`, para que um pai possa pôr um botão nele. Salve o `src/Card.tsx`:

```tsx
import type { ReactNode } from 'react'

type CardProps = {
  title: ReactNode
  children: ReactNode
}

export function Card({ title, children }: CardProps) {
  return (
    <article className="card">
      <h2>{title}</h2>
      {children}
    </article>
  )
}
```

O `src/CourseCard.tsx` monta o botão e o entrega ao `Card` como título. O botão chama `onOpen` com o
id do curso, e `onOpen` é uma prop nova:

```tsx
import { Card } from './Card'
import type { Course, Session } from './types'
import { minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
  onOpen: (id: string) => void
}

export function CourseCard({ course, sessions, onOpen }: CourseCardProps) {
  const count = sessions.length
  const title = (
    <button type="button" onClick={() => onOpen(course.id)}>
      {course.name}
    </button>
  )
  return (
    <Card title={title}>
      <p>
        {count} {count === 1 ? 'session' : 'sessions'} · {minutes(sessions)} min
      </p>
    </Card>
  )
}
```

O `src/CourseList.tsx` repassa o `onOpen` para cada cartão:

```tsx
import { CourseCard } from './CourseCard'
import type { Course, Session } from './types'

type CourseListProps = {
  courses: Course[]
  sessions: Session[]
  onOpen: (id: string) => void
}

export function CourseList({ courses, sessions, onOpen }: CourseListProps) {
  return (
    <section aria-label="Courses">
      {courses.map((course) => (
        <CourseCard
          key={course.id}
          course={course}
          sessions={sessions.filter((s) => s.course === course.id)}
          onOpen={onOpen}
        />
      ))}
    </section>
  )
}
```

A segunda tela é nova, `src/CourseScreen.tsx`. Ela lista as sessões de um curso em ordem de data,
cada uma com uma caixa de marcação, e um botão para voltar:

```tsx
import type { Course, Session } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  sessions: Session[]
  onToggle: (id: string) => void
  onBack: () => void
}

export function CourseScreen({ course, sessions, onToggle, onBack }: CourseScreenProps) {
  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  return (
    <>
      <button type="button" onClick={onBack}>
        Back to courses
      </button>
      <h1>{course.name}</h1>
      <ul>
        {sorted.map((s) => (
          <li key={s.id}>
            <label>
              <input type="checkbox" checked={s.done} onChange={() => onToggle(s.id)} />
              {formatDay(s.date)} · {s.minutes} min
            </label>
          </li>
        ))}
      </ul>
    </>
  )
}
```

O `[...sessions].sort(…)` copia o array antes de ordená-lo, porque o `sort` ordena no lugar e essas
sessões pertencem ao `App`. Cada caixa é **controlada**: o `checked` vem dos dados, e o `onChange`
pede ao `App` que mude os dados, então a caixa mostra o que o estado diz e mais nada. A aula 10 trata
de inputs desse tipo.

E o `App` guarda os três pedaços de estado e decide qual tela desenhar:

```tsx
import { useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import { courses, sessions as initialSessions } from './sample'
import { inWeek, mondayOf, today } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

function App() {
  const [monday, setMonday] = useState(() => mondayOf(today()))
  const [sessions, setSessions] = useState(initialSessions)
  const [openId, setOpenId] = useState<string | null>(null)

  function toggleDone(id: string) {
    setSessions((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }

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

O `sessions as initialSessions` renomeia o import, para que `sessions` possa ser o estado. O `openId`
é `string | null`, com `null` para "nenhum curso aberto", e o tipo precisa ser escrito porque o React
não consegue adivinhá-lo a partir de `null`. **Quando um curso está aberto, o `App` retorna cedo** com
a segunda tela, e nada da primeira é desenhado. O `toggleDone` usa a forma de função de duas seções
atrás, e monta um array novo com um objeto novo dentro; a próxima seção mostra por que precisa ser
assim.

```schooling-figure
{"svg": "<svg data-fig=\"lifted\" viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"O App guarda três pedaços de estado: monday, sessions e openId. Os valores descem como props para WeekNav, WeekSummary, CourseList e CourseScreen. Os pedidos de mudança voltam como chamadas de função: onChange do WeekNav, onOpen dos cartões, onToggle e onBack do CourseScreen. Os totais do WeekSummary são calculados a partir das props, não guardados.\"><rect x=\"220\" y=\"14\" width=\"280\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"38.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">App</text><text x=\"360.0\" y=\"53.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">monday · sessions · openId</text><rect x=\"20\" y=\"170\" width=\"155\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"97.5\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekNav</text><line x1=\"50\" y1=\"80\" x2=\"50\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"50.0,168.0 46.8,160.5 53.2,160.5\" fill=\"var(--phosphor)\"></polygon><line x1=\"145\" y1=\"168\" x2=\"145\" y2=\"80\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"145.0,80.0 148.2,87.5 141.8,87.5\" fill=\"var(--amber)\"></polygon><text x=\"139\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">onChange</text><rect x=\"195\" y=\"170\" width=\"155\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272.5\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekSummary</text><line x1=\"225\" y1=\"80\" x2=\"225\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"225.0,168.0 221.8,160.5 228.2,160.5\" fill=\"var(--phosphor)\"></polygon><rect x=\"370\" y=\"170\" width=\"155\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"447.5\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseList</text><line x1=\"400\" y1=\"80\" x2=\"400\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"400.0,168.0 396.8,160.5 403.2,160.5\" fill=\"var(--phosphor)\"></polygon><line x1=\"495\" y1=\"168\" x2=\"495\" y2=\"80\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"495.0,80.0 498.2,87.5 491.8,87.5\" fill=\"var(--amber)\"></polygon><text x=\"489\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">onOpen</text><rect x=\"545\" y=\"170\" width=\"155\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"622.5\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseScreen</text><line x1=\"575\" y1=\"80\" x2=\"575\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"575.0,168.0 571.8,160.5 578.2,160.5\" fill=\"var(--phosphor)\"></polygon><line x1=\"670\" y1=\"168\" x2=\"670\" y2=\"80\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"670.0,80.0 673.2,87.5 666.8,87.5\" fill=\"var(--amber)\"></polygon><text x=\"664\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">onToggle, onBack</text><text x=\"272\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">calcula os totais a partir das props</text><text x=\"20\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">para baixo: valores como props</text><text x=\"380\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">para cima: pedidos como chamadas</text></svg>", "caption": "Valores descem como props; pedidos de mudança sobem como chamadas."}
```

## Marcando uma sessão como feita

```
ana@dev:~/planner$ npx tsc -b && echo no errors
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 | sed -n 9,13p
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]:
        - button "Statistics"
      - paragraph: 2 sessions · 90 min
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics'
-- click button Statistics
- main:
  - button "Back to courses"
  - heading "Statistics" [level=1]
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | sed -n 6,13p
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 120 of 195 minutes done
  - region "Courses":
    - article:
```

O título do curso agora contém um botão, e o retrato mostra os dois. Na segunda tela, as duas sessões
de Statistics são caixas de marcação, com o nome tirado dos rótulos, e a do dia 19 já está feita. O
último `look` abre Statistics, marca o dia 21 e volta, e o resumo diz **120 de 195**: os 80 que havia,
mais os 40 recém-feitos. Ninguém mandou o resumo se atualizar. Ele calculou o total a partir de
`sessions`, e `sessions` tinha mudado.
