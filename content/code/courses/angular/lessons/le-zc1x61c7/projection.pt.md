---
title: Projeção de conteúdo, passando marcação para dentro
version: 1
---

**`<ng-content />` no template de um componente marca onde vai aparecer o que o pai escreveu entre as
tags do componente.** Inputs passam valores; a projeção passa marcação, elementos e outros componentes,
que o pai escreve e o filho posiciona. É como um componente oferece uma moldura, um cartão, um diálogo,
um painel, em volta de um conteúdo que ele não conhece.

As duas telas do planner são um título seguido de conteúdo. Um painel pode dar a elas a mesma moldura:

```
ana@dev:~/planner$ npx ng generate component panel --inline-template --inline-style --skip-tests
CREATE src/app/panel/panel.ts (269 bytes)
```

```typescript
// src/app/panel/panel.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'app-panel',
  imports: [],
  template: `
    <section class="panel">
      <ng-content select="h2" />
      <ng-content />
    </section>
  `,
  styles: `
    .panel {
      border: 1px solid currentColor;
      border-radius: 0.5rem;
      padding: 0 1rem 1rem;
      margin-bottom: 1rem;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Panel {}
```

Dois slots. O **`select="h2"`** pega o `<h2>` do pai, onde quer que o pai o tenha escrito, e o põe
primeiro; o `<ng-content />` simples pega todo o resto. O `select` aceita um seletor CSS, então um slot
pode pegar um elemento, uma classe ou um atributo.

A semana envolve o seu template nele:

```html
<!-- src/app/week/week.html -->
<app-panel>
  <h2>This week</h2>
  @if (data.isLoading()) {
    <p>Loading the week…</p>
  } @else if (data.error(); as error) {
    <p>The week could not be loaded: {{ error.message }}</p>
  } @else {
    <app-week-summary [planned]="totals().planned" [done]="totals().done" />
    <h3>Courses</h3>
    <ul>
      @for (row of rows(); track row.course.id) {
        <li><app-course-card [course]="row.course" [minutes]="row.minutes" /></li>
      } @empty {
        <li>No courses yet.</li>
      }
    </ul>
  }
</app-panel>
```

e o importa, com o `Panel` acrescentado aos `imports` e ao arquivo:

```typescript
// src/app/week/week.ts
import { ChangeDetectionStrategy, Component, computed, resource } from '@angular/core';
import { isoDay, loadPlanner, totals, weekOf } from '../planner';
import { CourseCard } from '../course-card/course-card';
import { Panel } from '../panel/panel';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [CourseCard, Panel, WeekSummary],
  templateUrl: './week.html',
  styleUrl: './week.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Week {
  protected readonly data = resource({ loader: loadPlanner });
  private readonly week = weekOf(isoDay(new Date()));
  protected readonly totals = computed(() => totals(this.data.value()?.sessions ?? [], this.week));
  protected readonly rows = computed(() => {
    const data = this.data.value();
    if (!data) return [];
    return data.courses.map((course) => ({
      course,
      minutes: totals(data.sessions.filter((s) => s.courseId === course.id), this.week).planned,
    }));
  });
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --html 'app-week section > *:first-child'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<h2>This week</h2>
```

O título é o primeiro filho do painel, dentro da `<section>`, exatamente onde o slot o pôs. **O
conteúdo projetado pertence ao pai.** É o template da semana, conferido com a semana, lendo os signals
da semana, e estilizado pela folha de estilo da semana; o painel só decide onde ele vai. A regra
`.panel` alcança a `<section>` porque a seção está no próprio template do painel.

Um slot também pode ter **conteúdo alternativo**, escrito dentro das tags `<ng-content>`, mostrado
quando o pai não dá nada para aquele slot. A página do curso poderia usar o mesmo painel, com as mesmas
duas linhas em volta do seu template.
