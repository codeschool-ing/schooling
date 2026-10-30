---
title: Uma primeira janela
version: 1
---

**O Electron é um pacote npm, instalado no planner como o Vite.** O programa em si, o build do Chromium e
do Node.js do Electron para o seu sistema, é baixado na primeira vez que ele roda, que é a linha sobre ele
na primeira execução abaixo. No Linux, a janela precisa das bibliotecas gráficas que um desktop já tem;
numa máquina virtual com Ubuntu Server, instale-as antes com `sudo apt install libgtk-3-0t64 libnss3
libxss1 libasound2t64 libgbm1 libxkbcommon0 libatk-bridge2.0-0t64 libcups2t64`, mais `xvfb xauth` para a
última seção desta aula.

```
ana@dev:~/planner$ npm install -E -D electron@45.0.0

added 9 packages, and audited 137 packages in 1s

3 moderate severity vulnerabilities

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner$ npm pkg set main=electron/main.mjs scripts.start="electron ."
ana@dev:~/planner$ grep -E "\"main\"|\"start\"|electron\"" package.json
    "start": "electron ."
    "electron": "45.0.0",
  "main": "electron/main.mjs"
```

**O `main` diz ao Electron onde está o processo principal**, e o `npm start` agora roda `electron .`, que
o inicia com esta pasta como o app. Um primeiro processo principal, o mais curto que abre o planner,
carrega o site construído direto do disco:

```javascript
// electron/main.mjs: the main process, a first version that opens the built site from disk.
import { app, BrowserWindow } from "electron";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));

app.whenReady().then(() => {
  const window = new BrowserWindow({ width: 900, height: 700 });
  window.loadFile(path.join(here, "..", "dist", "index.html"));
});

app.on("window-all-closed", () => app.quit());
```

## Vendo pelo terminal

No seu computador, `npm run build` e depois `npm start` abre uma janela com o planner dentro. As
transcrições precisam de uma versão imprimível dessa janela, então esta aula tem um equivalente próprio do
`look.mjs`: **o Playwright controla o Electron como controla o Chromium**, e o `desk.mjs` inicia o app,
espera a janela e imprime o título e a árvore de acessibilidade dela. Salve-o ao lado do `look.mjs`:

```javascript
// desk.mjs: start the planner as a desktop app, and print what its window holds.
//
//   node desk.mjs [--click NAME] [--wait MS] [--eval EXPRESSION] ...
//
// It launches Electron on this folder with --today=2026-10-21, waits for the
// window, runs the options in order, and prints the window's title and its
// accessibility tree, with every console message and failed request on the way.
import { _electron as electron } from "playwright";

const args = process.argv.slice(2);
const app = await electron.launch({ args: [".", "--today=2026-10-21"] });
const window = await app.firstWindow();
window.on("console", (m) => console.log(`console.${m.type()}: ${m.text()}`));
window.on("requestfailed", (r) => console.log(`failed: ${r.url()}`));
await window.waitForLoadState("load");
for (let i = 0; i < args.length; i += 2) {
  const [flag, value] = [args[i], args[i + 1]];
  if (flag === "--click") await window.getByRole("button", { name: value, exact: true }).first().click();
  else if (flag === "--wait") await window.waitForTimeout(Number(value));
  else if (flag === "--eval") console.log(`${value} = ${await window.evaluate(value).catch((e) => e.message)}`);
  else throw new Error(`desk: unknown option ${flag}`);
}
console.log(`title: ${await window.title()}`);
console.log(await window.locator("body").ariaSnapshot());
await app.close();
```

A máquina de gravação não tem tela, então cada execução abaixo começa com `xvfb-run -a`, que dá à janela
uma tela virtual; num desktop você deixa essas duas palavras de fora, e a última seção desta aula as
explica. Construa, e abra a janela:

```
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ xvfb-run -a node desk.mjs
Downloading Electron binary...
failed: file:///assets/index-BzzYGMWI.js
console.error: Failed to load resource: net::ERR_FILE_NOT_FOUND
failed: file:///assets/dist-iCT9NZ5Z.js
console.error: Failed to load resource: net::ERR_FILE_NOT_FOUND
failed: file:///assets/definitions-DlpntO5o.js
console.error: Failed to load resource: net::ERR_FILE_NOT_FOUND
failed: file:///assets/dist-C93lqtQh.js
console.error: Failed to load resource: net::ERR_FILE_NOT_FOUND
title: Study planner
- main
```

**A janela abriu, o título está certo, e a página está vazia.** Quatro arquivos não carregaram, e a página
nunca rodou. O motivo está no `index.html` construído da aula 1: ele carrega o script como
`/assets/index-….js`, um endereço a partir da raiz de um site. De um arquivo aberto do disco, a raiz é a
raiz do disco, `/assets/` não existe lá, e o script do planner nunca é encontrado. O `fetch("courses.json")`
também falharia: o Chromium não deixa uma página buscar endereços `file://` de jeito nenhum.

Duas correções são comuns. Uma é mandar o Vite escrever caminhos relativos, com `base: "./"`, o que
conserta o script e ainda deixa o fetch quebrado. **A melhor é o que um navegador tinha desde sempre: um
site servido a partir de uma origem.** Essa é a próxima seção.
