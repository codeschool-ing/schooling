---
title: O laço cujos callbacks veem todos 3
version: 1
---

Este é o bug pelo qual o `var` é famoso, e ele ainda aparece em revisões de código. Um laço agenda
algum trabalho para depois, e **cada pedaço de trabalho vê o valor que o contador tinha no fim**:

```javascript
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log("var", i), 0);
}
```

```javascript
for (let i = 0; i < 3; i++) {
  setTimeout(() => console.log("let", i), 0);
}
```

```
ana@dev:~/js$ node loop-var.js
var 3
var 3
var 3
ana@dev:~/js$ node loop-let.js
let 0
let 1
let 2
```

`setTimeout(fn, 0)` roda `fn` depois que o programa atual terminou, o que aqui quer dizer depois
que o laço acabou. A aula 15 trata do que "zero" significa de verdade; por ora, o que importa é que
**os callbacks rodam depois que o laço terminou de contar**.

## Por que o `var` imprime 3 três vezes

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Dois laços agendando três callbacks cada. Com var existe uma variável i para o laço inteiro, os três callbacks apontam para ela, e quando rodam ela vale 3. Com let cada volta do laço tem o seu próprio i, valendo 0, 1 e 2, e cada callback aponta para o seu.\"><defs><marker id=\"loops-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"loops-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"16\" y=\"14\" width=\"336\" height=\"242\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"184\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">for (var i …)</text><rect x=\"36\" y=\"62\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"96.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">callback</text><path d=\"M156 79 L232 145\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#loops-ah-amber)\"></path><rect x=\"36\" y=\"116\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"96.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">callback</text><path d=\"M156 133 L232 145\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#loops-ah-amber)\"></path><rect x=\"36\" y=\"170\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"96.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">callback</text><path d=\"M156 187 L232 145\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#loops-ah-amber)\"></path><rect x=\"236\" y=\"122\" width=\"96\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"284.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">i = 3</text><text x=\"284\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma variável</text><rect x=\"368\" y=\"14\" width=\"336\" height=\"242\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"536\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">for (let i …)</text><rect x=\"388\" y=\"62\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"448.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">callback</text><path d=\"M508 79 L580 79\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#loops-ah-phosphor)\"></path><rect x=\"584\" y=\"62\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"632.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">i = 0</text><rect x=\"388\" y=\"116\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"448.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">callback</text><path d=\"M508 133 L580 133\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#loops-ah-phosphor)\"></path><rect x=\"584\" y=\"116\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"632.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">i = 1</text><rect x=\"388\" y=\"170\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"448.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">callback</text><path d=\"M508 187 L580 187\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#loops-ah-phosphor)\"></path><rect x=\"584\" y=\"170\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"632.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">i = 2</text><text x=\"536\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma variável por volta</text></svg>", "caption": "Um callback guarda a variável, não o valor que ela tinha quando o callback foi criado.", "same": ["callback"]}
```

Com `var`, existe **um `i` para o laço inteiro**, porque o `var` pertence à função, ou aqui ao
arquivo, e não ao bloco do laço. Cada arrow function lembra a variável `i`, não o número que ela
tinha quando a arrow foi escrita. Quando as três rodam, o laço já levou `i` a 3, o valor que tornou
`i < 3` falso, e as três leem isso.

Com `let`, **cada volta do laço ganha o seu próprio `i`**, um vínculo novo inicializado com o valor
em que a volta anterior terminou. Cada arrow lembra uma variável diferente, e cada variável ainda
guarda o número que tinha na sua volta.

Isso é regra da linguagem, não um truque do `setTimeout`. **Uma função guarda as variáveis que
enxerga, não cópias dos valores delas**, e a aula 6 dá a isso um nome, closure, e o põe no centro
da aula. O mesmo bug aparece sempre que um laço cria funções para depois: handlers de evento
ligados num laço (aula 12), requisições cujos resultados chegam depois (aula 14).

## O conserto, antes e agora

O conserto hoje é uma palavra: `let`. Código escrito antes de 2015 usava outros consertos, que você
vai reconhecer se encontrar. O comum envolve o corpo numa função chamada na hora com `i`, o que cria
uma variável nova por volta à mão:

```javascript
for (var i = 0; i < 3; i++) {
  (function (j) {
    setTimeout(() => console.log("old fix", j), 0);
  })(i);
}
```

```
ana@dev:~/js$ node loop-iife.js
old fix 0
old fix 1
old fix 2
```

**Se você encontrar esse formato num código, ele é o conserto antigo deste bug**, e trocar `var` por
`let` deixa você apagá-lo.
