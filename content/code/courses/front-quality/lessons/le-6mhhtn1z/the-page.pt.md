---
title: A página, e o planner rodando
version: 1
---

**A página são três arquivos pequenos: o `index.html` carrega um script, o `src/main.ts` busca os
dados, e o `src/view.ts` desenha a tela a partir deles.** Salve cada um com o nome que está na sua
primeira linha.

O `index.html` é o do template, com o título trocado e o ícone retirado:

```html
<!-- index.html -->
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

O livrinho desenhado ao lado de cada curso vai em `public/`:

```xml
<!-- public/book.svg -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><path d="M2 2h5a2 2 0 0 1 1 .3A2 2 0 0 1 9 2h5v11H9a1 1 0 0 0-1 1 1 1 0 0 0-1-1H2z" fill="none" stroke="#2f6f4e" stroke-width="1.2"/></svg>
```

## Desenhando a tela

O `src/view.ts` transforma um plano em elementos. Ele os cria um a um com `createElement` e põe o
texto com `textContent`, menos os três campos do formulário, que são curtos o bastante para escrever
como marcação:

```schooling-example
{"language": "typescript", "file": "src/view.ts", "parts": [{"code": "// src/view.ts\nimport { addSession, markDone, weekTotal, type Plan } from \"./planner\";\n\nexport function render(root: HTMLElement, plan: Plan, day: string, route: string, update: (next: Plan) => void): void {\n  const course = plan.courses.find((c) => route === `#/course/${c.id}`);\n  root.replaceChildren();", "note": "Uma função desenha a tela inteira dentro de `root`, a partir do plano, da data de hoje e do endereço depois do `#`. Quando algo muda, ela não mexe no plano: entrega um plano novo a `update`, e quem a chamou desenha de novo."}, {"code": "  if (!course) {\n    root.append(el(\"h1\", \"Study planner\"));\n    const list = el(\"ul\", \"\", \"courses\");\n    for (const c of plan.courses) {\n      const link = el(\"a\", c.title);\n      link.href = `#/course/${c.id}`;\n      const icon = el(\"img\");\n      icon.src = \"/book.svg\";\n      link.prepend(icon);\n      const item = el(\"li\");\n      item.append(link, el(\"span\", ` ${weekTotal(plan, day, c.id)} min this week`, \"mins\"));\n      list.append(item);\n    }\n    root.append(list, el(\"p\", `This week: ${weekTotal(plan, day)} min`, \"week\"));\n    return;\n  }", "note": "Nenhum curso no endereço: a lista de cursos, cada um com um link para a própria página e um livrinho na frente, e o total da semana de tudo no fim."}, {"code": "  const back = el(\"a\", \"←\", \"back\");\n  back.href = \"#/\";\n  root.append(back, el(\"h1\", course.title));\n  const list = el(\"ul\", \"\", \"sessions\");\n  for (const s of plan.sessions.filter((s) => s.course === course.id)) {\n    const item = el(\"li\", `${s.date} · ${s.minutes} min `, s.done ? \"session done\" : \"session\");\n    if (s.done) {\n      item.append(el(\"span\", \"done\", \"state\"));\n    } else {\n      const tick = el(\"button\", \"Done\", \"tick\");\n      tick.addEventListener(\"click\", () => update(markDone(plan, s.id)));\n      item.append(tick);\n    }\n    list.append(item);\n  }", "note": "A página de um curso: uma seta de volta para a lista, o título e as sessões dele. Uma sessão por fazer tem um botão Done; uma já feita diz que está feita."}, {"code": "  const form = el(\"form\", \"\", \"add\");\n  form.innerHTML = `<input name=\"date\" type=\"date\" placeholder=\"Date\">\n    <input name=\"minutes\" type=\"number\" placeholder=\"Minutes\">\n    <button>Add session</button>`;\n  form.addEventListener(\"submit\", (event) => {\n    event.preventDefault();\n    const data = new FormData(form);\n    update(addSession(plan, course.id, String(data.get(\"date\")), Number(data.get(\"minutes\"))));\n  });\n  root.append(list, form, el(\"p\", `This week: ${weekTotal(plan, day, course.id)} min`, \"week\"));\n}\n", "note": "O formulário que adiciona uma sessão, e o total do curso na semana. O `preventDefault()` impede o navegador de enviar o formulário para algum lugar; o `FormData` lê os dois campos pelo `name`."}, {"code": "function el<K extends keyof HTMLElementTagNameMap>(tag: K, text = \"\", cls = \"\"): HTMLElementTagNameMap[K] {\n  const e = document.createElement(tag);\n  e.textContent = text;\n  if (cls) e.className = cls;\n  return e;\n}", "note": "Um ajudante pequeno: um elemento, o texto e a classe numa chamada só. O parâmetro de tipo faz de `el(\"a\")` um `HTMLAnchorElement`, e por isso `link.href` passa na checagem de tipos."}]}
```

## Ligando

O `src/main.ts` é o ponto de entrada que o `index.html` indica. Ele busca os dados, guarda o plano
atual, e desenha de novo sempre que o plano ou o endereço mudam:

```typescript
// src/main.ts
import "./style.css";
import { today, type Plan } from "./planner";
import { render } from "./view";

