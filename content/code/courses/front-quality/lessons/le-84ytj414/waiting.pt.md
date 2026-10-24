---
title: O que chega depois
version: 1
---

**Uma página que busca seus dados não desenha nada até os dados chegarem, então um teste dela precisa
esperar, e o `findBy…` é o jeito de esperar.** A busca dos dados do planner mora no `main.ts`, no nível
mais alto do módulo, onde nenhum teste a alcança: importar o arquivo o executaria. O primeiro passo é
levá-la para uma função que um teste consiga chamar.

Salve isto como `src/app.ts`:

```typescript
// src/app.ts
import { today, type Plan } from "./planner";
import { render } from "./view";

export async function start(root: HTMLElement, load = () => fetch("/courses.json")): Promise<void> {
  const response = await load();
  if (!response.ok) {
    root.textContent = "Could not load your courses.";
    return;
  }
  let plan: Plan = await response.json();
  const draw = (): void =>
    render(root, plan, today(), location.hash, (next) => {
      plan = next;
      draw();
    });
  window.addEventListener("hashchange", draw);
  draw();
}
```

E o `src/main.ts` encolhe para o que só um navegador faz, que é ligá-la:

```typescript
// src/main.ts
import "./style.css";
import { start } from "./app";

await start(document.querySelector<HTMLElement>("#app")!);
```

**O `load` é um parâmetro com o `fetch` de verdade como padrão.** A página não passa nada e busca o
`/courses.json` como antes; um teste passa uma função que responde o que o teste precisar, e nenhum
global é trocado. Salve isto como `src/app.test.ts`:

```typescript
// src/app.test.ts
// @vitest-environment jsdom
import { expect, test } from "vitest";
import { screen } from "@testing-library/dom";
import "@testing-library/jest-dom/vitest";
import { start } from "./app";
import data from "../public/courses.json";

function root(): HTMLElement {
  document.body.innerHTML = '<div id="app"></div>';
  return document.querySelector<HTMLElement>("#app")!;
}

test("the courses appear once the data has arrived", async () => {
  const started = start(root(), async () => Response.json(data));
  expect(screen.queryByRole("heading")).not.toBeInTheDocument();
  expect(await screen.findByRole("heading", { name: "Study planner" })).toBeInTheDocument();
  await started;
});

test("a failed load says so", async () => {
  await start(root(), async () => new Response("", { status: 500 }));
  expect(screen.getByText("Could not load your courses.")).toBeInTheDocument();
});
```

O primeiro teste confere a página duas vezes. Logo depois de o `start` ser chamado os dados ainda não
chegaram, e o `queryByRole` confirma que ainda não há título; depois o `findByRole` espera, tentando de
novo, até o título aparecer. O `Response.json(data)` monta a resposta que um servidor mandaria, com os
próprios dados do planner. O segundo teste responde com um 500, e a página diz isso.

```
ana@dev:~/planner$ npx vitest run src/app.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  2 passed (2)
   Start at  19:53:26
   Duration  983ms (environment 70%, tests 14%, import 9%, transform 7%, worker 1%)

ana@dev:~/planner$ npx tsc --noEmit
```

O `npx tsc --noEmit` não mostrou nada, então a mudança também passa na checagem de tipos. O app se
comporta exatamente como antes, e o servidor de desenvolvimento o serve do mesmo jeito; o que mudou é
que a única parte dele que a cobertura da aula 2 não alcançava agora é alcançável.

A suíte inteira, e o commit:

```
ana@dev:~/planner$ npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner


 Test Files  4 passed (4)
      Tests  27 passed (27)
   Start at  19:53:30
   Duration  1.25s (environment 67%, tests 20%, import 9%, transform 4%, worker 1%)
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Start the app from a function a test can call"
```

## Esperar, e não dormir

Um teste que espera com uma pausa fixa, meio segundo e depois olha, é um teste que falha numa máquina
lenta e perde tempo numa rápida. O `findBy…` consulta a página e volta assim que o elemento está lá, e
desiste depois de um segundo com o mesmo relatório que um `getBy…` dá. **Espere pela coisa, nunca pelo
relógio.** A aula 4 encontra a mesma regra num navegador de verdade, onde ela importa mais.
