---
title: O seu computador, preparado para este curso
version: 1
---

**Tudo neste curso roda no seu próprio computador, e se você fez o `javascript` quase tudo já está
lá.** Aquele curso instalou o Node.js 22 na primeira aula. Este usa o mesmo Node, na mesma versão,
instalado do mesmo jeito, para que ninguém instale duas vezes nem acabe com dois. O que este curso
acrescenta é pouco: uma pasta para o seu trabalho e um programa chamado `look`, que abre uma página
num navegador de verdade e imprime o que há nela, para que uma transcrição possa mostrar o que a tela
mostrou.

## Três jeitos de ter isso

| caminho | o que você ganha | quanto custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | o Node.js e o `look` no computador que você já usa, com o seu navegador ao lado | cerca de 700 MB de disco quando o navegador e os projetos estiverem lá | batem como impressas no Linux; parecidas nos outros |
| uma máquina virtual | o Ubuntu Server 24.04 separado do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto roda | batem como impressas |
| online | uma máquina Linux numa aba do navegador | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**Instale no computador que você usa.** Um curso de front-end é mais fácil onde você já tem um
navegador com janela: você vai abrir cada página que construir em `http://localhost:5173` e vê-la
mudar enquanto digita. O Node vai para `~/.local/node` e não mexe em mais nada. No **Linux** os
comandos abaixo funcionam como estão. No **Windows**, instale o WSL primeiro (`wsl --install -d
Ubuntu-24.04` num PowerShell aberto como administrador, reinicie, abra o Ubuntu pelo menu Iniciar) e
digite tudo dentro dele; o endereço que um servidor de desenvolvimento imprime dentro do WSL abre no
seu navegador do Windows do jeito que está. No **Mac**, o instalador do Node.js 22 do nodejs.org lhe
dá o mesmo `node`, embora esse caminho não tenha sido rodado para este curso, e um caminho numa
transcrição pode ser diferente do seu.

**Uma máquina virtual** é o VirtualBox no Windows ou no Linux, ou o UTM num Mac com chip da Apple,
com o Ubuntu Server 24.04 LTS como convidado e os passos do Linux dentro dele. Foi assim que este
curso foi gravado. Um servidor não tem área de trabalho, então lá não há janela de navegador, e o
`look` é como você vê uma página. **Online**, o GitHub Codespaces e serviços parecidos dão um
terminal Linux numa aba do navegador, com uma cota mensal cujas condições a empresa define e pode
mudar; isso não foi rodado para este curso, e lá um servidor de desenvolvimento é alcançado por um
endereço que o serviço lhe dá, e não por `localhost`.

## Node.js, em resumo

Esta é a seção "Node.js" da aula 1 do javascript, sem a explicação; leia lá se algum passo for novo
para você. `uname -m` diz qual arquivo pegar: `x86_64` pega o que termina em `linux-x64`, e
`aarch64` o que termina em `linux-arm64`.

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

**A última linha falha, e isso é esperado.** `~/.local/bin` entra no seu `PATH`, a lista de pastas
em que o shell procura um comando, só num terminal aberto depois de a pasta existir. Feche este, abra
um novo e confira os dois programas:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ npm config set update-notifier false
ana@dev:~$ mkdir ~/vue ~/vue-tools
```

O `node` tem de dizer `v22.22.0`, ou um 22 posterior. A terceira linha faz o npm parar de oferecer
um npm mais novo embaixo de cada instalação: o npm que veio com o Node 22 é o que este curso usa. E
**`~/vue` é onde fica o seu trabalho**, com `~/vue-tools` ao lado para a única ferramenta do curso.

## O comando look

O `look` é feito com o **Playwright**, uma biblioteca que controla um navegador de verdade a partir
de um programa; a aula 1 do javascript o usou no comando `page`. Este curso fixa a sua própria cópia,
numa versão exata, em `~/vue-tools`:

```
ana@dev:~/vue-tools$ npm init -y > /dev/null
ana@dev:~/vue-tools$ npm install --save-exact playwright@1.63.0

added 2 packages, and audited 3 packages in 2s

