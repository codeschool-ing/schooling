---
title: Breakpoints: parando a página
version: 2
---

**Um breakpoint (ponto de parada) pausa o programa numa linha, antes de ela rodar, e deixa tudo como
estava.** Enquanto ele está pausado, você lê toda variável no escopo e a cadeia de chamadas que
levou até ali. Esta página tem um bug:

```html
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Shelf</title></head>
<body>
  <ul id="books"></ul>
  <script src="shelf.js"></script>
</body>
</html>
```

```javascript
async function load() {
  const res = await fetch("/api/books");
  const books = await res.json();
  render(books);
}

function render(books) {
  const list = document.querySelector("#books");
  for (let i = 0; i <= books.length; i++) {
    const book = books[i];
    const item = document.createElement("li");
    item.textContent = `${book.title} (${book.year})`;
    list.append(item);
  }
}

load();
```

```
ana@dev:~/js$ page shelf.html --dom '#books'
Uncaught TypeError: Cannot read properties of undefined (reading 'title')
<ul id="books"><li>Dom Casmurro (1899)</li><li>Grande Sertão: Veredas (1956)</li><li>A Hora da Estrela (1977)</li></ul>
```

**A página parece certa e está errada.** Os três livros foram desenhados, e então o script lançou
um erro. Ninguém olhando só a tela saberia, e é por isso que o console é a primeira coisa a abrir
quando uma página se comporta mal. A mensagem nomeia uma propriedade, `title`, e um valor,
`undefined`, mas não qual livro nem por quê.

## Pausando no erro

No DevTools, o painel Sources tem uma chave para **pausar em exceções não capturadas**. O `page`
consegue pedir a mesma coisa ao Chromium quando mais um arquivo está ao lado dele em `~/js-tools`.
Salve isto como `devtools.mjs`:

