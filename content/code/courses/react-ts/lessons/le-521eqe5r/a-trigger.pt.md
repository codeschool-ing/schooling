---
title: Alguma coisa precisa mudar
version: 1
---

**Uma tela que nunca muda é renderizada uma vez e esquecida.** Para ver como o React redesenha, o
planejador precisa de algo que mude, e a aula 1 prometeu: botões para ir de uma semana à seguinte.
Esta seção os acrescenta. Ela usa um hook, o `useState`, que a aula 4 explica direito; aqui ele só
importa como a coisa que manda o React desenhar de novo.

Primeiro, um jeito de saber em que semana hoje está. Acrescente isto ao fim de `src/week.ts`:

```typescript

export function today(): string {
  const d = new Date()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${d.getFullYear()}-${month}-${day}`
}
```

Ele lê a data do próprio computador, no fuso horário do próprio computador, que é o que "hoje"
significa para quem olha a tela. Depois um componente com os dois botões, `src/WeekNav.tsx`:

```tsx
import { addDays } from './week'

type WeekNavProps = {
  monday: string
  onChange: (monday: string) => void
}

export function WeekNav({ monday, onChange }: WeekNavProps) {
  return (
    <nav aria-label="Week">
      <button type="button" onClick={() => onChange(addDays(monday, -7))}>
        Previous week
      </button>
      <button type="button" onClick={() => onChange(addDays(monday, 7))}>
        Next week
      </button>
    </nav>
  )
}
```

O `WeekNav` não sabe onde a semana é guardada. **Ele recebe a segunda-feira atual e uma função para
chamar com uma nova**, e é assim que um filho pede uma mudança ao pai: o pai passa a função para
baixo como prop, como qualquer outro valor. O `onClick` também recebe uma função, e o navegador a
chama quando o botão é apertado. E o `App` guarda a semana:

```tsx
import { useState } from 'react'
import { CourseList } from './CourseList'
import { courses, sessions } from './sample'
import { inWeek, mondayOf, today } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

function App() {
  const [monday, setMonday] = useState(() => mondayOf(today()))
  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList courses={courses} sessions={thisWeek} />
    </main>
  )
}

export default App
```

O `useState(() => mondayOf(today()))` dá ao `App` um valor que sobrevive entre renderizações,
começando na segunda desta semana, e uma função, `setMonday`, que o substitui. O `App` passa o
`setMonday` ao `WeekNav` como `onChange`. Apertar "Next week" a chama com a segunda sete dias
adiante, o React percebe, e a tela é desenhada de novo:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 2 sessions · 90 min
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 2 sessions · 60 min
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 1 session · 45 min
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Next week'
-- click button Next week
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - region "This week":
    - paragraph: Week of 26 Oct 2026
    - paragraph: 0 of 0 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 0 sessions · 0 min
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 0 sessions · 0 min
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 0 sessions · 0 min
ana@dev:~/planner$ npx tsc -b && echo no errors
no errors
```

A semana de 26 de outubro não tem sessões, então todo número é zero, e "Previous week" traz o 19 de
volta. No seu navegador o planejador abre na semana em que você está vivendo, que provavelmente está
vazia; dois ou três cliques num botão levam aos dados. **O resto desta aula trata do que aconteceu
entre o clique e os números novos.**