found 0 vulnerabilities
```

O `--save-exact` escreve `1.63.0` no `package.json` em vez de `^1.63.0`, que deixaria uma instalação
posterior pegar um Playwright mais novo. **Toda versão neste curso é fixada do mesmo jeito**, pelo
motivo que uma transcrição exige: uma versão diferente imprime coisas diferentes.

O navegador é um download separado, de cerca de 300 MB. O Playwright 1.63.0 controla o Chromium
153.0.8010.12, e esta linha baixa esse build, com as bibliotecas do sistema de que ele precisa no
Linux (ela pede a sua senha para instalá-las):

```sh
cd ~/vue-tools && npx playwright install --with-deps --only-shell chromium
```

*Essa linha não foi rodada onde o curso foi gravado. A máquina de gravação já tinha o mesmo build, o
Chromium 153.0.8010.12, e o `~/.cache/ms-playwright` foi apontado para ele.*

Agora o programa. Salve-o como `~/vue-tools/look.mjs`. Você ainda não precisa lê-lo; o primeiro
comentário diz o que ele imprime e que opções aceita, e as aulas 2 a 22 usam essas opções uma de cada
vez.

```javascript
// look.mjs: open a page in a real browser and print what is on it.
//
//   look URL [options]
//
// The browser is Chromium with no window, driven by Playwright. The page is
// opened at URL, usually the address your dev server printed, and once it
// has loaded this prints, in order: every console message the page wrote
// ([warn] and [error] marked as the browser marks them, an uncaught
// exception as "Uncaught" and its message), a line "-- ACTION" for each
// action below as it is performed, and at the end the text of the page as
// a reader sees it: the innerText of #app, or of the element --text names.
//
// Options, applied in the order given:
//   --do 'click SEL'      click the first element SEL matches
//   --do 'fill SEL TEXT'  type TEXT into a field (SEL without spaces)
//   --do 'check SEL'      tick a checkbox
//   --do 'select SEL VAL' choose the option whose value is VAL (SEL without spaces)
//   --do 'press KEY'      press a key on whatever has focus (Tab, Enter...)
//   --do 'goto PATH'      go to another address on the same site
//   --do 'wait MS'        let MS milliseconds pass
//   --text SEL            print the text of SEL instead of #app ('-' for none)
//   --html SEL            also print SEL's HTML, as the page has it now
//   --source              also print the HTML the server sent, before any
//                         script ran
//   --no-js               open the page with JavaScript turned off
//   --network             list every request the page made
//   --clock ISO           the date the page's clock says, e.g. 2026-10-21T10:00
//   --width PX            the window's width (1024)
//   --reduced-motion      the reader has asked their system for less motion
import { chromium } from "playwright";

const args = process.argv.slice(2);
const url = args.shift();
if (!url) { console.error("usage: look URL [options]"); process.exit(2); }
const opt = { do: [], text: "#app", width: 1024 };
while (args.length) {
  const a = args.shift();
  if (a === "--do") opt.do.push(args.shift());
  else if (a === "--text") opt.text = args.shift();
  else if (a === "--html") opt.html = args.shift();
  else if (a === "--source") opt.source = true;
  else if (a === "--no-js") opt.noJs = true;
  else if (a === "--network") opt.network = true;
  else if (a === "--clock") opt.clock = args.shift();
  else if (a === "--width") opt.width = Number(args.shift());
  else if (a === "--reduced-motion") opt.reducedMotion = "reduce";
  else { console.error(`look: unknown option ${a}`); process.exit(2); }
}

const browser = await chromium.launch();
const context = await browser.newContext({
  javaScriptEnabled: !opt.noJs,
  locale: "en-GB",
  timezoneId: process.env.TZ || undefined,
  viewport: { width: opt.width, height: 768 },
  reducedMotion: opt.reducedMotion || "no-preference",
});
const page = await context.newPage();
const say = (s) => process.stdout.write(s + "\n");
if (opt.clock) await page.clock.setFixedTime(new Date(opt.clock));
page.on("console", (m) => {
  const t = m.type();
  say(t === "error" ? `[error] ${m.text()}` : t === "warning" ? `[warn] ${m.text()}` : m.text());
});
page.on("pageerror", (e) => say(`Uncaught ${e.name}: ${e.message}`));
const origin = new URL(url).origin;
if (opt.network) {
  page.on("response", (r) => say(`net  ${r.request().method()} ${r.url().replace(origin, "")}  ${r.status()}`));
}

const first = await page.goto(url, { waitUntil: "networkidle" });
if (opt.source) {
  say("== the HTML the server sent");
  say((await first.text()).trimEnd());
}
for (const action of opt.do) {
  say(`-- ${action}`);
  const [verb, ...rest] = action.split(" ");
  const sel = rest[0];
  if (verb === "click") await page.click(rest.join(" "));
  else if (verb === "fill") await page.fill(sel, rest.slice(1).join(" "));
  else if (verb === "check") await page.check(rest.join(" "));
  else if (verb === "select") await page.selectOption(sel, rest.slice(1).join(" "));
  else if (verb === "press") await page.keyboard.press(sel);
  else if (verb === "goto") await page.goto(origin + sel, { waitUntil: "networkidle" });
  else if (verb === "wait") await page.waitForTimeout(Number(sel));
  else say(`look: unknown action ${verb}`);
  await page.waitForTimeout(100);
}
await page.waitForTimeout(200);
if (opt.html) {
  say(`== the HTML of ${opt.html}`);
  say(await page.$eval(opt.html, (e) => e.outerHTML).catch(() => `(nothing matches ${opt.html})`));
}
if (opt.text !== "-") {
  say(`== the text of ${opt.text}`);
  say((await page.innerText(opt.text).catch(() => `(nothing matches ${opt.text})`)).trimEnd());
}
await browser.close();
```

Por último, um comando chamado `look` que o roda de onde você estiver:

```sh
cat > ~/.local/bin/look <<'END'
#!/bin/sh
exec node "$HOME/vue-tools/look.mjs" "$@"
END
chmod +x ~/.local/bin/look
```

Um arquivo em `~/.local/bin` que começa com `#!/bin/sh` e está marcado como executável é um comando,
e o `"$@"` lhe entrega tudo o que for digitado depois do nome dele. Os dois arquivos, como ficaram:

```
ana@dev:~$ cat ~/.local/bin/look
#!/bin/sh
exec node "$HOME/vue-tools/look.mjs" "$@"
ana@dev:~$ cat ~/vue-tools/package.json
{
  "name": "vue-tools",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "playwright": "1.63.0"
  }
}
```

Ainda não há nada para ver: o `look` precisa de uma página, e a próxima seção faz a primeira.
