---
title: Funções construtoras e new
version: 1
---

Antes da sintaxe de classe, **objetos de um tipo eram feitos por uma função chamada com `new`**. Você
vai ler isso em código mais antigo e em bibliotecas, e é exatamente o que uma classe faz por baixo:

```javascript
"use strict";

function Book(title, year) {
  this.title = title;
  this.year = year;
}

Book.prototype.describe = function () {
  return `${this.title} (${this.year})`;
};

const b = new Book("Iracema", 1865);
console.log(b.describe());
console.log(Object.getPrototypeOf(b) === Book.prototype, b instanceof Book);
console.log(Object.keys(b));

const oops = Book("Dom Casmurro", 1899);
```

```
ana@dev:~/js$ node constructor.js 2>&1 | head -n 9
Iracema (1865)
true true
[ 'title', 'year' ]
/home/ana/js/constructor.js:4
  this.title = title;
             ^

TypeError: Cannot set properties of undefined (setting 'title')
    at Book (/home/ana/js/constructor.js:4:14)
```

## O que o `new` faz

`new Book("Iracema", 1865)` faz quatro coisas, em ordem:

1. cria um objeto vazio;
2. **define o protótipo desse objeto como `Book.prototype`**;
3. chama `Book` com `this` apontando para o objeto novo, então `this.title = title` o preenche;
4. devolve o objeto, a menos que a função tenha devolvido outro objeto próprio.

## Duas coisas diferentes chamadas protótipo

**Toda função normal tem uma propriedade chamada `prototype`**: um objeto comum, criado junto com a
função, que fica lá sem uso até a função ser chamada com `new`. O passo 2 é onde ela importa: vira o
protótipo de todo objeto que `new Book` cria. Então:

- `Book.prototype` **não** é o protótipo de `Book`. É o objeto que vai ser o protótipo das instâncias
  de Book;
- `Object.getPrototypeOf(b) === Book.prototype` é `true`, que é o que o `instanceof` confere:
  `Book.prototype` está em algum ponto da cadeia de `b`?
- pôr `describe` em `Book.prototype` significa que **todo livro compartilha um `describe`**, enquanto
  `title` e `year`, definidos no passo 3, são de cada livro. `Object.keys(b)` lista só esses dois.

## Esquecer o `new`

A última linha chamou `Book` sem `new`. **Os passos 1, 2 e 4 nunca aconteceram**, então `this` foi o
que uma chamada sozinha dá, `undefined` no modo estrito, e `this.title = title` lançou erro. Sem modo
estrito teria criado variáveis globais chamadas `title` e `year`, o que é pior. Esse erro é um dos
motivos de a sintaxe de classe existir: a próxima seção mostra uma classe se recusando a ser chamada
assim.
