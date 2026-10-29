---
title: O planner de estudos, o app que este curso publica
version: 1
---

**Toda aula deste curso trabalha com um app pequeno, e você o constrói aqui, inteiro.** É um planner de
estudos: lista os seus cursos, abre um, deixa você acrescentar sessões de estudo com data e duração,
marca as sessões como feitas e mostra o total da semana. É TypeScript puro construído com o Vite, sem
framework, porque nada do que este curso ensina depende de um: um host serve os arquivos que um build de
React, Angular, Vue ou Svelte grava exatamente como serve estes. Se você fez front-quality ou
front-performance, já conhece este app. Os arquivos abaixo são a versão de onde este curso parte, então
construa de novo a partir deles: se um `~/planner` de um curso anterior ainda estiver lá, tire-o do
caminho antes com `mv ~/planner ~/planner-before`, e nada que você tenha acrescentado nele muda o que
você vê aqui.

## O projeto

`npm create vite` grava um projeto inicial a partir de um template. A versão depois do `@` é fixada para
você receber os mesmos arquivos que esta aula recebeu, e `vanilla-ts` é o template com TypeScript e sem
framework:

```
ana@dev:~$ npm create vite@9.3.1 planner -- --template vanilla-ts --no-interactive
npm warn exec The following package was not found and will be installed: create-vite@9.3.1

> npx
> cva planner --template vanilla-ts --no-interactive


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/planner...
│
└  Done. Now run:

  cd planner
  npm install
  npm run dev
```

O template vem com uma demonstração de contador, que sai, e com as dependências escritas como
intervalos: `^8.3.4` quer dizer qualquer 8.x de 8.3.4 para cima. **Este curso fixa versões exatas**, para
que o build que você roda na aula 3 numa máquina limpa seja o mesmo que você rodou aqui, e `--save-exact`
as grava sem o `^`:

```
ana@dev:~$ cd planner
ana@dev:~/planner$ rm -r src/counter.ts src/assets public/icons.svg
ana@dev:~/planner$ npm install --save-dev --save-exact vite@8.3.5 typescript@6.0.3

added 16 packages, and audited 17 packages in 10s

8 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ cat package.json
{
  "name": "planner",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "typescript": "6.0.3",
    "vite": "8.3.5"
  }
}
```

As duas versões no `package.json` agora são exatas: **Vite 8.3.5 e TypeScript 6.0.3**. O lockfile,
`package-lock.json`, registra a versão exata de cada pacote por baixo delas também, e vai para o commit
junto com o código. A aula 3 diz por que esse é o arquivo em que o CI confia.

## Os dados

O planner lê um arquivo, servido ao lado da página. Tudo o que está em `public/` é copiado para o build
sem mudança, então este arquivo é alcançado em `/courses.json` tanto enquanto você desenvolve quanto
depois de publicado.

```schooling-example
{"language": "json", "file": "public/courses.json", "parts": [
 {"code": "{\n  \"courses\": [\n    { \"id\": \"html-css\", \"title\": \"HTML and CSS\" },\n    { \"id\": \"javascript\", \"title\": \"JavaScript\" },\n    { \"id\": \"git\", \"title\": \"Git\" }\n  ],", "note": "Três cursos. O `id` é aquilo a que um link e uma sessão se referem; o `title` é só o que uma pessoa lê, e pode mudar sem quebrar nada."},
 {"code": "  \"sessions\": [\n    { \"id\": 1, \"course\": \"html-css\", \"date\": \"2026-10-05\", \"minutes\": 50, \"done\": true },\n    { \"id\": 2, \"course\": \"javascript\", \"date\": \"2026-10-06\", \"minutes\": 40, \"done\": true },\n    { \"id\": 3, \"course\": \"git\", \"date\": \"2026-10-08\", \"minutes\": 30, \"done\": true },", "note": "Seis sessões em outubro de 2026. Uma data é escrita como `YYYY-MM-DD`, que se ordena corretamente como texto, então duas datas podem ser comparadas com `<` sem converter nenhuma."},
 {"code": "    { \"id\": 4, \"course\": \"javascript\", \"date\": \"2026-10-12\", \"minutes\": 60, \"done\": true },\n    { \"id\": 5, \"course\": \"html-css\", \"date\": \"2026-10-14\", \"minutes\": 25, \"done\": false },\n    { \"id\": 6, \"course\": \"javascript\", \"date\": \"2026-10-15\", \"minutes\": 45, \"done\": false }\n  ]\n}", "note": "As três últimas caem na semana que começa na segunda, 12 de outubro, que é a semana que a página inicial totaliza: 130 minutos planejados, 60 deles feitos."}
]}
```

