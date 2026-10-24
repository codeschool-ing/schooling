---
title: Um teste de componente, numa página que não existe
version: 1
---

**O `view.ts` cria elementos e escuta cliques, então os testes dele precisam de um documento, e o
jsdom é um: o DOM escrito em JavaScript, rodando no Node, sem tela por trás.** O Vitest o sobe para
qualquer arquivo de teste que pedir. É um pacote separado, e este curso fixa o 29.1.1: o jsdom 30 pede
o Node 22.22.2 ou mais novo, uma versão de correção além do Node com que este curso foi gravado, e o
npm reclama a cada instalação de um Node que não lhe foi prometido.

```
ana@dev:~/planner$ npm install --save-exact -D jsdom@29.1.1

added 38 packages, and audited 77 packages in 2s

found 0 vulnerabilities
```

Salve isto como `src/view.test.ts`:

```typescript
// src/view.test.ts
// @vitest-environment jsdom
import { beforeEach, expect, test, vi } from "vitest";
import { render } from "./view";
import type { Plan } from "./planner";
import data from "../public/courses.json";

const plan: Plan = data;
let root: HTMLElement;

beforeEach(() => {
  document.body.innerHTML = '<div id="app"></div>';
  root = document.querySelector<HTMLElement>("#app")!;
});

test("the home page lists every course with its week", () => {
  render(root, plan, "2026-10-21", "", () => {});
  const items = [...root.querySelectorAll(".courses li")].map((li) => li.textContent);
  expect(items).toEqual(["HTML and CSS 45 min this week", "JavaScript 90 min this week", "Git 25 min this week"]);
});

test("Done hands back a plan in which that session is done", () => {
  const update = vi.fn();
  render(root, plan, "2026-10-21", "#/course/javascript", update);
  root.querySelector<HTMLButtonElement>(".tick")!.click();
  expect(update).toHaveBeenCalledTimes(1);
  const next: Plan = update.mock.calls[0][0];
  expect(next.sessions.find((s) => s.id === 4)?.done).toBe(true);
});

test("the form adds a session and the total follows", () => {
  let current = plan;
  const draw = () =>
    render(root, current, "2026-10-21", "#/course/javascript", (next) => {
      current = next;
      draw();
    });
  draw();
  root.querySelector<HTMLInputElement>("[name=date]")!.value = "2026-10-23";
  root.querySelector<HTMLInputElement>("[name=minutes]")!.value = "15";
  root.querySelector("form")!.requestSubmit();
  expect(root.querySelector(".week")!.textContent).toBe("This week: 105 min");
});
```

O comentário da segunda linha é lido pelo Vitest: **o `@vitest-environment jsdom` dá um documento a
este arquivo**, e o `planner.test.ts`, que não tem essa linha, continua rodando no Node puro, onde
começa mais rápido. O `beforeEach` dá a cada teste um `#app` novo e vazio, então nenhum teste vê o que
o anterior desenhou.

O terceiro teste é aquele de que o troféu fala. Ele desenha a página do curso como o `main.ts` faz,
com um `update` que guarda o plano novo e desenha de novo, depois preenche os dois campos, envia o
formulário e lê o total que foi desenhado como resultado. **A ligação de três arquivos está sob
teste, e nenhum navegador foi aberto**: o `view.ts` lendo o formulário, o `addSession` aceitando os
valores, e o `weekTotal` somando.

```
ana@dev:~/planner$ npx vitest run src/view.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  3 passed (3)
   Start at  19:52:54
   Duration  833ms (environment 82%, transform 9%, tests 7%, import 2%, worker 1%)
```

## O que o jsdom não faz

Estes testes acham as coisas com seletores CSS, `.tick` e `[name=minutes]`, que é o hábito contra o
qual a aula 1 avisou: renomeie uma classe e eles quebram sem que nada tenha mudado. A aula 3 os troca
por buscas pelo que uma pessoa lê. E o jsdom não desenha nada: o `requestSubmit()` rodou o tratador do
envio, mas nada aqui poderia dizer que o botão estava escondido, ou o texto cinza sobre cinza. **Um
teste de componente que passa quer dizer que a ligação funciona, não que a tela é utilizável**, e as
aulas 4 e 10 são onde a tela é conferida.
