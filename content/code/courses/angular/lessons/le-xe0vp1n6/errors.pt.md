---
title: Quando o servidor diz não, ou não diz nada
version: 1
---

**Um pedido pode falhar de dois jeitos, e o `HttpClient` relata os dois como um
`HttpErrorResponse`.** O servidor pode responder com um status de erro, 400, 404 ou 500, e um corpo
dizendo por quê; ou pode não haver resposta nenhuma, porque o servidor caiu ou a rede caiu, e aí o
status é 0, ou, pelo proxy do servidor de desenvolvimento, um 500 que o proxy inventou. De um jeito
ou de outro, o Observable do pedido termina com um erro em vez de um valor.

A leitura já trata disso. O resource vai para o estado de erro, e os templates da aula 6 mostram a
mensagem. Pare a API com `Ctrl-C` no terminal dela, e carregue a página:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week --network
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  500
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
This week

2026-10-19 to 2026-10-25

The week could not be loaded: Http failure response for http://localhost:4200/api/planner: 500 Internal Server Error
```

O terminal do servidor de desenvolvimento diz o que houve por trás daquele 500, em duas linhas:
`[vite] http proxy error: /api/planner` e `Error: connect ECONNREFUSED 127.0.0.1:3000`. O proxy
tentou a porta 3000, nada estava escutando, e ele respondeu ao navegador com um status próprio.

## Uma escrita que falha

Escrever é o caso mais difícil, porque a página já disse sim. Inicie a API de novo com
`node server/api.mjs`, e desta vez deixe a página carregar e pare a API antes de marcar. O
`--do 'wait 5000'` dá cinco segundos para apertar `Ctrl-C` no terminal da API. O `--a11y` mostra o
estado da caixa como um leitor de tela o ouviria, `checked` ou não:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --a11y app-course-page --do 'wait 5000' --do 'check 2026-10-24, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- wait 5000
-- check 2026-10-24, 50 minutes
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
[error] HttpErrorResponse
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

O `PATCH` falhou, e a caixa ficou marcada. A página diz que a sessão está feita e o servidor nunca
ficou sabendo: recarregue, e a marcação some. O erro em si chegou ao console, como
`HttpErrorResponse`, porque ninguém o tratou; uma pessoa olhando a página não vê nada. **Uma
atualização otimista tem de ser desfeita quando o servidor a recusa**, e a pessoa tem de ser avisada.

O `subscribe` aceita um objeto com um callback `error`. O store põe a sessão de volta e guarda uma
mensagem, num signal que a página do curso pode mostrar:

```schooling-example
{"language": "typescript", "file": "src/app/planner-store.ts", "parts": [
 {"code": "// src/app/planner-store.ts\nimport { HttpClient, HttpErrorResponse, httpResource } from '@angular/common/http';\nimport { Injectable, computed, inject, signal } from '@angular/core';\nimport { Session, isoDay, parsePlanner, totals, weekOf } from './planner';\nimport { TODAY } from './today';\n\n@Injectable({\n  providedIn: 'root',\n})\nexport class PlannerStore {\n  private readonly http = inject(HttpClient);\n  private readonly data = httpResource(() => '/api/planner', { parse: parsePlanner });\n\n  readonly isLoading = this.data.isLoading;\n  readonly error = this.data.error;\n  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));\n  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));\n  readonly week = weekOf(isoDay(inject(TODAY)));\n  readonly weekTotals = computed(() => totals(this.sessions(), this.week));\n  readonly saveError = signal<string | null>(null);\n\n  minutesThisWeek(courseId: string): number {\n    return totals(this.sessions().filter((s) => s.courseId === courseId), this.week).planned;\n  }", "note": "`HttpErrorResponse` é o tipo do que um pedido que falhou relata, e o `signal` guarda a mensagem."},
 {"code": "  toggle(id: number, done: boolean): void {\n    this.saveError.set(null);\n    this.setDone(id, done);\n    this.http.patch<Session>(`/api/sessions/${id}`, { done }).subscribe({\n      error: (error: HttpErrorResponse) => {\n        this.setDone(id, !done);\n        this.saveError.set(`Session ${id} was not saved: ${error.error?.error ?? error.statusText}`);\n      },\n    });\n  }", "note": "A marcação aparece na hora, como antes. Se o servidor recusar, a sessão volta e a mensagem diz por quê: a frase do próprio servidor quando ele mandou uma, o texto do status quando não havia ninguém para mandar."},
 {"code": "  private setDone(id: number, done: boolean): void {\n    this.data.update((data) =>\n      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },\n    );\n  }\n}", "note": "A mudança na cópia, agora feita em dois lugares, vira um método privado só dela."}
]}
```

A página do curso mostra a mensagem acima da lista. O `role="alert"` faz um leitor de tela anunciá-la
no momento em que aparece, o que importa aqui: a caixa que a pessoa acabou de marcar se desmarcou
sozinha, e quem não consegue ver isso precisa ouvir por quê.

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
} @else {
  <p>There is no course called {{ courseId() }}.</p>
}
```

Inicie a API, e os mesmos cinco segundos e o mesmo `Ctrl-C`:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --a11y app-course-page --do 'wait 5000' --do 'check 2026-10-24, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- wait 5000
-- check 2026-10-24, 50 minutes
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
- heading "JavaScript" [level=2]
- alert
  - text: Session 5 was not saved: Internal Server Error
- list
  - listitem [level=1]
    - ListMarker "• "
    - checkbox " 2026-10-13, 45 minutes" [checked]
  - listitem [level=1]
    - ListMarker "• "
    - checkbox " 2026-10-20, 60 minutes" [checked]
  - listitem [level=1]
    - ListMarker "• "
    - checkbox " 2026-10-24, 50 minutes" [focused]
```

A caixa está desmarcada, e a página diz por quê. "Internal Server Error" é do proxy, porque a API não
estava lá para dizer nada; com a API no ar e recusando, a mensagem seria a frase dela,
`done must be true or false` ou `there is no session 9`.

**Nem toda falha merece uma nova tentativa, e nenhuma merece silêncio.** Um 400 vai falhar do mesmo
jeito toda vez, então tentar de novo é ruído. Uma falha de rede pode não falhar, e a aula 13 tenta
essas de novo com um operador do RxJS. O que nenhuma falha pode fazer é deixar a página dizendo algo
em que o servidor não acredita.

Com a API rodando de novo, o planner vai para um commit:

```
ana@dev:~/planner$ git add -A && git commit -q -m "HttpClient: the planner talks to its own API"
```
