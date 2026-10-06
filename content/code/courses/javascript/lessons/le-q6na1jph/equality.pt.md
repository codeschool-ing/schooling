---
title: Dois sinais de igual ou três
version: 1
---

O JavaScript tem dois operadores de igualdade. **`===` é estrito**: dois valores só são iguais se
forem do mesmo tipo e do mesmo valor. **`==` é frouxo**: se os tipos diferem, ele converte um ou
os dois antes, com regras parecidas com as da seção de coerção, e depois compara.

```javascript
console.log(0 == "", 0 == "0", "" == "0");
console.log(0 === "", 0 === "0", "" === "0");
console.log(null == undefined, null === undefined);
console.log(null == 0, null >= 0);
console.log(1 == true, 2 == true);
console.log([1] == 1, [1] === 1);
```

```
ana@dev:~/js$ node equality.js
true true false
false false false
true false
false true
true false
true false
```

## O que o `==` erra

A primeira linha é o argumento contra ele. `0 == ""` é verdadeiro, `0 == "0"` é verdadeiro, e
**`"" == "0"` é falso**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três valores ligados pela igualdade frouxa. A string vazia é igual a 0, e 0 é igual à string zero, mas a string vazia não é igual à string zero.\"><path d=\"M360 58 L190 182\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></path><path d=\"M360 58 L530 182\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></path><path d=\"M210 200 L510 200\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"5 3\"></path><rect x=\"310\" y=\"22\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">0</text><rect x=\"90\" y=\"182\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">&quot;&quot;</text><rect x=\"510\" y=\"182\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">&quot;0&quot;</text><text x=\"205\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">&quot;&quot; == 0</text><text x=\"205\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">true</text><text x=\"515\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0 == &quot;0&quot;</text><text x=\"515\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">true</text><text x=\"360\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">&quot;&quot; == &quot;0&quot;</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">false</text></svg>", "caption": "A igualdade frouxa não é transitiva: duas comparações verdadeiras não tornam a terceira verdadeira."}
```

Uma relação em que A é igual a B e B é igual a C, mas A não é igual a C, é uma com a qual ninguém
consegue raciocinar. O resto da saída acrescenta mais. `null == 0` é falso enquanto `null >= 0` é
verdadeiro, porque `>=` converte `null` em número e `==` tem uma regra especial para ele. E
`1 == true` é verdadeiro enquanto `2 == true` é falso, porque `true` vira `1`.

**Escreva `===` e `!==`, sempre.** Com três sinais a segunda linha saiu toda `false`, e os tipos
decidem antes de qualquer outra coisa.

**A exceção que as pessoas fazem de propósito é `value == null`**, que é verdadeiro para `null` e
para `undefined` e para nada mais, como mostra a terceira linha. É um jeito curto de dizer "sem
valor", e muitos guias de estilo permitem exatamente esse uso. `value === null || value ===
undefined` diz o mesmo com mais palavras.

## `NaN` não é igual a si mesmo

```javascript
const parsed = Number("forty");
console.log(parsed);
console.log(parsed === NaN, parsed == NaN);
console.log(Number.isNaN(parsed), Object.is(parsed, NaN));
console.log(0 === -0, Object.is(0, -0));
```

```
ana@dev:~/js$ node nan.js
NaN
false false
true true
true false
```

**`NaN` é o único valor que não é igual a nada, nem a si mesmo**, então `parsed === NaN` nunca pode
ser verdadeiro. `Number.isNaN` é o teste a usar. `Object.is` é uma terceira comparação que trata
`NaN` como igual a `NaN` e, mostra a última linha, distingue `0` de `-0`, o que `===` não faz; você
raramente vai precisar dela.

## Objetos são comparados pela identidade

```javascript
const a = { title: "Iracema" };
const b = { title: "Iracema" };
const c = a;
console.log(a === b, a == b, a === c);
console.log(a.title === b.title);
```

```
ana@dev:~/js$ node objects-equal.js
false false true
true
```

`a` e `b` parecem iguais e são dois objetos diferentes, então **`===` responde `false`: ele
pergunta se os dois lados são o mesmo objeto**, não se guardam as mesmas coisas. `c` é outro nome
para `a`, e isso dá `true`. Para comparar conteúdo, compare as propriedades que importam. A aula 4
trata do que significa dois nomes dividirem um objeto.
