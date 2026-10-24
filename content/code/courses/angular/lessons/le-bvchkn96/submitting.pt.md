---
title: Enviando, e esperando o servidor
version: 1
---

**Um formulário é enviado com `(ngSubmit)` no `<form>`, que o Angular dispara quando o formulário é
enviado e que impede o envio do próprio navegador, o que recarregaria a página.** Apertar Enter num
campo envia tanto quanto clicar num botão `type="submit"`, e isso é metade do motivo para usar um
`<form>` de verdade e um botão de envio de verdade: teclados e leitores de tela já sabem o que eles
querem dizer.

O store ganha o método que a aula 11 prometeu. Diferente do `toggle`, ele não é otimista: uma sessão
nova não tem id até o servidor dar um, então o store espera a resposta e acrescenta a sessão que o
servidor mandou de volta. Ele retorna o Observable em vez de assiná-lo, para quem o chama poder saber
quando terminou:

```schooling-example
{"language": "typescript", "file": "src/app/planner-store.ts", "parts": [
 {"code": "// src/app/planner-store.ts\nimport { HttpClient, HttpErrorResponse, httpResource } from '@angular/common/http';\nimport { Injectable, computed, inject, signal } from '@angular/core';\nimport { Observable, retry, tap, throwError, timer } from 'rxjs';\nimport { Session, isoDay, parsePlanner, totals, weekOf } from './planner';\nimport { TODAY } from './today';\n\nconst transient = (error: HttpErrorResponse) => error.status === 0 || error.status >= 500;\n\n@Injectable({\n  providedIn: 'root',\n})\nexport class PlannerStore {\n  private readonly http = inject(HttpClient);\n  private readonly data = httpResource(() => '/api/planner', { parse: parsePlanner });\n\n  readonly isLoading = this.data.isLoading;\n  readonly error = this.data.error;\n  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));\n  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));\n  readonly week = weekOf(isoDay(inject(TODAY)));\n  readonly weekTotals = computed(() => totals(this.sessions(), this.week));\n  readonly saveError = signal<string | null>(null);\n\n  minutesThisWeek(courseId: string): number {\n    return totals(this.sessions().filter((s) => s.courseId === courseId), this.week).planned;\n  }\n\n  toggle(id: number, done: boolean): void {\n    this.saveError.set(null);\n    this.setDone(id, done);\n    this.http\n      .patch<Session>(`/api/sessions/${id}`, { done })\n      .pipe(retry({ count: 3, delay: (error: HttpErrorResponse) => (transient(error) ? timer(2000) : throwError(() => error)) }))\n      .subscribe({\n        error: (error: HttpErrorResponse) => {\n          this.setDone(id, !done);\n          this.saveError.set(`Session ${id} was not saved: ${error.error?.error ?? error.statusText}`);\n        },\n      });\n  }", "note": "`Observable` para o tipo de retorno, e o `tap`, que roda para cada valor e o repassa."},
 {"code": "  add(draft: Omit<Session, 'id' | 'done'>): Observable<Session> {\n    return this.http.post<Session>('/api/sessions', draft).pipe(\n      tap((session) => this.data.update((data) => data && { ...data, sessions: [...data.sessions, session] })),\n    );\n  }", "note": "O que quem chama manda é uma sessão sem os dois campos que o servidor decide. A sessão acrescentada à cópia é a da resposta, com id e tudo. Sem `retry`: a aula 13 disse por quê."},
 {"code": "  private setDone(id: number, done: boolean): void {\n    this.data.update((data) =>\n      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },\n    );\n  }\n}"}
]}
```

O formulário precisa saber a que curso acrescenta, então recebe o id como input, e assina o `add`
para se reiniciar quando o servidor tiver dito sim:

