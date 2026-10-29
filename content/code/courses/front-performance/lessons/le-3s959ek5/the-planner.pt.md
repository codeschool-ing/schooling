---
title: O planner que você vai medir
version: 1
---

**Este curso mede um app só, e você o constrói aqui, inteiro, em TypeScript puro.** É um planner
de estudos: uma lista de cursos, uma página por curso com as suas sessões de estudo, um botão que
marca uma sessão como feita, um formulário que adiciona uma, e o total de minutos por semana. Ele
não usa framework, de propósito. Toda técnica deste curso funciona igual em React, Angular, Vue ou
Svelte, e onde um framework faz algo do seu jeito, a aula mostra os quatro lado a lado. Um app puro
é o único lugar onde nada é feito por você, então dá para ver cada técnica fazendo o seu trabalho.

Ele é pequeno o bastante para ler em cinco minutos, e toda aula seguinte o muda ou o mede.

## Criando o projeto

O Vite cria um projeto novo a partir de um modelo. `vanilla-ts` é o que não tem framework e tem
TypeScript. Na sua pasta home:

```
ana@dev:~$ npm create vite@9.3.1 planner -- --template vanilla-ts
npm warn exec The following package was not found and will be installed: create-vite@9.3.1

> npx
> cva planner --template vanilla-ts


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/planner...
│
└  Done. Now run:

  cd planner
  npm install
  npm run dev

ana@dev:~$ cd planner
ana@dev:~/planner$ rm -r src/assets src/counter.ts public/icons.svg
ana@dev:~/planner$ npm install --save-exact --save-dev vite@8.3.5 typescript@6.0.3

added 16 packages, and audited 17 packages in 16s

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

`npm create vite@9.3.1` roda o programa que cria projetos Vite, numa versão exata, e tudo depois de
`--` é repassado a ele. O modelo vem com uma página de demonstração, um contador e três imagens; o
`rm` os apaga, porque o planner substitui tudo isso. **`--save-exact` escreve cada versão no
`package.json` sem o `^` ou o `~` na frente**, que de outro modo deixariam uma instalação futura
pegar uma versão mais nova. O `package-lock.json`, escrito ao lado, registra a versão exata de cada
pacote instalado por baixo desses dois, e os dois arquivos vão para o Git.

O Playwright entra no mesmo projeto, como a terceira ferramenta:

```
ana@dev:~/planner$ npm install --save-exact --save-dev playwright@1.63.0

added 4 packages, and audited 21 packages in 2s

9 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

O pacote e o navegador que ele controla são dois downloads. Este baixa o build do Chromium que este
Playwright controla, uns 650 MB depois de descompactado, em `~/.cache/ms-playwright`:

```sh
npx playwright install chromium
```

No Linux, o Chromium também precisa de algumas bibliotecas do sistema, e
`npx playwright install-deps chromium` as instala se uma abertura reclamar (a seção anterior tem o
erro). *O download não foi executado onde o curso foi gravado: aquela máquina não alcança o
servidor de downloads do Playwright e já tinha este mesmo build, o Chromium 153.0.8010.12, que
todas as transcrições do curso usaram.*

## Os dados

O planner lê um arquivo só, servido como está. Três cursos, seis sessões, todas em outubro de 2026.
Salve como `public/courses.json`:

```json
{
  "courses": [
    { "slug": "html-css", "title": "HTML and CSS" },
    { "slug": "javascript", "title": "JavaScript" },
    { "slug": "git", "title": "Git" }
  ],
  "sessions": [
    { "id": 1, "course": "html-css", "date": "2026-10-19", "minutes": 45, "done": true },
    { "id": 2, "course": "html-css", "date": "2026-10-21", "minutes": 30, "done": false },
    { "id": 3, "course": "javascript", "date": "2026-10-20", "minutes": 60, "done": true },
    { "id": 4, "course": "javascript", "date": "2026-10-23", "minutes": 50, "done": false },
    { "id": 5, "course": "git", "date": "2026-10-24", "minutes": 25, "done": false },
    { "id": 6, "course": "git", "date": "2026-10-27", "minutes": 40, "done": false }
  ]
}
```

Tudo o que está em `public/` é servido na raiz do site como está, então este arquivo fica em
`/courses.json` no desenvolvimento e é copiado sem mudança para o build.

## As regras

`src/planner.ts` guarda o que o planner sabe, como funções puras: cada uma recebe um plano e
devolve um plano novo, ou um número, e nenhuma toca na página. É isso que deixa um servidor usar o
mesmo arquivo mais adiante nesta aula.

