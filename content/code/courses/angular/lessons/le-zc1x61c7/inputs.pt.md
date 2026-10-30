---
title: Inputs, dados passados para baixo
version: 1
---

**Um input é uma propriedade que um componente deixa o pai definir pelo template, escrita
`[nome]="expressão"` onde o componente é usado.** É o property binding da aula 4, apontado para um
componente seu em vez de um elemento, e é como os dados descem pela árvore. A aula 6 deixou os dados da
semana carregados duas vezes, uma pelo `Week` e outra pelo `WeekSummary`. Com inputs, o `Week` carrega,
calcula os números e os passa para baixo.

## O resumo recebe dois números

```typescript
// src/app/week-summary/week-summary.ts
import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WeekSummary {
  readonly planned = input.required<number>();
  readonly done = input.required<number>();
}
```

O `input()` devolve um signal, só de leitura para o componente, que o binding do pai define.
**`input.required<number>()`** quer dizer que um pai precisa fornecê-lo: escreva `<app-week-summary />`
sem `[planned]` e o build falha, em vez de desenhar um resumo de `undefined`. O `input(0)`, com um valor
padrão, o torna opcional. Os inputs são `readonly` e não `protected`: o template do pai os define, então
fazem parte da face pública do componente.

O template os lê como signals:

```html
<!-- src/app/week-summary/week-summary.html -->
@let left = planned() - done();
<p>{{ planned() }} minutes planned, {{ done() }} done.</p>
@if (planned() === 0) {
  <p>Nothing planned this week.</p>
} @else if (left <= 0) {
  <p>Everything planned is done.</p>
} @else {
  <p>{{ left }} minutes to go.</p>
}
<label for="week-progress">Done this week</label>
<progress id="week-progress" [value]="done()" [max]="planned()"></progress>
```

O resumo não sabe mais de onde vêm os números, nem que existe um arquivo, nem o que é uma semana. Isso o
deixa mais simples, reutilizável para qualquer período, e testável com dois números.

## Um cartão por curso

A lista de cursos ganha um componente próprio, o `CourseCard` da árvore da aula 1. É o primeiro
componente gerado desde que a aula 7 definiu o OnPush como padrão e, como todo componente que esta aula
gera, vem sem o teste gerado, que só confere se o componente pode ser criado: a aula 24 escreve testes
de verdade.

```
ana@dev:~/planner$ npx ng generate component course-card --inline-template --inline-style --skip-tests
CREATE src/app/course-card/course-card.ts (286 bytes)
```

```typescript
// src/app/course-card/course-card.ts
import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { Course } from '../planner';

@Component({
  selector: 'app-course-card',
  imports: [],
  template: `<span class="name">{{ course().name }}</span>: {{ minutes() }} minutes`,
  styles: `
    .name {
      font-weight: 600;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CourseCard {
  readonly course = input.required<Course>();
  readonly minutes = input(0);
}
```

O `changeDetection: ChangeDetectionStrategy.OnPush` veio do gerador, como o `ng config` pediu.

## A semana passa os dois para baixo

```typescript
// src/app/week/week.ts
import { ChangeDetectionStrategy, Component, computed, resource } from '@angular/core';
import { isoDay, loadPlanner, totals, weekOf } from '../planner';
import { CourseCard } from '../course-card/course-card';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [CourseCard, WeekSummary],
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

```html
<!-- src/app/week/week.html -->
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
```

Os ramos de carregando e de erro subiram junto com os dados: o componente que carrega é o que diz que
está carregando.

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --network
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /courses.json  200
Study planner
This week

165 minutes planned, 90 done.

75 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 110 minutes
Git: 25 minutes
```

Uma requisição desta vez, e a mesma página. **Os dados descem pelos inputs, e um filho nunca sobe para
buscá-los.** A semana é dona dos dados e decide o que cada filho vê; cada filho desenha o que recebe.

## Os inputs que você ainda vai encontrar

Antes do Angular 17.1, um input era um campo com decorator, e a maior parte do código no trabalho ainda
é assim:

```typescript
@Input({ required: true }) planned!: number;
```

O valor é um campo comum, não um signal, então um computed não depende dele, e reagir a uma mudança
exige o hook `ngOnChanges` da aula 9. O `input()` o substituiu, e a CLI traz uma migração,
`ng generate @angular/core:signal-input-migration`, que reescreve a forma antiga na nova.