```schooling-example
{"language": "typescript", "file": "src/app/add-session/add-session.ts", "parts": [
 {"code": "import { HttpErrorResponse } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';\nimport { FormControl, FormGroup, ReactiveFormsModule } from '@angular/forms';\nimport { PlannerStore } from '../planner-store';\n\n@Component({\n  selector: 'app-add-session',\n  imports: [ReactiveFormsModule],"},
 {"code": "  template: `\n    <form [formGroup]=\"form\" (ngSubmit)=\"submit()\">\n      <h3>Add a session</h3>\n      <label for=\"date\">Date</label>\n      <input id=\"date\" type=\"date\" formControlName=\"date\" />\n      <label for=\"minutes\">Minutes</label>\n      <input id=\"minutes\" type=\"number\" formControlName=\"minutes\" />\n      <button type=\"submit\">Add</button>\n      @if (error(); as message) {\n        <p role=\"alert\">{{ message }}</p>\n      }\n    </form>\n  `,\n  styles: `\n    form {\n      display: grid;\n      gap: 0.5rem;\n      max-width: 20rem;\n    }\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class AddSession {\n  readonly courseId = input.required<string>();\n  private readonly store = inject(PlannerStore);\n  protected readonly error = signal<string | null>(null);\n  protected readonly form = new FormGroup({\n    date: new FormControl('', { nonNullable: true }),\n    minutes: new FormControl(30, { nonNullable: true }),\n  });", "note": "`(ngSubmit)` no formulário, um botão de envio dentro dele, e a recusa do servidor num alerta, como a aula 12 fez para um salvamento."},
 {"code": "  protected submit(): void {\n    this.error.set(null);\n    this.store.add({ courseId: this.courseId(), ...this.form.getRawValue() }).subscribe({\n      next: () => this.form.reset(),\n      error: (error: HttpErrorResponse) => this.error.set(`Not added: ${error.error?.error ?? error.statusText}`),\n    });\n  }\n}", "note": "`getRawValue()` é `{ date, minutes }`, tipado por inteiro, e o espalhamento põe o curso ao lado. O `reset()` devolve os dois controles aos primeiros valores, porque eles são `nonNullable`."}
]}
```

```html
<!-- src/app/course-page/course-page.html -->
@if (store.isLoading()) {
  <p>Loading the course…</p>
} @else if (store.error(); as error) {
  <p>The course could not be loaded: {{ error.message }}</p>
} @else if (course(); as course) {
  <h2>{{ course.name }}</h2>
  @if (store.saveError(); as message) {
    <p role="alert">{{ message }}</p>
  }
  <app-session-list [sessions]="sessions()" (toggled)="store.toggle($event.id, $event.done)" />
  <app-add-session [courseId]="course.id" />
} @else {
  <p>There is no course called {{ courseId() }}.</p>
}
```

Uma sessão na segunda, dia 26, de 40 minutos:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-course-page --do 'fill Date = 2026-10-26' --do 'fill Minutes = 40' --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Date = 2026-10-26
-- fill Minutes = 40
-- click Add
JavaScript
 2026-10-13, 45 minutes
 2026-10-20, 60 minutes
 2026-10-24, 50 minutes
 2026-10-26, 40 minutes
Add a session
Date
Minutes
Add
```

A sessão nova está na lista, na ordem das datas, porque o `CoursePage` ordena o que o store tem, e o
store agora a tem. O terminal da API tem o `POST`, e um recarregamento a mostraria de novo a partir
do `planner.json`. Agora o mesmo botão sem data:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-course-page --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add
[error] Failed to load resource: the server responded with a status of 400 (Bad Request)
JavaScript
 2026-10-13, 45 minutes
 2026-10-20, 60 minutes
 2026-10-24, 50 minutes
 2026-10-26, 40 minutes
Add a session
Date
Minutes
Add

Not added: date must be YYYY-MM-DD
```

O formulário mandou uma data vazia, e o servidor a recusou com as próprias palavras. É o servidor
fazendo o trabalho dele, e o formulário não fazendo o seu: nada avisou a pessoa de que a data faltava
até um pedido atravessar a rede e voltar. A aula 15 confere os campos antes de mandar qualquer coisa,
e mantém a conferência do servidor, que é a que não pode ser pulada.
