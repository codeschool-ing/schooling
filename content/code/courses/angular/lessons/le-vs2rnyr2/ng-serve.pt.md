---
title: O servidor de desenvolvimento, e um jeito de ler o que ele serve
version: 1
---

**O `ng serve` faz o build da aplicação em memória, serve-a em `http://localhost:4200`, e faz o build
de novo toda vez que você salva um arquivo.** É o comando que fica rodando o dia todo, num terminal
só dele. Inicie-o num segundo terminal, em `~/planner`:

```
ana@dev:~/planner$ npx ng serve
❯ Building...
✔ Building...
Initial chunk files | Names         | Raw size
main.js             | main          | 47.76 kB | 
styles.css          | styles        | 95 bytes | 

                    | Initial total | 47.85 kB

Application bundle generation complete. [1.450 seconds] - 2026-10-23T22:43:50.048Z

Watch mode enabled. Watching for file changes...
NOTE: Raw file sizes do not reflect development server per-request transformations.
  ➜  Local:   http://localhost:4200/
```

A tabela é o build: `main.js` é a sua aplicação, `styles.css` os estilos globais. Os pacotes do
próprio framework não estão nela: em desenvolvimento eles são servidos como arquivos separados,
preparados uma vez e reaproveitados, o que é parte do motivo de uma mudança ser reconstruída numa
fração de segundo. `Watch mode enabled` quer dizer que agora ele espera você mudar alguma coisa. Ele
fica com aquele terminal; pare-o com Ctrl-C quando terminar o dia.

**A memória que ele ocupa** é o número que a tabela da aula 1 citou. O `ps` lista os processos e a
memória de cada um, em kilobytes, na primeira coluna:

```
ana@dev:~/planner$ ps -o rss=,args= -u ana | sort -rn | head -3
370528 ng serve (planner)
82496 npm exec ng serve
17724 /home/ana/planner/node_modules/@esbuild/linux-x64/bin/esbuild --service=0.28.1 --ping
```

A primeira linha é o servidor de desenvolvimento, a segunda o `npx` que o iniciou, a terceira o
`esbuild`, o compilador que a CLI usa por baixo.

Duas coisas dão errado com ele com frequência suficiente para saber de antemão. Inicie um segundo
enquanto o primeiro roda e ele recusa, porque a porta está ocupada:

```
ana@dev:~/planner$ npx ng serve
An unhandled exception occurred: Port 4200 is already in use. Use '--port' to specify a different port.
See "/tmp/ng-WloOfH/angular-errors.log" for further details.
```

Num terminal, ele pergunta em vez disso se deve usar outra porta. De qualquer jeito, o conserto
costuma ser achar o terminal onde o primeiro está rodando. E dentro de uma máquina virtual,
`npx ng serve --host 0.0.0.0` o faz escutar em todos os endereços do convidado e não só no
`localhost` dele, que é o que um navegador no hospedeiro precisa.

## look: lendo uma página pelo terminal

Abra `http://localhost:4200` num navegador e você vê a página de boas-vindas do Angular. Uma janela de
navegador não cabe numa aula, então este curso lê páginas com um programa curto, do jeito que
`javascript` usou o `page`. Salve-o ao lado do `page.mjs`, como `~/js-tools/look.mjs`:

