---
title: Um pipe seu
version: 1
---

**Um pipe seu é uma classe com `@Pipe` e um método `transform`, e é o lugar certo para uma formatação
de que mais de um template precisa.** O planner escreve durações como um número e a palavra "minutes"
em cinco lugares, e "165 minutes" é mais difícil de captar de relance do que "2 hours 45 minutes". Um
pipe pode dizer isso do mesmo jeito em todo lugar.

```
ana@dev:~/planner$ npx ng generate pipe minutes
CREATE src/app/minutes-pipe.spec.ts (191 bytes)
CREATE src/app/minutes-pipe.ts (220 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/minutes-pipe.ts", "parts": [
 {"code": "// src/app/minutes-pipe.ts\nimport { Pipe, PipeTransform } from '@angular/core';\n\n@Pipe({\n  name: 'minutes',\n})\nexport class MinutesPipe implements PipeTransform {", "note": "O nome é o que os templates escrevem depois do `|`. A classe é importada onde é usada, como o `DatePipe`."},
 {"code": "  transform(value: number): string {\n    const hours = Math.floor(value / 60);\n    const minutes = value % 60;\n    const parts: string[] = [];\n    if (hours > 0) parts.push(hours === 1 ? '1 hour' : `${hours} hours`);\n    if (minutes > 0 || hours === 0) parts.push(minutes === 1 ? '1 minute' : `${minutes} minutes`);\n    return parts.join(' ');\n  }\n}", "note": "Palavras em vez de `h` e `min`: um leitor de tela lê \"1 hour 50 minutes\" como uma pessoa leria, e uma abreviação letra por letra."}
]}
```

**Um pipe é uma função comum numa classe, então é a coisa mais fácil de testar no Angular**: sem
`TestBed`, sem template, um `new` e uma chamada. O spec do CLI só confere que um pode ser feito; este
confere o que ele diz:

```typescript
// src/app/minutes-pipe.spec.ts
import { MinutesPipe } from './minutes-pipe';

describe('MinutesPipe', () => {
  const pipe = new MinutesPipe();

  it('writes less than an hour in minutes', () => {
    expect(pipe.transform(50)).toBe('50 minutes');
    expect(pipe.transform(1)).toBe('1 minute');
  });

  it('writes whole hours without minutes', () => {
    expect(pipe.transform(60)).toBe('1 hour');
    expect(pipe.transform(120)).toBe('2 hours');
  });

  it('writes hours and minutes together', () => {
    expect(pipe.transform(165)).toBe('2 hours 45 minutes');
    expect(pipe.transform(61)).toBe('1 hour 1 minute');
  });

  it('writes nothing as 0 minutes', () => {
    expect(pipe.transform(0)).toBe('0 minutes');
  });
});
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|Tests '
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯
 FAIL  |planner| src/app/week/week.spec.ts > Week > counts the week that holds today
      Tests  1 failed | 8 passed (9)
```

Os testes do pipe passam. O da aula 10 não, e está certo em não passar: ele procura
`2026-10-26 to 2026-11-01`, e a primeira seção desta aula mudou como o intervalo é escrito. Um teste
que confere o que uma pessoa vê precisa mudar quando o que ela vê muda de propósito. O teste da semana
agora espera inglês britânico, que é também a língua em que os testes rodam, já que a localidade de
origem vale para eles também:

```typescript
// src/app/week/week.spec.ts
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { TODAY } from '../today';
import { Week } from './week';

describe('Week', () => {
  it('counts the week that holds today', async () => {
    TestBed.configureTestingModule({
      imports: [Week],
      providers: [provideRouter([]), { provide: TODAY, useValue: new Date('2026-10-28T09:00:00') }],
    });
    const fixture = TestBed.createComponent(Week);
    await fixture.whenStable();
    const text = (fixture.nativeElement as HTMLElement).textContent;
    expect(text).toContain('26 October to 1 November 2026');
  });
});
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|Tests '
      Tests  9 passed (9)
```

Depois, os cinco lugares. O resumo da semana:

