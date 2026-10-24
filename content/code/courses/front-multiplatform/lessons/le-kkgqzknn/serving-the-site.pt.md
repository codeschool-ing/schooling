---
title: Servindo o site de dentro do app
version: 1
---

**O Electron deixa o processo principal responder a pedidos de um esquema próprio**, do jeito que o
Capacitor respondia a `https://localhost` num celular. O processo principal do planner registra `app://`,
e serve todo endereço sob `app://planner/` a partir da pasta `dist/`, então o site vê uma origem comum:
caminhos absolutos funcionam, o `fetch` funciona, e o `localStorage` pertence a essa origem. Troque o
`electron/main.mjs` pelo inteiro:

```javascript
// electron/main.mjs: the main process. It owns the window, the files and the app's life.
import { app, BrowserWindow, ipcMain, net, protocol } from "electron";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const site = path.join(here, "..", "dist");

// The site is served under app://planner/, as a host would serve it, instead of file://.
protocol.registerSchemesAsPrivileged([
  { scheme: "app", privileges: { standard: true, secure: true, supportFetchAPI: true } },
]);

function serveSite() {
  protocol.handle("app", (request) => {
    const file = path.join(site, decodeURIComponent(new URL(request.url).pathname));
    if (!file.startsWith(site + path.sep)) return new Response("not found", { status: 404 });
    return net.fetch(pathToFileURL(file).toString());
  });
}

// The one thing the page may ask of the main process: write an export of the plan.
ipcMain.handle("export-plan", async (_event, text) => {
  if (typeof text !== "string" || text.length > 1_000_000) throw new Error("not a plan");
  const file = path.join(app.getPath("userData"), "planner-export.json");
  await fs.writeFile(file, text);
  return file;
});

app.whenReady().then(() => {
  serveSite();
  const window = new BrowserWindow({
    width: 900,
    height: 700,
    webPreferences: {
      preload: path.join(here, "preload.cjs"),
      contextIsolation: true,
      sandbox: true,
      nodeIntegration: false,
    },
  });
  // The transcripts start it with --today=2026-10-21, as lesson 1 opens the page with ?today=.
  const today = process.argv.find((a) => a.startsWith("--today="))?.slice("--today=".length);
  window.loadURL(`app://planner/index.html${today ? `?today=${today}` : ""}`);
});

app.on("window-all-closed", () => app.quit());
```

- **`registerSchemesAsPrivileged`** roda antes de o app estar pronto e marca `app:` como um esquema
  *padrão* e *seguro* que o `fetch` pode usar, para o Chromium tratá-lo como `https:`.
- **`protocol.handle`** responde a cada pedido. Ele transforma o endereço num caminho dentro da `dist/`,
  recusa qualquer coisa que sairia dessa pasta, o que um `..` forjado num endereço poderia fazer, e deixa o
  `net.fetch` ler o arquivo.
- **`webPreferences`** escreve por extenso as três configurações das próximas seções. Elas são os padrões
  do Electron desde a versão 20, escritas aqui para ninguém precisar lembrar disso.
- **`ipcMain.handle("export-plan", …)`** é a porta da seção anterior, e o script de preload abaixo é o
  outro lado dela.

Antes de rodá-lo, salve o `electron/preload.cjs` como a próxima seção o mostra, porque o `webPreferences`
o nomeia. Depois:

```
ana@dev:~/planner$ xvfb-run -a node desk.mjs --click Statistics
title: Study planner
- main:
  - button "All courses"
  - heading "Statistics" [level=1]
  - paragraph: "This week: 75 of 125 minutes done"
  - list:
    - listitem: 2026-10-20, 45 min done
    - listitem:
      - text: 2026-10-26, 60 min
      - button "Mark done"
      - button "Remind me on 2026-10-26"
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes"
  - button "Add session"
  - button "Photo of my notes"
  - button "Keep the screen on"
  - button "Let the screen sleep"
  - status
```

**O planner, inteiro, numa janela própria**: a semana, os cursos, e depois do toque, a tela de Statistics
com as sessões e o formulário. Nada na `src/` mudou para chegar aqui. É a mesma `dist/` que o Capacitor
copiou para os projetos de celular na aula 2.
