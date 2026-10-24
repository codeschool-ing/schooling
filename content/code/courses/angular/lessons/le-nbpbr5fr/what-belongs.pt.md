---
title: O que vai no store, e o que fica no componente
version: 1
---

**Um fato sobre o planner vai no store; uma decisão sobre uma tela fica no componente dela.** Os
totais da semana são um fato: quantos minutos estão planejados nesta semana é a mesma resposta
qualquer que seja a tela que pergunte, e a página do curso da aula 17 também vai querer os minutos da
semana de um curso. O formato das linhas da lista da semana, um curso ao lado de um número, é daquela
tela. Então a semana e os totais vão, e as linhas ficam.

```schooling-example
{"language": "typescript", "file": "src/app/planner-store.ts", "parts": [
 {"code": "import { Injectable, computed, inject, resource } from '@angular/core';\nimport { isoDay, loadPlanner, totals, weekOf } from './planner';\nimport { TODAY } from './today';\n\n@Injectable({\n  providedIn: 'root',\n})\nexport class PlannerStore {\n  private readonly data = resource({ loader: loadPlanner });\n\n  readonly isLoading = this.data.isLoading;\n  readonly error = this.data.error;\n  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));\n  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));", "note": "Um serviço pode injetar como qualquer outra coisa. O store pede o `TODAY`, que é o token da aula 10 fazendo aquilo para que foi feito."},
 {"code": "  readonly week = weekOf(isoDay(inject(TODAY)));\n  readonly weekTotals = computed(() => totals(this.sessions(), this.week));", "note": "A semana, calculada uma vez para a aplicação inteira, e os totais dela como um computed ao lado das listas."},
 {"code": "  minutesThisWeek(courseId: string): number {\n    return totals(this.sessions().filter((s) => s.courseId === courseId), this.week).planned;\n  }\n\n  toggle(id: number, done: boolean): void {\n    this.data.update((data) =>\n      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },\n    );\n  }\n}", "note": "Um método que lê signals é tão reativo quanto os signals: chamado dentro de um `computed` ou de um template, ele é rastreado como uma leitura de `sessions()` seria."}
]}
```

O `Week` fica com o que é dele, as linhas:

```typescript
// src/app/week/week.ts
import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { CourseCard } from '../course-card/course-card';
import { Panel } from '../panel/panel';
import { PlannerStore } from '../planner-store';
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
  protected readonly rows = computed(() =>
    this.store.courses().map((course) => ({ course, minutes: this.store.minutesThisWeek(course.id) })),
  );
}
```

```html
<!-- src/app/week/week.html -->
<app-panel>
  <h2>This week</h2>
  <p>{{ store.week.start }} to {{ store.week.end }}</p>
  @if (store.isLoading()) {
    <p>Loading the week…</p>
  } @else if (store.error(); as error) {
    <p>The week could not be loaded: {{ error.message }}</p>
  } @else {
    <app-week-summary [planned]="store.weekTotals().planned" [done]="store.weekTotals().done" />
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

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week
[vite] connecting...
[vite] connected.
Angular is running in development mode.
This week

2026-10-19 to 2026-10-25

165 minutes planned, 90 done.

75 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 110 minutes
Git: 25 minutes
```

A página está como estava. O teste da aula 10 vale a pena rodar, porque o `Week` não pede mais o
`TODAY`, e o teste ainda o fornece:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error|Tests '
      Tests  5 passed (5)
```

Cinco testes, o gerado para o store entre eles, e o teste da semana ainda passa. O `TestBed` fez o
store no próprio injetor raiz, o store pediu o `TODAY` a esse injetor, e o `useValue` do teste
respondeu. O teste não precisou saber que a pergunta tinha passado do componente para o store, que é a
mesma propriedade que deixou os dois componentes pararem de saber um do outro: seja quem for que
pergunte, o injetor responde.
