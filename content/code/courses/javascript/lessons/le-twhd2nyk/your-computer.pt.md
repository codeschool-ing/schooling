---
title: O seu computador, pronto para este curso
version: 1
---

**Tudo neste curso roda no seu próprio computador, e esta seção o prepara.** Você precisa de duas
coisas: o **Node.js**, que roda JavaScript como um programa qualquer, e um jeito de abrir uma
página num navegador e ler o que os scripts dela imprimiram. A segunda é um programa curto que você
vai salvar daqui a pouco, chamado `page`. Toda transcrição do curso que começa com `page` foi feita
com ele.

## Três jeitos de ter um

| caminho | o que você ganha | quanto custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | o Node.js e o `page` no computador que você já usa | cerca de 540 MB de disco | iguais às impressas no Linux; parecidas nos outros |
| uma máquina virtual | o Ubuntu Server 24.04 separado do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto roda | iguais às impressas |
| online | uma máquina Linux numa aba do navegador | nada no seu computador; horas de uma franquia mensal | parecidas, não idênticas |

**Instale no computador que você usa.** Nada aqui mexe no resto do sistema: o Node vai para uma
pasta dentro da sua pasta pessoal, e o navegador que o `page` comanda é uma cópia própria, não a que
você usa para navegar. No **Linux**, os comandos abaixo funcionam como estão. No **Windows**, todo
comando deste curso é digitado num terminal Linux, então instale o WSL antes: `wsl --install -d
Ubuntu-24.04` num PowerShell aberto como administrador, reinicie, abra o Ubuntu pelo menu Iniciar e
siga os passos do Linux lá dentro. No **Mac**, pegue o instalador do Node.js 22 em nodejs.org e pule
para "O comando page"; esse caminho não foi rodado para este curso, então um caminho ou uma versão
numa transcrição pode diferir da sua.

**Uma máquina virtual** é o mesmo passo a passo do Linux dentro de uma máquina só dela: VirtualBox
no Windows ou no Linux, UTM num Mac com chip da Apple, e o Ubuntu Server 24.04 LTS como convidado. Foi
assim que este curso foi gravado. Um servidor não tem área de trabalho, então lá não há janela de
navegador para abrir, e o `page` é o único jeito de ver uma página.

**Online**, o GitHub Codespaces dá uma máquina Linux com um terminal numa aba do navegador. Não
custa nada ao seu computador, e o GitHub dá às contas pessoais uma franquia mensal e cobra o que
passar dela, em termos que ele define e pode mudar. Não foi rodado para este curso.
`cat /etc/os-release` diz qual Linux você recebeu antes de começar.

## Node.js

O Node vem de nodejs.org como uma pasta compactada. Qual delas depende do processador, e
`uname -m` diz qual: `x86_64` fica com o arquivo terminado em `linux-x64`, `aarch64` com o terminado
em `linux-arm64`. Este curso foi gravado no 22.22.0, e qualquer 22 posterior funciona igual. Um
terminal, do começo:

```
ana@dev:~$ uname -m
x86_64
ana@dev:~$ curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz
ana@dev:~$ mkdir -p ~/.local/node ~/.local/bin
ana@dev:~$ tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1
ana@dev:~$ ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/
ana@dev:~$ node --version
bash: line 13: node: command not found
```

O `curl -O` salva o arquivo com o próprio nome, e o `tar` o desempacota em `~/.local/node`. A linha
do `ln` põe os três programas onde o Ubuntu procura os seus: `~/.local/bin` entra no seu `PATH`, a
lista de pastas onde o shell procura, **a partir da próxima vez que você entrar na sessão**. Por
isso a última linha falha. O terminal decidiu o `PATH` dele quando abriu, antes de a pasta existir.
Feche-o e abra outro:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
```

O `npm` veio na mesma pasta. Ele instala pacotes de JavaScript, e a aula 21 é sobre ele.

## O comando page

O `page` é feito com o **Playwright**, uma biblioteca que comanda um navegador de verdade a partir
de um programa. Ele mora numa pasta própria, `~/js-tools`, para as ferramentas do curso nunca se
misturarem com o seu trabalho em `~/js`:

```
ana@dev:~$ mkdir ~/js-tools ~/js
ana@dev:~$ cd ~/js-tools
ana@dev:~/js-tools$ npm install playwright@1.56.0

