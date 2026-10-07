---
title: O spread substituiu quase todo o apply
version: 1
---

Antes de 2015, **o uso mais comum do `apply` não tinha nada a ver com `this`**. Era o único jeito de
chamar uma função com os itens de um array como argumentos separados. O spread da aula 4 faz a mesma
coisa, e lê melhor:

```javascript
const years = [1899, 1865, 1928];
console.log(Math.max.apply(null, years));
console.log(Math.max(...years));

const many = Array.from({ length: 1_000_000 }, (_, i) => i);
console.log(many.reduce((a, b) => Math.max(a, b)));
console.log(Math.max(...many));
```

```
ana@dev:~/js$ node spread-instead.js 2>&1 | head -n 8
1928
1928
999999
/home/ana/js/spread-instead.js:7
console.log(Math.max(...many));
                 ^

RangeError: Maximum call stack size exceeded
```

As duas primeiras linhas são a mesma chamada. `Math.max` ignora o `this`, e é por isso que a versão
antiga passava `null` para ele. **Se você encontrar `fn.apply(null, list)`, leia como `fn(...list)`**,
e em geral dá para reescrever assim.

## O limite que os dois dividem

A última linha lançou `RangeError: Maximum call stack size exceeded`. **Todo argumento de uma chamada
ocupa espaço na pilha de chamadas**, e um milhão de argumentos é mais do que o V8 permite. O spread e
o `apply` transformam um array em argumentos, então os dois falham do mesmo jeito. Onde fica o limite
depende do motor e de quanto da pilha já está em uso, e é exatamente por isso que você não quer
depender dele.

**Para um array de tamanho desconhecido, não o espalhe numa chamada.** O `reduce` percorre o array
com uma chamada por item e nenhuma lista de argumentos crescendo, e deu `999999` sem problema. A
aula 13 explica o que é a pilha de chamadas e por que ela tem tamanho.
