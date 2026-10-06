---
title: Como um método perde o seu objeto
version: 1
---

A regra "o objeto antes do ponto" tem uma consequência que pega todo mundo: **tire o método do seu
ponto, e ele não tem mais objeto.**

```javascript
"use strict";

const shelf = {
  prefix: "Shelf A",
  label(title) {
    return `${this.prefix}: ${title}`;
  },
};

console.log(shelf.label("Iracema"));

const label = shelf.label;
console.log(label("Iracema"));
```

```
ana@dev:~/js$ node losing-this.js 2>&1 | head -n 7
Shelf A: Iracema
/home/ana/js/losing-this.js:6
    return `${this.prefix}: ${title}`;
                   ^

TypeError: Cannot read properties of undefined (reading 'prefix')
    at label (/home/ana/js/losing-this.js:6:20)
```

`const label = shelf.label` copiou uma referência à função, e `label("Iracema")` a chamou sozinha,
sem ponto. Pela segunda regra, `this` era `undefined`, e ler `this.prefix` lançou erro. **`Cannot
read properties of undefined (reading 'prefix')` dentro de um método quase sempre significa isso**:
o método foi chamado sem o seu objeto.

## Onde acontece sem atribuição

Ninguém escreve `const label = shelf.label` de propósito. A mesma coisa acontece toda vez que um
método é **passado como callback**:

```javascript
"use strict";

const shelf = {
  prefix: "Shelf A",
  label(title) {
    return `${this.prefix}: ${title}`;
  },
};

const titles = ["Iracema", "Dom Casmurro"];

console.log(titles.map((t) => shelf.label(t)));
console.log(titles.map(shelf.label));
```

```
ana@dev:~/js$ node callbacks-this.js 2>&1 | head -n 7
[ 'Shelf A: Iracema', 'Shelf A: Dom Casmurro' ]
/home/ana/js/callbacks-this.js:6
    return `${this.prefix}: ${title}`;
                   ^

TypeError: Cannot read properties of undefined (reading 'prefix')
    at label (/home/ana/js/callbacks-this.js:6:20)
```

`titles.map(shelf.label)` entrega a função ao `map`, e o `map` a chama sem objeto na frente. A
primeira linha, que embrulha a chamada numa arrow, funciona, porque dentro da arrow a chamada está
escrita `shelf.label(t)`, com o seu ponto. Passar um método para `setTimeout`, para
`addEventListener` (aula 12) ou para `then` (aula 14) perde o `this` exatamente do mesmo jeito.

Três consertos, todos comuns:

- **embrulhar numa arrow no ponto em que você passa**, como acima. O mais simples e o mais legível;
- **fazer bind**, que cria uma cópia da função com o `this` fixo. Essa é a aula 7;
- **definir o método como um campo de classe arrow function**, para ele nunca ter tido `this`
  próprio. Essa é a aula 8.

## O callback dentro de um método

O problema contrário: um método que passa um callback próprio, e quer o `this` dentro dele.

```javascript
const shelf = {
  name: "Classics",
  titles: ["Iracema", "Dom Casmurro"],
  withFunction() {
    return this.titles.map(function (t) {
      return `${this?.name}: ${t}`;
    });
  },
  withArrow() {
    return this.titles.map((t) => `${this.name}: ${t}`);
  },
};

console.log(shelf.withFunction());
console.log(shelf.withArrow());
```

```
ana@dev:~/js$ node arrow-inside.js
[ 'undefined: Iracema', 'undefined: Dom Casmurro' ]
[ 'Classics: Iracema', 'Classics: Dom Casmurro' ]
```

Em `withFunction`, a `function (t)` de dentro é chamada pelo `map` sozinha, então recebe o seu
próprio `this`. Este arquivo não é estrito, então esse `this` é o objeto global, que não tem `name`,
e toda linha diz `undefined`. **Em `withArrow`, a arrow não tem `this` próprio e usa o do método**,
que é `shelf`. Este é o trabalho para o qual as arrow functions foram acrescentadas à linguagem.
