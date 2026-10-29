---
title: Um custom element
version: 1
---

**Um custom element é uma classe que o navegador roda sempre que a tag dele aparece numa página.** A tag
precisa ter um hífen, `planner-session` e nunca `session`, para que nenhum elemento futuro do HTML possa
colidir com ela. A classe decide o que o elemento desenha e como ele se comporta; a página decide onde ele
fica e com quais atributos.

O elemento do planner mora na biblioteca, `~/planner-ui`, ao lado dos componentes em forma de função, e
desenha a mesma coisa que o `sessionRow`: uma data, uma duração, e um botão ou a palavra *done*. Este é o
arquivo inteiro, e as seções depois desta tratam das partes dele uma a uma:

```schooling-example
{"language": "typescript", "file": "src/session-element.ts", "parts": [
 {"code": "// src/session-element.ts\nimport { duration } from \"./format\";\n\nconst template = document.createElement(\"template\");\ntemplate.innerHTML = `\n  <style>\n    :host {\n      display: flex;\n      gap: var(--space-2, 0.5rem);\n      align-items: center;\n    }\n    .when {\n      color: var(--muted, GrayText);\n    }\n    button {\n      font: inherit;\n      background: var(--accent, ButtonFace);\n      color: var(--on-accent, ButtonText);\n      border: 0;\n      border-radius: var(--space-1, 0.25rem);\n      padding: var(--space-1, 0.25rem) var(--space-3, 0.75rem);\n    }\n  </style>\n  <slot></slot>\n  <span class=\"when\"></span>\n  <button type=\"button\" part=\"button\">Mark done</button>\n  <span class=\"done\" hidden>done</span>\n`;", "note": "O template: a marcação privada do elemento, interpretada uma vez quando o módulo carrega e clonada para cada elemento. O `<style>` dele vale só dentro do elemento, como a seção sobre shadow DOM mostra. Todo valor é um token com uma alternativa depois da vírgula, então o elemento ainda se desenha numa página sem os tokens do planner."},
 {"code": "\nexport class PlannerSession extends HTMLElement {\n  static observedAttributes = [\"date\", \"minutes\", \"done\"];", "note": "Um custom element é uma classe que estende `HTMLElement`. `observedAttributes` lista os atributos cujas mudanças o navegador avisa a ela."},
 {"code": "\n  #root = this.attachShadow({ mode: \"open\" });", "note": "A raiz shadow, criada com o elemento: a árvore privada em que todo o resto é desenhado. `open` deixa scripts da página e testes entrarem por `element.shadowRoot`; `#root` é um campo privado, então a classe guarda a própria referência qualquer que seja o modo."},
 {"code": "\n  constructor() {\n    super();\n    this.#root.append(template.content.cloneNode(true));\n    this.#root.querySelector(\"button\")!.addEventListener(\"click\", () => {\n      this.done = true;\n      this.dispatchEvent(new CustomEvent(\"session-done\", { bubbles: true, detail: { id: this.id } }));\n    });\n  }", "note": "O construtor clona o template para dentro da raiz shadow e liga o botão. Apertá-lo marca o `done` do próprio elemento e dispara um evento `session-done` que sobe pela página, levando o `id` do elemento."},
 {"code": "\n  get done(): boolean {\n    return this.hasAttribute(\"done\");\n  }\n\n  set done(value: boolean) {\n    this.toggleAttribute(\"done\", value);\n  }", "note": "`done` como propriedade, apoiada no atributo `done`, para que os dois nunca discordem: mudar um muda o outro."},
 {"code": "\n  connectedCallback(): void {\n    this.#render();\n  }\n\n  attributeChangedCallback(): void {\n    this.#render();\n  }", "note": "Dois callbacks do ciclo de vida. `connectedCallback` roda quando o elemento é posto numa página; `attributeChangedCallback` roda quando um atributo observado muda. Os dois só desenham."},
 {"code": "\n  #render(): void {\n    const minutes = Number(this.getAttribute(\"minutes\") ?? 0);\n    this.#root.querySelector(\".when\")!.textContent = `${this.getAttribute(\"date\") ?? \"\"} · ${duration(minutes)}`;\n    this.#root.querySelector(\"button\")!.hidden = this.done;\n    this.#root.querySelector<HTMLElement>(\".done\")!.hidden = !this.done;\n  }\n}", "note": "O desenho: a data e a duração vêm dos atributos, que são sempre strings, então `minutes` passa por `Number`. O botão aparece até a sessão estar feita, e a palavra *done* depois."},
 {"code": "\n/** Registers <planner-session> with the browser; a second call does nothing. */\nexport function definePlannerSession(): void {\n  if (!customElements.get(\"planner-session\")) customElements.define(\"planner-session\", PlannerSession);\n}", "note": "O registro é uma função, e não algo que acontece no import, então importar a biblioteca não registra nada: a página decide quando a tag começa a funcionar."}
]}
```

## Uma página para vê-lo

A biblioteca não tem app, então ganha uma pagininha para experimentar o elemento, que o Vite serve em
desenvolvimento e o build da biblioteca ignora. Ela carrega os tokens gerados e depois pinta de propósito
de vermelho todo botão e todo `.when` dentro de `main`, o que a seção sobre shadow DOM explica:

```html
<!-- index.html -->
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>planner-session</title>
    <link rel="stylesheet" href="/src/tokens.css" />
    <style>
      main button {
        background: red;
      }
      main .when {
        color: red;
      }
    </style>
  </head>
  <body>
    <main>
      <h1>planner-session</h1>
      <planner-session id="session-6" date="2026-10-15" minutes="45">JavaScript</planner-session>
      <planner-session id="session-4" date="2026-10-12" minutes="60" done>JavaScript</planner-session>
      <p id="log">No session marked done yet</p>
    </main>
    <script type="module">
      import { definePlannerSession } from "/src/session-element.ts";
      definePlannerSession();
      document.addEventListener("session-done", (event) => {
        document.querySelector("#log").textContent = `${event.detail.id} marked done`;
      });
    </script>
  </body>
</html>
```

Inicie o Vite na biblioteca e abra o endereço que ele imprime:

```
ana@dev:~/planner-ui$ npx vite

  VITE v8.3.5  ready in 452 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

Duas linhas: *JavaScript 2026-10-15 · 45 min* com um botão verde **Mark done**, e *JavaScript 2026-10-12 ·
1 h done*. Aperte o botão e a linha vira do segundo tipo, e a frase abaixo delas muda para *session-6
marked done*. O botão não está vermelho, e as datas também não, embora a página tenha pedido as duas
coisas.