added 2 packages in 2s
npm notice
npm notice New major version of npm available! 10.9.4 -> 12.2.0
npm notice Changelog: https://github.com/npm/cli/releases/tag/v12.2.0
npm notice To update run: npm install -g npm@12.2.0
npm notice
```

O `npm install` trouxe a biblioteca para `~/js-tools/node_modules`. O aviso embaixo é o npm
oferecendo uma versão mais nova de si mesmo, que você pode ignorar: a que veio com o Node é a que
este curso usa. **O navegador é um download à parte**, e isto pergunta ao Playwright onde ele o
poria:

```
ana@dev:~$ cd ~/js-tools
ana@dev:~/js-tools$ npx playwright install --dry-run --only-shell chromium
browser: chromium-headless-shell version 141.0.7390.37
  Install location:    /home/ana/.cache/ms-playwright/chromium_headless_shell-1194
  Download url:        https://cdn.playwright.dev/dbazure/download/playwright/builds/chromium/1194/chromium-headless-shell-linux.zip
  Download fallback 1: https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/chromium/1194/chromium-headless-shell-linux.zip
  Download fallback 2: https://cdn.playwright.dev/builds/chromium/1194/chromium-headless-shell-linux.zip

browser: ffmpeg
  Install location:    /home/ana/.cache/ms-playwright/ffmpeg-1011
  Download url:        https://cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 1: https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 2: https://cdn.playwright.dev/builds/ffmpeg/1011/ffmpeg-linux.zip
```

Depois, o download em si, que ocupa cerca de 320 MB em disco depois de desempacotado. O
`--only-shell` pega a versão do Chromium que roda sem janela, que é tudo de que o `page` precisa;
no Linux, o `--with-deps` também instala as bibliotecas do sistema de que ela depende, e pede a sua
senha para isso:

```sh
npx playwright install --with-deps --only-shell chromium
```

*Esta linha não foi rodada onde o curso foi gravado. Aquela máquina não alcançava o servidor de
download do Playwright, e já tinha a mesma versão, 141.0.7390.37, que o `page` usou em todas as
transcrições.*

Agora os dois programas. Salve cada um em `~/js-tools` com o nome que está na primeira linha dele.
Você não precisa lê-los agora: o `page.mjs` abre uma página e imprime o que o console dela disse, e
o `serve.mjs` é o servidor web pequeno de onde ele abre a página. A aula 16 acrescenta um terceiro
arquivo ao lado deles e a aula 22 um quarto, cada um mostrado inteiro onde é preciso.

```javascript
// page.mjs: open one of your pages in a real browser, and print what its
// console said. The transcripts in this course that start with `page` were
// made with it.
//
//   page FILE.html [options]
//
// The browser is Chromium with no window, driven by Playwright. The page is
// served from the folder you are in, at http://127.0.0.1:8080, by serve.mjs.
//
// Each line is one console message. console.warn and console.error are marked
// [warn] and [error]; an exception nobody caught is printed as "Uncaught" and
// its message, as the browser's own console prints it; and an action this
// program performed is printed as "-- " and the action.
//
// Options, applied in order after the page has loaded:
//   --do 'click SEL' | 'fill SEL TEXT' (SEL without spaces) | 'press KEY' | 'focus SEL'
//        | 'wait MS' | 'reload' | 'newtab' | 'eval CODE'
//   --dom SEL        at the end, print SEL's outerHTML
//   --wait MS        how long to let timers run after the last action (300)
//   --geo LAT,LON    the position the browser reports, and permission for it
//   --grant PERM     grant a permission (notifications, geolocation)
//   --fresh          forget everything the browser stored (localStorage)
//   --network        list every request the page made
//   --file           open the page from file:// instead of the server, as a
//                    file double-clicked on a desktop would be
// Lesson 22 adds devtools.mjs beside this file, and with it --break, --if,
// --step, --profile and --waterfall.
import { chromium } from "playwright";
import { createServer } from "./serve.mjs";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const args = process.argv.slice(2);
const file = args.shift();
if (!file) { console.error("usage: page FILE.html [options]"); process.exit(2); }
const opt = { do: [], wait: 300, grant: [], step: [] };
while (args.length) {
  const a = args.shift();
  if (a === "--do") opt.do.push(args.shift());
  else if (a === "--dom") opt.dom = args.shift();
  else if (a === "--wait") opt.wait = Number(args.shift());
  else if (a === "--geo") opt.geo = args.shift().split(",").map(Number);
  else if (a === "--grant") opt.grant.push(args.shift());
  else if (a === "--fresh") opt.fresh = true;
  else if (a === "--network") opt.network = true;
  else if (a === "--file") opt.file = true;
  else if (a === "--break") opt.break = args.shift();
  else if (a === "--if") opt.if = args.shift();
  else if (a === "--step") opt.step.push(args.shift());
  else if (a === "--profile") opt.profile = true;
  else if (a === "--waterfall") opt.waterfall = true;
  else { console.error(`page: unknown option ${a}`); process.exit(2); }
}

