---
title: Objetos: partes com nome
version: 1
---

**Um objeto é uma coleção de propriedades, cada uma um nome com um valor.** O valor pode ser
qualquer coisa, outro objeto inclusive, e quando é uma função a propriedade se chama **método**.
Você escreve um com chaves:

```javascript
const field = "year";
const book = {
  title: "Dom Casmurro",
  author: "Machado de Assis",
  [field]: 1899,
  "page count": 256,
  describe() {
    return `${this.title}, ${this.year}`;
  },
};

console.log(book.title, book["author"], book[field]);
console.log(book["page count"]);
console.log(book.describe());
console.log(book.isbn);

book.isbn = "978-85-359-0277-8";
delete book["page count"];
console.log("isbn" in book, "page count" in book);
console.log(Object.keys(book));
```

```
ana@dev:~/js$ node objects.js
Dom Casmurro Machado de Assis 1899
256
Dom Casmurro, 1899
undefined
true false
[ 'title', 'author', 'year', 'describe', 'isbn' ]
```

## Ler e escrever uma propriedade

**A notação de ponto, `book.title`, é para um nome que você sabe quando escreve o código.** Os
colchetes, `book["author"]`, aceitam qualquer expressão, então são o que se usa quando o nome está
numa variável, como `book[field]`, ou quando não é um identificador válido, como `"page count"` com
o seu espaço. Dentro do literal, `[field]: 1899` é uma **chave computada**: a propriedade recebe o
nome que `field` guarda, que é `year`.

Uma propriedade que não existe é lida como `undefined`, como `book.isbn`. **Nenhum erro**, o que é
cômodo e também é como um erro de digitação no nome de uma propriedade passa despercebido; a
última seção desta aula trata da consequência. Atribuir a uma propriedade a cria, e `delete`
remove uma. `in` pergunta se uma propriedade existe, o que é uma pergunta diferente de saber se o
valor dela é `undefined`.

## Métodos e `this`

`describe` está escrito com a sintaxe curta de método, e dentro dele **`this` é o objeto em que o
método foi chamado**, então `book.describe()` conseguiu ler `this.title`. Esse é o caso simples. A
aula 6 mostra os casos em que `this` não é o que você espera.

## Atalho e listagem

```javascript
const title = "Iracema";
const year = 1865;
const book = { title, year };
console.log(book);
console.log(Object.entries(book));
```

```
ana@dev:~/js$ node shorthand.js
{ title: 'Iracema', year: 1865 }
[ [ 'title', 'Iracema' ], [ 'year', 1865 ] ]
```

Quando uma propriedade tem o mesmo nome da variável que guarda o valor dela, **`{ title, year }` é
atalho para escrever cada nome duas vezes, como em `year: year`**, e você vai ver isso o tempo todo. `Object.keys`,
`Object.values` e `Object.entries` transformam um objeto em arrays dos seus nomes, dos seus valores
ou de pares `[nome, valor]`, que é como você percorre um objeto com as ferramentas de array mais
adiante nesta aula.