## As regras, sem DOM nenhum

`src/planner.ts` guarda o que o app sabe sobre sessões, como funções que recebem dados e devolvem dados.
Nenhuma delas toca na página, e é isso que permite à aula 3 testá-las sem navegador.

```schooling-example
{"language": "typescript", "file": "src/planner.ts", "parts": [
 {"code": "// src/planner.ts\nexport interface Course {\n  id: string;\n  title: string;\n}\n\nexport interface Session {\n  id: number;\n  course: string;\n  date: string;\n  minutes: number;\n  done: boolean;\n}", "note": "Os dois formatos de `courses.json`, escritos como tipos. Uma sessão cita o curso pelo `id`, nunca pelo título."},
 {"code": "\nexport function addSession(sessions: Session[], course: string, date: string, minutes: number): Session[] {\n  const id = Math.max(0, ...sessions.map((s) => s.id)) + 1;\n  return [...sessions, { id, course, date, minutes, done: false }];\n}", "note": "Uma lista nova com uma sessão a mais, e nunca uma mudança na antiga. O id é um a mais que o maior; `Math.max(0, …)` dá 1 para uma lista vazia."},
 {"code": "\nexport function markDone(sessions: Session[], id: number): Session[] {\n  return sessions.map((s) => (s.id === id ? { ...s, done: true } : s));\n}", "note": "A mesma lista com uma sessão copiada e marcada como feita. Aqui, feito nunca volta a ser não feito."},
 {"code": "\nexport function mondayOf(date: string): string {\n  const d = new Date(`${date}T00:00:00Z`);\n  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));\n  return d.toISOString().slice(0, 10);\n}", "note": "A segunda-feira que abre a semana de uma data. Tudo está em UTC, então a resposta é a mesma qualquer que seja o fuso horário do computador de quem lê. `getUTCDay()` é 0 no domingo, e `+ 6) % 7` transforma isso em seis dias para trás."},
 {"code": "\nexport function weekTotal(sessions: Session[], monday: string): { planned: number; done: number } {\n  const next = new Date(`${monday}T00:00:00Z`);\n  next.setUTCDate(next.getUTCDate() + 7);\n  const end = next.toISOString().slice(0, 10);\n  const week = sessions.filter((s) => s.date >= monday && s.date < end);\n  const sum = (list: Session[]) => list.reduce((n, s) => n + s.minutes, 0);\n  return { planned: sum(week), done: sum(week.filter((s) => s.done)) };\n}", "note": "Minutos planejados e minutos feitos daquela segunda até a próxima, sem incluí-la."}
]}
```

## A página

`src/view.ts` constrói as três telas como elementos. Todo pedaço de texto entra por `textContent`, que o
trata como texto e nunca como marcação, então um título de curso com `<` aparece como `<`.