let devtools = null;
if (opt.break || opt.profile || opt.waterfall) {
  if (!fs.existsSync(new URL("./devtools.mjs", import.meta.url))) {
    console.error("page: --break, --profile and --waterfall need devtools.mjs beside page.mjs (lesson 22)");
    process.exit(2);
  }
  devtools = await import("./devtools.mjs");
}

const root = process.cwd();
const server = createServer(root);
await new Promise((ok) => server.listen(8080, "127.0.0.1", ok));

// The browser keeps what pages store, as yours does, in a folder of its own.
const profileDir = path.join(os.homedir(), ".page-profile");
if (opt.fresh) fs.rmSync(profileDir, { recursive: true, force: true });
const context = await chromium.launchPersistentContext(profileDir, {
  headless: true,
  locale: "en-GB", // so the browser's own messages are in the course's language
  timezoneId: process.env.TZ || undefined,
  ...(opt.geo ? { geolocation: { latitude: opt.geo[0], longitude: opt.geo[1] } } : {}),
});
const origin = "http://127.0.0.1:8080";
if (opt.geo) await context.grantPermissions(["geolocation"], { origin });
if (opt.grant.length) await context.grantPermissions(opt.grant, { origin });

const say = (s) => process.stdout.write(s + "\n");
function watch(page) {
  page.on("console", (m) => {
    const t = m.type();
    const text = m.text();
    if (t === "error") say(`[error] ${text}`);
    else if (t === "warning") say(`[warn] ${text}`);
    else say(text);
  });
  page.on("pageerror", (e) => say(`Uncaught ${String(e.message).startsWith(e.name) ? e.message : `${e.name}: ${e.message}`}`));
}

let page = context.pages()[0] || (await context.newPage());
watch(page);
if (opt.network) {
  page.on("requestfailed", (r) => say(`net  ${r.method()} ${r.url().replace(origin, "")}  failed: ${r.failure()?.errorText}`));
  page.on("response", async (r) => {
    const q = r.request();
    let size = "?";
    try { size = (await r.body()).length; } catch {} // a body that is gone is printed as "?"
    say(`net  ${q.method()} ${r.url().replace(origin, "")}  ${r.status()}  ${q.resourceType()}  ${size} B`);
  });
}
const tools = devtools && (await devtools.attach({ context, page, opt, say, origin }));

