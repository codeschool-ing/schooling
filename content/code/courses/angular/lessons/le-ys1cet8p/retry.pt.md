---
title: Tentando de novo o que pode dar certo na segunda vez
version: 1
---

**A aula 12 deixou o planner desfazendo uma marcação sempre que um `PATCH` falhava, fosse qual fosse o
motivo.** Isso está certo para um 400, que vai falhar do mesmo jeito toda vez que for mandado. É
apressado demais para um 500 de um servidor que está reiniciando, ou de uma rede que caiu por um
segundo, onde o mesmo pedido um instante depois teria funcionado.

O `retry` assina de novo depois de um erro, o que num Observable do `HttpClient` quer dizer mandar o
pedido de novo. A opção `delay` dele decide, para cada erro, se tenta de novo e quando: um Observable
que emite quer dizer "tente agora", um que dá erro quer dizer "pare, e repasse este erro".

```schooling-example
{"language": "typescript", "file": "src/app/planner-store.ts", "parts": [
 {"code": "// src/app/planner-store.ts\nimport { HttpClient, HttpErrorResponse, httpResource } from '@angular/common/http';\nimport { Injectable, computed, inject, signal } from '@angular/core';\nimport { retry, throwError, timer } from 'rxjs';\nimport { Session, isoDay, parsePlanner, totals, weekOf } from './planner';\nimport { TODAY } from './today';\n\nconst transient = (error: HttpErrorResponse) => error.status === 0 || error.status >= 500;", "note": "Os operadores vêm do `rxjs`; o `transient` é uma função comum que diz quais falhas merecem uma segunda tentativa."},
 {"code": "@Injectable({\n  providedIn: 'root',\n})\nexport class PlannerStore {\n  private readonly http = inject(HttpClient);\n  private readonly data = httpResource(() => '/api/planner', { parse: parsePlanner });\n\n  readonly isLoading = this.data.isLoading;\n  readonly error = this.data.error;\n  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));\n  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));\n  readonly week = weekOf(isoDay(inject(TODAY)));\n  readonly weekTotals = computed(() => totals(this.sessions(), this.week));\n  readonly saveError = signal<string | null>(null);\n\n  minutesThisWeek(courseId: string): number {\n    return totals(this.sessions().filter((s) => s.courseId === courseId), this.week).planned;\n  }"},
 {"code": "  toggle(id: number, done: boolean): void {\n    this.saveError.set(null);\n    this.setDone(id, done);\n    this.http\n      .patch<Session>(`/api/sessions/${id}`, { done })\n      .pipe(retry({ count: 3, delay: (error: HttpErrorResponse) => (transient(error) ? timer(2000) : throwError(() => error)) }))\n      .subscribe({\n        error: (error: HttpErrorResponse) => {\n          this.setDone(id, !done);\n          this.saveError.set(`Session ${id} was not saved: ${error.error?.error ?? error.statusText}`);\n        },\n      });\n  }", "note": "Até mais três tentativas, com dois segundos entre elas, para uma falha que pode passar. Qualquer outra, um 400 ou um 404, vai direto para o callback `error`, como antes."},
 {"code": "  private setDone(id: number, done: boolean): void {\n    this.data.update((data) =>\n      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },\n    );\n  }\n}"}
]}
```

O teste é a página do curso, com os mesmos cinco segundos da aula 12, o mesmo `Ctrl-C` no terminal
da API, e depois, alguns segundos depois da marcação, `node server/api.mjs` de novo:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --a11y app-course-page --network --do 'wait 5000' --do 'check 2026-10-24, 50 minutes' --do 'wait 4000'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
net  GET /api/planner  200
-- wait 5000
-- check 2026-10-24, 50 minutes
net  PATCH /api/sessions/5  500
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
-- wait 4000
net  PATCH /api/sessions/5  200
- heading "JavaScript" [level=2]
- list
  - listitem [level=1]
    - ListMarker "• "
    - checkbox " 2026-10-13, 45 minutes" [checked]
  - listitem [level=1]
    - ListMarker "• "
    - checkbox " 2026-10-20, 60 minutes" [checked]
  - listitem [level=1]
    - ListMarker "• "
    - checkbox " 2026-10-24, 50 minutes" [focused] [checked]
```

O primeiro `PATCH` encontrou o 500 do proxy. Dois segundos depois o `retry` o mandou de novo, a API
tinha voltado, e respondeu 200. A caixa ficou marcada, nenhuma mensagem apareceu, e a pessoa nem
ficou sabendo.

**Só tente de novo o que é seguro mandar duas vezes.** Definir `done` como `true` duas vezes deixa a
sessão igual a defini-lo uma vez; um `PATCH` como este, e um `GET`, são seguros de repetir. Um `POST`
que acrescenta uma sessão não é: se o primeiro chegou ao servidor e só a resposta dele se perdeu, uma
nova tentativa acrescenta uma segunda sessão. O formulário da aula 14 manda um `POST`, e não tenta de
novo.
