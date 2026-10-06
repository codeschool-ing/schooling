---
title: O valor de this
version: 1
---

Toda chamada normal de função tem uma entrada extra escondida chamada `this`. **O valor dela é
decidido por como a função é chamada, não por onde é escrita**, o que é o contrário da regra de
todo outro nome desta aula. Quatro regras cobrem o assunto:

```javascript
"use strict";

const book = {
  title: "Iracema",
  describe() {
    return this;
  },
};

function plain() {
  return this;
}

function Shelf(name) {
  this.name = name;
}

const arrow = () => this;

console.log(book.describe() === book);
console.log(plain());
console.log(new Shelf("Romance"));
console.log(arrow());
```

```
ana@dev:~/js$ node this-rules.js
true
undefined
Shelf { name: 'Romance' }
{}
```

| como a função é chamada | `this` dentro dela | a linha |
|---|---|---|
| como método: `book.describe()` | **o objeto antes do ponto** | `true` |
| sozinha: `plain()` | **`undefined`** no modo estrito | `undefined` |
| com `new`: `new Shelf("Romance")` | um objeto novinho, que o `new` devolve | `Shelf { name: 'Romance' }` |
| uma arrow function, chamada de qualquer jeito | **o `this` que havia onde a arrow foi escrita** | `{}` |

O arquivo começa com `"use strict"`, que é o assunto da aula 20; classes e módulos são estritos
automaticamente, então essa é a configuração em que roda a maior parte do código moderno. Sem ele,
uma chamada sozinha dá o objeto global em vez de `undefined`, o que esconde o erro de que trata a
próxima seção.

## O objeto antes do ponto

A primeira regra é a que vale guardar. **`this` é o objeto de onde o método foi lido no momento da
chamada**: em `book.describe()`, a chamada acontece em `book`, então `this` é `book`. Escreva
`shelf.describe = book.describe` e chame `shelf.describe()`, e a mesma função recebe `shelf`. A
função não pertence a objeto nenhum; a chamada decide.

## Arrows não têm o seu

**Uma arrow function não tem `this` próprio.** Ela usa o `this` do código em volta, achado do mesmo
jeito que qualquer outro nome, pela cadeia de escopos. Aqui a arrow foi escrita no topo de um
arquivo do Node, onde `this` é o objeto de exports do módulo, um `{}` vazio (aula 9). Isso torna as
arrows a escolha errada para métodos e a escolha certa para callbacks escritos dentro de métodos, e
a próxima seção mostra as duas coisas.
