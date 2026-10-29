---
title: O store, contra um servidor falso
version: 1
---

**Um serviço que conversa com um servidor se testa com um falso: o `HttpTestingController` fica onde
a rede estaria, e o teste decide com o que cada requisição é respondida.** A aula 10 disse que esta
aula testaria os totais desse jeito. Nada sai do teste, cada resposta está escrita nele, e o store não
tem como notar a diferença. O marcador do CLI no `planner-store.spec.ts` dá lugar a dois testes que
dizem alguma coisa:

```schooling-example
{"language": "typescript", "file": "src/app/planner-store.spec.ts", "parts": [
 {"code": "// src/app/planner-store.spec.ts\nimport { provideHttpClient } from '@angular/common/http';\nimport { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';\nimport { ApplicationRef } from '@angular/core';\nimport { TestBed } from '@angular/core/testing';\nimport { PlannerData } from './planner';\nimport { PlannerStore } from './planner-store';\nimport { TODAY } from './today';\n"},
 {"code": "const planner: PlannerData = {\n  courses: [{ id: 'git', name: 'Git' }],\n  sessions: [\n    { id: 1, courseId: 'git', date: '2026-10-19', minutes: 30, done: true },\n    { id: 2, courseId: 'git', date: '2026-10-24', minutes: 50, done: false },\n    { id: 3, courseId: 'git', date: '2026-10-27', minutes: 40, done: false },\n  ],\n};\n", "note": "O planner, como o servidor falso vai mandar: três sessões de um curso, duas na semana de 23 de outubro."},
 {"code": "describe('PlannerStore', () => {\n  let store: PlannerStore;\n  let server: HttpTestingController;\n\n  beforeEach(() => {\n    TestBed.configureTestingModule({\n      providers: [\n        provideHttpClient(),\n        provideHttpClientTesting(),\n        { provide: TODAY, useValue: new Date('2026-10-23T09:00:00') },\n      ],\n    });\n    store = TestBed.inject(PlannerStore);\n    server = TestBed.inject(HttpTestingController);\n  });\n", "note": "Dois providers deixam o `HttpClient` real e o backend dele falso: o `provideHttpClient()`, e depois o `provideHttpClientTesting()`, que precisa vir depois dele. O `TODAY` é fixo, como a aula 10 tornou possível, para a semana não depender de quando o teste roda."},
 {"code": "  afterEach(() => server.verify());\n", "note": "Depois de cada teste, o `verify()` falha se foi feita uma requisição que o teste nunca respondeu: uma requisição que ninguém esperava também é um achado."},
 {"code": "  async function load(): Promise<void> {\n    TestBed.tick();\n    server.expectOne('/api/planner').flush(planner);\n    await TestBed.inject(ApplicationRef).whenStable();\n  }\n", "note": "O `TestBed.tick()` roda o que o Angular rodaria sozinho numa aplicação, e o resource manda a requisição nessa hora. O `expectOne` acha essa requisição, ou falha; o `flush` a responde. O `whenStable()` espera o resource receber a resposta."},
 {"code": "  it('totals the week from what the server sent', async () => {\n    await load();\n    expect(store.weekTotals()).toEqual({ planned: 80, done: 30 });\n  });\n", "note": "O primeiro teste lê o que as telas leem, o `weekTotals()`: 30 + 50 planejados, 30 concluídos."},
 {"code": "  it('puts a session back when the server refuses the change', async () => {\n    await load();\n    store.toggle(2, true);\n    expect(store.weekTotals().done).toBe(80);\n\n    server\n      .expectOne({ method: 'PATCH', url: '/api/sessions/2' })\n      .flush({ error: 'done must be true or false' }, { status: 400, statusText: 'Bad Request' });\n\n    expect(store.weekTotals().done).toBe(30);\n    expect(store.saveError()).toBe('Session 2 was not saved: done must be true or false');\n  });\n});", "note": "O segundo marca uma sessão, confere a mudança otimista, e responde o `PATCH` com o `400` que a API de verdade manda para um corpo errado. O store precisa pôr a sessão de volta e dizer por quê."}
]}
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E '✓.*planner-store|Tests '
 ✓ |planner| src/app/planner-store.spec.ts (2 tests) 24ms
      Tests  19 passed (19)
```

## Por que o `TestBed.tick()`

É uma linha fácil de esquecer, porque nada no teste parece precisar dela. Tire-a, e:

```
ana@dev:~/planner$ sed -i 's|^    TestBed.tick();|    // TestBed.tick();|' src/app/planner-store.spec.ts
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error|Tests '
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 2 ⎯⎯⎯⎯⎯⎯⎯
 FAIL  |planner| src/app/planner-store.spec.ts > PlannerStore > totals the week from what the server sent
Error: Expected one matching request for criteria "Match URL: /api/planner", found none.
 FAIL  |planner| src/app/planner-store.spec.ts > PlannerStore > puts a session back when the server refuses the change
Error: Expected one matching request for criteria "Match URL: /api/planner", found none.
      Tests  2 failed | 17 passed (19)
```

"found none". Um resource não manda a requisição quando é criado: ele a manda de um effect, e effects
rodam quando o Angular sincroniza da próxima vez, o que numa aplicação acontece sozinho um instante
depois. Um teste não é uma aplicação; nada roda até o teste mandar, e o `TestBed.tick()` é como ele
manda. O mesmo vale para qualquer outra coisa feita de effects ou de detecção de mudanças, e é por
isso que a maioria dos testes desta aula tem um `tick()` ou um `whenStable()`.

```
ana@dev:~/planner$ sed -i 's|^    // TestBed.tick();|    TestBed.tick();|' src/app/planner-store.spec.ts
```

## Para que o servidor falso serve

O segundo teste é o valioso. Um `PATCH` que falha é difícil de produzir à mão: a aula 12 precisou
parar a API numa janela de cinco segundos para ver um. Aqui é uma linha, e roda toda vez. Responder
com um erro é a mesma chamada de responder com dados, o `flush`, com um `status`; uma falha de rede
sem resposta nenhuma é `error(new ProgressEvent('error'))`. Cada caminho do store pode ter um teste,
as novas tentativas de um `500` inclusive, sem nada estar fora do ar.

O que um servidor falso não testa é o de verdade. Se a API trocasse o campo do erro, esses testes
continuariam passando contra a resposta com que foram escritos. Esse é o nível acima deste, e a
última seção desta aula diz quem o confere.
