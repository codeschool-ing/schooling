---
title: Hidratando o planner
version: 1
---

**Três mudanças fazem o planner hidratar**: o servidor põe o plano na página, o script o lê de lá em
vez de buscá-lo, e o `mount` mantém o HTML que achou em vez de trocá-lo. Esta seção também acrescenta
um recurso pequeno, o dia da semana ao lado da data de cada sessão, porque uma página de verdade
sempre tem algo assim, e a próxima seção mostra o que ele faz.

## O servidor põe os dados na página

No `server.ts`, a linha que monta a página agora acrescenta um `<script type="application/json">`
depois do `<main>`. Um script desse tipo nunca roda; é um lugar para guardar dados que o script da
própria página consegue ler. Troque a linha que monta o `html` por estas:

```typescript
  // The plan goes into the page as data, so the browser does not fetch it again. A "<" is
  // written as \u003c, so no title can close the script element early.
  const data = JSON.stringify(plan).replace(/</g, "\\u003c");
  const html = shell.replace('<main id="app"></main>',
    `<main id="app">${page(plan, pathname)}</main><script type="application/json" id="plan">${data}</script>`);
```

**O `replace` não é enfeite.** Um curso com o título `</script><script>…` fecharia o elemento de dados
no meio e começaria um script próprio, escrito por quem deu nome ao curso. O JSON permite escrever `<`
como `\u003c`, que é o mesmo caractere para o `JSON.parse` e não quer dizer nada para o parser de
HTML.

## O script os lê

O `src/main.ts` procura esse elemento primeiro, e só busca quando ele não está lá, como no build
renderizado no cliente:

```typescript
// src/main.ts: take the plan the server put in the page, or fetch it, and hand it to the view.
import "./style.css";
import type { Plan } from "./planner.ts";
import { mount } from "./view.ts";

const embedded = document.getElementById("plan");
const plan: Plan = embedded
  ? JSON.parse(embedded.textContent!)
  : await (await fetch("/courses.json")).json();
mount(document.querySelector<HTMLElement>("#app")!, plan);
```

## A view mantém o que achou

O `src/view.ts` muda em três lugares, então aqui está ele inteiro. A nova função `day` acrescenta o
dia da semana; a nova `same` compara o HTML na tela com o HTML que o script desenharia; e o `mount`
só desenha quando precisa:

```schooling-example
{"language": "typescript", "file": "src/view.ts", "parts": [
 {"code": "// src/view.ts: the planner's pages as HTML, and the DOM that shows them.\nimport { addSession, markDone, weekTotal, weeks, type Plan } from \"./planner.ts\";\n\nconst esc = (s: string) => s.replace(/[&<>\"']/g, (c) => `&#${c.charCodeAt(0)};`);", "note": "O escape, como antes."},
 {"code": "// \"2026-10-24\" as \"Sat 2026-10-24\", the day of the week it falls on.\nconst day = (date: string) => `${new Date(date).toLocaleDateString(\"en-GB\", { weekday: \"short\" })} ${date}`;", "note": "Novo: o dia da semana, a partir da data, em inglês, como \"Sat 2026-10-24\"."},
 {"code": "export function homePage(plan: Plan): string {\n  const courses = plan.courses.map((c) => {\n    const n = plan.sessions.filter((s) => s.course === c.slug).length;\n    return `<li><a href=\"/courses/${esc(c.slug)}\">${esc(c.title)}</a> · ${n} sessions</li>`;\n  });\n  const totals = weeks(plan.sessions).map((monday) => {\n    const done = weekTotal(plan.sessions.filter((s) => s.done), monday);\n    return `<li>Week of ${monday}: ${weekTotal(plan.sessions, monday)} min, ${done} done</li>`;\n  });\n  return `<h1>Study planner</h1>\n<ul class=\"courses\">${courses.join(\"\")}</ul>\n<h2>Weeks</h2>\n<ul class=\"weeks\">${totals.join(\"\")}</ul>`;\n}", "note": "A página inicial não muda."},
 {"code": "export function coursePage(plan: Plan, slug: string): string {\n  const course = plan.courses.find((c) => c.slug === slug);\n  if (!course) return `<h1>No such course</h1><p><a href=\"/\">All courses</a></p>`;\n  const rows = plan.sessions.filter((s) => s.course === slug).map((s) =>\n    `<li>${day(s.date)} · ${s.minutes} min ${s.done ? \"· done\" : `<button data-done=\"${s.id}\">Mark done</button>`}</li>`);\n  return `<p><a href=\"/\">All courses</a></p>\n<h1>${esc(course.title)}</h1>\n<ul class=\"sessions\">${rows.join(\"\")}</ul>\n<form>\n  <label>Date <input name=\"date\" type=\"date\" required></label>\n  <label>Minutes <input name=\"minutes\" type=\"number\" min=\"5\" step=\"5\" required></label>\n  <button>Add session</button>\n</form>`;\n}\n\n// The page an address names: /courses/<slug> is one course, anything else the list.\nexport function page(plan: Plan, path: string): string {\n  const m = path.match(/^\\/courses\\/([a-z0-9-]+)$/);\n  return m ? coursePage(plan, m[1]) : homePage(plan);\n}", "note": "A página de um curso chama day() onde antes imprimia só a data."},
 {"code": "// Whether the HTML already in root says what html says, letter for letter.\nfunction same(root: HTMLElement, html: string): boolean {\n  const drawn = document.createElement(\"template\");\n  drawn.innerHTML = html;\n  return drawn.content.textContent === root.textContent;\n}", "note": "Novo: o HTML que o script desenharia é interpretado fora da página, e o seu texto comparado com o texto que já está na tela. Texto, e não marcação, porque o navegador reescreve os atributos de um jeito diferente do que a string escreveu."},
 {"code": "// Take over the page the server drew, or draw it if the server sent none.\nexport function mount(root: HTMLElement, start: Plan): void {\n  let plan = start;\n  const draw = () => { root.innerHTML = page(plan, location.pathname); };\n  root.addEventListener(\"click\", (e) => {\n    const target = e.target as HTMLElement;\n    const link = target.closest(\"a\");\n    if (link) {\n      e.preventDefault();\n      history.pushState(null, \"\", link.pathname);\n      draw();\n    } else if (target.dataset.done) {\n      plan = markDone(plan, Number(target.dataset.done));\n      draw();\n    }\n  });\n  root.addEventListener(\"submit\", (e) => {\n    e.preventDefault();\n    const form = new FormData(e.target as HTMLFormElement);\n    const slug = location.pathname.split(\"/\")[2];\n    plan = addSession(plan, slug, String(form.get(\"date\")), Number(form.get(\"minutes\")));\n    draw();\n  });\n  addEventListener(\"popstate\", draw);", "note": "Os listeners são os mesmos de antes. Eles ficam no contêiner, então funcionam no HTML que o servidor desenhou exatamente como no HTML que o script desenhou."},
 {"code": "  if (!root.firstElementChild) {\n    draw();\n  } else if (!same(root, page(plan, location.pathname))) {\n    console.warn(\"hydration mismatch: the page the server sent is not the page this script draws; drawing again\");\n    draw();\n  }\n  document.documentElement.dataset.hydrated = String(Math.round(performance.now()));\n}", "note": "A parte nova. Um main vazio é desenhado, como no build renderizado no cliente. Um main que diz outra coisa é desenhado de novo, com um aviso, porque o script não deve agir sobre uma página que ele não entende. E quando termina, o horário vai para um atributo que uma ferramenta de medida consegue ler."}
]}
```

## Uma ferramenta que vê acontecer

O `tools/hydrate.ts` abre uma página no Chromium **como uma pessoa em São Paulo abriria**, com esse
fuso horário, e imprime o que o console disse, quando a página pintou e quando o script a assumiu. Ele
tem duas opções que a seção depois da próxima usa. Salve em `tools/`:

```typescript
// tools/hydrate.ts: open a page as a person in São Paulo would, and report what
// its console said, when it painted, and when the script took it over.
//
//   node tools/hydrate.ts URL [--script-delay MS] [--click-at MS]
//
// --script-delay MS  every script arrives MS milliseconds late, as on a slow network
// --click-at MS      click the first "Mark done" button MS milliseconds after the
//                    page arrived, whether or not the script has run yet
import { chromium } from "playwright";

