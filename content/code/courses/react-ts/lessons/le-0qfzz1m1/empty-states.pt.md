---
title: Uma lista vazia também é uma tela
version: 1
---

**Uma lista sem nada dentro deve dizer isso.** Um `<ul>` vazio não desenha nada, e uma tela que não
desenha nada não pode ser distinguida de uma tela que falhou, ou de uma que ainda não carregou; a aula
5 fez o mesmo ponto sobre a espera. A tela do curso é o único lugar do planejador onde uma lista pode
estar vazia sem nada mais na tela explicar: um curso sem sessões planejadas. Este é o
`src/CourseScreen.tsx` com esse caso:

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
      {sorted.length === 0 ? (
        <p>No sessions planned for this course yet.</p>
      ) : (
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
      )}
    </>
  )
}
```

Um ternário escolhe entre a frase e a lista, e a frase diz o que está vazio e, com o "yet", que este
é um estado que o usuário pode mudar; a aula 10 acrescenta o formulário que o muda. Todo curso do
`courses.json` tem sessões, então, para ver isso, mais um curso entra no arquivo por um momento, com
uma linha de Node que lê o JSON, acrescenta Latin e o grava de volta:

```
ana@dev:~/planner$ node -e "const f='public/courses.json', d=JSON.parse(require('fs').readFileSync(f)); d.courses.push({id:'latin', name:'Latin'}); require('fs').writeFileSync(f, JSON.stringify(d, null, 2))"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Latin'
-- click button Latin
- main:
  - button "Back to courses"
  - heading "Latin" [level=1]
  - paragraph: No sessions planned for this course yet.
ana@dev:~/planner$ cp /tmp/courses.json public/courses.json
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 65ms on 13 files with 116 rules using 4 threads.
no errors
```

O curso vazio abre na frase, embaixo do título que tem o foco. O `cp` pôs os dados de volta, e o
linter e a checagem de tipos estão limpos.

O que um estado vazio deve dizer depende de por que a lista está vazia, e um bom estado vazio
responde a pergunta que o usuário faria em seguida:

| por que está vazia | o que a tela diz |
|---|---|
| nada foi acrescentado | que está vazia, e como acrescentar o primeiro |
| um filtro ou uma busca excluiu tudo | que nada combina, e como limpar o filtro |
| ainda está carregando | que está carregando: outra tela, como na aula 5 |
| falhou ao carregar | que falhou, e o que fazer: aula 12 |

O planejador tem o primeiro e os dois últimos. Ele não tem filtros, então o segundo não aparece aqui.
