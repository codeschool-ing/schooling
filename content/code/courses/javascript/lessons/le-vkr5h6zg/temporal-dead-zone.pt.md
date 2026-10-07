---
title: A zona morta temporal
version: 2
---

**A zona morta temporal é a parte de um bloco entre a chave de abertura e uma declaração `let` ou
`const`**, onde o nome já existe e todo uso dele lança erro. "Temporal" porque se trata de quando a
linha roda, não de onde ela fica:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma linha do tempo de um bloco. Quando o bloco começa, o nome let title é criado mas não inicializado; dali até a linha da declaração fica a zona morta temporal, onde lê-lo lança um ReferenceError. Da linha da declaração em diante, ele guarda o seu valor.\"><defs><marker id=\"tdz-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M40 140 L700 140\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#tdz-ah-wire)\"></path><rect x=\"40\" y=\"70\" width=\"330\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"205.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">zona morta temporal</text><text x=\"205.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ler title lança ReferenceError</text><rect x=\"390\" y=\"70\" width=\"270\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">inicializado</text><text x=\"525.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">title === &quot;Iracema&quot;</text><text x=\"40\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">{ o bloco começa</text><text x=\"390\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">let title = &quot;Iracema&quot;;</text><text x=\"40\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o nome é criado aqui</text><text x=\"390\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a declaração roda</text></svg>", "caption": "O nome existe desde o começo do bloco, e não pode ser usado até a declaração dele ter rodado."}
```

## Dois erros diferentes

O `tdz-read.js` lê o nome uma linha cedo demais:

```javascript
console.log(title);
let title = "Iracema";
```

```
ana@dev:~/js$ node tdz-read.js 2>&1 | grep Error
ReferenceError: Cannot access 'title' before initialization
ana@dev:~/js$ node not-declared.js 2>&1 | grep Error
ReferenceError: title is not defined
```

Leia as duas mensagens lado a lado, porque elas dizem coisas diferentes. **`Cannot access 'title'
before initialization` significa que o nome existe neste escopo e a linha dele ainda não rodou.**
`title is not defined` significa que não existe nome assim em lugar nenhum onde o motor procurou.
O primeiro é um problema de ordem; o segundo costuma ser um erro de digitação ou um import que
falta.

## O `typeof` não é seguro aqui

`typeof` responde `"undefined"` para um nome que nunca foi declarado, e as pessoas o usam como
sonda segura. **Dentro da zona morta ele lança erro como qualquer outra leitura**:

```javascript
console.log(typeof missing);
console.log(typeof title);
let title = "Iracema";
```

```
ana@dev:~/js$ node tdz.js 2>&1 | head -n 6
undefined
/home/ana/js/tdz.js:2
console.log(typeof title);
        ^

ReferenceError: Cannot access 'title' before initialization
```

## A armadilha: um nome sombreado desde o topo do bloco

```javascript
const year = 1899;

function check() {
  console.log(year);
  const year = 1865;
}

check();
```

```
ana@dev:~/js$ node shadow.js 2>&1 | head -n 5
/home/ana/js/shadow.js:4
  console.log(year);
              ^

ReferenceError: Cannot access 'year' before initialization
```

Existe um `year` fora da função, e `console.log(year)` parece que deveria lê-lo. **O `const year`
da linha 5 é içado para o topo do corpo de `check`**, então desde a chave de abertura o nome de
dentro cobre o de fora, situação chamada de **sombreamento**, e a linha 4 está dentro da zona
morta do de dentro. Com `var` o mesmo programa imprimiria `undefined` e seguiria em frente.

## Por que isso é bom

O `var` te dava `undefined` e deixava um valor errado viajar. **A zona morta transforma o mesmo erro
numa falha na linha que o cometeu**, com uma mensagem que diz o nome da variável. O remédio é o que
a aula 1 já deu: declare os nomes no topo do bloco, antes do código que os usa.
