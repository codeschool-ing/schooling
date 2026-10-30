---
title: Rodando os testes
version: 1
---

**O `ng test` faz o build dos testes e os roda com o Vitest, numa imitação de navegador chamada
jsdom, sem janela e sem servidor.** Projetos Angular 21 usam o Vitest por padrão; projetos mais
antigos usam o Karma e um navegador de verdade, e a aula 24 diz o que mudou. Rode-o uma vez, agora,
com `--watch=false` para ele parar quando terminar:

```
ana@dev:~/planner$ npx ng test --watch=false
❯ Building...
✔ Building...
Initial chunk files                   | Names                              |  Raw size
chunk-CGZBV6BD.js                     | -                                  |   4.07 kB | 
spec-app-app.js                       | spec-app-app                       |   2.04 kB | 
spec-app-week-summary-week-summary.js | spec-app-week-summary-week-summary |   1.76 kB | 
init-testbed.js                       | init-testbed                       |   1.21 kB | 
vitest-mock-patch.js                  | vitest-mock-patch                  | 974 bytes | 
styles.css                            | styles                             |  56 bytes | 

                                      | Initial total                      |  10.11 kB

Application bundle generation complete. [1.857 seconds] - 2026-10-29T23:36:19.212Z


 RUN  v4.1.12 /home/ana/planner

 ✓ |planner| src/app/week-summary/week-summary.spec.ts (1 test) 40ms
 ❯ |planner| src/app/app.spec.ts (2 tests | 1 failed) 86ms
     ✓ should create the app 57ms
     × should render title 26ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  |planner| src/app/app.spec.ts > App > should render title
AssertionError: expected 'Study planner' to contain 'Hello, planner'

Expected: "Hello, planner"
Received: "Study planner"

 ❯ src/app/app.spec.ts:21:55
     19|     await fixture.whenStable();
     20|     const compiled = fixture.nativeElement as HTMLElement;
     21|     expect(compiled.querySelector('h1')?.textContent).toContain('Hello…
       |                                                       ^
     22|   });
     23| });

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯


 Test Files  1 failed | 1 passed (2)
      Tests  1 failed | 2 passed (3)
   Start at  20:36:19
   Duration  1.35s (transform 138ms, setup 735ms, import 152ms, tests 126ms, environment 1.30s)
```

Um teste falhou, e com razão. O teste que o `ng new` escreveu confere se o título da página diz
`Hello, planner`, e a seção anterior mudou o título. Leia o relatório de cima para baixo: o arquivo e o
teste que falhou, depois `AssertionError` e os dois valores lado a lado, `Expected` e `Received`,
depois a linha do teste com um acento circunflexo embaixo do lugar onde ele parou. Essa ordem é a
mesma em toda falha que o Vitest relata, e vale aprender a lê-la rápido.

O arquivo que a CLI escreveu, inteiro:

```
ana@dev:~/planner$ cat src/app/app.spec.ts
import { TestBed } from '@angular/core/testing';
import { App } from './app';

describe('App', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [App],
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(App);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('should render title', async () => {
    const fixture = TestBed.createComponent(App);
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('Hello, planner');
  });
});
```

`describe` dá nome a um grupo de testes e `it` a um teste. `TestBed` é o jeito do Angular de construir
um componente como a aplicação construiria, fora da aplicação, e `fixture.nativeElement` é o DOM que
ele desenhou. A aula 24 conta a história inteira; o que importa agora é a última linha do segundo
teste. Faça-a esperar o título que a página tem agora:

```typescript
// src/app/app.spec.ts
import { TestBed } from '@angular/core/testing';
import { App } from './app';

describe('App', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [App],
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(App);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('should render the heading', async () => {
    const fixture = TestBed.createComponent(App);
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toBe('Study planner');
  });
});
```

`toBe` é mais estrito que `toContain`: o título precisa ser exatamente aquele, não só conter.

```
ana@dev:~/planner$ npx ng test --watch=false
❯ Building...
✔ Building...
Initial chunk files                   | Names                              |  Raw size
chunk-CGZBV6BD.js                     | -                                  |   4.07 kB | 
spec-app-app.js                       | spec-app-app                       |   2.04 kB | 
spec-app-week-summary-week-summary.js | spec-app-week-summary-week-summary |   1.76 kB | 
init-testbed.js                       | init-testbed                       |   1.21 kB | 
vitest-mock-patch.js                  | vitest-mock-patch                  | 974 bytes | 
styles.css                            | styles                             |  56 bytes | 

                                      | Initial total                      |  10.11 kB

Application bundle generation complete. [1.835 seconds] - 2026-10-29T23:36:23.873Z


 RUN  v4.1.12 /home/ana/planner

 ✓ |planner| src/app/week-summary/week-summary.spec.ts (1 test) 41ms
 ✓ |planner| src/app/app.spec.ts (2 tests) 49ms

 Test Files  2 passed (2)
      Tests  3 passed (3)
   Start at  20:36:24
   Duration  1.09s (transform 119ms, setup 549ms, import 120ms, tests 90ms, environment 1.08s)
```

Três testes em dois arquivos: os dois do `app.spec.ts`, e o que veio com o `WeekSummary`.

Sem o `--watch=false`, o `ng test` se comporta como o `ng serve`: roda os testes, fica com o terminal,
e roda de novo os afetados toda vez que você salva. É assim que você vai rodá-lo enquanto trabalha; as
transcrições usam `--watch=false` porque uma aula precisa que o comando termine.
