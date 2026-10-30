---
title: O build web, e um programa que o lê
version: 1
---

**O mesmo projeto roda num navegador**, com o `react-native-web` desenhando cada componente como HTML:
uma `<View>` vira um `<div>`, um `<Text>` um `<div>` ou `<span>` com texto dentro, e os papéis que você
lhes dá viram papéis ARIA. Não é o app nativo, e as diferenças são reais: nada da física de rolagem
nativa, nada de câmera, outro teclado. Mas componentes, estado, layout e lógica rodam, que é quase tudo
o que as aulas 4 a 11 constroem, e não precisa de nada além do computador que você tem.

## Exportando

O `npx expo export --platform web` escreve um site estático em `dist/`, do jeito que a aula 1 escreveu um
bundle Android. O `npx expo serve` serve essa pasta numa porta à sua escolha. Suba-o no segundo terminal
e deixe-o lá:

```
ana@dev:~/planner$ npx expo export --platform web > /dev/null 2>&1
ana@dev:~/planner$ ls dist
_expo
favicon.ico
index.html
metadata.json
```

O `index.html` é a página, o `_expo/` guarda o bundle JavaScript, e o `assets/` as imagens e as fontes.
Abra `http://localhost:8082/?today=2026-10-21` no navegador e a primeira tela do planner está lá. O
`?today=` fixa a semana deste curso, do jeito que o `src/today.ts` a lê.

## Um programa que lê a página

Olhar uma tela é um jeito de conferi-la. **Uma transcrição do que a tecnologia assistiva recebe é um
jeito melhor**, porque é exata, pode ser comparada de um dia para o outro, e confere que um leitor de
tela tem algo para ler. Toda transcrição web deste curso vem do programa abaixo, construído sobre o
**Playwright**, que comanda um Chromium de verdade a partir do Node.js. Você o instalou com o projeto;
ele também precisa do próprio navegador, uma vez:

```sh
npx playwright install chromium
```

Depois salve isto no projeto como `look.mjs`. Você não precisa acompanhar cada linha hoje: a aula 11 é a
primeira a usar o `--fill`, a aula 13 o `--file`, e a aula 15 o `--grant` e o `--geo`.

```javascript
// look.mjs: open a page in Chromium and print what a screen reader is given.
//
//   node look.mjs URL [--click NAME] [--fill LABEL=TEXT] [--grant PERMISSION]
//                     [--geo LAT,LON] [--file LABEL=PATH] [--wait MS] ...
//
// The options run in order, after the page has loaded. --click presses the
// control whose accessible name is NAME, --fill types TEXT into the field
// labelled LABEL, --grant and --geo answer the permission questions a page
// asks, --file picks PATH in the file chooser that pressing LABEL opens, and
// --wait lets timers run. Then it prints the accessibility tree of the page,
// and every console message and uncaught error on the way.
import { chromium } from "playwright";

const [url, ...args] = process.argv.slice(2);
const browser = await chromium.launch();
const context = await browser.newContext({ locale: "en-GB", timezoneId: process.env.TZ });
const page = await context.newPage();
page.on("console", (m) => console.log(`console.${m.type()}: ${m.text()}`));
page.on("pageerror", (e) => console.log(`uncaught: ${e.message}`));
for (let i = 0; i < args.length; i += 2) {
  if (args[i] === "--grant") await context.grantPermissions([args[i + 1]], { origin: new URL(url).origin });
  if (args[i] === "--geo") {
    const [latitude, longitude] = args[i + 1].split(",").map(Number);
    await context.setGeolocation({ latitude, longitude });
  }
}
await page.goto(url);
await page.waitForLoadState("networkidle");
for (let i = 0; i < args.length; i += 2) {
  const [flag, value] = [args[i], args[i + 1]];
  if (flag === "--click") await page.getByRole("button", { name: value, exact: true }).first().click();
  else if (flag === "--fill") {
    const [label, text] = value.split("=");
    await page.getByLabel(label, { exact: true }).fill(text);
  } else if (flag === "--file") {
    const [label, path] = value.split("=");
    const chooser = page.waitForEvent("filechooser");
    await page.getByRole("button", { name: label, exact: true }).click();
    await (await chooser).setFiles(path);
  } else if (flag === "--wait") await page.waitForTimeout(Number(value));
  else if (flag !== "--grant" && flag !== "--geo") throw new Error(`look: unknown option ${flag}`);
}
await page.waitForTimeout(300);
console.log(await page.locator("body").ariaSnapshot());
await browser.close();
```

Peça a página a ele:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/?today=2026-10-21'
- heading "Study planner" [level=1]
- text: "This week: 75 of 125 minutes done Spanish A2 Statistics Guitar"
```

Isso é a **árvore de acessibilidade**: cada elemento que um leitor de tela anunciaria, com o papel e o
nome dele. O `role="heading"` no primeiro `<Text>` do `App.tsx` é o motivo de a primeira linha dizer
`heading`; sem ele, o título seria mais um pedaço de texto, e um usuário de leitor de tela andando pelos
títulos não encontraria o título da tela.

**A segunda linha é o problema para o qual esta árvore existe.** O total e os três nomes de curso chegam
como um único trecho de texto, porque nada disse ao navegador que são coisas separadas: nenhum
parágrafo, nenhuma lista, nenhum botão. Num celular a mesma tela também seria lida como um bloco só. A
aula 4 dá a cada elemento do planner o papel que ele deve ter, e confere cada um deste jeito.

**O que isto não mostra** é a aparência do app nativo. A árvore num navegador e a árvore que um celular
monta a partir dos mesmos componentes são próximas, porque as duas vêm das mesmas props, mas são duas
renderizações, e as aulas que dependem da diferença dizem isso.
