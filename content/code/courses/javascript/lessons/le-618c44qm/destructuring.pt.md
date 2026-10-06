---
title: Desestruturação
version: 1
---

**A desestruturação declara vários nomes de uma vez a partir das partes de um objeto ou de um
array.** O padrão à esquerda do `=` tem a forma do valor à direita, e cada nome do padrão recebe a
parte correspondente:

```javascript
const book = { title: "Dom Casmurro", year: 1899, author: { name: "Machado de Assis" } };

const { title, year } = book;
console.log(title, year);

const { title: name, pages = 0, isbn } = book;
console.log(name, pages, isbn);

const { author: { name: authorName } } = book;
console.log(authorName);

const [first, , third = "none", ...rest] = ["a", "b", "c", "d", "e"];
console.log(first, third, rest);

let left = "Iracema";
let right = "Ubirajara";
[left, right] = [right, left];
console.log(left, right);

function label({ title, year = "?" }) {
  return `${title} (${year})`;
}
console.log(label(book), label({ title: "Iracema" }));
```

```
ana@dev:~/js$ node destructuring.js
Dom Casmurro 1899
Dom Casmurro 0 undefined
Machado de Assis
a c [ 'd', 'e' ]
Ubirajara Iracema
Dom Casmurro (1899) Iracema (?)
```

## Objetos

- `const { title, year } = book` é atalho para duas linhas, `const title = book.title` e
  `const year = book.year`. **Os nomes batem com os nomes das propriedades**;
- `title: name` renomeia: lê `book.title` para uma variável chamada `name`. `pages = 0` é um
  **padrão**, usado quando a propriedade falta, como faltava `pages`. `isbn` não tinha padrão e
  saiu `undefined`, como toda propriedade que falta;
- padrões se aninham: `{ author: { name: authorName } }` alcança dentro de `book.author`. Se
  `author` faltasse, esta linha lançaria erro, pelo motivo que a última seção desta aula explica.

## Arrays

**Padrões de array batem pela posição, não pelo nome.** `[first, , third = "none", ...rest]` pega o
primeiro item, pula o segundo com uma vaga vazia, dá um padrão ao terceiro e junta o resto.
Desestruturar um array também é o jeito limpo de **trocar duas variáveis**:
`[left, right] = [right, left]` constrói um array de dois itens e o desmonta na outra ordem.

## Em parâmetros

O padrão pode ficar na lista de parâmetros de uma função, que é onde você mais vai vê-lo. **Uma
função que recebe um objeto e o desestrutura se lê como uma função com argumentos nomeados**:
`label({ title, year = "?" })` diz exatamente que propriedades usa, e quem chama sem `year` recebe
o padrão, como mostra `Iracema (?)`. Os componentes de todo framework a que este curso leva recebem
as entradas desse jeito.