```typescript
// src/view.ts
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
  main.append(el("h1", "Study planner"), el("p", `This week: ${week.planned} min planned, ${week.done} min done`), list);
  return main;
}

export function coursePage(course: Course, sessions: Session[], actions: Actions): HTMLElement {
  const main = el("main");
  const back = el("a", "All courses");
  back.href = base;
  const list = el("ul");
  for (const s of sessions) {
    const item = el("li", `${s.date} · ${s.minutes} min `);
    if (s.done) {
      item.append(el("span", "done"));
    } else {
      const button = el("button", "Mark done");
      button.addEventListener("click", () => actions.done(s.id));
      item.append(button);
    }
    list.append(item);
  }
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
  form.append(dateLabel, minutesLabel, el("button", "Add session"));
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

**`import.meta.env.BASE_URL` é a única linha deste arquivo que importa para um deploy.** É o caminho de
onde o site é servido, `/` a menos que o build receba outro, e todo link começa com ele. A última seção
desta aula é sobre o dia em que ele não é `/`.

`src/main.ts` guarda o estado e decide qual tela desenhar a partir do endereço:

```schooling-example
{"language": "typescript", "file": "src/main.ts", "parts": [
 {"code": "// src/main.ts\nimport \"./style.css\";\nimport { addSession, markDone, mondayOf, weekTotal, type Course, type Session } from \"./planner\";\nimport { courseList, coursePage, notFound } from \"./view\";\n\nconst base = import.meta.env.BASE_URL;\nconst app = document.querySelector<HTMLDivElement>(\"#app\")!;\nlet courses: Course[] = [];\nlet sessions: Session[] = [];", "note": "O estado inteiro são duas listas na memória. Nada é salvo: recarregar a página volta ao que o `courses.json` diz, e é tudo de que um curso sobre entrega precisa."},
 {"code": "\nfunction render(): void {\n  const path = location.pathname.slice(base.length);\n  if (path === \"\") {\n    const latest = sessions.map((s) => s.date).sort().at(-1) ?? \"2026-10-01\";\n    app.replaceChildren(courseList(courses, weekTotal(sessions, mondayOf(latest))));\n    return;\n  }", "note": "O endereço É a tela. No caminho base, a lista de cursos, com o total da semana da sessão mais recente."},
 {"code": "  const course = courses.find((c) => path === `course/${c.id}`);\n  if (!course) {\n    app.replaceChildren(notFound());\n    return;\n  }", "note": "Qualquer outro caminho que não cite um curso desenha a tela *Not found* do próprio app."},
 {"code": "  const own = sessions.filter((s) => s.course === course.id);\n  app.replaceChildren(\n    coursePage(course, own, {\n      add(date, minutes) {\n        sessions = addSession(sessions, course.id, date, minutes);\n        render();\n      },\n      done(id) {\n        sessions = markDone(sessions, id);\n        render();\n      },\n    }),\n  );\n}", "note": "A página de um curso. Cada ação troca a lista pela que o `planner.ts` devolve e desenha a tela de novo."},
 {"code": "\ndocument.addEventListener(\"click\", (event) => {\n  const link = (event.target as Element).closest(\"a\");\n  if (link && link.origin === location.origin && link.pathname.startsWith(base)) {\n    event.preventDefault();\n    history.pushState(null, \"\", link.pathname);\n    render();\n  }\n});\nwindow.addEventListener(\"popstate\", render);", "note": "Um clique num dos links do próprio app muda o endereço com `history.pushState` e desenha a tela nova, sem pedir uma página ao servidor. O botão Voltar dispara `popstate`."},
 {"code": "\nasync function start(): Promise<void> {\n  const response = await fetch(`${base}courses.json`);\n  ({ courses, sessions } = await response.json());\n  render();\n}\n\nstart();", "note": "Busca os dados e depois desenha. O endereço dos dados também começa com o caminho base."}
]}
```

**Os endereços são caminhos de verdade, `/course/git`, e não fragmentos como `#/course/git`.** É uma
escolha com custo, e a aula 4 paga a conta: um host a quem se pede `/course/git` diretamente procura um
arquivo com esse nome, e não há nenhum.

Os três últimos arquivos são curtos. A folha de estilo:

```css
/* src/style.css */
body {
  font-family: system-ui, sans-serif;
  margin: 2rem auto;
  max-width: 40rem;
  padding: 0 1rem;
  line-height: 1.5;
}

li {
  margin: 0.25rem 0;
}

form {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
  align-items: end;
}
```

A página, que é a do template com o título trocado e um comentário dizendo o nome dela:

```html
<!-- index.html -->
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

## Rodando

`npm run dev` inicia o servidor de desenvolvimento do Vite, que compila cada arquivo quando o navegador
pede. Ele ocupa o terminal, então inicie num e use um segundo:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 269 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

```
ana@dev:~/planner$ curl -s http://localhost:5173/courses.json | head -3
{
  "courses": [
    { "id": "html-css", "title": "HTML and CSS" },
```

Abra `http://localhost:5173/` no navegador. Você deve ver o título *Study planner*, a linha *This week:
130 min planned, 60 min done* e os três cursos como links. Abra *JavaScript*: três sessões, uma feita, e
um formulário embaixo delas. Acrescente uma e ela aparece na lista; aperte *Mark done* e o botão vira a
palavra *done*. De volta à página inicial, uma sessão acrescentada na mesma semana muda o total.

Então transforme isso num repositório, que é de onde tudo depois daqui começa:

```
ana@dev:~/planner$ git init -q
ana@dev:~/planner$ git add .
ana@dev:~/planner$ git commit -qm "The study planner"
ana@dev:~/planner$ git log --oneline
833a261 The study planner
```

O `.gitignore` do template já deixa de fora `node_modules` e `dist`, então o commit guarda o código, o
lockfile e nada construído.
