---
title: HttpClient, e um resource que o usa
version: 1
---

**O `HttpClient` é o serviço do Angular para conversar com um servidor.** O `fetch` funciona numa
aplicação Angular, e a aula 6 o usou, mas o `HttpClient` faz três coisas que o `fetch` deixa com
você: lê o JSON por você, trata um 404 ou um 500 como erro em vez de resposta, e todo pedido que ele
faz passa por interceptors, que a sexta seção desta aula usa. Ele é um serviço como qualquer outro,
então uma classe recebe um com `inject(HttpClient)`.

No Angular 21 nada precisa ser fornecido antes: o `HttpClient` tem `providedIn: 'root'`, e manda os
pedidos com `XMLHttpRequest`. Código escrito para versões anteriores sempre lista
`provideHttpClient()` no `app.config.ts`, porque sem ele não havia `HttpClient` para injetar; a
linha ainda é como os recursos dele são ligados, e o planner a acrescenta quando precisar de um.

## O store lê da API

Para ler, o `@angular/common/http` tem um resource próprio, o `httpResource`: um `resource` cujo
loader é um GET do `HttpClient`. Ele recebe uma função que retorna a URL, então uma URL montada a
partir de signals é buscada de novo quando eles mudam, como os `params` da aula 6. Como o `resource`,
ele é marcado como experimental no Angular 21. O store muda em três linhas:

```schooling-example
{"language": "typescript", "file": "src/app/planner-store.ts", "parts": [
 {"code": "// src/app/planner-store.ts\nimport { HttpClient, httpResource } from '@angular/common/http';\nimport { Injectable, computed, inject } from '@angular/core';\nimport { PlannerData, Session, isoDay, totals, weekOf } from './planner';\nimport { TODAY } from './today';\n\n@Injectable({\n  providedIn: 'root',\n})\nexport class PlannerStore {", "note": "O `HttpClient` e o `httpResource` vêm do pacote HTTP do Angular. O `loadPlanner` não é mais importado."},
 {"code": "  private readonly http = inject(HttpClient);\n  private readonly data = httpResource<PlannerData>(() => '/api/planner');", "note": "O `HttpClient` é para escrever, duas seções adiante. O resource lê: o argumento de tipo diz o que se espera que a resposta seja."},
 {"code": "  readonly isLoading = this.data.isLoading;\n  readonly error = this.data.error;\n  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));\n  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));\n  readonly week = weekOf(isoDay(inject(TODAY)));\n  readonly weekTotals = computed(() => totals(this.sessions(), this.week));\n\n  minutesThisWeek(courseId: string): number {\n    return totals(this.sessions().filter((s) => s.courseId === courseId), this.week).planned;\n  }\n\n  toggle(id: number, done: boolean): void {\n    this.data.update((data) =>\n      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },\n    );\n  }\n}"}
]}
```

Nada mais muda. Os componentes pedem ao store os mesmos signals, e o store os enche a partir de
outro lugar:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week-summary --network
[vite] connecting...
[vite] connected.
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
165 minutes planned, 90 done.

75 minutes to go.

Done this week
```

A mesma semana, vinda de `/api/planner`, e o terminal da API tem mais uma linha `GET`. A página se
conectou ao servidor de desenvolvimento duas vezes: ela foi a primeira página a importar o
`@angular/common/http`, então o servidor de desenvolvimento preparou esse pacote para o navegador e
recarregou a página, e o terminal dele diz `new dependencies optimized: @angular/common/http`. Isso
acontece uma vez por pacote. O `loadPlanner` no `planner.ts` não tem mais quem o chame; a próxima
seção o troca por algo de que o resource precisa mais.
