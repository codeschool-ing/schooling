---
title: Um argumento de tipo é uma afirmação, não uma checagem
version: 1
---

**`httpResource<PlannerData>` e `http.get<PlannerData>` dizem ao compilador como a resposta vai ser,
e nada em tempo de execução confere que ela é.** O argumento de tipo é uma promessa que você faz em
nome do servidor. O TypeScript acredita nela, toda linha depois dela é conferida contra ela, e o JSON
que chega é o que o servidor tiver mandado. Quando os dois discordam, nada falha onde eles se
encontram; algo dá errado depois, em outro lugar.

Um servidor que manda um número como string é um erro fácil de cometer, e uma edição na cópia de
trabalho dele o comete. O `sed -i` muda o arquivo no lugar, aqui os minutos da sessão 5 de `50` para
`"50"`:

```
ana@dev:~/planner$ sed -i 's/"minutes": 50,/"minutes": "50",/' server/planner.json
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week
[vite] connecting...
[vite] connected.
Angular is running in development mode.
This week

2026-10-19 to 2026-10-25

11550 minutes planned, 90 done.

11460 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 6050 minutes
Git: 25 minutes
```

**11550 minutos planejados.** O `totals` soma `s.minutes` a um número corrente: 30, 90, 115, e
depois `115 + "50"`, que em JavaScript é a string `"11550"`. O compilador foi avisado de que
`minutes` é um `number`, então não tinha motivo para reclamar, e a página mostra um número errado com
toda a cara de certo. O 6050 do JavaScript é `60 + "50"`, e "11460 minutes to go" é o mesmo valor
usado do outro jeito: `-` não tem sentido para strings, então o JavaScript transforma `"11550"` de
volta em número para subtrair 90 dele.

## Conferindo na borda

O lugar de descobrir é onde os dados entram, uma vez, para que tudo lá dentro possa confiar no tipo.
O `httpResource` aceita uma opção `parse`: uma função que recebe a resposta crua e retorna o valor
tipado ou lança um erro. O `planner.ts` perde o `loadPlanner`, que ninguém chama, e ganha a checagem:

```schooling-example
{"language": "typescript", "file": "src/app/planner.ts", "parts": [
 {"code": "export interface Course {\n  id: string;\n  name: string;\n}\n\nexport interface Session {\n  id: number;\n  courseId: string;\n  date: string;\n  minutes: number;\n  done: boolean;\n}\n\nexport interface PlannerData {\n  courses: Course[];\n  sessions: Session[];\n}\nexport interface WeekRange {\n  start: string;\n  end: string;\n}\nexport function isoDay(date: Date): string {\n  const two = (n: number) => String(n).padStart(2, '0');\n  return `${date.getFullYear()}-${two(date.getMonth() + 1)}-${two(date.getDate())}`;\n}\nexport function weekOf(day: string): WeekRange {\n  const date = new Date(`${day}T12:00:00`);\n  const fromMonday = (date.getDay() + 6) % 7;\n  const monday = new Date(date);\n  monday.setDate(date.getDate() - fromMonday);\n  const sunday = new Date(monday);\n  sunday.setDate(monday.getDate() + 6);\n  return { start: isoDay(monday), end: isoDay(sunday) };\n}\nexport function inWeek(session: Session, week: WeekRange): boolean {\n  return session.date >= week.start && session.date <= week.end;\n}\nexport function totals(sessions: Session[], week: WeekRange): { planned: number; done: number } {\n  let planned = 0;\n  let done = 0;\n  for (const s of sessions) {\n    if (!inWeek(s, week)) continue;\n    planned += s.minutes;\n    if (s.done) done += s.minutes;\n  }\n  return { planned, done };\n}"},
 {"code": "export function parsePlanner(raw: unknown): PlannerData {\n  const data = raw as PlannerData;\n  if (!Array.isArray(data?.courses) || !Array.isArray(data?.sessions)) {\n    throw new Error('the answer has no courses or no sessions');\n  }", "note": "A resposta crua é `unknown`: nada é suposto sobre ela até ela ser olhada. O `as` deixa as checagens abaixo serem escritas; são as checagens que o tornam verdade."},
 {"code": "  for (const s of data.sessions) {\n    if (typeof s.minutes !== 'number') throw new Error(`session ${s.id}: minutes is ${JSON.stringify(s.minutes)}`);\n    if (typeof s.done !== 'boolean') throw new Error(`session ${s.id}: done is ${JSON.stringify(s.done)}`);\n  }\n  return data;\n}", "note": "Os dois campos de que a aritmética depende. Um erro lançado põe o resource no estado de erro, com esta mensagem."}
]}
```

O resource recebe a função, e tira o tipo do que a função retorna, então o argumento de tipo sai:

```typescript
// src/app/planner-store.ts
import { HttpClient, httpResource } from '@angular/common/http';
import { Injectable, computed, inject } from '@angular/core';
import { Session, isoDay, parsePlanner, totals, weekOf } from './planner';
import { TODAY } from './today';

@Injectable({
  providedIn: 'root',
})
export class PlannerStore {
  private readonly http = inject(HttpClient);
  private readonly data = httpResource(() => '/api/planner', { parse: parsePlanner });

  readonly isLoading = this.data.isLoading;
  readonly error = this.data.error;
  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));
  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));
  readonly week = weekOf(isoDay(inject(TODAY)));
  readonly weekTotals = computed(() => totals(this.sessions(), this.week));

  minutesThisWeek(courseId: string): number {
    return totals(this.sessions().filter((s) => s.courseId === courseId), this.week).planned;
  }

  toggle(id: number, done: boolean): void {
    this.data.update((data) =>
      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },
    );
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week
[vite] connecting...
[vite] connected.
Angular is running in development mode.
This week

2026-10-19 to 2026-10-25

The week could not be loaded: session 5: minutes is "50"
```

A página agora diz o que está errado, e onde, em vez de mostrar um número errado. Uma checagem deste
tamanho, à mão, basta para uma forma com cinco campos; para uma API de verdade com dezenas, uma
biblioteca como a Zod escreve a mesma checagem a partir de uma descrição da forma, e tira o tipo da
mesma descrição, para os dois não se afastarem.

A cópia do servidor volta a ter um número:

```
ana@dev:~/planner$ sed -i 's/"minutes": "50",/"minutes": 50,/' server/planner.json
```
