---
title: Lendo uma página como texto
version: 1
---

**Uma transcrição não comporta uma captura de tela, então este curso lê páginas como texto.** A
ferramenta que faz isso se chama `look`, e você a constrói nesta seção: um programa curto que abre
uma página num navegador de verdade, sem janela, e imprime duas coisas. Primeiro, o que a página
escreveu no console enquanto carregava, que é onde o React relata os erros dele. Depois a página em
si, como **um retrato de acessibilidade**: uma linha por coisa que um leitor de tela anunciaria, com
o papel e o nome dela.

Você não precisa do `look` para acompanhar o curso, porque o seu navegador mostra a mesma página.
Vai querer mesmo assim. Ele responde "o que está na tela agora" numa forma que você consegue comparar
com as transcrições, e o retrato é a mesma visão de uma página que os testes da aula 22 consultam;
lê-lo agora é treino para escrevê-los.

## O Playwright, e um navegador que ele consegue dirigir

O `look` é feito sobre o **Playwright**, uma biblioteca que dirige um navegador a partir de um
programa. Ele vai numa pasta própria, `~/react-tools`, para que as ferramentas do curso nunca se
misturem com o seu app:

```
ana@dev:~$ mkdir ~/react-tools
ana@dev:~/react-tools$ npm init -y
Wrote to /home/ana/react-tools/package.json:

{
  "name": "react-tools",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}



ana@dev:~/react-tools$ npm install --save-exact playwright@1.63.0

added 2 packages, and audited 3 packages in 965ms

found 0 vulnerabilities
```

O `npm init -y` escreveu um `package.json` aceitando todos os padrões, e o `--save-exact` fixa a
biblioteca na 1.63.0 sem um `.npmrc` de projeto. **O navegador é um download à parte.** Isto
pergunta ao Playwright qual ele quer e onde o poria:

```
ana@dev:~/react-tools$ npx playwright install --dry-run --only-shell chromium
Chrome Headless Shell 153.0.8010.12 (playwright chromium-headless-shell v1243)
  Install location:    /home/ana/.cache/ms-playwright/chromium_headless_shell-1243
  Download url:        https://cdn.playwright.dev/builds/cft/153.0.8010.12/linux64/chrome-headless-shell-linux64.zip

FFmpeg (playwright ffmpeg v1011)
  Install location:    /home/ana/.cache/ms-playwright/ffmpeg-1011
  Download url:        https://cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 1: https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 2: https://cdn.playwright.dev/builds/ffmpeg/1011/ffmpeg-linux.zip
```

O Chrome Headless Shell é o Chromium construído para rodar sem janela, o 153 nesta versão do
Playwright, e ocupa uns 260 MB descompactado. No Linux, `--with-deps` também instala as bibliotecas
do sistema de que ele precisa, e pede a sua senha para isso:

```sh
npx playwright install --with-deps --only-shell chromium
```

*Esta linha não foi rodada onde o curso foi gravado.* Aquela máquina já tinha o mesmo build,
153.0.8010.12, que todas as transcrições do curso usaram. No Windows dentro do WSL, e numa máquina
virtual, a linha é a mesma. No Mac, tire o `--with-deps`.

## O programa

Salve isto em `~/react-tools` como `look.mjs`. Você não precisa acompanhar cada linha; o comentário
no topo diz o que ele faz e quais opções aceita, e as transcrições usam só essas.

```javascript
// look.mjs: open a page of yours in Chromium and print what it shows, as text.
//
//   look URL [options]
//
// It prints what the page wrote to its console while it loaded, then the page
// itself as an accessibility snapshot: one line per thing a screen reader
// would announce, with its role and its name. That is what most transcripts
// in this course show instead of a screenshot.
//
// Options, applied in order after the page has loaded:
//   --do 'click ROLE NAME'   press the button, link or checkbox with that name
//   --do 'fill LABEL=TEXT'   type TEXT into the field labelled LABEL
//   --do 'press KEY'         a key on the keyboard, such as Tab or Enter
//   --do 'wait MS'           let the page run for MS milliseconds
//   --today YYYY-MM-DD       the date the page's clock reads (default: today)
//   --network                list every request the page made
//   --html SELECTOR          at the end, print that element's HTML as well
//   --quiet                  print the console only, without the snapshot
import { chromium } from "playwright";

const args = process.argv.slice(2);
const url = args.shift();
if (!url) {
  console.error("usage: look URL [--do ACTION]... [--today DATE] [--network] [--html SELECTOR]");
  process.exit(2);
}
const opt = { do: [] };
while (args.length) {
  const a = args.shift();
  if (a === "--do") opt.do.push(args.shift());
  else if (a === "--today") opt.today = args.shift();
  else if (a === "--network") opt.network = true;
  else if (a === "--html") opt.html = args.shift();
  else if (a === "--quiet") opt.quiet = true;
  else { console.error(`look: unknown option ${a}`); process.exit(2); }
}

const say = (s) => process.stdout.write(s + "\n");
const browser = await chromium.launch();
const page = await browser.newPage({ locale: "en-GB", timezoneId: process.env.TZ || undefined });
if (opt.today) await page.clock.setFixedTime(new Date(`${opt.today}T10:00:00`));

page.on("console", (m) => {
  const t = m.type();
  if (t === "debug") return; // Vite's own "[vite] connecting..." lines
  const text = m.text();
  if (text.startsWith("[vite]")) return;
  if (text.includes("Download the React DevTools")) return; // React's own advert
  say(t === "error" ? `[error] ${text}` : t === "warning" ? `[warn] ${text}` : text);
});
page.on("pageerror", (e) => say(`Uncaught ${e.name}: ${e.message}`));
if (opt.network) {
  const origin = new URL(url).origin;
  page.on("response", (r) => say(`net  ${r.request().method()} ${r.url().replace(origin, "")}  ${r.status()}`));
}

await page.goto(url, { waitUntil: "networkidle" });
for (const action of opt.do) {
  say(`-- ${action}`);
  const [verb, ...rest] = action.split(" ");
  if (verb === "click") {
    const [role, ...name] = rest;
    await page.getByRole(role, { name: name.join(" "), exact: true }).click();
  } else if (verb === "fill") {
    const [label, ...text] = rest.join(" ").split("=");
    await page.getByLabel(label, { exact: true }).fill(text.join("="));
  } else if (verb === "press") await page.keyboard.press(rest[0]);
  else if (verb === "wait") await page.waitForTimeout(Number(rest[0]));
  else say(`look: unknown action ${verb}`);
  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(100);
}
await page.waitForTimeout(200);
if (!opt.quiet) say((await page.locator("body").ariaSnapshot()).trimEnd());
if (opt.html) say(await page.locator(opt.html).first().evaluate((e) => e.outerHTML));
await browser.close();
```

