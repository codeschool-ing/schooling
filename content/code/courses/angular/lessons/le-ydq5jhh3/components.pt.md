---
title: Um componente, pelo que ele mostra
version: 1
---

**Um teste de componente monta o componente com o `TestBed`, dá a ele o que precisa, e confere a
página que ele desenha.** O `CourseSessions` é um bom assunto: ele filtra as sessões do store para um
curso, ordena por data, e esconde as concluídas quando pedem. Cada uma dessas é uma regra que uma
pessoa lendo a página perceberia quebrar, então o teste lê a página:

```schooling-example
{"language": "typescript", "file": "src/app/course-sessions/course-sessions.spec.ts", "parts": [
 {"code": "// src/app/course-sessions/course-sessions.spec.ts\nimport { provideHttpClient } from '@angular/common/http';\nimport { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';\nimport { TestBed } from '@angular/core/testing';\nimport { PlannerData } from '../planner';\nimport { CourseSessions } from './course-sessions';\n"},
 {"code": "const planner: PlannerData = {\n  courses: [{ id: 'git', name: 'Git' }],\n  sessions: [\n    { id: 3, courseId: 'git', date: '2026-10-27', minutes: 40, done: false },\n    { id: 1, courseId: 'git', date: '2026-10-19', minutes: 30, done: true },\n    { id: 2, courseId: 'html-css', date: '2026-10-20', minutes: 60, done: false },\n  ],\n};\n", "note": "Três sessões, fora de ordem, uma delas de outro curso: o componente precisa escolher e ordenar, e os dados têm o formato que faz um erro em qualquer dos dois aparecer."},
 {"code": "describe('CourseSessions', () => {\n  beforeEach(() => {\n    localStorage.clear();\n    TestBed.configureTestingModule({\n      imports: [CourseSessions],\n      providers: [provideHttpClient(), provideHttpClientTesting()],\n    });\n  });\n", "note": "O `imports` recebe o componente testado, standalone como ele é. Os imports dele, o `MatCheckbox`, o `SessionList` e o resto, vêm junto, de verdade: é um teste do componente como a página o usa, não do componente sozinho. O `localStorage.clear()` porque o `Preferences` guarda o que um teste definiu para o seguinte."},
 {"code": "  async function render() {\n    const fixture = TestBed.createComponent(CourseSessions);\n    fixture.componentRef.setInput('courseId', 'git');\n    TestBed.tick();\n    TestBed.inject(HttpTestingController).expectOne('/api/planner').flush(planner);\n    await fixture.whenStable();\n    return fixture;\n  }\n", "note": "O `setInput` define um input de signal, como o template de um pai faria. Depois a requisição, respondida como na seção anterior, e o `whenStable()` até tudo que depende dela ter sido desenhado."},
 {"code": "  it(\"lists the course's sessions, oldest first\", async () => {\n    const fixture = await render();\n    const rows = [...(fixture.nativeElement as HTMLElement).querySelectorAll('li')];\n    expect(rows.map((li) => li.textContent?.trim())).toEqual(['Mon 19 Oct, 30 minutes', 'Tue 27 Oct, 40 minutes']);\n  });\n\n});", "note": "O teste lê a página, não os campos do componente: o texto de cada linha, como uma pessoa leria. Isso o faz passar para qualquer implementação que mostre as linhas certas, e falhar para qualquer uma que não mostre."}
]}
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E '✓.*course-sessions|Tests '
 ✓ |planner| src/app/course-sessions/course-sessions.spec.ts (1 test) 163ms
      Tests  20 passed (20)
```

O teste não fornece um `PlannerStore` falso. Poderia, com `{ provide: PlannerStore, useValue: ... }`,
e algumas equipes fazem isso para todo componente. Mas o store é parte do que a página do componente
depende, e com a camada HTTP falsa por baixo, o store de verdade não custa nada e pega mais: um teste
contra um falso escrito à mão confere o componente contra o falso, que concorda com o que o autor
dele acreditava. Troque uma dependência quando a de verdade é lenta, precisa de rede, ou faz um teste
depender de algo que não é o assunto dele.

## O marcador, feito para dizer alguma coisa

O `week-summary.spec.ts` foi criado com o componente na aula 2 e só perguntou, até hoje, se o
componente existe. O trabalho inteiro do componente são duas frases:

```typescript
// src/app/week-summary/week-summary.spec.ts
import { TestBed } from '@angular/core/testing';
import { WeekSummary } from './week-summary';

describe('WeekSummary', () => {
  it('says what is planned, what is done and what is left', async () => {
    const fixture = TestBed.createComponent(WeekSummary);
    fixture.componentRef.setInput('planned', 165);
    fixture.componentRef.setInput('done', 90);
    await fixture.whenStable();

    const text = (fixture.nativeElement as HTMLElement).textContent;
    expect(text).toContain('2 hours 45 minutes planned, 1 hour 30 minutes done.');
    expect(text).toContain('1 hour 15 minutes to go.');
  });
});
```

Nenhum `configureTestingModule`: um componente standalone sem dependências pode ser criado direto. Um
componente não é só a classe dele, então o "should create" prova menos do que parece: ele passa para
um template que mostra os números errados.

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E '✓.*week-summary|Tests '
 ✓ |planner| src/app/week-summary/week-summary.spec.ts (1 test) 24ms
      Tests  20 passed (20)
```