```javascript
// devtools.mjs: what page.mjs needs to pause, step and measure a page. It
// asks Chromium through the Chrome DevTools Protocol, the same channel the
// developer tools panel uses. page.mjs loads it when it sits beside it.
//
//   --break F:LINE   pause at a line, print the stack and the local scope
//   --break debugger pause only at `debugger;` statements in the page
//   --break uncaught pause where an exception nobody catches is thrown
//   --if COND        only pause there when COND is true (a conditional breakpoint)
//   --step KIND      after a pause, step over|into|out and print again
//   --profile        record a CPU profile and print where the busy time went,
//                    by function: its own time, not the time of what it called
//   --waterfall      at the end, every request on a time line from the first
//                    one, rounded to 100 ms: when it started and how long it
//                    took, drawn as a bar of # (one per 100 ms)
import path from "node:path";

// A value as the Scope pane draws it: an object with its first properties,
// an array with its length, an element by its tag.
function shown(v) {
  if (!v) return "(uninitialised)";
  if (v.type === "undefined") return "undefined";
  if (v.type === "string") return JSON.stringify(v.value);
  if (v.type !== "object" || v.subtype === "null") return v.description ?? String(v.value);
  const pv = v.preview;
  if (!pv || v.subtype === "node") return v.description;
  const item = (p) => (p.type === "string" ? JSON.stringify(p.value) : p.type === "object" ? "{…}" : p.value);
  const more = pv.overflow ? ", …" : "";
  if (v.subtype === "array") return `${v.description} [${pv.properties.map(item).join(", ")}${more}]`;
  return `{${pv.properties.map((p) => `${p.name}: ${item(p)}`).join(", ")}${more}}`;
}

export async function attach({ context, page, opt, say, origin }) {
  const timeline = [];
  if (opt.waterfall) {
    const t = new Map();
    page.on("request", (r) => t.set(r, { start: Date.now(), r }));
    const end = (r) => { const e = t.get(r); if (e) { e.end = Date.now(); timeline.push(e); } };
    page.on("requestfinished", end);
    page.on("requestfailed", end);
  }

  let cdp;
  if (opt.break || opt.profile) cdp = await context.newCDPSession(page);

  async function scopeOf(frame) {
    const out = [];
    for (const s of frame.scopeChain) {
      if (s.type === "global") continue;
      const { result } = await cdp.send("Runtime.getProperties", { objectId: s.object.objectId, ownProperties: true, generatePreview: true });
      const vars = result.map((p) => `${p.name} = ${shown(p.value)}`);
      out.push(`  ${s.type} scope: ${vars.join(", ") || "(empty)"}`);
    }
    return out;
  }

  if (opt.break) {
    const [bf, bl] = opt.break.split(":");
    const urls = new Map();
    cdp.on("Debugger.scriptParsed", (ev) => urls.set(ev.scriptId, ev.url));
    await cdp.send("Debugger.enable");
    if (opt.break === "uncaught") await cdp.send("Debugger.setPauseOnExceptions", { state: "uncaught" });
    else if (opt.break !== "debugger")
      await cdp.send("Debugger.setBreakpointByUrl", { lineNumber: Number(bl) - 1, urlRegex: `${bf.replace(/[.]/g, "\\.")}$`, condition: opt.if ?? "" });
    const steps = [...opt.step];
    cdp.on("Debugger.paused", async (ev) => {
      const top = ev.callFrames[0];
      const at = (f) => `${path.basename(urls.get(f.location.scriptId) ?? "")}:${f.location.lineNumber + 1}`;
      say(`paused at ${at(top)}${ev.reason === "exception" || ev.reason === "promiseRejection" ? `, on ${ev.data?.description?.split("\n")[0]}` : ""}`);
      say("  call stack: " + ev.callFrames.map((f) => `${f.functionName || "(anonymous)"} ${at(f)}`).join("  <  "));
      for (const l of await scopeOf(top)) say(l);
      const next = steps.shift();
      if (next) { say(`-- step ${next}`); await cdp.send(`Debugger.step${next[0].toUpperCase()}${next.slice(1)}`); }
      else await cdp.send("Debugger.resume");
    });
  }

  if (opt.profile) {
    await cdp.send("Profiler.enable");
    await cdp.send("Profiler.setSamplingInterval", { interval: 100 });
    await cdp.send("Profiler.start");
  }

  async function finish() {
    if (opt.profile) {
      const { profile } = await cdp.send("Profiler.stop");
      const self = new Map();
      const byId = new Map(profile.nodes.map((n) => [n.id, n]));
      const dt = profile.timeDeltas;
      profile.samples.forEach((id, i) => {
        const n = byId.get(id);
        const name = n.callFrame.functionName || `(${n.callFrame.url ? "anonymous" : n.callFrame.functionName || "program"})`;
        const where = n.callFrame.url ? `${path.basename(n.callFrame.url)}:${n.callFrame.lineNumber + 1}` : "";
        const k = `${name}  ${where}`.trim();
        self.set(k, (self.get(k) || 0) + (dt[i] || 0));
      });
      // Time the page spent waiting for something to do is not time anything
      // cost, so the shares are of the time the browser was busy.
      self.delete("(idle)");
      const busy = [...self.values()].reduce((a, b) => a + b, 0);
      say("share  self time  function");
      for (const [k, us] of [...self].sort((a, b) => b[1] - a[1]).slice(0, 5))
        say(`${String(Math.round((100 * us) / busy)).padStart(4)}%  ${(us / 1000).toFixed(0).padStart(6)} ms  ${k}`);
      say(`       ${(busy / 1000).toFixed(0).padStart(6)} ms  busy in total`);
    }
    if (opt.waterfall) {
      const first = Math.min(...timeline.map((e) => e.start));
      const tenth = (ms) => Math.round(ms / 100);
      say("start  took    request");
      for (const e of timeline.sort((a, b) => a.start - b.start)) {
        const s0 = tenth(e.start - first), d = tenth(e.end - e.start);
        const what = `${e.r.method()} ${e.r.url().replace(origin, "")}`;
        say(`${String(s0 * 100).padStart(5)}  ${String(d * 100).padStart(4)}  ${what.padEnd(28)} ${" ".repeat(s0)}${"#".repeat(Math.max(d, 1))}`);
      }
    }
  }
  return { finish };
}
```

Ele conversa com o Chromium pelo **Chrome DevTools Protocol**, o mesmo canal que a janela do
DevTools usa, e dá ao `page` as cinco opções do topo do arquivo. Se você tem uma área de trabalho,
faça cada passo desta aula no DevTools também: as transcrições são a mesma pausa, impressa como
texto. Com o arquivo no lugar, o `--break uncaught`:

