---
title: As duas telas pedem o store
version: 1
---

**Cada componente troca o próprio `resource` por `inject(PlannerStore)`, e lê os signals do store
onde lia os seus.** O `Week` mantém a sua semana e os seus dois valores computed; só muda de onde vêm
as sessões e os cursos:

```typescript
// src/app/week/week.ts
import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { isoDay, totals, weekOf } from '../planner';
import { CourseCard } from '../course-card/course-card';
import { Panel } from '../panel/panel';
import { PlannerStore } from '../planner-store';
import { TODAY } from '../today';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [CourseCard, Panel, WeekSummary],
  templateUrl: './week.html',
  styleUrl: './week.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Week {
  protected readonly store = inject(PlannerStore);
  protected readonly week = weekOf(isoDay(inject(TODAY)));
  protected readonly totals = computed(() => totals(this.store.sessions(), this.week));
  protected readonly rows = computed(() =>
    this.store.courses().map((course) => ({
      course,
      minutes: totals(this.store.sessions().filter((s) => s.courseId === course.id), this.week).planned,
    })),
  );
}
```

O template pergunta ao store se ainda está carregando, ou se falhou:

```html
<!-- src/app/week/week.html -->
<app-panel>
  <h2>This week</h2>
  <p>{{ week.start }} to {{ week.end }}</p>
  @if (store.isLoading()) {
    <p>Loading the week…</p>
  } @else if (store.error(); as error) {
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

O `CoursePage` perde o método `toggle` além do resource, e o template dele chama o do store:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { PlannerStore } from '../planner-store';
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
  protected readonly store = inject(PlannerStore);
  protected readonly course = computed(() => this.store.courses().find((c) => c.id === this.courseId()));
  protected readonly sessions = computed(() =>
    this.store
      .sessions()
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );
}
```

```html
<!-- src/app/course-page/course-page.html -->
@if (store.isLoading()) {
  <p>Loading the course…</p>
} @else if (store.error(); as error) {
  <p>The course could not be loaded: {{ error.message }}</p>
} @else if (course(); as course) {
  <h2>{{ course.name }}</h2>
  <app-session-list [sessions]="sessions()" (toggled)="store.toggle($event.id, $event.done)" />
} @else {
  <p>There is no course called {{ courseId() }}.</p>
}
```

A mesma marcação de antes:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week-summary --network --do 'check 2026-10-24, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /courses.json  200
-- check 2026-10-24, 50 minutes
165 minutes planned, 140 done.

25 minutes to go.

Done this week
```

**Um pedido, e 140 minutos feitos.** A marcação foi para o store; o `sessions` do store mudou; o
`totals` do `Week` lê o `sessions`, então foi marcado como velho, e o resumo foi desenhado de novo.
Nenhum dos componentes sabe que o outro existe. Eles concordam porque leem o mesmo signal, que é o
único tipo de concordância que não tem como se desfazer.

O `store` é `protected` e não `private` porque os templates o leem. Isso põe o store inteiro ao
alcance do template, o `toggle` incluído, que é a escolha cômoda e uma das mais comuns. A mais
rigorosa é manter o store `private` e dar ao template só valores computed e métodos do próprio
componente; a próxima seção é sobre o lado do store da mesma questão.
