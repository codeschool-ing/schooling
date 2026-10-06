---
title: Dois nomes, um objeto
version: 1
---

**Uma variável não contém um objeto. Ela guarda uma referência a ele**, uma seta apontando para onde
o objeto mora. Atribuir um objeto a um segundo nome copia a seta, não o objeto:

```javascript
const original = { title: "Iracema", copies: 3 };
const alias = original;
alias.copies = 0;
console.log(original.copies);

function lend(book) {
  book.copies = book.copies - 1;
}
const other = { title: "Dom Casmurro", copies: 2 };
lend(other);
console.log(other.copies);
```

```
ana@dev:~/js$ node references.js
0
1
```

`alias.copies = 0` mudou o único objeto para o qual os dois nomes apontam, então `original.copies`
também é 0. O mesmo acontece numa chamada de função: **`lend` recebeu uma referência e mudou por
ela o objeto de quem chamou.** Um primitivo não se comporta assim, porque um primitivo não pode ser
mudado de jeito nenhum (aula 2): uma função que recebe um número e soma a ele muda a própria cópia
e nada mais.

Este é o fato mais útil da aula, porque explica uma família de bugs que parecem não ter relação.
Uma lista que muda "sozinha" depois de ser passada a uma função auxiliar. Um objeto de
configurações padrão que aos poucos se enche das escolhas de um usuário, porque todos os usuários
o compartilham. Um teste que passa sozinho e falha depois de outro teste, porque os dois mudaram o
mesmo dado de teste.

## Copiar um objeto

Para ter um segundo objeto, você faz um. A sintaxe de spread, `{ ...book }`, que a seção de spread
cobre direito, constrói um objeto novo com as mesmas propriedades:

```javascript
const book = { title: "Iracema", author: { name: "José de Alencar" } };

const shallow = { ...book };
shallow.title = "Ubirajara";
shallow.author.name = "J. de Alencar";
console.log(book.title, "/", book.author.name);

const deep = structuredClone(book);
deep.author.name = "Alencar";
console.log(book.author.name, "/", deep.author.name);
```

```
ana@dev:~/js$ node copies.js
Iracema / J. de Alencar
J. de Alencar / Alencar
```

`shallow.title = "Ubirajara"` deixou `book.title` em paz: os dois objetos externos são separados.
**Mas `shallow.author.name` mudou `book.author.name` também**, porque a cópia é rasa. Ela copiou o
valor de cada propriedade, e o valor de `author` é uma referência, então os dois objetos apontam
para o mesmo autor:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois nomes, book e shallow, apontam cada um para o seu objeto externo, feito espalhando book num novo. Os dois objetos externos têm uma propriedade author, e os dois apontam para o mesmo objeto author interno, e é por isso que mudar shallow.author.name mudou o de book também. Um terceiro nome, deep, feito com structuredClone, aponta para um objeto externo com o seu próprio author.\"><defs><marker id=\"shallow-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"shallow-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"shallow-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">book</text><rect x=\"20\" y=\"120\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shallow</text><rect x=\"20\" y=\"200\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">deep</text><path d=\"M110 55 L170 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#shallow-ah-paper-dim)\"></path><path d=\"M110 135 L170 135\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#shallow-ah-paper-dim)\"></path><path d=\"M110 215 L170 215\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#shallow-ah-paper-dim)\"></path><rect x=\"170\" y=\"30\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"182\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title: …</text><text x=\"182\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">author:</text><rect x=\"170\" y=\"110\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"182\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title: …</text><text x=\"182\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">author:</text><rect x=\"170\" y=\"190\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"182\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title: …</text><text x=\"182\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">author:</text><rect x=\"470\" y=\"60\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">{ name: &quot;J. de Alencar&quot; }</text><rect x=\"470\" y=\"190\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">{ name: &quot;Alencar&quot; }</text><path d=\"M370 64 L466 78\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#shallow-ah-amber)\"></path><path d=\"M370 144 L466 90\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#shallow-ah-amber)\"></path><path d=\"M370 224 L466 214\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#shallow-ah-phosphor)\"></path><text x=\"580\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">compartilhado por book e shallow</text><text x=\"580\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">deep tem o seu</text></svg>", "caption": "Um spread copia um nível. Os objetos de dentro são compartilhados; structuredClone copia até o fim."}
```

`structuredClone` copia **até o fim**, então `deep.author` é um terceiro objeto, independente. Ele
vem embutido no Node e em todo navegador atual. Copia dados, ou seja, objetos simples, arrays,
datas, maps e sets; recusa funções e alguns outros valores, e o erro diz qual.

Que cópia você precisa depende do que vai mudar. **Se vai mudar só propriedades de nível de cima,
um spread basta. Se vai mudar algo aninhado, clone**, ou construa o objeto aninhado novo à mão.