```
ana@dev:~/js$ page shelf.html --break uncaught
paused at shelf.js:12, on TypeError: Cannot read properties of undefined (reading 'title')
  call stack: render shelf.js:12  <  load shelf.js:4
  block scope: book = undefined, item = li
  block scope: i = 3
  local scope: books = Array(3) [{…}, {…}, {…}], list = ul#books
Uncaught TypeError: Cannot read properties of undefined (reading 'title')
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Uma página pausada, desenhada em três painéis. À esquerda, o código de render com a linha 12 marcada como a linha em que o navegador parou, a template string que lê book.title. No alto à direita, a pilha de chamadas: render na linha 12, chamada por load na linha 4. Abaixo, os escopos: book é undefined, i é 3, books guarda três itens. Os três fatos juntos explicam o erro: o laço pediu um quarto livro.\"><defs><marker id=\"paused-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"400\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelf.js</text><text x=\"48\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><text x=\"56.0\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">function render(books) {</text><text x=\"48\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"66.8\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">const list = document.querySelector(&quot;#books&quot;);</text><text x=\"48\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9</text><text x=\"66.8\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">for (let i = 0; i &lt;= books.length; i++) {</text><text x=\"48\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"77.6\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">const book = books[i];</text><text x=\"48\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11</text><text x=\"77.6\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">const item = document.createElement(&quot;li&quot;);</text><rect x=\"26\" y=\"164\" width=\"388\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"48\" y=\"174\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">12</text><text x=\"77.6\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">item.textContent = `${book.title} (${book.year})`;</text><text x=\"48\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13</text><text x=\"77.6\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">list.append(item);</text><text x=\"48\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14</text><text x=\"66.8\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">}</text><text x=\"48\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><text x=\"56.0\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">}</text><rect x=\"450\" y=\"20\" width=\"250\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"462\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Pilha de chamadas</text><text x=\"462\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">render   shelf.js:12</text><text x=\"462\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">load     shelf.js:4</text><rect x=\"450\" y=\"136\" width=\"250\" height=\"124\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"462\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Escopo</text><text x=\"462\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">book  = undefined</text><text x=\"462\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">i     = 3</text><text x=\"462\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">books = Array(3)</text><text x=\"462\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">list  = ul#books</text><path d=\"M420 174 L446 180\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#paused-ah-amber)\"></path></svg>", "caption": "Onde parou, como chegou lá, e o que cada variável guardava naquele momento."}
```

Três fatos, lidos de uma pausa:

- **onde**: linha 12, a template string que lê `book.title`;
- **como chegou lá**: `render`, chamada por `load` na linha 4. Essa lista é a **pilha de
  chamadas**, a chamada mais nova primeiro;
- **o que tudo guardava**: `book` é `undefined`, `i` é `3`, e `books` tem três itens. O índice 3
  de um array de três itens não existe.

Os escopos vêm em camadas, a cadeia de escopos da aula 6: dois escopos de **bloco**, um para o corpo
do laço e um para o `i` do laço, e então o escopo **local** da função. A causa agora cabe numa
frase: o laço roda enquanto `i <= books.length`, então pede um livro a mais.

## Um breakpoint numa linha, com condição

Pausar no erro funciona quando há um erro. Mais vezes há só um valor errado, e você pausa numa linha
que escolhe. No DevTools você clica no número da linha no painel Sources. Um breakpoint simples na
linha 11 pausaria quatro vezes, uma por volta do laço. Um **breakpoint condicional** só pausa quando
uma expressão é verdadeira:

```
ana@dev:~/js$ page shelf.html --break shelf.js:11 --if 'book === undefined'
paused at shelf.js:11
  call stack: render shelf.js:11  <  load shelf.js:4
  block scope: book = undefined, item = li
  block scope: i = 3
  local scope: books = Array(3) [{…}, {…}, {…}], list = ul#books
Uncaught TypeError: Cannot read properties of undefined (reading 'title')
```

A condição rodou em toda volta e só foi verdadeira na última. Essa é a ferramenta para um bug no
item 900 de uma lista: você escreve como é o "errado" e deixa o navegador esperar por ele.

## A correção

```
ana@dev:~/js$ sed -i 's/i <= books.length/i < books.length/' shelf.js
ana@dev:~/js$ sed -n 9p shelf.js
  for (let i = 0; i < books.length; i++) {
ana@dev:~/js$ page shelf.html --dom '#books'
<ul id="books"><li>Dom Casmurro (1899)</li><li>Grande Sertão: Veredas (1956)</li><li>A Hora da Estrela (1977)</li></ul>
```

Nenhum erro, e os mesmos três livros. A correção é um caractere, e achá-la levou duas execuções e
nenhuma edição no código.