```schooling-example
{"language": "typescript", "file": "src/planner.ts", "parts": [
 {"code": "// src/planner.ts: the planner's rules. No DOM here, so a server can use them too.\nexport interface Course { slug: string; title: string }\nexport interface Session { id: number; course: string; date: string; minutes: number; done: boolean }\nexport interface Plan { courses: Course[]; sessions: Session[] }", "note": "Um plano são duas listas, e uma sessão nomeia o seu curso pelo slug, a mesma string que o endereço usa."},
 {"code": "export function addSession(plan: Plan, course: string, date: string, minutes: number): Plan {\n  const id = Math.max(0, ...plan.sessions.map((s) => s.id)) + 1;\n  return { ...plan, sessions: [...plan.sessions, { id, course, date, minutes, done: false }] };\n}\n\nexport function markDone(plan: Plan, id: number): Plan {\n  return { ...plan, sessions: plan.sessions.map((s) => (s.id === id ? { ...s, done: true } : s)) };\n}", "note": "Adicionar e marcar como feita nunca mudam o plano que receberam. Devolvem um novo, e é isso que as deixa fáceis de testar e seguras de chamar em qualquer lugar."},
 {"code": "// A date is a calendar day, \"2026-10-23\", so the arithmetic is done in UTC,\n// where no day is 23 or 25 hours long.\nexport function mondayOf(date: string): string {\n  const d = new Date(date + \"T00:00:00Z\");\n  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));\n  return d.toISOString().slice(0, 10);\n}", "note": "A semana começa na segunda-feira. getUTCDay é 0 no domingo, então (dia + 6) % 7 conta os dias de volta até a segunda."},
 {"code": "export function weekTotal(sessions: Session[], monday: string): number {\n  return sessions.filter((s) => mondayOf(s.date) === monday).reduce((sum, s) => sum + s.minutes, 0);\n}\n\n// Every week that has a session in it, earliest first.\nexport function weeks(sessions: Session[]): string[] {\n  return [...new Set(sessions.map((s) => mondayOf(s.date)))].sort();\n}", "note": "O total da semana, e a lista de semanas para as quais a página inicial mostra um total."}
]}
```

## As páginas

`src/view.ts` transforma um plano em HTML, como strings, e põe esse HTML na página. **As duas
metades ficam separadas de propósito**: as funções que devolvem strings rodam em qualquer lugar, e
só `mount` precisa de um navegador.

