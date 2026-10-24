---
title: O script de preload e o IPC
version: 1
---

**O "Export plan" do planner escrevia no IndexedDB do navegador na aula 4**, porque uma página não tem
sistema de arquivos. Um app desktop consegue fazer melhor: escrever um arquivo de verdade, na pasta que o
sistema dá a cada app para os dados dele. Só o processo principal consegue, então a página pede a ele pela
única função que o script de preload oferece. Salve-o como `electron/preload.cjs`:

```javascript
// electron/preload.cjs: the only door between the page and the main process.
const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("desktop", {
  exportPlan: (text) => ipcRenderer.invoke("export-plan", text),
});
```

**O `contextBridge.exposeInMainWorld` é o único jeito de algo atravessar para a página.** Ele põe um objeto
no `window`, aqui `window.desktop`, cujas funções rodam no mundo isolado do próprio preload, e a página só
vê o que está nesse objeto. O preload é CommonJS, `.cjs`, porque um preload em sandbox não carrega módulos
ES.

No `src/device.ts`, o `exportPlan` procura esse objeto primeiro, e o usa quando ele está lá. A linha acima
da função e a primeira linha dentro dela são novas:

```typescript
// In the desktop app, Electron's preload puts this on window; in a browser or a phone it is absent.
const desktop = (window as { desktop?: { exportPlan: (text: string) => Promise<string> } }).desktop;

export async function exportPlan(plan: Plan): Promise<string> {
  if (desktop) return `exported to ${await desktop.exportPlan(JSON.stringify(plan))}`;
```

Construa, exporte pelo app desktop, e olhe a pasta onde o processo principal escreveu:

```
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ xvfb-run -a node desk.mjs --click 'Export plan' --wait 500 | tail -n 3
  - button "Export plan"
  - button "Where am I?"
  - status: exported to /home/ana/.config/planner/planner-export.json
ana@dev:~/planner$ ls ~/.config/planner
Cache
Code Cache
Crashpad
DIPS
DawnGraphiteCache
DawnWebGPUCache
DevToolsActivePort
Dictionaries
GPUCache
GPUPersistentCache
Local State
Local Storage
Network Persistent State
Preferences
Session Storage
Shared Dictionary
Trust Tokens
Trust Tokens-journal
blob_storage
declarative_performance_observer.db
declarative_performance_observer.db-journal
planner-export.json
ana@dev:~/planner$ head -c 80 ~/.config/planner/planner-export.json; echo
{"courses":[{"id":"spanish","name":"Spanish A2"},{"id":"statistics","name":"Stat
```

**`~/.config/planner` é a pasta de dados do app no Linux**, a que o `app.getPath("userData")` devolve, com o
nome do `name` do `package.json`; no Windows ela fica em `%APPDATA%` e no macOS em
`~/Library/Application Support`. Ao lado da exportação estão os arquivos do próprio Chromium para este
app: o cache, o armazenamento local, onde o Preferences guarda o plano, como num navegador. A exportação em
si é o plano em JSON, escrito pelo Node, a partir de um toque na página.

O mesmo build ainda funciona onde não há `window.desktop`:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click 'Export plan' --wait 300 | tail -n 1
  - status: exported 599 characters to planner-export.json
```

No navegador, a exportação foi para o IndexedDB, como na aula 4. **Uma base de código, três lugares, e cada
um usa o que o lugar dá**, que é o mesmo movimento que a aula 5 fez com um plugin, feito aqui com vinte
linhas e nenhum código nativo.