```javascript
// look.mjs: open a page of your app in a real browser, and print what a
// person would see on it. The transcripts in this course that start with
// `look` were made with it.
//
//   look URL [options]
//
// The browser is Chromium with no window, driven by Playwright, the same one
// page.mjs drives. What it prints, in order:
//   - each console message, as page.mjs prints them ([warn], [error], and
//     "Uncaught" for an exception nobody caught)
//   - each action it performs, as "-- " and the action
//   - at the end, the text of the page as a reader sees it: what the browser
//     renders, with hidden elements left out
//
// Options, applied in order after the page has loaded:
//   --do 'click TEXT' | 'fill LABEL = TEXT' | 'check LABEL' | 'press KEY'
//        | 'select LABEL = OPTION' | 'go PATH' | 'wait MS'
//        click finds a button or a link by what it says; fill, check and
//        select find a form field by its label, as a screen reader would
//   --text SEL     print the text of SEL instead of the whole page
//   --html SEL     print SEL's HTML instead of text, without the attributes
//                  Angular adds to keep a component's styles to itself
//                  (_ngcontent-…, _nghost-…); --raw keeps them
//   --a11y SEL     print SEL's accessibility tree: the roles and names a
//                  screen reader announces
//   --today DATE   make the browser's clock say DATE (YYYY-MM-DD), at 09:00
//   --network      list every request the page made, and its status
//   --no-js        open the page with JavaScript turned off
//   --wait MS      how long to let the page settle after each step (500)
import { chromium } from "playwright";

const args = process.argv.slice(2);
const url = args.shift();
if (!url) { console.error("usage: look URL [options]"); process.exit(2); }
const opt = { do: [], wait: 500 };
while (args.length) {
  const a = args.shift();
  if (a === "--do") opt.do.push(args.shift());
  else if (a === "--text") opt.text = args.shift();
  else if (a === "--html") opt.html = args.shift();
  else if (a === "--raw") opt.raw = true;
  else if (a === "--a11y") opt.a11y = args.shift();
  else if (a === "--today") opt.today = args.shift();
  else if (a === "--network") opt.network = true;
  else if (a === "--no-js") opt.noJs = true;
  else if (a === "--wait") opt.wait = Number(args.shift());
  else { console.error(`look: unknown option ${a}`); process.exit(2); }
}

const browser = await chromium.launch();
const context = await browser.newContext({
  locale: "en-GB", // so the browser's own messages are in the course's language
  timezoneId: process.env.TZ || undefined,
  javaScriptEnabled: !opt.noJs,
});
const page = await context.newPage();
if (opt.today) await page.clock.setFixedTime(new Date(`${opt.today}T09:00:00`));

const say = (s) => process.stdout.write(s + "\n");
page.on("console", (m) => {
  const t = m.type();
  if (t === "error") say(`[error] ${m.text()}`);
  else if (t === "warning") say(`[warn] ${m.text()}`);
  else say(m.text());
});
page.on("pageerror", (e) => say(`Uncaught ${e.name}: ${e.message}`));
const origin = new URL(url).origin;
if (opt.network) {
  page.on("response", (r) => say(`net  ${r.request().method()} ${r.url().replace(origin, "")}  ${r.status()}`));
  page.on("requestfailed", (r) => say(`net  ${r.method()} ${r.url().replace(origin, "")}  failed: ${r.failure()?.errorText}`));
}

const settle = () => page.waitForTimeout(opt.wait);
const field = (label) => page.getByLabel(label, { exact: true });
await page.goto(url);
await settle();
for (const action of opt.do) {
  say(`-- ${action}`);
  const [verb, ...rest] = action.split(" ");
  const arg = rest.join(" ");
  const [label, value] = arg.split(" = ");
  if (verb === "click") await page.getByRole("button", { name: arg, exact: true })
    .or(page.getByRole("link", { name: arg, exact: true })).first().click();
  else if (verb === "fill") await field(label).fill(value ?? "");
  else if (verb === "check") await field(arg).check();
  else if (verb === "select") await field(label).selectOption(value);
  else if (verb === "press") await page.keyboard.press(arg);
  else if (verb === "go") await page.goto(new URL(arg, origin).href);
  else if (verb === "wait") await page.waitForTimeout(Number(arg));
  else say(`look: unknown action ${verb}`);
  await settle();
}

if (opt.html) {
  let html = await page.locator(opt.html).first().evaluate((e) => e.outerHTML);
  if (!opt.raw) html = html.replace(/ _ng(content|host)-[\w-]+=""/g, "");
  say(html);
} else if (opt.a11y) {
  say(await page.locator(opt.a11y).first().ariaSnapshot());
} else {
  say((await page.locator(opt.text || "body").first().innerText()).trim());
}
await browser.close();
```

e dê a ele um comando próprio, como a aula 1 de `javascript` fez para o `page`:

```sh
cat > ~/.local/bin/look <<'END'
#!/bin/sh
exec node "$HOME/js-tools/look.mjs" "$@"
END
chmod +x ~/.local/bin/look
```

Você não precisa ler o programa agora; as primeiras linhas dele dizem o que ele faz. Ele abre o
endereço que você dá no Chromium, pelo Playwright que você instalou para `javascript`, e imprime o que
a página escreveu no console e depois o texto que uma pessoa leria. Com `--text h1` ele imprime só o
primeiro título:

```
ana@dev:~/planner$ look http://localhost:4200/ --text h1
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Hello, planner
```

As três linhas antes do título são o console. `[vite]` é a conexão de recarregamento ao vivo do
servidor de desenvolvimento, que o `ng serve` constrói sobre o Vite, e `Angular is running in
development mode` é o Angular dizendo que as conferências de que as aulas 7 e 9 dependem estão
ligadas. Um build de produção, duas seções adiante, não imprime nenhuma das duas.

## A sua primeira edição

