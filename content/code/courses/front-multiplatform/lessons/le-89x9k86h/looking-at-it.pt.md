---
title: Olhando para ele, no navegador e pelo terminal
version: 1
---

**`npm run dev` serve o planner enquanto você trabalha nele**, e recarrega a página sempre que você
salva um arquivo. Inicie-o num terminal só dele com `npm run dev` e deixe rodando. Ele imprime o endereço que serve,
`http://localhost:5173/`, e fica esperando.

Abra `http://localhost:5173/?today=2026-10-21` no seu navegador. A página lista os três cursos embaixo
de uma linha dizendo que esta semana tem 125 minutos e que 75 deles foram feitos: a semana da
segunda-feira, 19 de outubro, que tem quatro das seis sessões. Aperte **Statistics**, acrescente uma
sessão, marque uma como feita e veja a linha mudar. `q` e Enter no terminal param o servidor.

## A mesma página, numa transcrição

Uma janela não pode ser colada numa aula, então as transcrições deste curso mostram uma página de
outro jeito: **a árvore de acessibilidade**, que é o que o navegador entrega a um leitor de tela. Todo
título, botão, campo e linha de texto está nela, com o seu papel e o seu nome, e nada do que é só
decoração. Ela também é um teste do seu próprio app: um controle que falta na árvore é um controle que
quem usa leitor de tela não encontra.

O programa que a imprime é o `look.mjs`, feito sobre o **Playwright**, a biblioteca que controla um
navegador de verdade a partir de um programa. Instale-o no planner na versão que este curso usou, e
depois o navegador que ele controla:

```
ana@dev:~/planner$ npm install -E -D playwright@1.63.0

added 4 packages, and audited 21 packages in 917ms

found 0 vulnerabilities
```

```sh
npx playwright install chromium
```

*Essa última linha baixa o Chromium e não foi rodada onde este curso foi gravado: aquela máquina não
alcançava o servidor de downloads do Playwright, e já tinha o mesmo build que o Playwright 1.63.0 pede,
que todas as transcrições usaram. No Linux, acrescente `--with-deps` a ela e ela instala também as
bibliotecas do sistema de que o Chromium precisa, pedindo a sua senha para isso.*

Agora o programa. Salve-o na pasta do planner como `look.mjs`. Você não precisa acompanhar cada linha
hoje; a aula 4 é a primeira a usar as opções de permissão.

```javascript
// look.mjs: open a page in Chromium and print what a screen reader is given.
//
//   node look.mjs URL [--click NAME] [--fill LABEL=TEXT] [--grant PERMISSION]
//                     [--geo LAT,LON] [--wait MS] ...
//
// The options run in order, after the page has loaded. --click presses the
// button whose accessible name is NAME, --fill types TEXT into the field
// labelled LABEL, --grant and --geo answer the permission questions a page
// asks, and --wait lets timers run. Then it prints the accessibility tree of
// the page, and every console message and uncaught error on the way.
import { chromium } from "playwright";

const [url, ...args] = process.argv.slice(2);
const browser = await chromium.launch();
const context = await browser.newContext({ locale: "en-GB", timezoneId: process.env.TZ });
const page = await context.newPage();
page.on("console", (m) => console.log(`console.${m.type()}: ${m.text()}`));
page.on("pageerror", (e) => console.log(`uncaught: ${e.message}`));
await page.goto(url);
for (let i = 0; i < args.length; i += 2) {
  const [flag, value] = [args[i], args[i + 1]];
  if (flag === "--click") await page.getByRole("button", { name: value, exact: true }).first().click();
  else if (flag === "--fill") {
    const [label, text] = value.split("=");
    await page.getByLabel(label, { exact: true }).fill(text);
  } else if (flag === "--grant") await context.grantPermissions([value], { origin: new URL(url).origin });
  else if (flag === "--geo") {
    const [latitude, longitude] = value.split(",").map(Number);
    await context.setGeolocation({ latitude, longitude });
  } else if (flag === "--wait") await page.waitForTimeout(Number(value));
  else throw new Error(`look: unknown option ${flag}`);
}
console.log(await page.locator("body").ariaSnapshot());
await browser.close();
```

Com `npm run dev` ainda rodando no terminal dele, abra o planner e aperte um curso:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21'
console.debug: [vite] connecting...
console.debug: [vite] connected.
- main:
  - heading "Study planner" [level=1]
  - paragraph: "This week: 75 of 125 minutes done"
  - list:
    - listitem:
      - button "Spanish A2"
    - listitem:
      - button "Statistics"
    - listitem:
      - button "Guitar"
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Statistics --fill Date=2026-10-23 --fill Minutes=25 --click 'Add session'
console.debug: [vite] connecting...
console.debug: [vite] connected.
- main:
  - button "All courses"
  - heading "Statistics" [level=1]
  - paragraph: "This week: 75 of 150 minutes done"
  - list:
    - listitem: 2026-10-20, 45 min done
    - listitem:
      - text: 2026-10-26, 60 min
      - button "Mark done"
    - listitem:
      - text: 2026-10-23, 25 min
      - button "Mark done"
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes"
  - button "Add session"
```

As duas linhas `console.debug` são do próprio Vite: o servidor de desenvolvimento põe na página um
pequeno script que a recarrega quando um arquivo muda, e esse script avisa que se conectou. Um site
construído não tem nenhuma das duas. Cada uma das outras linhas é uma coisa que um leitor de tela
anuncia. `heading "Study planner" [level=1]` é o `<h1>`, `button "Spanish A2"` é um botão cujo nome é
o texto dele, e `list` e `listitem` são o `<ul>` e os `<li>` dele. A segunda execução apertou
**Statistics**, digitou uma data e uma duração nos dois campos que o formulário rotula, 23 de outubro e
25 minutos, e apertou **Add session**. A sessão nova é o último item, e o total da semana foi de 125
para 150 minutos, porque 23 de outubro cai na mesma semana.

Os dados ficam só na memória. **Recarregue a página e a sessão acrescentada some**, porque nada a salvou
em lugar nenhum. A aula 4 resolve isso com um plugin do Capacitor, que é a primeira vez que o app
precisa de algo que um celular dá e uma página não.
