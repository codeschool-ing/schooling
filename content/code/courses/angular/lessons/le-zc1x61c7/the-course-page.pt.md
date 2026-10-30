---
title: A segunda tela, que recebe o curso por um input
version: 1
---

**A segunda tela do planner mostra um curso e as suas sessões, e qual curso é um input.** Até a aula
17 dar um endereço a cada tela, as duas telas ficam numa página só, e a página do curso fica sabendo
que curso mostrar do mesmo jeito que o resumo ficou sabendo os números: pelo pai, por meio de um
input. Na aula 17 o router define esse mesmo input a partir do endereço, e nada na página muda.

Dois componentes, gerados:

```
ana@dev:~/planner$ npx ng generate component course-page --skip-tests
CREATE src/app/course-page/course-page.css (0 bytes)
CREATE src/app/course-page/course-page.ts (281 bytes)
CREATE src/app/course-page/course-page.html (26 bytes)
```

```
ana@dev:~/planner$ npx ng generate component session-list --inline-template --inline-style --skip-tests
CREATE src/app/session-list/session-list.ts (289 bytes)
```

## A lista de sessões

O `SessionList` desenha as sessões que recebe, e não sabe mais nada:

```typescript
// src/app/session-list/session-list.ts
import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { Session } from '../planner';

@Component({
  selector: 'app-session-list',
  imports: [],
  template: `
    <ul>
      @for (session of sessions(); track session.id) {
        <li>{{ session.date }}, {{ session.minutes }} minutes{{ session.done ? ', done' : '' }}</li>
      } @empty {
        <li>No sessions yet.</li>
      }
    </ul>
  `,
  styles: ``,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SessionList {
  readonly sessions = input.required<Session[]>();
}
```

## A página

O `CoursePage` carrega os dados, acha o seu curso e escolhe as sessões desse curso, ordenadas por data:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, input, resource } from '@angular/core';
import { loadPlanner } from '../planner';
import { SessionList } from '../session-list/session-list';

@Component({
  selector: 'app-course-page',
  imports: [SessionList],
  templateUrl: './course-page.html',
  styleUrl: './course-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CoursePage {
  readonly courseId = input.required<string>();
  protected readonly data = resource({ loader: loadPlanner });
  protected readonly course = computed(() =>
    this.data.value()?.courses.find((c) => c.id === this.courseId()),
  );
  protected readonly sessions = computed(() =>
    (this.data.value()?.sessions ?? [])
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );
}
```

O `course` e o `sessions` leem o input como qualquer outro signal, então o acompanham: dê à página outro
`courseId` e os dois recalculam. É isso que permite ao router da aula 17 conduzir esta página sem
mudá-la. O `filter` constrói um array novo antes de o `sort` reordená-lo, então o array do resource
nunca é alterado no lugar, como a aula 6 exigiu.

```html
<!-- src/app/course-page/course-page.html -->
@if (data.isLoading()) {
  <p>Loading the course…</p>
} @else if (data.error(); as error) {
  <p>The course could not be loaded: {{ error.message }}</p>
} @else if (course(); as course) {
  <h2>{{ course.name }}</h2>
  <app-session-list [sessions]="sessions()" />
} @else {
  <p>There is no course called {{ courseId() }}.</p>
}
```

**O ramo de erro precisa vir antes de qualquer coisa que leia o valor.** No estado de erro, o
`value()` de um resource não responde `undefined`: ele lança um erro, e o `course()` que o lê lançaria
junto, derrubando a página. Conferir o `error()` primeiro faz com que o `course()` só seja lido quando
há um valor para ler. O último ramo importa a partir da aula 17, quando o curso vier de um endereço que
alguém pode ter digitado errado.

## As duas telas, por enquanto

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-course-page courseId="javascript" />
</main>
<router-outlet />
```

`courseId="javascript"`, sem colchetes, passa o texto `javascript`. Com colchetes ele seria lido como
expressão, um campo chamado `javascript`, que não existe.

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { CoursePage } from './course-page/course-page';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, CoursePage],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-course-page
[vite] connecting...
[vite] connected.
Angular is running in development mode.
JavaScript
2026-10-13, 45 minutes, done
2026-10-20, 60 minutes, done
2026-10-24, 50 minutes
```

As três sessões de JavaScript, em ordem de data. A página carrega o arquivo de novo, uma segunda cópia,
pelo motivo que a aula 6 deu e que a aula 11 remove; a próxima seção mostra quanto essa segunda cópia
custa.
