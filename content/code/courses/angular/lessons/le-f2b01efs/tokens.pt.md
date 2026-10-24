---
title: Tokens para o que não é uma classe
version: 1
---

**Uma classe é o próprio token, mas a maior parte do que um programa precisa não é uma classe: uma
data, uma URL, um número de minutos.** `inject(Date)` pediria a própria classe `Date`, que é a
pergunta errada, e duas strings diferentes não podem ser as duas o tipo `string`. O `InjectionToken`
faz um token a partir do nada: um objeto cujo único trabalho é ser pedido, carregando o tipo do que
ele representa.

O dia de hoje é o que o planner precisa. Um arquivo só dele, já que mais de um componente vai pedir:

```schooling-example
{"language": "typescript", "file": "src/app/today.ts", "parts": [
 {"code": "import { InjectionToken } from '@angular/core';\n\nexport const TODAY = new InjectionToken<Date>('TODAY', {", "note": "O argumento de tipo é o que o `inject(TODAY)` retorna. A string é uma descrição, mostrada em mensagens de erro e em nenhum outro lugar."},
 {"code": "  providedIn: 'root',\n  factory: () => new Date(),\n});", "note": "`providedIn` e `factory` dão ao token uma receita padrão, como o `providedIn: 'root'` faz para uma classe: ninguém precisa listá-lo em lugar nenhum."}
]}
```

A factory é chamada uma vez, na primeira vez que alguém pede, e a resposta é guardada. Então o
`TODAY` é o momento em que a aplicação precisou dele pela primeira vez, não um relógio: um planner
aberto de domingo para segunda continua contando a semana velha. Esse é o comportamento que o
`new Date()` num campo já tinha, e as próximas aulas o mantêm.

## A semana pede o dia

O `Week` muda numa linha, e o `week` vira `protected` para o template poder mostrar o intervalo que
ele conta:

```typescript
// src/app/week/week.ts
import { ChangeDetectionStrategy, Component, computed, inject, resource } from '@angular/core';
import { isoDay, loadPlanner, totals, weekOf } from '../planner';
import { CourseCard } from '../course-card/course-card';
import { Panel } from '../panel/panel';
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
  protected readonly data = resource({ loader: loadPlanner });
  protected readonly week = weekOf(isoDay(inject(TODAY)));
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
<app-panel>
  <h2>This week</h2>
  <p>{{ week.start }} to {{ week.end }}</p>
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

Nada que uma pessoa veja mudou, fora a linha nova: a factory ainda chama `new Date()`, e o `--today`
ainda define o relógio do navegador por baixo dela. A aula 19 escreve essas datas do jeito que uma
pessoa escreveria. O que mudou é quem decide, e um teste mostra isso.

## Um teste que diz o seu dia

O teste que o CLI gerou para o `Week` só confere que ele pode ser feito. Troque-o por um que confere
o intervalo, para quarta, 28 de outubro, a semana depois da das transcrições:

```typescript
// src/app/week/week.spec.ts
import { TestBed } from '@angular/core/testing';
import { Week } from './week';

describe('Week', () => {
  it('counts the week that holds today', async () => {
    TestBed.configureTestingModule({ imports: [Week] });
    const fixture = TestBed.createComponent(Week);
    await fixture.whenStable();
    const text = (fixture.nativeElement as HTMLElement).textContent;
    expect(text).toContain('2026-10-26 to 2026-11-01');
  });
});
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error|Tests '
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯
 FAIL  |planner| src/app/week/week.spec.ts > Week > counts the week that holds today
AssertionError: expected 'This week2026-10-19 to 2026-10-25The …' to contain '2026-10-26 to 2026-11-01'
      Tests  1 failed | 3 passed (4)
```

Ele falhou, e só passaria durante aquela semana. O teste não tem como dizer de que dia está falando:
o componente o lê, e o relógio é o que o computador disser. O `TestBed` constrói o componente por um
injetor próprio, e os `providers` na configuração dele vão para esse injetor. Um `useValue` diz o dia:

```typescript
// src/app/week/week.spec.ts
import { TestBed } from '@angular/core/testing';
import { TODAY } from '../today';
import { Week } from './week';

describe('Week', () => {
  it('counts the week that holds today', async () => {
    TestBed.configureTestingModule({
      imports: [Week],
      providers: [{ provide: TODAY, useValue: new Date('2026-10-28T09:00:00') }],
    });
    const fixture = TestBed.createComponent(Week);
    await fixture.whenStable();
    const text = (fixture.nativeElement as HTMLElement).textContent;
    expect(text).toContain('2026-10-26 to 2026-11-01');
  });
});
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error|Tests '
      Tests  4 passed (4)
```

**O provider do teste vence a factory do token**, como o `useClass` venceu o `providedIn` na seção
anterior, e o teste agora passa em qualquer dia em que rodar. O teste nunca carrega os dados, porque o
jsdom não tem servidor de onde buscar o `/courses.json`, então ele confere só o que não depende
deles; a aula 24 testa os totais também, com um servidor falso no lugar do real.
