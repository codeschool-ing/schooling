---
title: Os componentes do planner, como funções
version: 1
---

**Antes que algo possa ser mostrado sozinho, ele precisa existir sozinho.** O código de tela do planner
construía todo elemento no meio do caminho, então uma linha de sessão eram dez linhas no meio de
`coursePage`. Ela sai para um arquivo próprio, com mais duas peças que o planner repete: o botão de ação e
o resumo da semana.

O arquivo novo é a biblioteca de componentes do planner. Cada componente é uma função que recebe dados e
devolve um elemento, que é o formato que um Web Component, um componente React ou um do Angular também
têm, com outros nomes:

```schooling-example
{"language": "typescript", "file": "src/components.ts", "parts": [
 {"code": "// src/components.ts\nimport { duration } from \"./format\";\nimport type { Session } from \"./planner\";", "note": "A biblioteca depende dos tipos do planner e do formatador de duração, e de nada no `view.ts`. Essa direção importa: a página usa a biblioteca, nunca o contrário."},
 {"code": "\n/** The button for the one action of a row or a form. */\nexport function actionButton(label: string, onClick?: () => void): HTMLButtonElement {\n  const button = document.createElement(\"button\");\n  button.textContent = label;\n  if (onClick) button.addEventListener(\"click\", onClick);\n  return button;\n}", "note": "Um botão com um rótulo e, opcionalmente, algo para fazer. O botão de envio de um formulário não precisa de tratador: o próprio evento de envio do formulário faz o trabalho. O comentário acima da função é um comentário JSDoc, que a documentação do Storybook lê."},
 {"code": "\n/** One session: its date and length, then either \"done\" or a button that marks it done. */\nexport function sessionRow(session: Session, onDone?: (id: number) => void): HTMLLIElement {\n  const item = document.createElement(\"li\");\n  item.textContent = `${session.date} · ${duration(session.minutes)} `;\n  if (session.done) {\n    const done = document.createElement(\"span\");\n    done.textContent = \"done\";\n    item.append(done);\n  } else {\n    item.append(actionButton(\"Mark done\", () => onDone?.(session.id)));\n  }\n  return item;\n}", "note": "A linha, como a aula 1 a desenhava, usando o botão acima. O que acontece quando o botão é apertado é assunto de quem chama, passado como `onDone`."},
 {"code": "\n/** The week's total as a sentence, or a sentence saying there is nothing in it. */\nexport function weekSummary(week: { planned: number; done: number }): HTMLParagraphElement {\n  const summary = document.createElement(\"p\");\n  summary.textContent =\n    week.planned === 0\n      ? \"Nothing planned this week\"\n      : `This week: ${duration(week.planned)} planned, ${duration(week.done)} done`;\n  return summary;\n}", "note": "A linha da página inicial, agora com durações em horas e minutos, e um estado que ela nunca teve: uma semana vazia. É o tipo de estado que uma oficina faz você escrever, porque escrever os exemplos faz você perguntar o que acontece no zero."}
]}
```

O `view.ts` fica mais curto, porque agora usa a biblioteca em vez de construir as peças. Troque-o
inteiro:

```typescript
// src/view.ts
import { actionButton, sessionRow, weekSummary } from "./components";
import { title } from "./env";
import type { Course, Session } from "./planner";

export interface Actions {
  add(date: string, minutes: number): void;
  done(id: number): void;
}

const base = import.meta.env.BASE_URL;

function el<K extends keyof HTMLElementTagNameMap>(tag: K, text = ""): HTMLElementTagNameMap[K] {
  const node = document.createElement(tag);
  node.textContent = text;
  return node;
}

export function courseList(courses: Course[], week: { planned: number; done: number }): HTMLElement {
  const main = el("main");
  const list = el("ul");
  for (const course of courses) {
    const link = el("a", course.title);
    link.href = `${base}course/${course.id}`;
    list.append(el("li"));
    list.lastElementChild!.append(link);
  }
  main.append(el("h1", title), weekSummary(week), list);
  return main;
}

export function coursePage(course: Course, sessions: Session[], actions: Actions): HTMLElement {
  const main = el("main");
  const back = el("a", "All courses");
  back.href = base;
  const list = el("ul");
  for (const s of sessions) list.append(sessionRow(s, actions.done));
  const form = el("form");
  const date = el("input");
  date.type = "date";
  date.required = true;
  const minutes = el("input");
  minutes.type = "number";
  minutes.min = "5";
  minutes.required = true;
  const dateLabel = el("label", "Date ");
  dateLabel.append(date);
  const minutesLabel = el("label", "Minutes ");
  minutesLabel.append(minutes);
  form.append(dateLabel, minutesLabel, actionButton("Add session"));
  form.addEventListener("submit", (event) => {
    event.preventDefault();
    actions.add(date.value, Number(minutes.value));
  });
  main.append(back, el("h1", course.title), list, el("h2", "New session"), form);
  return main;
}

export function notFound(): HTMLElement {
  const main = el("main");
  const back = el("a", "All courses");
  back.href = base;
  main.append(el("h1", "Not found"), back);
  return main;
}
```

As conferências da aula 3 dizem que nada quebrou:

```
ana@dev:~/planner$ npx tsc && npm test 2>&1 | grep Tests
      Tests  5 passed (5)
```

Abra a página inicial e a linha dela agora diz *This week: 2 h 10 min planned, 1 h done*: os mesmos
números, escritos pelo `weekSummary`.
