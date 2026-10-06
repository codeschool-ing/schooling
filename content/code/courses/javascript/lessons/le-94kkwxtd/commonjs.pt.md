---
title: CommonJS: require e module.exports
version: 1
---

No CommonJS, um arquivo traz outro com **`require`**, uma chamada de função que devolve o que o outro
arquivo pôs em **`module.exports`**. É o sistema original do Node, o padrão para um arquivo `.js`
quando nenhum `package.json` diz o contrário, e o formato da maior parte do código e dos pacotes Node
mais antigos:

```javascript
console.log("books.js is running");

const books = [
  { title: "Iracema", year: 1865 },
  { title: "Dom Casmurro", year: 1899 },
];

function byYear(list) {
  return list.toSorted((a, b) => a.year - b.year);
}

module.exports = { books, byYear };
```

```javascript
const { books, byYear } = require("./books");
const again = require("./books.js");

console.log(byYear(books).map((b) => b.title));
console.log(again.books === books);
console.log(this === module.exports, arguments.length);
console.log(__filename);
```

```
ana@dev:~/js$ node cjs/main.js
books.js is running
[ 'Iracema', 'Dom Casmurro' ]
true
true 5
/home/ana/js/cjs/main.js
```

- `module.exports = { books, byYear }` é toda a superfície pública, um objeto comum, e
  `require("./books")` o devolveu. **A extensão é opcional** no CommonJS, que procura `books`,
  `books.js`, `books.json` e mais alguns;
- o segundo `require` devolveu **o mesmo objeto**, e `books.js is running` saiu uma vez: como um ES
  module, um arquivo CommonJS roda uma vez e fica em cache;
- **`require` é uma função comum, executada quando a linha é alcançada.** Pode ficar dentro de um
  `if` ou de uma função, e o argumento pode ser calculado. Essa flexibilidade é o que torna o
  CommonJS impossível de conferir antes de rodar, ao contrário do `import`.

## De onde vem o escopo do arquivo

As duas últimas linhas respondem duas perguntas abertas desde a aula 3 e a aula 6. O Node roda todo
arquivo CommonJS **dentro de uma função que ele embrulha em volta do código**, e ele mostra as duas metades que põe em
volta do seu arquivo:

```
ana@dev:~/js$ node -p 'require("node:module").wrapper'
[
  '(function (exports, require, module, __filename, __dirname) { ',
  '\n});'
]
```

É por isso que `arguments.length` no topo de um arquivo imprimiu `5`, que `require`, `module`,
`__filename` e `__dirname` existem sem serem declarados, e que **um `var` de nível de cima ficou no
arquivo na aula 3: ele é uma variável local dessa função.** E o Node chama a função com o `this`
valendo `module.exports`, e é por isso que o `this` deu `true` contra ele aqui, e o `{}` vazio que a
arrow no topo de um arquivo imprimiu na aula 6.
