---
title: Listas com @for, e o track que ele exige
version: 1
---

**`@for (item of lista; track chave) { … }` desenha o seu bloco uma vez por item, e o `track` diz ao
Angular como reconhecer um item que ele já desenhou.** O track não é opcional: deixe-o de fora e o
template não compila. A próxima seção mostra para que ele serve; esta põe os cursos do planner na tela
da semana.

Os formatos dos dados, do `session.ts` da aula 1, ganham um arquivo próprio no projeto, de onde todo
componente pode importá-los:

```typescript
// src/app/planner.ts
export interface Course {
  id: string;
  name: string;
}

export interface Session {
  id: number;
  courseId: string;
  date: string;
  minutes: number;
  done: boolean;
}
```

A semana lista os três cursos. Eles estão escritos na classe por enquanto, os mesmos três do
`public/courses.json`; a aula 6 lê o arquivo no lugar:

```typescript
// src/app/week/week.ts
import { Component } from '@angular/core';
import { Course } from '../planner';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [WeekSummary],
  templateUrl: './week.html',
  styleUrl: './week.css',
})
export class Week {
  protected readonly courses: Course[] = [
    { id: 'html-css', name: 'HTML and CSS' },
    { id: 'javascript', name: 'JavaScript' },
    { id: 'git', name: 'Git' },
  ];
}
```

```html
<!-- src/app/week/week.html -->
<h2>This week</h2>
<app-week-summary />
<h3>Courses</h3>
<ul>
  @for (course of courses; track course.id) {
    <li>{{ course.name }}</li>
  } @empty {
    <li>No courses yet.</li>
  }
</ul>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
- main
  - heading "This week" [level=2]
  - paragraph
    - text: 165 minutes planned, 90 done.
  - paragraph
    - text: 75 minutes to go.
  - LabelText
    - text: Done this week
  - progressbar "Done this week": 90
  - heading "Courses" [level=3]
  - list
    - listitem [level=1]
      - ListMarker "• "
      - text: HTML and CSS
    - listitem [level=1]
      - ListMarker "• "
      - text: JavaScript
    - listitem [level=1]
      - ListMarker "• "
      - text: Git
```

Uma lista de três itens, e o leitor de tela fica sabendo que é uma lista com três. O **`@empty`** é o
bloco desenhado quando a lista não tem item nenhum, que é o estado de toda lista no primeiro dia e o
mais esquecido.

## O que o @for sabe sobre cada item

Dentro do bloco, além do item, o `@for` oferece alguns nomes sobre onde o item está:

| nome | é |
|---|---|
| `$index` | a posição do item, a partir de 0 |
| `$count` | quantos itens existem |
| `$first`, `$last` | se este é o primeiro ou o último |
| `$even`, `$odd` | se o `$index` é par ou ímpar |

`<li>{{ $index + 1 }} of {{ $count }}: {{ course.name }}</li>` numeraria os cursos. Eles são práticos
e você vai vê-los, e um deles, o `$index`, é a coisa errada para usar como track, que é o assunto da
próxima seção.
