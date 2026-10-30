---
title: Um ref para um elemento do DOM, e para onde vai o foco
version: 1
---

**Um ref também é como um componente alcança o elemento do DOM que renderizou.** Dê a um elemento um
atributo `ref`, e depois do commit o React põe o elemento no `current` do ref. O planejador precisa
disso por um motivo que não tem nada a ver com o React e tudo a ver com a pessoa que o usa.

Quando "Statistics" é apertado, a lista de cursos sai e a tela do curso chega. O botão que tinha o
foco do teclado não existe mais. Para onde vai o foco? Apertar Tab responde:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'press Tab' --quiet --html ':focus'
-- click button Statistics
-- press Tab
<button type="button">Back to courses</button>
```

O foco voltou ao começo da página, então o Tab caiu em "Back to courses", a primeira coisa ali. Para
quem usa mouse isso é invisível. **Para quem usa teclado ou leitor de tela, é uma página que mudou sem
avisar**: nada foi anunciado, e o lugar da pessoa é onde quer que o navegador o tenha deixado. A WCAG
pede que o foco ande numa ordem que preserve o sentido, e a resposta consagrada para uma troca de tela
num app como este é levar o foco ao título da tela nova.

Este é o `src/CourseScreen.tsx` fazendo isso:

```tsx
import { useEffect, useRef } from 'react'
import type { Course, Session } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  sessions: Session[]
  onToggle: (id: string) => void
  onBack: () => void
}

export function CourseScreen({ course, sessions, onToggle, onBack }: CourseScreenProps) {
  const heading = useRef<HTMLHeadingElement>(null)
  useEffect(() => {
    heading.current?.focus()
  }, [])

  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  return (
    <>
      <button type="button" onClick={onBack}>
        Back to courses
      </button>
      <h1 ref={heading} tabIndex={-1}>
        {course.name}
      </h1>
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

- **`useRef<HTMLHeadingElement>(null)`** cria um ref que vai guardar o `<h1>`; o tipo diz que tipo de
  elemento, e `null` é o valor até o commit.
- **`ref={heading}`** no `<h1>` é onde o React põe o elemento.
- **`tabIndex={-1}`** torna um título focável pelo código sem acrescentá-lo à ordem do Tab: um título
  não é algo em que o usuário deva cair apertando Tab.
- **O efeito** o foca depois do commit, uma vez, quando a tela aparece. O `?.` cobre o caso em que o
  elemento não está lá, o que neste componente nunca acontece e não custa nada prever.

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --quiet --html ':focus'
-- click button Statistics
<h1 tabindex="-1">Statistics</h1>
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'press Tab' --quiet --html ':focus'
-- click button Statistics
-- press Tab
<input type="checkbox" checked="">
```

O foco agora está no título, então um leitor de tela anuncia "Statistics, título nível 1" quando a
tela chega, e o Tab continua dali para a primeira caixa de marcação. A aula 14 volta aos refs para os
casos que este não cobre: um ref para outro componente, e o foco dentro de um diálogo.