Depois um comando de três linhas, para que o `look` funcione de qualquer pasta. Salve como
`~/.local/bin/look`, a pasta de onde o `node` é ligado, e torne-o executável:

```sh
#!/bin/sh
exec node ~/react-tools/look.mjs "$@"
```

```
ana@dev:~$ chmod +x ~/.local/bin/look
```

## Usando

Com o servidor de desenvolvimento ainda rodando no terminal dele:

```
ana@dev:~/planner$ look http://localhost:5173/
- img "React logo"
- img "Vite logo"
- heading "Get started" [level=1]
- paragraph:
  - text: Edit
  - code: src/App.tsx
  - text: and save to test
  - code: HMR
- button "Count is 0"
- heading "Documentation" [level=2]
- paragraph: Your questions, answered
- list:
  - listitem:
    - link "Explore Vite":
      - /url: https://vite.dev/
  - listitem:
    - link "Learn more":
      - /url: https://react.dev/
- heading "Connect with us" [level=2]
- paragraph: Join the Vite community
- list:
  - listitem:
    - link "GitHub":
      - /url: https://github.com/vitejs/vite
  - listitem:
    - link "Discord":
      - /url: https://chat.vite.dev/
  - listitem:
    - link "X.com":
      - /url: https://x.com/vite_js
  - listitem:
    - link "Bluesky":
      - /url: https://bsky.app/profile/vite.dev
```

Leia como o esboço que um leitor de tela daria. Cada linha com `-` é um elemento, recuada sob o que a
contém: uma imagem anunciada como "React logo", um título de nível 1, um parágrafo feito de texto e
código, um botão cujo nome é o rótulo. A imagem principal não está na lista porque o modelo deu a ela
`alt=""`, o que diz que é decoração, e um leitor de tela a pula. Os links mostram para onde vão na
linha `/url:` logo abaixo.

Nada veio antes do retrato, o que quer dizer que a página não escreveu nada no console. O build de
desenvolvimento do React imprime, sim, uma linha, um anúncio da extensão dele para o navegador, e o
`look` a deixa de fora; qualquer outra coisa que a página disser aparece acima do retrato, marcada
`[error]` ou `[warn]` quando for o caso.

O `--do` executa uma ação antes de tirar o retrato, e as ações rodam na ordem dada:

```
ana@dev:~/planner$ look http://localhost:5173/ --do 'click button Count is 0' --do 'click button Count is 1'
-- click button Count is 0
-- click button Count is 1
- img "React logo"
- img "Vite logo"
- heading "Get started" [level=1]
- paragraph:
  - text: Edit
  - code: src/App.tsx
  - text: and save to test
  - code: HMR
- button "Count is 2"
- heading "Documentation" [level=2]
- paragraph: Your questions, answered
- list:
  - listitem:
    - link "Explore Vite":
      - /url: https://vite.dev/
  - listitem:
    - link "Learn more":
      - /url: https://react.dev/
- heading "Connect with us" [level=2]
- paragraph: Join the Vite community
- list:
  - listitem:
    - link "GitHub":
      - /url: https://github.com/vitejs/vite
  - listitem:
    - link "Discord":
      - /url: https://chat.vite.dev/
  - listitem:
    - link "X.com":
      - /url: https://x.com/vite_js
  - listitem:
    - link "Bluesky":
      - /url: https://bsky.app/profile/vite.dev
```

Dois cliques, e o nome do botão foi de "Count is 0" para "Count is 2". Cada `look` abre uma página
nova, então a contagem começa do zero toda vez; o botão que você aperta no seu navegador guarda a
própria contagem. **Um botão é encontrado pelo papel e pelo nome, nunca por onde está na página**, e
essa é a mesma regra que os testes da aula 22 seguem.
