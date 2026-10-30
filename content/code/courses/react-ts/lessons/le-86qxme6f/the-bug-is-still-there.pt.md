---
title: O defeito continua lá
version: 1
---

**Um boundary decide como uma falha aparece. Ele não faz a falha sumir**, e o cartão de estatística
continua falhando toda vez que alguém termina uma semana. A correção é no `CourseCard`, e começa tirando
o `!`, o único caractere que pedia ao compilador para não conferir:

```
ana@dev:~/planner$ sed -i 's/(s) => !s.done)!/(s) => !s.done)/' src/CourseCard.tsx && npx tsc -b
src/CourseCard.tsx(24,27): error TS18048: 'next' is possibly 'undefined'.
```

**TS18048: `'next' is possibly 'undefined'`.** Sem o `!`, o TypeScript volta a saber o que o `find`
devolve, e aponta a linha que derrubou a página, antes de qualquer coisa rodar. Esse é o erro que o
`!` tinha calado. A pergunta que ele faz é real: o que o cartão deve dizer quando a semana não tem mais
nada? Responda no cartão:

```tsx
import { Card } from './Card'
import type { Course, Session } from './types'
import { formatDay, minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
  onOpen: (id: string) => void
}

export function CourseCard({ course, sessions, onOpen }: CourseCardProps) {
  const count = sessions.length
  const next = sessions.find((s) => !s.done)
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
      <p>{next ? `Next: ${formatDay(next.date)}` : 'Nothing left this week'}</p>
    </Card>
  )
}
```

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 64ms on 19 files with 116 rules using 4 threads.
no errors
```

Marque de novo a última sessão de estatística:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep -E 'heading|paragraph'
  - heading "Study planner" [level=1]
    - paragraph: Week of 19 Oct 2026
    - paragraph: 120 of 195 minutes done
      - heading "Statistics" [level=2]:
      - paragraph: 2 sessions · 90 min
      - paragraph: Nothing left this week
      - heading "Spanish" [level=2]:
      - paragraph: 2 sessions · 60 min
      - paragraph: "Next: Fri 23 Oct"
      - heading "Organic chemistry" [level=2]:
      - paragraph: 1 session · 45 min
      - paragraph: "Next: Thu 22 Oct"
```

O cartão de estatística diz *Nothing left this week*, e a semana anterior, que falhava nos três
cartões, agora dá um console sem nada:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Previous week' --quiet
-- click button Previous week
```

Trate **uma asserção de não nulo `!` como uma afirmação que você precisa conseguir defender**: que esse
valor não pode ser `undefined`, aqui, para toda entrada que este código vai ver. "Os dados com que
testei sempre têm um" não é defesa, e foi exatamente assim que este defeito foi escrito. A aula 19 fala
mais de deixar o TypeScript carregar esse tipo de fato por você.

Mantenha os dois boundaries mesmo assim. Todo defeito que chega aos usuários era um que alguém não
conhecia, e o próximo também não vai se anunciar: os boundaries estão lá para que ele custe um cartão, ou
uma tela com uma frase, e não uma página branca.