O `src/app/app.html` tem 20 kilobytes de página de boas-vindas. Troque tudo por duas linhas:

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<router-outlet />
```

`<router-outlet />` é onde o router vai desenhar uma tela, a partir da aula 17; por enquanto ele não
desenha nada. A primeira linha é um comentário HTML com o nome do arquivo, como todo arquivo que este
curso pede para você salvar, e o build tira comentários dos templates. Assim que você salva, o
terminal do servidor de desenvolvimento ganha um build novo:

```
ana@dev:~/planner$ npx ng serve
❯ Building...
✔ Building...
Initial chunk files | Names         | Raw size
main.js             | main          | 47.76 kB | 
styles.css          | styles        | 95 bytes | 

                    | Initial total | 47.85 kB

Application bundle generation complete. [1.450 seconds] - 2026-10-23T22:43:50.048Z

Watch mode enabled. Watching for file changes...
NOTE: Raw file sizes do not reflect development server per-request transformations.
  ➜  Local:   http://localhost:4200/
❯ Changes detected. Rebuilding...
✔ Changes detected. Rebuilding...
Initial chunk files | Names | Raw size
main.js             | main  |  2.39 kB | 

Application bundle generation complete. [0.135 seconds] - 2026-10-23T22:43:53.033Z

Component update sent to client(s).
```

**Só o que mudou foi reconstruído**, um `main.js` de dois kilobytes e pouco no lugar da aplicação
inteira, e `Component update sent to client(s)` quer dizer que a página aberta trocou o template novo
sem recarregar. Pergunte de novo:

```
ana@dev:~/planner$ look http://localhost:4200/
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Study planner
```

## Os dados, em public/

Por último, os dados do planner da aula 1, na pasta que o build copia como está. Salve-os como
`public/courses.json`:

```schooling-example
{"language": "json", "file": "public/courses.json", "parts": [
 {"code": "{\n  \"courses\": [\n    { \"id\": \"html-css\", \"name\": \"HTML and CSS\" },\n    { \"id\": \"javascript\", \"name\": \"JavaScript\" },\n    { \"id\": \"git\", \"name\": \"Git\" }\n  ],", "note": "Três cursos. O `id` de um curso é como as sessões dele o encontram, e o `name` é o que uma pessoa lê."},
 {"code": "  \"sessions\": [\n    { \"id\": 1, \"courseId\": \"javascript\", \"date\": \"2026-10-13\", \"minutes\": 45, \"done\": true },\n    { \"id\": 2, \"courseId\": \"html-css\", \"date\": \"2026-10-19\", \"minutes\": 30, \"done\": true },\n    { \"id\": 3, \"courseId\": \"javascript\", \"date\": \"2026-10-20\", \"minutes\": 60, \"done\": true },\n    { \"id\": 4, \"courseId\": \"git\", \"date\": \"2026-10-22\", \"minutes\": 25, \"done\": false },\n    { \"id\": 5, \"courseId\": \"javascript\", \"date\": \"2026-10-24\", \"minutes\": 50, \"done\": false },\n    { \"id\": 6, \"courseId\": \"html-css\", \"date\": \"2026-10-27\", \"minutes\": 40, \"done\": false }\n  ]\n}", "note": "Seis sessões. `courseId` é o `id` do curso ao qual a sessão pertence. `date` é escrita `AAAA-MM-DD`, para as datas ficarem em ordem certa como texto, e `minutes` é um número inteiro."}
]}
```

Tudo em `public/` é servido na raiz do site, então o arquivo devia estar agora em `/courses.json`:

```
ana@dev:~/planner$ curl -s http://localhost:4200/courses.json | head -4
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
```

Isso não é JSON. É o começo da página, o `index.html`, e dois fatos sobre o servidor de
desenvolvimento explicam o porquê. **Ele lê o `public/` quando inicia**, então um arquivo acrescentado
com ele rodando ainda não existe para ele. E **ele responde todo endereço para o qual não tem arquivo
com o `index.html`**, que é o que uma aplicação Angular precisa de um servidor, por um motivo que a
seção de build mostra daqui a pouco. Pare o servidor com Ctrl-C no terminal dele, e inicie de novo:

```
ana@dev:~/planner$ npx ng serve
❯ Building...
✔ Building...
Initial chunk files | Names         | Raw size
main.js             | main          |  2.39 kB | 
styles.css          | styles        | 95 bytes | 

                    | Initial total |  2.48 kB

Application bundle generation complete. [1.468 seconds] - 2026-10-23T22:43:59.268Z

Watch mode enabled. Watching for file changes...
NOTE: Raw file sizes do not reflect development server per-request transformations.
  ➜  Local:   http://localhost:4200/
```

```
ana@dev:~/planner$ curl -s http://localhost:4200/courses.json | head -4
{
  "courses": [
    { "id": "html-css", "name": "HTML and CSS" },
    { "id": "javascript", "name": "JavaScript" },
```

Nada na aplicação lê o arquivo ainda. A aula 6 lê, com o primeiro signal que espera por alguma coisa.
