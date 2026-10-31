---
title: Medindo uma animação
version: 1
---

**Uma animação é uma sequência de quadros, e a única prova de que ela aconteceu é a sequência.** Este
programa abre o planner num navegador, vai para *This week*, aperta um botão *Mark done*, volta para
*Courses* e lê a largura desenhada da barra a cada 50 milissegundos. Salve-o como `frames.mjs`:

```javascript
// frames.mjs: open the Courses tab, go to This week, press a button, come back, and print the
// week bar's drawn width every 50 ms for the next half second.
//
//   node frames.mjs URL BUTTON [--reduced]
//
// --reduced asks the browser for reduced motion, as the phone's accessibility setting would.
import { chromium } from "playwright";

const [url, button, flag] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage({ reducedMotion: flag === "--reduced" ? "reduce" : "no-preference" });
await page.goto(url);
await page.waitForLoadState("networkidle");
await page.getByRole("tab", { name: "This week" }).click(); // Courses stays mounted behind it
const press = await page.getByRole("button", { name: button, exact: true }).elementHandle();
const tab = await page.getByRole("tab", { name: "Courses" }).elementHandle();
// Pressed and measured inside the page, in one go, so the times are the page's own and not
// the program's round trips to the browser.
const widths = await page.evaluate(
  ([press, tab]) =>
    new Promise((done) => {
      press.click();
      tab.click();
      const seen = [];
      const look = () => {
        const bar = document.querySelector('[data-testid="week-done"]');
        seen.push(Math.round(bar.getBoundingClientRect().width));
        if (seen.length < 11) setTimeout(look, 50);
        else done(seen);
      };
      look();
    }),
  [press, tab],
);
console.log("width every 50 ms:", widths.join(" "));
await browser.close();
```

Dois detalhes deixam os números honestos. A aba *Courses* é aberta primeiro, então a barra já está na
tela quando a sessão é marcada como feita; uma aba que o React Navigation nunca mostrou montaria a barra
já no valor novo, sem nada para animar. E o toque, a volta e a amostragem acontecem dentro da página, num
único `evaluate`, então os 50 milissegundos são da própria página, e não o tempo que o programa leva para
falar com o navegador.

Com o servidor rodando e o build web servido como na aula 10:

```
ana@dev:~/planner$ node frames.mjs 'http://localhost:8082/?today=2026-10-21' 'Mark 20 min on 2026-10-21 done'
width every 50 ms: 739 796 861 902 924 934 936 936 936 936 936
```

**739 é 60 por cento dos 1232 pontos que a barra pode preencher, e 936 é 76 por cento**: 75 e depois 95
de 125 minutos. No meio, a largura sobe rápido e depois desacelera, 57, 65, 41, 22, 10, 2 pontos por
amostra, que é o `Easing.out(Easing.cubic)`, e chega dentro dos 300 milissegundos pedidos. Na web, o
`react-native-web` roda a animação do driver nativo em JavaScript, já que um navegador não tem uma thread
de UI separada para entregá-la; *num celular a mesma descrição roda na thread de UI, o que não foi medido
para este curso*. O que o navegador prova é a descrição: o começo, o fim, a curva e o tempo.