await page.goto(opt.file ? `file://${path.resolve(root, file)}` : `${origin}/${file}`);
for (const action of opt.do) {
  say(`-- ${action}`);
  const [verb, ...rest] = action.split(" ");
  const sel = rest[0];
  const text = rest.slice(1).join(" ");
  if (verb === "click") await page.click(rest.join(" "));
  else if (verb === "fill") await page.fill(sel, text);
  else if (verb === "press") await page.keyboard.press(sel);
  else if (verb === "focus") await page.focus(rest.join(" "));
  else if (verb === "wait") await page.waitForTimeout(Number(sel));
  else if (verb === "reload") await page.reload();
  else if (verb === "newtab") { page = await context.newPage(); watch(page); await page.goto(`${origin}/${file}`); }
  else if (verb === "eval") { const r = await page.evaluate(rest.join(" ")); if (r !== undefined) say(String(r)); }
  else { say(`page: unknown action ${verb}`); }
}
await page.waitForTimeout(opt.wait);
if (tools) await tools.finish();

if (opt.dom) {
  const html = await page.$eval(opt.dom, (e) => e.outerHTML).catch(() => `(no element matches ${opt.dom})`);
  say(html);
}
await context.close();
server.close();
```

```javascript
// serve.mjs: a web server for the pages in this course.
//
//   node serve.mjs [FOLDER] [PORT]      FOLDER defaults to this one, PORT to 8080
//
// It sends the files in FOLDER as they are, so a page has a real address,
// http://127.0.0.1:8080/, as it would on the web. Lesson 16 puts api.mjs
// beside it, and from then on it also answers the addresses under /api/.
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const TYPES = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8", ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8", ".svg": "image/svg+xml",
  ".txt": "text/plain; charset=utf-8",
};

// api.mjs is optional until lesson 16 writes it.
let api = null;
if (fs.existsSync(new URL("./api.mjs", import.meta.url))) ({ api } = await import("./api.mjs"));

export function createServer(root) {
  const state = {};
  return http.createServer((req, res) => {
    const url = new URL(req.url, "http://127.0.0.1");
    if (url.pathname.startsWith("/api/")) {
      if (api) return api(req, res, url, state);
      res.writeHead(404, { "content-type": "text/plain" });
      return res.end("no api.mjs beside serve.mjs: lesson 16 writes it\n");
    }
    const file = path.join(root, decodeURIComponent(url.pathname));
    if (!file.startsWith(path.resolve(root))) { res.writeHead(403); return res.end(); }
    fs.readFile(file, (err, data) => {
      if (err) { res.writeHead(404, { "content-type": "text/plain" }); return res.end("not found\n"); }
      res.writeHead(200, { "content-type": TYPES[path.extname(file)] || "application/octet-stream" });
      res.end(data);
    });
  });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const root = path.resolve(process.argv[2] || ".");
  const port = Number(process.argv[3] || 8080);
  createServer(root).listen(port, "127.0.0.1", () => console.log(`serving ${root} on http://127.0.0.1:${port}`));
}
```

Por último, um comando chamado `page` que roda o primeiro, de onde você estiver:

```sh
cat > ~/.local/bin/page <<'EOF'
#!/bin/sh
exec node "$HOME/js-tools/page.mjs" "$@"
EOF
chmod +x ~/.local/bin/page
```

Um arquivo em `~/.local/bin` que começa com `#!/bin/sh` e está marcado como executável é um comando,
e o `"$@"` repassa a ele tudo o que foi digitado depois do nome. No Mac, `~/.local/bin` só entra no
`PATH` depois que `export PATH="$HOME/.local/bin:$PATH"` é acrescentado ao `~/.zprofile`.

## Conferindo se funciona

O seu trabalho fica em `~/js`. Uma página com uma linha de script basta para testar:

```
ana@dev:~$ cd ~/js
ana@dev:~/js$ echo '<script>console.log("the browser works")</script>' > check.html
ana@dev:~/js$ page check.html
the browser works
```

**Essa linha veio do Chromium**: o `page` serviu `~/js` em `http://127.0.0.1:8080`, abriu
`check.html` ali e imprimiu o console. Se você tem uma área de trabalho, abra o mesmo endereço no
seu próprio navegador com `node ~/js-tools/serve.mjs` rodando num segundo terminal, e aperte F12
para ver o console. As transcrições usam o `page` porque um terminal mostra a saída dele, e uma
janela não se cola.
