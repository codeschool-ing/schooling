---
title: A semana, calculada a partir dos dados
version: 1
---

**Os números do planner deixam de ser digitados: são calculados a partir das seis sessões e da data de
hoje, por funções simples, lidas por meio de `computed`.** A regra do que vai onde é a que esta aula
vem construindo: os dados chegam num `resource`, tudo o que se calcula a partir deles é um `computed`,
e a aritmética em si é TypeScript comum que não sabe nada de Angular.

## A aritmética, sozinha

A semana vai de segunda a domingo e contém o dia de hoje. Quatro funções, acrescentadas ao
`planner.ts` abaixo das interfaces, e o loader, que vem do componente para cá:

```schooling-example
{"language": "typescript", "file": "src/app/planner.ts", "parts": [
 {"code": "export interface Course {\n  id: string;\n  name: string;\n}\n\nexport interface Session {\n  id: number;\n  courseId: string;\n  date: string;\n  minutes: number;\n  done: boolean;\n}\n\nexport interface PlannerData {\n  courses: Course[];\n  sessions: Session[];\n}", "note": "Os formatos de antes, sem mudança."},
 {"code": "export async function loadPlanner(): Promise<PlannerData> {\n  const response = await fetch('/courses.json');\n  if (!response.ok) throw new Error(`${response.url} answered ${response.status}`);\n  return response.json();\n}", "note": "O loader da seção anterior, trazido para cá para os dois componentes que precisam dos dados o compartilharem."},
 {"code": "export interface WeekRange {\n  start: string;\n  end: string;\n}", "note": "Uma semana, como o primeiro e o último dia. Não se chama `Week`: esse é o nome do componente."},
 {"code": "export function isoDay(date: Date): string {\n  const two = (n: number) => String(n).padStart(2, '0');\n  return `${date.getFullYear()}-${two(date.getMonth() + 1)}-${two(date.getDate())}`;\n}", "note": "Uma `Date` como `AAAA-MM-DD`, no fuso horário do próprio computador. O `toISOString()` responderia em UTC, e em São Paulo às 22h isso já é amanhã."},
 {"code": "export function weekOf(day: string): WeekRange {\n  const date = new Date(`${day}T12:00:00`);\n  const fromMonday = (date.getDay() + 6) % 7;\n  const monday = new Date(date);\n  monday.setDate(date.getDate() - fromMonday);\n  const sunday = new Date(monday);\n  sunday.setDate(monday.getDate() + 6);\n  return { start: isoDay(monday), end: isoDay(sunday) };\n}", "note": "O `getDay()` conta a partir do domingo como 0. Somar seis e tirar o resto faz da segunda o 0, então `fromMonday` é quantos dias voltar. O meio-dia impede que uma mudança de horário de verão mova a data."},
 {"code": "export function inWeek(session: Session, week: WeekRange): boolean {\n  return session.date >= week.start && session.date <= week.end;\n}", "note": "Datas escritas `AAAA-MM-DD` se comparam certo como texto, e foi por isso que a aula 2 as escolheu."},
 {"code": "export function totals(sessions: Session[], week: WeekRange): { planned: number; done: number } {\n  let planned = 0;\n  let done = 0;\n  for (const s of sessions) {\n    if (!inWeek(s, week)) continue;\n    planned += s.minutes;\n    if (s.done) done += s.minutes;\n  }\n  return { planned, done };\n}", "note": "Minutos planejados e feitos numa semana. Toda sessão da semana conta como planejada; as feitas contam duas vezes, uma em cada total."}
]}
```

Nada nele importa o Angular, então a aula 24 consegue testá-lo em poucas linhas, e os outros três
cursos de framework poderiam usá-lo como está. `resource({ loader: loadPlanner })` agora é tudo o que um
componente precisa escrever.

## O resumo, a partir dos dados

```typescript
// src/app/week-summary/week-summary.ts
import { Component, computed, resource } from '@angular/core';
import { isoDay, loadPlanner, totals, weekOf } from '../planner';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
})
export class WeekSummary {
  protected readonly data = resource({ loader: loadPlanner });
  private readonly week = weekOf(isoDay(new Date()));
  protected readonly totals = computed(() => totals(this.data.value()?.sessions ?? [], this.week));
}
```

```html
<!-- src/app/week-summary/week-summary.html -->
@if (data.isLoading()) {
  <p>Loading the week…</p>
} @else if (data.error(); as error) {
  <p>The week could not be loaded: {{ error.message }}</p>
} @else {
  @let t = totals();
  @let left = t.planned - t.done;
  <p>{{ t.planned }} minutes planned, {{ t.done }} done.</p>
  @if (t.planned === 0) {
    <p>Nothing planned this week.</p>
  } @else if (left <= 0) {
    <p>Everything planned is done.</p>
  } @else {
    <p>{{ left }} minutes to go.</p>
  }
  <label for="week-progress">Done this week</label>
  <progress id="week-progress" [value]="t.done" [max]="t.planned"></progress>
}
```

`week` é um campo comum: o dia de hoje não muda enquanto a página está aberta, pelo menos não de um
jeito que interesse a este planner, então ele não precisa de signal. A aula 10 troca o `new Date()` por
algo que um teste consegue definir.

## Os cursos, com os seus minutos

A tela da semana lista cada curso com os próprios minutos da semana. Ela lê o mesmo arquivo:

```typescript
// src/app/week/week.ts
import { Component, computed, resource } from '@angular/core';
import { isoDay, loadPlanner, totals, weekOf } from '../planner';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [WeekSummary],
  templateUrl: './week.html',
  styleUrl: './week.css',
})
export class Week {
  protected readonly data = resource({ loader: loadPlanner });
  private readonly week = weekOf(isoDay(new Date()));
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
<app-week-summary />
<h3>Courses</h3>
@if (data.hasValue()) {
  <ul>
    @for (row of rows(); track row.course.id) {
      <li>{{ row.course.name }}: {{ row.minutes }} minutes</li>
    } @empty {
      <li>No courses yet.</li>
    }
  </ul>
}
```

Peça a página com hoje definido como sexta-feira, 23 de outubro, a data para a qual a aula 1 calculou
os números:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23
[vite] connecting...
[vite] connected.
Angular is running in development mode.
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

165 e 90, como calculados à mão na aula 1, agora calculados pelo programa, e 75 por fazer. JavaScript
tem 110 minutos nesta semana, os 60 da terça e os 50 do sábado. Leve o hoje para a semana seguinte, e
cada número acompanha:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-28
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Study planner
This week

40 minutes planned, 0 done.

40 minutes to go.

Done this week
Courses
HTML and CSS: 40 minutes
JavaScript: 0 minutes
Git: 0 minutes
```

## O preço de dois resources

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --network
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /courses.json  200
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

Duas requisições de `/courses.json`: o `Week` e o `WeekSummary` carregaram o arquivo cada um. Também
calcularam a semana cada um. São duas cópias dos mesmos dados numa página, o que é desperdício agora e
erro no dia em que uma mudar e a outra não. **A aula 8 remove a segunda cópia**: a semana vai passar os
seus números para o resumo, por meio de um input. A aula 11 então leva os dados para fora dos dois
componentes, para um serviço.

Apague a pasta `try/`, rode os testes, e faça o commit:

```
ana@dev:~/planner$ rm -r try
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep Tests
      Tests  4 passed (4)
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Signals: the week computed from the data"
```
