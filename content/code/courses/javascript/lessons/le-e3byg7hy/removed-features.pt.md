---
title: Sintaxe que o modo estrito recusa
version: 1
---

Alguns recursos antigos tornam o código difícil de ler, difícil de otimizar, ou fácil de errar. **No
modo estrito eles são erros de sintaxe**, então um arquivo que usa um nem começa:

```javascript
"use strict";
const book = { title: "Iracema" };
with (book) {
  console.log(title);
}
```

```javascript
"use strict";
const shelf = 010;
```

```javascript
"use strict";
function lend(book, book) {}
```

```
ana@dev:~/js$ node removed-with.js 2>&1 | grep SyntaxError
SyntaxError: Strict mode code may not include a with statement
ana@dev:~/js$ node removed-octal.js 2>&1 | grep SyntaxError
SyntaxError: Octal literals are not allowed in strict mode.
ana@dev:~/js$ node removed-params.js 2>&1 | grep SyntaxError
SyntaxError: Duplicate parameter name not allowed in this context
```

- **`with (obj) { … }`** fazia toda propriedade de `obj` parecer uma variável dentro do bloco, então ler
  `title` podia significar `book.title` ou um `title` de fora, dependendo do objeto em tempo de
  execução. Ninguém conseguia saber lendo o código, e é por isso que ele saiu. A desestruturação
  (aula 4) faz a parte útil com segurança;
- **`010`** significava oito no modo não estrito, uma notação octal antiga que surpreende todo mundo
  que escreve um CEP ou um horário com zero na frente. O modo estrito a recusa; quando você quiser
  octal, escreva `0o10`;
- **dois parâmetros com o mesmo nome** deixavam o segundo esconder o primeiro em silêncio.

## Duas mudanças mais discretas

```javascript
function sloppy(copies) {
  arguments[0] = 99;
  return copies;
}
function strict(copies) {
  "use strict";
  arguments[0] = 99;
  return copies;
}
console.log(sloppy(1), strict(1));

eval("var leaked = 'from sloppy eval'");
console.log(typeof leaked);
(function () {
  "use strict";
  eval("var kept = 'from strict eval'");
  console.log(typeof kept);
})();
```

```
ana@dev:~/js$ node arguments.js
99 1
string
undefined
```

No modo não estrito, `arguments[0]` e o parâmetro `copies` estão **ligados**: mudar um mudou o outro,
e a função não estrita devolveu 99. No modo estrito eles são cópias independentes. E um `eval` não
estrito conseguia declarar variáveis no código em volta, como mostra `leaked`; um `eval` estrito guarda
as declarações para si. As duas mudanças fazem as variáveis de uma função significarem o que parecem
significar, e nenhuma é algo de que depender em código novo: parâmetros rest (aula 4) substituem o
`arguments`, e o `eval` não tem lugar em programas comuns.
