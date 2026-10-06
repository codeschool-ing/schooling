---
title: call e apply: escolhendo o this de uma chamada
version: 1
---

A aula 6 mostrou que o `this` é decidido por como uma função é chamada. **`call` e `apply` são o
jeito de dizer isso explicitamente**: eles rodam a função uma vez, agora, com o `this` que você
passa como primeiro argumento.

```javascript
"use strict";

function describe(open, close) {
  return `${open}${this.title}, ${this.year}${close}`;
}

const iracema = { title: "Iracema", year: 1865 };
const casmurro = { title: "Dom Casmurro", year: 1899 };

console.log(describe.call(iracema, "[", "]"));
console.log(describe.call(casmurro, "(", ")"));
console.log(describe.apply(casmurro, ["<", ">"]));
console.log(describe("{", "}"));
```

```
ana@dev:~/js$ node call.js 2>&1 | head -n 9
[Iracema, 1865]
(Dom Casmurro, 1899)
<Dom Casmurro, 1899>
/home/ana/js/call.js:4
  return `${open}${this.title}, ${this.year}${close}`;
                        ^

TypeError: Cannot read properties of undefined (reading 'title')
    at describe (/home/ana/js/call.js:4:25)
```

`describe` não é método de nenhum dos livros. **`describe.call(iracema, "[", "]")` a rodou com `this`
valendo `iracema`**, e os argumentos restantes foram para os parâmetros da própria função. Chamada do
mesmo jeito com `casmurro`, a mesma função descreveu o outro livro. A última linha a chamou sozinha,
sem `this` nenhum, e ela lançou o erro que a aula 6 ensinou você a reconhecer.

## A única diferença

`apply` faz exatamente o que `call` faz, e **recebe os argumentos da função num único array** em vez
de um a um. `describe.apply(casmurro, ["<", ">"])` é `describe.call(casmurro, "<", ">")`. Um truque
em inglês para lembrar: **a**pply recebe um **a**rray, **c**all recebe **c**ommas, vírgulas.

## Quando você vai escrevê-los

Menos do que vai lê-los. Uma função escrita para usar o `this` de qualquer objeto que lhe derem é
um estilo mais antigo; hoje o objeto costumaria ser um parâmetro, `describe(book, "[", "]")`, o que
dispensa `call`. Onde o `call` ainda é a ferramenta certa é o **empréstimo**: rodar uma função que
pertence a um tipo de objeto em outro tipo, que é a seção de empréstimo desta aula. E o `apply`
sobrevive em código anterior ao spread, que é o assunto da próxima seção.