const root = document.querySelector<HTMLElement>("#app")!;
let plan: Plan = { courses: [], sessions: [] };

function draw(): void {
  render(root, plan, today(), location.hash, (next) => {
    plan = next;
    draw();
  });
}

const response = await fetch("/courses.json");
if (response.ok) {
  plan = await response.json();
  window.addEventListener("hashchange", draw);
  draw();
} else {
  root.textContent = "Could not load your courses.";
}
```

Um `await` no topo de um módulo é permitido em todo navegador atual, e quer dizer que nada é desenhado
antes de os dados chegarem. Um plano em que você acrescenta coisas vive só na memória: recarregue a
página e ele volta ao arquivo. A aula 5 dá a ele um lugar para ser guardado.

E os estilos, que são curtos e, como as aulas 10 a 13 mostram, nem todos corretos:

```css
/* src/style.css */
body { font-family: system-ui, sans-serif; margin: 2rem auto; max-width: 36rem; padding: 0 1rem; color: #1d1d1d; }
a { color: #2f6f4e; }
ul { padding: 0; list-style: none; }
li { padding: 0.4rem 0; border-bottom: 1px solid #ddd; }
.courses img { vertical-align: middle; margin-right: 0.4rem; }
.mins { color: #555; }
.session.done { color: #aaa; }
.tick { font-size: 0.7rem; padding: 1px 4px; }
button:focus { outline: none; }
.add { display: flex; gap: 0.5rem; margin: 1rem 0; }
.week { font-weight: bold; animation: pulse 1s ease-in-out 3; }
@keyframes pulse { 50% { transform: scale(1.06); } }
```

O TypeScript confere o projeto inteiro sem executá-lo, e não diz nada quando está satisfeito:

```
ana@dev:~/planner$ npx tsc --noEmit
```

Depois, o servidor de desenvolvimento:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 176 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

**Abra `http://localhost:5173/` no seu navegador.** Você vê os três cursos, cada um com seus minutos
da semana, e o total embaixo; o nome de um curso abre a página dele, com as sessões, um botão Done em
cada uma ainda por fazer, e um formulário para adicionar outra. Os totais dão todos 0, a menos que o
seu calendário diga que é a semana de 19 de outubro de 2026, porque a "semana atual" vem do relógio do
computador. A aula 4 acerta o relógio do navegador que os testes dela controlam, e é assim que um
teste de data tem a mesma resposta todo dia.

O servidor fica rodando até você apertar Ctrl+C no terminal dele, e recarrega a página cada vez que
você salva um arquivo.

Vale a pena olhar uma vez o que o navegador recebe, de um segundo terminal. Os dados vêm do jeito que
estão em `public/`, e um arquivo TypeScript vem com os tipos removidos, porque um navegador roda
JavaScript e mais nada:

```
ana@dev:~/planner$ curl -s http://localhost:5173/courses.json | head -n 4
{
  "courses": [
    { "id": "html-css", "title": "HTML and CSS" },
    { "id": "javascript", "title": "JavaScript" },
ana@dev:~/planner$ curl -s http://localhost:5173/src/planner.ts | head -n 3
export function addSession(plan, course, date, minutes) {
	if (!plan.courses.some((c) => c.id === course)) throw new Error(`no course ${course}`);
	if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error(`not a date: ${date}`);
```

## Para o Git

O projeto é um repositório daqui em diante. O `.gitignore` do template já deixa de fora o
`node_modules`, que o `npm ci` consegue reconstruir a partir do lockfile:

```
ana@dev:~/planner$ git init
Initialized empty Git repository in /home/ana/planner/.git/
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "The study planner"
ana@dev:~/planner$ git log --oneline
050e2d3 The study planner
```

Toda aula deste curso termina com um commit como este, então o `git log` é o registro do próprio
curso do que mudou e por quê.
