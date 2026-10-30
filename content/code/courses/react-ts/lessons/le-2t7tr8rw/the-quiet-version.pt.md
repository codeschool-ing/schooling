---
title: A versão que não quebra
version: 1
---

**O mesmo erro num componente com um hook só não quebra. Ele perde estado, em silêncio.** Isso é
pior, porque nada avisa. Aqui está um `WeekSummary` que aprendeu uma coisa nova: um botão que troca a
segunda linha entre os minutos feitos e os minutos que faltam. Ele também retorna cedo quando a
semana está vazia, e o único hook dele está depois desse `return`:

```tsx
import { useState } from 'react'
import type { Session } from './types'
import { formatWeek, minutes } from './week'

type WeekSummaryProps = {
  monday: string
  sessions: Session[]
}

// A mistake, on purpose: a hook after an early return.
export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
  if (sessions.length === 0) {
    return <p>Nothing planned in the week of {formatWeek(monday)}.</p>
  }
  const [showLeft, setShowLeft] = useState(false)
  const planned = minutes(sessions)
  const done = minutes(sessions.filter((s) => s.done))
  return (
    <section aria-label="This week">
      <p>Week of {formatWeek(monday)}</p>
      <p>{showLeft ? `${planned - done} minutes left` : `${done} of ${planned} minutes done`}</p>
      <button type="button" onClick={() => setShowLeft(!showLeft)}>
        {showLeft ? 'Show minutes done' : 'Show minutes left'}
      </button>
    </section>
  )
}
```

```
ana@dev:~/planner$ npx tsc -b && echo no errors
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Show minutes left' | sed -n 6,10p
    - button "Next week"
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 115 minutes left
    - button "Show minutes done"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Next week' | sed -n 6,8p
    - button "Next week"
  - paragraph: Nothing planned in the week of 26 Oct 2026.
  - region "Courses":
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Show minutes left' --do 'click button Next week' --do 'click button Previous week' | grep minutes
-- click button Show minutes left
    - paragraph: 80 of 195 minutes done
    - button "Show minutes left"
```

Toda transcrição parece certa. O botão troca para "115 minutes left", e uma semana vazia desenha a
frase dela. **A última é o bug.** Aperte "Show minutes left", vá para a semana vazia e volte, e o
resumo esqueceu: "80 of 195 minutes done", com o botão oferecendo "Show minutes left" de novo.

O que aconteceu é o argumento da ordem de duas seções atrás, na beirada. Na semana vazia o
`WeekSummary` não chamou hook nenhum, então o React jogou fora o único espaço dele; de volta a uma
semana cheia ele chamou um hook, e o React, vendo um componente sem espaços, criou um novo com o valor
inicial, `false`. Nenhum hook estava no lugar errado, então não havia o que detectar nem erro. Um
componente com dois hooks ou mais, um de cada lado do `return`, leva a quebra da seção anterior.

O linter não se engana com nenhum dos dois:

```
ana@dev:~/planner$ npm run lint

> planner@0.0.0 lint
> oxlint


  x react-hooks(rules-of-hooks): React Hook "useState" is called conditionally. React Hooks must be called in the exact same order in every component render.
    ,-[src/WeekSummary.tsx:15:35]
 14 |   }
 15 |   const [showLeft, setShowLeft] = useState(false)
    :                                   ^^^^^^^|^^^^^^^
    :                                          `-- This Hook call is not reachable on every render path.
 16 |   const planned = minutes(sessions)
    `----
  help: Move the Hook call before the condition, or call it unconditionally and branch inside the Hook/effect instead.

Found 0 warnings and 1 error.
Finished in 77ms on 11 files with 116 rules using 4 threads.
```

"This Hook call is not reachable on every render path." Levar o `useState` para cima do `if` é a
correção inteira, e a ordem se mantém qualquer que seja a semana:

```tsx
import { useState } from 'react'
import type { Session } from './types'
import { formatWeek, minutes } from './week'

type WeekSummaryProps = {
  monday: string
  sessions: Session[]
}

export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
  const [showLeft, setShowLeft] = useState(false)
  if (sessions.length === 0) {
    return <p>Nothing planned in the week of {formatWeek(monday)}.</p>
  }
  const planned = minutes(sessions)
  const done = minutes(sessions.filter((s) => s.done))
  return (
    <section aria-label="This week">
      <p>Week of {formatWeek(monday)}</p>
      <p>{showLeft ? `${planned - done} minutes left` : `${done} of ${planned} minutes done`}</p>
      <button type="button" onClick={() => setShowLeft(!showLeft)}>
        {showLeft ? 'Show minutes done' : 'Show minutes left'}
      </button>
    </section>
  )
}
```

```
ana@dev:~/planner$ npm run lint

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 28ms on 11 files with 116 rules using 4 threads.
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Next week' | sed -n 6,8p
    - button "Next week"
  - paragraph: Nothing planned in the week of 26 Oct 2026.
  - region "Courses":
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Show minutes left' --do 'click button Next week' --do 'click button Previous week' | grep minutes
-- click button Show minutes left
    - paragraph: 115 minutes left
    - button "Show minutes done"
```

O linter está limpo, a semana vazia ainda desenha a frase, e a última transcrição é a que falhava
antes: **"115 minutes left"** depois da ida e volta, porque o hook foi chamado em todas as semanas e
o espaço dele nunca foi jogado fora. Esta versão também não fica. As telas do planejador são fixas
entre os quatro cursos de framework, e a aula 1 desenhou esta sem o botão, então os comandos no fim
da próxima seção põem de volta o `WeekSummary` da aula 5.
