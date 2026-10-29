---
title: A custom element
version: 1
---

**A custom element is a class the browser runs whenever its tag appears in a page.** The tag must contain a
hyphen, `planner-session` and never `session`, so that no future HTML element can ever collide with it.
The class decides what the element draws and how it behaves; the page decides where it goes and with which
attributes.

The planner's element lives in the library, `~/planner-ui`, beside the function components, and draws the
same thing `sessionRow` does: a date, a length, and either a button or the word *done*. This is the whole
file, and the sections after this one take its pieces in turn:

```schooling-example
{"language": "typescript", "file": "src/session-element.ts", "parts": [
 {"code": "// src/session-element.ts\nimport { duration } from \"./format\";\n\nconst template = document.createElement(\"template\");\ntemplate.innerHTML = `\n  <style>\n    :host {\n      display: flex;\n      gap: var(--space-2, 0.5rem);\n      align-items: center;\n    }\n    .when {\n      color: var(--muted, GrayText);\n    }\n    button {\n      font: inherit;\n      background: var(--accent, ButtonFace);\n      color: var(--on-accent, ButtonText);\n      border: 0;\n      border-radius: var(--space-1, 0.25rem);\n      padding: var(--space-1, 0.25rem) var(--space-3, 0.75rem);\n    }\n  </style>\n  <slot></slot>\n  <span class=\"when\"></span>\n  <button type=\"button\" part=\"button\">Mark done</button>\n  <span class=\"done\" hidden>done</span>\n`;", "note": "The template: the element's private markup, parsed once when the module loads and cloned for every element. Its `<style>` applies only inside the element, as the section on shadow DOM shows. Every value is a token with a fallback after the comma, so the element still draws on a page without the planner's tokens."},
 {"code": "\nexport class PlannerSession extends HTMLElement {\n  static observedAttributes = [\"date\", \"minutes\", \"done\"];", "note": "A custom element is a class that extends `HTMLElement`. `observedAttributes` names the attributes whose changes the browser reports to it."},
 {"code": "\n  #root = this.attachShadow({ mode: \"open\" });", "note": "The shadow root, created with the element: the private tree everything else is drawn into. `open` lets page scripts and tests reach in through `element.shadowRoot`; `#root` is a private field, so the class keeps its own reference whatever the mode."},
 {"code": "\n  constructor() {\n    super();\n    this.#root.append(template.content.cloneNode(true));\n    this.#root.querySelector(\"button\")!.addEventListener(\"click\", () => {\n      this.done = true;\n      this.dispatchEvent(new CustomEvent(\"session-done\", { bubbles: true, detail: { id: this.id } }));\n    });\n  }", "note": "The constructor clones the template into the shadow root and wires the button. Pressing it sets the element's own `done` and dispatches a `session-done` event that bubbles up through the page, carrying the element's `id`."},
 {"code": "\n  get done(): boolean {\n    return this.hasAttribute(\"done\");\n  }\n\n  set done(value: boolean) {\n    this.toggleAttribute(\"done\", value);\n  }", "note": "`done` as a property, backed by the `done` attribute, so the two never disagree: setting one sets the other."},
 {"code": "\n  connectedCallback(): void {\n    this.#render();\n  }\n\n  attributeChangedCallback(): void {\n    this.#render();\n  }", "note": "Two lifecycle callbacks. `connectedCallback` runs when the element is put into a page; `attributeChangedCallback` runs when an observed attribute changes. Both just draw."},
 {"code": "\n  #render(): void {\n    const minutes = Number(this.getAttribute(\"minutes\") ?? 0);\n    this.#root.querySelector(\".when\")!.textContent = `${this.getAttribute(\"date\") ?? \"\"} · ${duration(minutes)}`;\n    this.#root.querySelector(\"button\")!.hidden = this.done;\n    this.#root.querySelector<HTMLElement>(\".done\")!.hidden = !this.done;\n  }\n}", "note": "Drawing: the date and the duration from the attributes, which are always strings, so `minutes` goes through `Number`. The button shows until the session is done, the word *done* after."},
 {"code": "\n/** Registers <planner-session> with the browser; a second call does nothing. */\nexport function definePlannerSession(): void {\n  if (!customElements.get(\"planner-session\")) customElements.define(\"planner-session\", PlannerSession);\n}", "note": "The registration is a function rather than something that happens on import, so importing the library registers nothing: the page decides when the tag starts working."}
]}
```

## A page to see it in

The library has no app, so it gets a small page for trying the element, which Vite serves in development
and the library build ignores. It loads the generated tokens, then deliberately paints every button and
every `.when` inside `main` red, which the section on shadow DOM explains:

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

Start Vite in the library, and open the address it prints:

```
ana@dev:~/planner-ui$ npx vite

  VITE v8.3.5  ready in 452 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

Two rows: *JavaScript 2026-10-15 · 45 min* with a green **Mark done** button, and *JavaScript 2026-10-12 · 1
h done*. Press the button and the row turns into the second kind, and the line below them changes to
*session-6 marked done*. The button is not red, and neither are the dates, though the page asked for
both.