```schooling-example
{"language": "typescript", "file": "src/view.ts", "parts": [
 {"code": "// src/view.ts: the planner's pages as HTML, and the DOM that shows them.\nimport { addSession, markDone, weekTotal, weeks, type Plan } from \"./planner.ts\";\n\nconst esc = (s: string) => s.replace(/[&<>\"']/g, (c) => `&#${c.charCodeAt(0)};`);", "note": "Todo texto que veio dos dados passa por esc, para que um título com um < dentro seja mostrado em vez de lido como tag."},
 {"code": "export function homePage(plan: Plan): string {\n  const courses = plan.courses.map((c) => {\n    const n = plan.sessions.filter((s) => s.course === c.slug).length;\n    return `<li><a href=\"/courses/${esc(c.slug)}\">${esc(c.title)}</a> · ${n} sessions</li>`;\n  });\n  const totals = weeks(plan.sessions).map((monday) => {\n    const done = weekTotal(plan.sessions.filter((s) => s.done), monday);\n    return `<li>Week of ${monday}: ${weekTotal(plan.sessions, monday)} min, ${done} done</li>`;\n  });\n  return `<h1>Study planner</h1>\n<ul class=\"courses\">${courses.join(\"\")}</ul>\n<h2>Weeks</h2>\n<ul class=\"weeks\">${totals.join(\"\")}</ul>`;\n}", "note": "A página inicial: cada curso com um link e uma contagem, depois uma linha por semana."},
 {"code": "export function coursePage(plan: Plan, slug: string): string {\n  const course = plan.courses.find((c) => c.slug === slug);\n  if (!course) return `<h1>No such course</h1><p><a href=\"/\">All courses</a></p>`;\n  const rows = plan.sessions.filter((s) => s.course === slug).map((s) =>\n    `<li>${s.date} · ${s.minutes} min ${s.done ? \"· done\" : `<button data-done=\"${s.id}\">Mark done</button>`}</li>`);\n  return `<p><a href=\"/\">All courses</a></p>\n<h1>${esc(course.title)}</h1>\n<ul class=\"sessions\">${rows.join(\"\")}</ul>\n<form>\n  <label>Date <input name=\"date\" type=\"date\" required></label>\n  <label>Minutes <input name=\"minutes\" type=\"number\" min=\"5\" step=\"5\" required></label>\n  <button>Add session</button>\n</form>`;\n}", "note": "A página de um curso: as suas sessões, um botão em cada uma ainda não feita, e o formulário que adiciona uma. O botão leva o id da sessão, e é assim que um clique acha a sessão."},
 {"code": "// The page an address names: /courses/<slug> is one course, anything else the list.\nexport function page(plan: Plan, path: string): string {\n  const m = path.match(/^\\/courses\\/([a-z0-9-]+)$/);\n  return m ? coursePage(plan, m[1]) : homePage(plan);\n}", "note": "O roteador, numa linha: um endereço decide qual página. É a função que um servidor também vai chamar."},
 {"code": "// Draw the page into root, and draw it again after every change.\nexport function mount(root: HTMLElement, start: Plan): void {\n  let plan = start;\n  const draw = () => { root.innerHTML = page(plan, location.pathname); };\n  root.addEventListener(\"click\", (e) => {\n    const target = e.target as HTMLElement;\n    const link = target.closest(\"a\");\n    if (link) {\n      e.preventDefault();\n      history.pushState(null, \"\", link.pathname);\n      draw();\n    } else if (target.dataset.done) {\n      plan = markDone(plan, Number(target.dataset.done));\n      draw();\n    }\n  });\n  root.addEventListener(\"submit\", (e) => {\n    e.preventDefault();\n    const form = new FormData(e.target as HTMLFormElement);\n    const slug = location.pathname.split(\"/\")[2];\n    plan = addSession(plan, slug, String(form.get(\"date\")), Number(form.get(\"minutes\")));\n    draw();\n  });\n  addEventListener(\"popstate\", draw);\n  draw();\n}", "note": "A metade do navegador. Um listener só no contêiner pega todo clique e todo formulário, então redesenhar o HTML nunca perde um listener. Um link muda o endereço com pushState e redesenha, sem pedir nada ao servidor."}
]}
```

As mudanças vivem na memória: uma sessão que você adiciona some quando você recarrega, porque nada
a grava em lugar nenhum. Isso basta para medir, e a aula 10 é onde o planner aprende a guardar
coisas.

## Ligando o app

`src/main.ts` busca os dados e os entrega à view. Ele substitui o arquivo do modelo:

```typescript
// src/main.ts: fetch the plan and hand it to the view.
import "./style.css";
import type { Plan } from "./planner.ts";
import { mount } from "./view.ts";

const plan: Plan = await (await fetch("/courses.json")).json();
mount(document.querySelector<HTMLElement>("#app")!, plan);
```

A página em volta também substitui a do modelo. O `<main>` está vazio, e esse vazio é o assunto da
próxima seção. Salve como `index.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner</title>
  </head>
  <body>
    <main id="app"></main>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

E algumas linhas de estilo, substituindo a folha de estilo longa do modelo, em `src/style.css`:

```css
body { font: 16px/1.5 system-ui, sans-serif; margin: 0 auto; max-width: 40rem; padding: 1rem; }
a { color: #1d4ed8; }
ul { padding-left: 1.2rem; }
li { margin: 0.4rem 0; }
form { display: flex; flex-wrap: wrap; gap: 0.75rem; align-items: end; }
label { display: flex; flex-direction: column; font-size: 0.9rem; }
```

`npm run dev` liga o servidor de desenvolvimento do Vite. Rode-o num segundo terminal e deixe-o lá:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 226 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

Depois, no primeiro terminal, peça a página a ele e confira se o TypeScript concorda com o código:

```
ana@dev:~/planner$ curl -s http://localhost:5173/courses.json | head -3
{
  "courses": [
    { "slug": "html-css", "title": "HTML and CSS" },
ana@dev:~/planner$ npx tsc
```

`npx tsc` não imprime nada quando os tipos batem. O `tsconfig.json` do modelo manda ele conferir e
não escrever arquivo nenhum, porque quem faz o build é o Vite. Abra `http://localhost:5173/` no seu
próprio navegador e clique por aí: um curso, *Mark done*, o formulário. Este é o app que toda aula
daqui em diante mede.
