---
title: Harnesses, para componentes que outra pessoa escreveu
version: 1
---

**Um harness de componente é uma API de teste para um componente, escrita pelos autores dele, para um
teste poder operá-lo sem conhecer o HTML.** O próximo teste marca "Hide sessions that are done". A
caixa é um `mat-checkbox`, e o jeito óbvio de marcá-la seria achar o `<input>` lá dentro e clicar
nele. Isso funciona hoje, e prende o teste a como o Material monta um checkbox por dentro, que é
assunto do Material e muda entre versões. O harness é a parte estável: o Material traz um para cada
componente dele como o jeito suportado de testá-los, e os métodos dele são feitos para continuar os
mesmos quando a marcação por baixo muda.

```schooling-example
{"language": "typescript", "file": "src/app/course-sessions/course-sessions.spec.ts", "parts": [
 {"code": "// src/app/course-sessions/course-sessions.spec.ts\nimport { TestbedHarnessEnvironment } from '@angular/cdk/testing/testbed';\nimport { provideHttpClient } from '@angular/common/http';\nimport { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';\nimport { TestBed } from '@angular/core/testing';\nimport { MatCheckboxHarness } from '@angular/material/checkbox/testing';", "note": "Dois imports a mais que antes: o ambiente de harness para o `TestBed`, do CDK, e o harness do checkbox, do ponto de entrada `testing` do próprio Material."},
 {"code": "import { PlannerData } from '../planner';\nimport { CourseSessions } from './course-sessions';\n\nconst planner: PlannerData = {\n  courses: [{ id: 'git', name: 'Git' }],\n  sessions: [\n    { id: 3, courseId: 'git', date: '2026-10-27', minutes: 40, done: false },\n    { id: 1, courseId: 'git', date: '2026-10-19', minutes: 30, done: true },\n    { id: 2, courseId: 'html-css', date: '2026-10-20', minutes: 60, done: false },\n  ],\n};\n\ndescribe('CourseSessions', () => {\n  beforeEach(() => {\n    localStorage.clear();\n    TestBed.configureTestingModule({\n      imports: [CourseSessions],\n      providers: [provideHttpClient(), provideHttpClientTesting()],\n    });\n  });\n\n  async function render() {\n    const fixture = TestBed.createComponent(CourseSessions);\n    fixture.componentRef.setInput('courseId', 'git');\n    TestBed.tick();\n    TestBed.inject(HttpTestingController).expectOne('/api/planner').flush(planner);\n    await fixture.whenStable();\n    return fixture;\n  }\n\n  it(\"lists the course's sessions, oldest first\", async () => {\n    const fixture = await render();\n    const rows = [...(fixture.nativeElement as HTMLElement).querySelectorAll('li')];\n    expect(rows.map((li) => li.textContent?.trim())).toEqual(['Mon 19 Oct, 30 minutes', 'Tue 27 Oct, 40 minutes']);\n  });\n"},
 {"code": "  it('hides the sessions that are done', async () => {\n    const fixture = await render();\n    const loader = TestbedHarnessEnvironment.loader(fixture);\n    const hide = await loader.getHarness(MatCheckboxHarness.with({ label: 'Hide sessions that are done' }));\n    await hide.check();\n", "note": "O loader acha harnesses dentro da fixture. O `with({ label })` escolhe o checkbox que uma pessoa escolheria, pelo que ele diz, e o `check()` o marca como um clique faria, eventos e tudo, e espera até o Angular ter desenhado o resultado."},
 {"code": "    const rows = await loader.getAllHarnesses(MatCheckboxHarness.with({ ancestor: 'app-session-list' }));\n    expect(await Promise.all(rows.map((row) => row.getLabelText()))).toEqual(['Tue 27 Oct, 40 minutes']);\n  });\n});", "note": "As linhas das sessões também são `mat-checkbox`, então o mesmo harness as lê, restrito às que estão dentro da lista."}
]}
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E '✓.*course-sessions|Tests '
 ✓ |planner| src/app/course-sessions/course-sessions.spec.ts (2 tests) 310ms
      Tests  21 passed (21)
```

Todo método de harness devolve uma promise, por isso o teste é `async` e cada chamada tem um `await`:
um harness espera o Angular terminar depois de cada ação, e o teste nunca precisa chamar o
`whenStable()` por conta própria. Os métodos são as perguntas que uma pessoa faria ao controle,
`isChecked()`, `getLabelText()`, `isDisabled()`, e as ações que ela faria, `check()`, `toggle()`. Um
harness de diálogo o abre e lê o título; um de select o abre e escolhe uma opção pelo texto.

**Harnesses não são só do Material.** O `ComponentHarness` do CDK é a classe que os do Material
estendem, e um componente seu pode ter um: uma classe que conhece o seletor do componente e como achar
as partes dele, com métodos com o nome do que uma pessoa faz. Para os componentes do próprio planner
não vale a pena, porque a marcação deles é do planner e os testes podem lê-la. Passa a valer para um
componente usado em muitos lugares, por pessoas que não deveriam precisar conhecer o interior dele,
que é exatamente a posição do Material.
