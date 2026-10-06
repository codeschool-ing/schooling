---
title: extends e super
version: 1
---

**`extends` faz a cadeia de protótipos de uma classe passar pela de outra.** Um `EBook` é um `Book`
com tamanho de arquivo, e deve reaproveitar o que `Book` já faz:

```javascript
class Book {
  constructor(title, year) {
    this.title = title;
    this.year = year;
  }
  describe() {
    return `${this.title} (${this.year})`;
  }
}

class EBook extends Book {
  constructor(title, year, sizeMb) {
    super(title, year);
    this.sizeMb = sizeMb;
  }
  describe() {
    return `${super.describe()}, ${this.sizeMb} MB`;
  }
}

const e = new EBook("Macunaíma", 1928, 2.4);
console.log(e.describe());
console.log(e instanceof EBook, e instanceof Book, e instanceof Object);
console.log(Object.getPrototypeOf(EBook.prototype) === Book.prototype);
console.log(e);
```

```
ana@dev:~/js$ node inherit.js
Macunaíma (1928), 2.4 MB
true true true
true
EBook { title: 'Macunaíma', year: 1928, sizeMb: 2.4 }
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A cadeia de protótipos de uma instância de EBook. A instância guarda title, year e sizeMb. O protótipo dela é EBook.prototype, que guarda describe. O protótipo deste é Book.prototype, que guarda outro describe. Depois Object.prototype, com hasOwnProperty e toString. Depois null, onde a busca para.\"><defs><marker id=\"proto-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"proto-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"12\" y=\"50\" width=\"138\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"81.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">e</text><text x=\"26\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title</text><text x=\"26\" y=\"116.275\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">year</text><text x=\"26\" y=\"132.55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sizeMb</text><path d=\"M150 110 L172 110\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#proto-ah-amber)\"></path><rect x=\"174\" y=\"50\" width=\"138\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"243.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">EBook.prototype</text><text x=\"188\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">describe</text><path d=\"M312 110 L334 110\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#proto-ah-amber)\"></path><rect x=\"336\" y=\"50\" width=\"138\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book.prototype</text><text x=\"350\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">describe</text><path d=\"M474 110 L496 110\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#proto-ah-amber)\"></path><rect x=\"498\" y=\"50\" width=\"138\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"567.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Object.prototype</text><text x=\"512\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">hasOwnProperty</text><text x=\"512\" y=\"116.275\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">toString</text><rect x=\"660\" y=\"92\" width=\"50\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"685.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">null</text><path d=\"M636 110 L658 110\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#proto-ah-amber)\"></path><text x=\"12\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e.describe() acha este primeiro</text><path d=\"M120 34 L220 52\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#proto-ah-paper-dim)\"></path><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cada seta é o [[Prototype]], lido com Object.getPrototypeOf</text></svg>", "caption": "Uma propriedade é procurada no objeto, depois ao longo dos protótipos, e a primeira encontrada ganha."}
```

A figura é a herança inteira. O protótipo de `EBook.prototype` é `Book.prototype`, então uma busca
num e-book que falha em `EBook.prototype` continua nos métodos de `Book`, e depois em
`Object.prototype`. **O `instanceof` percorre a mesma cadeia**, e é por isso que `e` é um `EBook`, um
`Book` e um `Object` ao mesmo tempo.

## `super`

`super` quer dizer "a classe que eu estendo", em dois lugares:

- **`super(title, year)` no construtor roda o construtor de `Book`** no objeto em construção, o que
  define `title` e `year`. O construtor de uma classe derivada precisa chamá-lo, e precisa chamá-lo
  antes de tocar no `this`;
- **`super.describe()` num método chama a versão de `describe` de `Book`**, então `EBook` acrescenta
  a ela em vez de reescrevê-la. Definir `describe` em `EBook` se chama **sobrescrever**: a busca acha
  `EBook.prototype.describe` primeiro e para ali, o que é sombreamento de novo.

```javascript
class Book {
  constructor(title) {
    this.title = title;
  }
}
class EBook extends Book {
  constructor(title, sizeMb) {
    this.sizeMb = sizeMb;
    super(title);
  }
}
new EBook("Macunaíma", 2.4);
```

```
ana@dev:~/js$ node no-super.js 2>&1 | grep Error
ReferenceError: Must call super constructor in derived class before accessing 'this' or returning from derived constructor
```

A mensagem é longa e diz exatamente o que aconteceu: **o `this` foi usado antes de o `super`
rodar**. Até o construtor do pai rodar, o objeto ainda não existe, então não há `this` em que pôr
`sizeMb`.

## Até que profundidade ir

Um nível, como aqui, é comum e fácil de acompanhar. **Hierarquias fundas não são**: um método achado
cinco protótipos acima, sobrescrito em três deles, é difícil de entender e mais difícil de mudar. A
maior parte do JavaScript moderno mantém a herança rasa e compõe comportamento a partir de objetos e
funções menores; frameworks que usam classes costumam pedir que você estenda uma das deles, um nível,
e não mais.