```html
<!-- src/app/week-summary/week-summary.html -->
@let left = planned() - done();
<p>{{ planned() | minutes }} planned, {{ done() | minutes }} done.</p>
@if (planned() === 0) {
  <p>Nothing planned this week.</p>
} @else if (left <= 0) {
  <p>Everything planned is done.</p>
} @else {
  <p>{{ left | minutes }} to go.</p>
}
<label for="week-progress">Done this week</label>
<progress id="week-progress" [value]="done()" [max]="planned()"></progress>
```

```typescript
// src/app/week-summary/week-summary.ts
import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { MinutesPipe } from '../minutes-pipe';

@Component({
  selector: 'app-week-summary',
  imports: [MinutesPipe],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WeekSummary {
  readonly planned = input.required<number>();
  readonly done = input.required<number>();
}
```

O cartão de cada curso:

```typescript
// src/app/course-card/course-card.ts
import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { MinutesPipe } from '../minutes-pipe';
import { Course } from '../planner';

@Component({
  selector: 'app-course-card',
  imports: [MinutesPipe, RouterLink],
  template: `<a class="name" [routerLink]="['/courses', course().id]">{{ course().name }}</a>: {{ minutes() | minutes }}`,
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

Cada sessão, com a data como dia da semana, que é como uma pessoa planeja uma. O pipe fica no label,
então um leitor de tela lê a caixa como "Sat 24 Oct, 50 minutes":

```typescript
// src/app/session-row/session-row.ts
import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { MinutesPipe } from '../minutes-pipe';
import { Session } from '../planner';

@Component({
  selector: 'app-session-row',
  imports: [DatePipe, MinutesPipe],
  template: `
    <label>
      <input type="checkbox" [checked]="session().done" (change)="changed($event)" />
      {{ session().date | date: 'EEE d MMM' }}, {{ session().minutes | minutes }}
    </label>
  `,
  styles: ``,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SessionRow {
  readonly session = input.required<Session>();
  readonly toggled = output<boolean>();

  protected changed(event: Event): void {
    this.toggled.emit((event.target as HTMLInputElement).checked);
  }
}
```

E a linha da página do curso sobre a semana:

```html
<!-- src/app/course-page/course-page.html -->
@if (store.isLoading()) {
  <p>Loading the course…</p>
} @else if (store.error(); as error) {
  <p>The course could not be loaded: {{ error.message }}</p>
} @else if (course(); as course) {
  <h2>{{ course.name }}</h2>
  <p>{{ store.minutesThisWeek(course.id) | minutes }} planned this week.</p>
  <nav aria-label="Course">
    <a routerLink="." routerLinkActive="current" [routerLinkActiveOptions]="{ exact: true }" ariaCurrentWhenActive="page">Sessions</a>
    <a routerLink="add" routerLinkActive="current" ariaCurrentWhenActive="page">Add sessions</a>
  </nav>
  <router-outlet />
} @else {
  <p>There is no course called {{ courseId() }}.</p>
}
```

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { MinutesPipe } from '../minutes-pipe';
import { PlannerStore } from '../planner-store';

@Component({
  selector: 'app-course-page',
  imports: [MinutesPipe, RouterLink, RouterLinkActive, RouterOutlet],
  templateUrl: './course-page.html',
  styleUrl: './course-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CoursePage {
  readonly courseId = input.required<string>();
  protected readonly store = inject(PlannerStore);
  protected readonly course = computed(() => this.store.courses().find((c) => c.id === this.courseId()));
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week
[vite] connecting...
[vite] connected.
Angular is running in development mode.
This week

19 October to 25 October 2026

2 hours 45 minutes planned, 1 hour 30 minutes done.

1 hour 15 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 1 hour 50 minutes
Git: 25 minutes
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript --today 2026-10-23 --text main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
JavaScript

1 hour 50 minutes planned this week.

Sessions
Add sessions
 Tue 13 Oct, 45 minutes
 Tue 20 Oct, 1 hour
 Sat 24 Oct, 50 minutes
```
