---
title: Escopo de bloco e escopo de função
version: 1
---

**Escopo é a região de um programa onde um nome pode ser usado.** A aula 1 mostrou que um `let` ou
um `const` pertence ao bloco em que é declarado, o par de chaves mais próximo. Isso é **escopo de
bloco**. A palavra-chave mais antiga do JavaScript, `var`, ignora blocos e pertence à função
inteira em volta dela. Isso é **escopo de função**, e é o primeiro dos três jeitos em que o `var`
se comporta diferente:

```javascript
function shelve() {
  if (true) {
    var label = "fiction";
    let shelf = 3;
  }
  console.log(label);
  console.log(typeof shelf);
}

shelve();
console.log(typeof label);
```

```
ana@dev:~/js$ node function-scope.js
fiction
undefined
undefined
```

Três linhas, três fatos:

- `label`, um `var` declarado dentro do `if`, **continua lá depois que o `if` fecha**. Ele pertence
  a `shelve`, então qualquer linha de `shelve` consegue lê-lo;
- `shelf`, um `let` declarado no mesmo lugar, não existe fora das chaves, e `typeof` responde
  `undefined` em vez de falhar, como faz com qualquer nome que nunca foi declarado;
- fora de `shelve`, `label` também não existe. **Uma função é uma fronteira para todo tipo de
  declaração**; só os blocos são diferentes.

## Por que isso importa

Um nome com escopo de bloco não é visto fora do bloco, então **dois blocos podem usar o mesmo nome
sem se tocar**: um `i` num laço e um `i` no seguinte são duas variáveis. Com `var` elas são uma
variável para a função inteira, e um laço que a muda a muda também para o código em volta do laço.
A maior parte desta aula são as consequências dessa diferença.

## Declarar o mesmo nome duas vezes

```javascript
console.log("first line");

var copies = 1;
var copies = 2;

let title = "Iracema";
let title = "Dom Casmurro";
```

```
ana@dev:~/js$ node redeclare.js 2>&1 | head -n 5
/home/ana/js/redeclare.js:7
let title = "Dom Casmurro";
    ^

SyntaxError: Identifier 'title' has already been declared
```

`var copies` duas vezes é permitido, e o segundo só atribui. **`let title` duas vezes é um
`SyntaxError`**, o que mostra mais uma coisa que vale saber: `first line` nunca foi impresso. Um
erro de sintaxe é encontrado enquanto o motor lê o arquivo, antes de qualquer parte rodar, então o
programa nem começa. Esse é o tipo de falha rápida e barulhenta, e é por isso que o `let` recusar
uma redeclaração é um recurso.
