---
title: Uma vista ao vivo, ou uma cópia
version: 1
---

Os dois sistemas parecem intercambiáveis até um módulo mudar algo que exporta depois de carregado.
**Um import de ES module é uma vista ao vivo da variável do módulo que exporta. Um `require` do
CommonJS devolve um objeto, e desestruturá-lo copia os valores para fora uma vez.** O mesmo contador
nos dois:

```javascript
export let count = 0;
export function increment() {
  count += 1;
}
```

```javascript
import { count, increment } from "./counter.mjs";

console.log(count);
increment();
increment();
console.log(count);
```

```javascript
let count = 0;
function increment() {
  count += 1;
}
module.exports = { count, increment };
```

```javascript
const { count, increment } = require("./counter.cjs");

console.log(count);
increment();
increment();
console.log(count);
```

```
ana@dev:~/js$ node live/main.mjs
0
2
ana@dev:~/js$ node live/main.cjs
0
0
ana@dev:~/js$ node live/assign.mjs 2>&1 | grep Error
TypeError: Assignment to constant variable.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Dois programas depois de increment rodar duas vezes. À esquerda, ES modules: o nome count em main.mjs é uma vista ao vivo da variável count dentro de counter.mjs, que vale 2, então main.mjs lê 2. À direita, CommonJS: main.cjs desestruturou count do objeto exports quando fez o require, copiando o valor 0; a variável do próprio módulo seguiu até 2, e main.cjs continua com 0.\"><defs><marker id=\"live-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"live-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16\" y=\"14\" width=\"334\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"183\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">ES modules</text><rect x=\"36\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"101.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main.mjs</text><text x=\"101.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">count → 2</text><rect x=\"200\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">counter.mjs</text><text x=\"265.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">count = 2</text><path d=\"M166 95 L196 95\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" marker-end=\"url(#live-ah-phosphor)\"></path><text x=\"183\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">vista ao vivo</text><text x=\"183\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois de increment() duas vezes</text><rect x=\"370\" y=\"14\" width=\"334\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"537\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">CommonJS</text><rect x=\"390\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main.cjs</text><text x=\"455.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">count = 0</text><rect x=\"554\" y=\"60\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"619.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">counter.cjs</text><text x=\"619.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">count = 2</text><path d=\"M550 95 L524 95\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#live-ah-amber)\"></path><text x=\"537\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">copiado uma vez</text><text x=\"537\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois de increment() duas vezes</text></svg>", "caption": "Um import é uma janela para a variável do módulo que exporta. Um require desestruturado é uma cópia tirada uma vez.", "same": ["CommonJS", "ES modules"]}
```

`main.mjs` leu `count` de novo depois de dois incrementos e **recebeu 2**: o `count` dele não é uma
variável própria, é uma janela para a que fica dentro de `counter.mjs`. `main.cjs` desestruturou
`count` do objeto exports quando fez o require do arquivo, o que **copiou o número 0**, e nada depois
conseguia alcançar essa cópia. Dentro de `counter.cjs`, `count` foi a 2 como o outro; ninguém de fora
via.

## Imports são somente leitura

O terceiro comando tentou `count = 10` num módulo que importa, e recebeu **`TypeError: Assignment to
constant variable.`**, o erro que a aula 1 deu para `const`. Um nome importado só pode ser lido; só o
módulo que declarou a variável pode mudá-la, pelo próprio código, que aqui é `increment`. Isso mantém
toda mudança no estado de um módulo dentro do módulo, onde dá para achá-la.

Na prática, **poucos módulos exportam uma variável que muda**, e na maior parte do tempo os dois
sistemas se comportam igual. Esta diferença aparece com imports circulares, dois módulos importando
um ao outro, onde ela decide se um deles vê os exports do outro preenchidos ou ainda vazios. Se você
encontrar um valor que é `undefined` na partida e certo depois, um ciclo entre dois módulos é a
primeira coisa a procurar.
