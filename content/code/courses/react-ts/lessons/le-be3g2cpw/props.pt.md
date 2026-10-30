---
title: Props descem, e são somente leitura
version: 1
---

**Props são os argumentos de um componente**: o pai as escreve como atributos, e o filho as recebe
como um objeto só. No React os dados andam num sentido, do pai para os filhos, e a tela é desenhada
do topo da árvore para baixo. Estes dois arquivos são o meio da árvore do planejador.

O `src/CourseList.tsx` recebe todos os cursos e as sessões da semana, e desenha um cartão por curso:

```tsx
import { CourseCard } from './CourseCard'
import type { Course, Session } from './types'

type CourseListProps = {
  courses: Course[]
  sessions: Session[]
}

export function CourseList({ courses, sessions }: CourseListProps) {
  return (
    <section aria-label="Courses">
      {courses.map((course) => (
        <CourseCard
          key={course.id}
          course={course}
          sessions={sessions.filter((s) => s.course === course.id)}
        />
      ))}
    </section>
  )
}
```

O `courses.map` transforma cada curso num elemento `<CourseCard>`, e o array de elementos que ele
devolve é um child válido: o React os desenha em ordem. O `key={course.id}` diz ao React qual cartão
é qual curso, para que ele os distinga quando a lista mudar; não é uma prop que o cartão consiga ler,
e a aula 8 trata de por que precisa ser um id. Cada cartão recebe só as sessões do próprio curso,
filtradas aqui.

O `src/CourseCard.tsx` transforma um curso e as sessões dele numa linha de texto:

```tsx
import { Card } from './Card'
import type { Course, Session } from './types'
import { minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
}

export function CourseCard({ course, sessions }: CourseCardProps) {
  const count = sessions.length
  return (
    <Card title={course.name}>
      <p>
        {count} {count === 1 ? 'session' : 'sessions'} · {minutes(sessions)} min
      </p>
    </Card>
  )
}
```

## Desestruturação, e o que o tipo diz

O `function CourseCard({ course, sessions }: CourseCardProps)` desmonta o objeto de props na lista
de parâmetros, como a aula 4 do `javascript` ensinou para qualquer objeto. O tipo depois dos dois
pontos é o que torna isso seguro. **O `CourseCardProps` é o contrato do componente**: um pai que
esquece `sessions`, ou passa um número como `course`, é avisado pelo compilador, e a seção depois da
próxima mostra isso acontecendo. O parâmetro poderia ser escrito `(props: CourseCardProps)` e lido
como `props.course`; desestruturar é o hábito da maior parte do código React, e este curso o segue.

## Somente leitura, por acordo

Um componente não pode mudar as próprias props. Nada na linguagem o impede, e é isto que acontece
quando um muda. Uma linha acrescentada ao `CourseCard`:

```
ana@dev:~/planner$ sed -i 's/^  const count = sessions.length$/  course.name = course.name.toUpperCase()\n  const count = sessions.length/' src/CourseCard.tsx
ana@dev:~/planner$ sed -n 10,13p src/CourseCard.tsx
export function CourseCard({ course, sessions }: CourseCardProps) {
  course.name = course.name.toUpperCase()
  const count = sessions.length
  return (
ana@dev:~/planner$ look http://localhost:5173/
- main:
  - heading "Study planner" [level=1]
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
    - article:
      - heading "STATISTICS" [level=2]
      - paragraph: 2 sessions · 90 min
    - article:
      - heading "SPANISH" [level=2]
      - paragraph: 2 sessions · 60 min
    - article:
      - heading "ORGANIC CHEMISTRY" [level=2]
      - paragraph: 1 session · 45 min
ana@dev:~/planner$ npx tsc -b
ana@dev:~/planner$ sed -i '/toUpperCase/d' src/CourseCard.tsx
```

Todos os nomes de curso na tela agora estão em maiúsculas, e o compilador não fez objeção, porque
`course` é um objeto comum e o tipo dele não diz nada sobre quem pode mudá-lo. **Os objetos não eram
cópias.** O `course` é o próprio objeto do array do `sample.ts`, então o cartão não mudou o que ele
mostra; mudou os dados, para todo componente que os lê, dali em diante. Uma segunda renderização
poria em maiúsculas o que já estava em maiúsculas, e um componente que acrescenta algo a uma lista a
cada renderização a faria crescer a cada renderização.

Então a regra é a que o React diz com todas as letras: **um componente, com as mesmas props, devolve
o mesmo JSX e não muda nada fora de si.** É uma função pura das suas entradas. A aula 3 mostra que o
React pode chamar um componente mais vezes do que você espera, e a aula 4 mostra como um componente
muda o que mostra sem mudar o que recebeu. A linha saiu de novo com o `sed` do fim da transcrição.
