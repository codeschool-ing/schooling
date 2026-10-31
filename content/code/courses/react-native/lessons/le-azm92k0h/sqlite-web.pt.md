---
title: O diário num navegador
version: 1
---

**O `expo-sqlite` roda na web também**, como SQLite compilado para WebAssembly, salvando o arquivo no
sistema de arquivos privado que o navegador dá ao site. Duas coisas precisam estar no lugar antes, e o
export diz qual falta:

```
ana@dev:~/planner$ npx expo export --platform web 2>&1 | grep -m1 "Unable to resolve"
Unable to resolve "./wa-sqlite/wa-sqlite.wasm" from "node_modules/expo-sqlite/web/worker.ts"
```

**O Metro não sabe o que é um arquivo `.wasm`.** Ele lê JavaScript e TypeScript, e copia assets cujas
extensões lhe foram ditas; WebAssembly não está na lista dele. O Metro lê as configurações do
`metro.config.js` na raiz do projeto, e este é o padrão do Expo mais essa extensão:

```javascript
// metro.config.js: Expo's defaults, plus one: SQLite's web build is a .wasm file, which Metro must
// treat as an asset to copy rather than as code to read.
const { getDefaultConfig } = require("expo/metro-config");

const config = getDefaultConfig(__dirname);
config.resolver.assetExts.push("wasm");
module.exports = config;
```

A segunda coisa são dois cabeçalhos HTTP. **O SQLite na web divide memória entre a página e um worker, e
os navegadores só permitem isso numa página isolada de outros sites**: um cabeçalho diz que a página não
abre janela para outro site, o outro que ela não carrega nada de fora a não ser que aquele site concorde.
O `serve` não manda nenhum dos dois, então esta aula serve o `dist/` com um servidor pequeno próprio.
Salve o `static.mjs`:

```javascript
// static.mjs: serve dist/ with the two headers SQLite on the web needs, falling back to index.html.
import { createReadStream, existsSync, statSync } from "node:fs";
import { createServer } from "node:http";
import { extname, join } from "node:path";

const [dir, port] = process.argv.slice(2);
const types = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm", ".css": "text/css", ".png": "image/png", ".json": "application/json", ".ico": "image/x-icon", ".ttf": "font/ttf" };
createServer((req, res) => {
  let file = join(dir, decodeURIComponent(new URL(req.url, "http://x").pathname));
  if (!existsSync(file) || statSync(file).isDirectory()) file = join(dir, "index.html");
  res.writeHead(200, {
    "content-type": types[extname(file)] ?? "application/octet-stream",
    "cross-origin-opener-policy": "same-origin",
    "cross-origin-embedder-policy": "require-corp",
  });
  createReadStream(file).pipe(res);
}).listen(Number(port), () => console.log(`serving ${dir} on ${port}`));
```

O servidor do planner já responde toda requisição com `access-control-allow-origin: *`, que é a
concordância que o segundo cabeçalho pede, então o plano continua carregando. Um app web publicado define
os mesmos dois cabeçalhos na configuração da hospedagem.

Por último, um programa que marca uma sessão como feita em *This week*, recarrega, e depois olha de um
navegador que nunca esteve lá. Salve-o como `journal.mjs`:

```javascript
// journal.mjs: on This week, read what the journal says, mark one session done, read it again, then
// reload the page and read it a third time; last, read it in a browser that has never been here.
//
//   node journal.mjs URL BUTTON
import { chromium } from "playwright";

const [url, button] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
const logged = page.getByText(/logged on this phone/i);
await page.goto(url);
console.log("before:      ", await logged.innerText());
await page.getByRole("button", { name: button }).click();
await page.getByText(/^Logged on this phone: /).waitFor();
console.log("after:       ", await logged.innerText());
await page.reload();
console.log("after reload:", await logged.innerText());
await page.close();
const other = await (await browser.newContext()).newPage();
await other.goto(url);
console.log("new browser: ", await other.getByText(/logged on this phone/i).innerText());
await browser.close();
```

Suba o servidor, exporte, e sirva o `dist/` com `node static.mjs dist 8082` no lugar do `serve`:

```
ana@dev:~/planner$ find dist -name "*.wasm"
dist/assets/node_modules/expo-sqlite/web/wa-sqlite/wa-sqlite.5e61fe84c4a4f49e0b1a33661b45c791.wasm
ana@dev:~/planner$ node journal.mjs 'http://localhost:8082/week?today=2026-10-21' 'Mark 20 min on 2026-10-21 done'
before:       Nothing logged on this phone yet
after:        Logged on this phone: Guitar 20 min
after reload: Logged on this phone: Guitar 20 min
new browser:  Nothing logged on this phone yet
```

**O diário sobreviveu à recarga, e é só deste navegador.** O navegador novo vê o mesmo plano do mesmo
servidor, com a sessão de guitar feita, e um diário vazio: o registro está no celular que o fez, que é
exatamente o que um diário no celular quer dizer. *Uma coisa encontrada durante a gravação: com o planner
aberto em duas abas, a segunda nunca terminou de carregar, porque o SQLite na web segura o arquivo para a
aba que o abriu. O `offline.mjs` fecha cada aba antes de abrir a próxima por esse motivo.*
