---
title: Pipes, e os que vêm com o Angular
version: 1
---

**Um pipe transforma um valor no que o template mostra, escrito depois de um `|`.** O
`{{ value | date }}` passa o `value` ao pipe `date` e mostra o que volta; argumentos vêm depois de
dois-pontos, `{{ value | date: 'longDate' }}`, e pipes se encadeiam, a saída de um alimentando o
próximo. Um pipe não muda nada: o valor na classe é o mesmo antes e depois, e só o texto na tela é
formatado.

A aula 10 deixou o intervalo da semana como duas strings `YYYY-MM-DD` e disse que esta aula as
escreveria do jeito que uma pessoa escreveria. O `DatePipe` é o pipe para isso, importado como um
componente:

```typescript
// src/app/week/week.ts
import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { CourseCard } from '../course-card/course-card';
import { Panel } from '../panel/panel';
import { PlannerStore } from '../planner-store';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [CourseCard, DatePipe, Panel, WeekSummary],
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
  <p>{{ store.week.start | date: 'd MMMM' }} to {{ store.week.end | date: 'longDate' }}</p>
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

O `'d MMMM'` é um padrão, o dia e depois o mês por extenso; o `'longDate'` é um formato com nome, que
a localidade decide. O `DatePipe` aceita um `Date`, um número de milissegundos, ou uma string, e lê
uma string só com uma data, como `2026-10-19`, como esse dia onde o navegador está, não como
meia-noite UTC, que é o que o `new Date('2026-10-19')` faria dela e que é o dia anterior em qualquer
lugar a oeste de Londres:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text 'app-week p'
[vite] connecting...
[vite] connected.
[vite] connecting...
[vite] connected.
Angular is running in development mode.
19 October to October 25, 2026
```

Os dois dias estão certos, e o segundo é americano: o `longDate` perguntou à localidade como uma data
é escrita por extenso, e a localidade disse mês, dia, vírgula, ano. A próxima seção é sobre isso.

## O resto da caixa

| pipe | transforma | em |
|---|---|---|
| `date` | uma data | `19 October 2026`, `Fri 23 Oct`, `09:00` |
| `number` | um número | `1,234.5`, com os dígitos que você pedir |
| `currency` | um valor em dinheiro | `£12.50`, `R$ 12,50` |
| `percent` | uma fração | `0.55` como `55%` |
| `uppercase`, `lowercase`, `titlecase` | texto | o mesmo texto em outra caixa |
| `slice` | uma string ou um array | uma parte dele |
| `json` | qualquer coisa | o JSON dela, para uma olhada rápida ao depurar |
| `keyvalue` | um objeto ou um `Map` | uma lista de `{ key, value }` para o `@for` |
| `async` | um Observable ou uma Promise | o último valor dele, como a aula 13 mostrou |

Cada um é uma classe no `@angular/common`, `DatePipe`, `CurrencyPipe` e assim por diante, importada
onde é usada.
