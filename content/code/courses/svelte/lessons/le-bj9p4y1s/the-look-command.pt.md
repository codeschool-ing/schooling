---
title: O comando look
version: 1
---

**Uma página é algo que se olha, e uma transcrição só mostra texto, então este curso lê páginas do
jeito que um leitor de tela lê.** O `look` é um programa curto que você vai salvar daqui a pouco. Ele
abre um endereço no Chromium, um navegador de verdade sem janela, e imprime a página como uma árvore
de papéis e nomes: um título e o seu nível, uma lista e os seus itens, um botão e as palavras nele.
Essa árvore é exatamente o que a tecnologia assistiva anuncia, então cada vez que você lê uma está
também conferindo se a página faz sentido para alguém que não a enxerga.

Se você tem uma área de trabalho, abra os mesmos endereços no seu navegador também. O `look` serve
às transcrições, e a uma máquina virtual sem tela; ele não substitui olhar.

## O Playwright e o seu navegador

O `look` é construído sobre o **Playwright**, uma biblioteca que dirige um navegador de verdade a
partir de um programa. A aula 19 usa ele de novo para testar o planner. Ele mora numa pasta
própria, `~/svelte-tools`, para que as ferramentas do curso nunca se misturem com o projeto:

```
ana@dev:~$ mkdir ~/svelte-tools && cd ~/svelte-tools
ana@dev:~/svelte-tools$ npm init -y > /dev/null
ana@dev:~/svelte-tools$ npm install --save-exact playwright@1.63.0

added 2 packages, and audited 3 packages in 2s

found 0 vulnerabilities
ana@dev:~/svelte-tools$ npx playwright install --dry-run --only-shell chromium
Chrome Headless Shell 153.0.8010.12 (playwright chromium-headless-shell v1243)
  Install location:    /home/ana/.cache/ms-playwright/chromium_headless_shell-1243
  Download url:        https://cdn.playwright.dev/builds/cft/153.0.8010.12/linux64/chrome-headless-shell-linux64.zip

FFmpeg (playwright ffmpeg v1011)
  Install location:    /home/ana/.cache/ms-playwright/ffmpeg-1011
  Download url:        https://cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 1: https://playwright.download.prss.microsoft.com/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-linux.zip
  Download fallback 2: https://cdn.playwright.dev/builds/ffmpeg/1011/ffmpeg-linux.zip
```

`--save-exact` grava a versão como `1.63.0` em vez de `^1.63.0`, então a pasta mantém esta versão
até você mudar. **O navegador é um download separado**, e `--dry-run` pergunta ao Playwright onde
ele o colocaria e que build ele quer: o Chrome Headless Shell 153, o build do Chromium que roda sem
janela. O download em si ocupa uns 260 MB depois de descompactado, e no Linux `--with-deps` também
instala as bibliotecas do sistema de que ele precisa, pedindo a sua senha para isso:

```sh
npx playwright install --with-deps --only-shell chromium
```

*Esta linha não foi rodada onde o curso foi gravado. Aquela máquina não alcança o servidor de
downloads do Playwright, e já tinha o mesmo build, 153.0.8010.12, que todo `look` deste curso usou.*

## O programa

Salve isto como `~/svelte-tools/look.mjs`. Você não precisa acompanhar cada linha agora. Ele abre o
endereço, faz em ordem o que as opções pedem, e imprime o caminho em que terminou, o título da
página quando ela tem um, e a árvore do `<main>` da página, ou da página inteira quando não há
`<main>`:

```javascript
// look.mjs: open a page in Chromium and print what is on it, as the tree of
// roles and names a screen reader is given. The transcripts in this course
// that start with `look` were made with it.
//
//   look URL [options]
//
// Options, carried out in order once the page has loaded:
//   --click NAME        press the button or link whose name is NAME
//   --fill LABEL=TEXT   type TEXT into the field whose label is LABEL
//   --check LABEL       tick or untick the checkbox whose label is LABEL
//   --press KEY         press a key, such as Enter or ArrowRight
//   --wait MS           let the page run for MS milliseconds
//   --no-js             open the page with JavaScript turned off
//   --console           print what the page wrote to its console, too
// At the end it prints the path it is on, the page's title if it has one,
// and the tree of <main>.
import { chromium } from "playwright";

const [url, ...args] = process.argv.slice(2);
if (!url) { console.error("usage: look URL [options]"); process.exit(2); }
const browser = await chromium.launch();
const page = await browser.newPage({ javaScriptEnabled: !args.includes("--no-js") });
if (args.includes("--console")) page.on("console", (m) => console.log(`console: ${m.text()}`));
page.on("pageerror", (e) => console.log(`error: ${e.message}`));
await page.goto(url, { waitUntil: "networkidle" });

for (let i = 0; i < args.length; i++) {
  const [flag, value] = [args[i], args[i + 1]];
  if (flag === "--no-js" || flag === "--console") continue;
  i++;
  console.log(`-- ${flag.slice(2)} ${value}`);
  if (flag === "--click") {
    const name = { name: value, exact: true };
    await page.getByRole("button", name).or(page.getByRole("link", name)).click();
  } else if (flag === "--fill") {
    const [label, ...text] = value.split("=");
    await page.getByLabel(label, { exact: true }).fill(text.join("="));
  } else if (flag === "--check") {
    await page.getByLabel(value, { exact: true }).click();
  } else if (flag === "--press") {
    await page.keyboard.press(value);
  } else if (flag === "--wait") {
    await page.waitForTimeout(Number(value));
  } else {
    console.error(`look: unknown option ${flag}`); process.exit(2);
  }
  await page.waitForLoadState("networkidle");
}

const where = new URL(page.url());
if (where.protocol.startsWith("http")) console.log(`at ${where.pathname}`);
if (await page.title()) console.log(`title: ${await page.title()}`);
const main = page.locator("main");
console.log(await ((await main.count()) ? main : page.locator("body")).ariaSnapshot());
await browser.close();
```

Depois, um comando chamado `look` que o roda de qualquer lugar, do mesmo jeito que a aula 1 do
`javascript` criou o `page`:

```sh
# ~/.local/bin/look: run look.mjs from any folder
cat > ~/.local/bin/look <<'EOF'
#!/bin/sh
exec node "$HOME/svelte-tools/look.mjs" "$@"
EOF
chmod +x ~/.local/bin/look
```

## Conferindo que funciona

Uma página não precisa de servidor para ser olhada. Um endereço que começa com `data:text/html,` traz
a página dentro de si:

```
ana@dev:~$ look 'data:text/html,<main><h1>It works</h1><button>Press me</button></main>'
- main:
  - heading "It works" [level=1]
  - button "Press me"
```

**Cada linha é uma coisa que um leitor de tela anunciaria.** `main` é a região principal da página,
e tudo o que vem recuado embaixo dele está dentro dela. `heading "It works" [level=1]` é o `<h1>`,
com o seu texto como nome e o nível ao lado; `button "Press me"` é o botão, nomeado pelo seu texto.
Uma página servida num endereço `http://` ganha também uma primeira linha dizendo em que caminho o
navegador terminou, o que passa a importar na aula 12, quando os links começam a levar de uma página
a outra. Quando você ler uma árvore dessas depois e um controle não tiver nome, ou um título tiver o
nível errado, você achou um defeito de acessibilidade antes de alguém precisar reclamar dele.
