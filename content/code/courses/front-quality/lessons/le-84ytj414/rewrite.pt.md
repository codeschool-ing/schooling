---
title: Os testes de componente, reescritos
version: 1
---

**Os três testes da aula 2 dizem as mesmas coisas com as buscas novas, e um deles agora falha.**
Troque o `src/view.test.ts` por este:

```typescript
// src/view.test.ts
// @vitest-environment jsdom
import { expect, test } from "vitest";
import { screen, within } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import "@testing-library/jest-dom/vitest";
import { render } from "./view";
import type { Plan } from "./planner";
import data from "../public/courses.json";

const plan: Plan = data;

function show(route: string): void {
  document.body.innerHTML = '<div id="app"></div>';
  const root = document.querySelector<HTMLElement>("#app")!;
  let current = plan;
  const draw = () =>
    render(root, current, "2026-10-21", route, (next) => {
      current = next;
      draw();
    });
  draw();
}

test("the home page lists every course with its week", () => {
  show("");
  const items = within(screen.getByRole("list")).getAllByRole("listitem");
  expect(items.map((li) => li.textContent)).toEqual([
    "HTML and CSS 45 min this week",
    "JavaScript 90 min this week",
    "Git 25 min this week",
  ]);
  expect(screen.getByRole("link", { name: "JavaScript" })).toHaveAttribute("href", "#/course/javascript");
});

test("Done marks the session done and takes its button away", async () => {
  const user = userEvent.setup();
  show("#/course/javascript");
  await user.click(screen.getByRole("button", { name: "Done" }));
  expect(screen.queryByRole("button", { name: "Done" })).not.toBeInTheDocument();
  expect(screen.getByText("2026-10-22 · 30 min")).toHaveTextContent("done");
});

test("the form adds a session and the total follows", async () => {
  const user = userEvent.setup();
  show("#/course/javascript");
  await user.type(screen.getByLabelText("Date"), "2026-10-23");
  await user.type(screen.getByLabelText("Minutes"), "15");
  await user.click(screen.getByRole("button", { name: "Add session" }));
  expect(screen.getByText("This week: 105 min")).toBeInTheDocument();
});
```

O `show` desenha uma página como o `main.ts` faz e mantém o plano em dia, então os testes conseguem
usá-la por vários passos. O `screen` é o documento inteiro; o `within(elemento)` limita as buscas a
uma parte dele, aqui a lista. O teste do Done agora confere o que uma pessoa vê depois do clique, a
sessão dizendo *done* e nenhum botão sobrando, em vez de ler o plano de dentro de um mock: com o
`show` desenhando de novo a cada mudança, a própria página é a saída.

```
ana@dev:~/planner$ npx vitest run src/view.test.ts 2>&1 | head -n 30

 RUN  v5.0.5 /home/ana/planner

 ❯ src/view.test.ts (3 tests | 1 failed) 195ms
   × the form adds a session and the total follows 9ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/view.test.ts > the form adds a session and the total follows
TestingLibraryElementError: Unable to find a label with the text of: Date

Ignored nodes: comments, script, style
<body>
  <div
    id="app"
  >
    <a
      class="back"
      href="#/"
    >
      ←
    </a>
    <h1>
      JavaScript
    </h1>
    <ul
      class="sessions"
    >
      <li
        class="session done"
```

**O terceiro teste não acha um campo com o rótulo *Date*, porque não existe nenhum.** O relatório diz
o que procurou, e depois mostra a página em que procurou; as primeiras trinta linhas estão acima, e
mais abaixo o mesmo despejo mostra o motivo. Os campos do formulário têm `placeholder="Date"` e
`placeholder="Minutes"`, e não há `<label>` em lugar nenhum. O teste da aula 2 achava os mesmos campos
pelo `name` e nunca percebeu. A próxima seção explica por que isso é um defeito real, e não um teste
sendo exigente.