const [url, ...rest] = process.argv.slice(2);
const option = (name: string) => (rest.includes(name) ? Number(rest[rest.indexOf(name) + 1]) : null);
const delay = option("--script-delay");
const clickAt = option("--click-at");

const browser = await chromium.launch();
const page = await browser.newPage({ timezoneId: "America/Sao_Paulo" });
page.on("console", (m) => console.log(`console.${m.type()}: ${m.text()}`));
if (delay) {
  await page.route("**/*.js", async (route) => {
    await new Promise((done) => setTimeout(done, delay));
    await route.continue();
  });
}
await page.goto(url, { waitUntil: "commit" });
if (clickAt !== null) {
  await page.waitForTimeout(clickAt);
  await page.click("[data-done]");
  console.log(`clicked Mark done ${clickAt} ms after the page arrived`);
}
await page.waitForFunction(() =>
  document.documentElement.dataset.hydrated && performance.getEntriesByName("first-contentful-paint").length);
const t = await page.evaluate(() => ({
  paint: Math.round(performance.getEntriesByName("first-contentful-paint")[0]?.startTime ?? 0),
  hydrated: document.documentElement.dataset.hydrated,
}));
console.log(`painted at ${t.paint} ms, taken over by the script at ${t.hydrated} ms`);
console.log((await page.locator("main li").allInnerTexts()).join("\n"));
await browser.close();
```

Faça o build, e ligue o `server.ts` no segundo terminal **com `TZ=UTC`**, o fuso em que quase todo
servidor de data center roda:

```sh
npm run build && TZ=UTC node server.ts
```

Depois peça o curso de Git, e abra-o como a pessoa em São Paulo:

```
ana@dev:~/planner$ curl -s http://localhost:3000/courses/git | grep -o '<li>[^<]*'
<li>Sat 2026-10-24 · 25 min 
<li>Tue 2026-10-27 · 40 min 
ana@dev:~/planner$ node tools/hydrate.ts http://localhost:3000/courses/git
console.warning: hydration mismatch: the page the server sent is not the page this script draws; drawing again
painted at 228 ms, taken over by the script at 253 ms
Fri 2026-10-24 · 25 min Mark done
Mon 2026-10-27 · 40 min Mark done
ana@dev:~/planner$ node tools/look.ts http://localhost:3000/courses/git | grep requests
requests: /courses/git /assets/index-B8ViuWQI.js /assets/index-1yLCgpWc.css
```

**O servidor disse sábado e o navegador disse sexta**, avisou, e desenhou a sua versão por cima da do
servidor. O `look.ts`, na última linha, lista as requisições: não há `/courses.json` entre elas, então
os dados na página fizeram o seu trabalho. Todo o resto é a próxima seção.
