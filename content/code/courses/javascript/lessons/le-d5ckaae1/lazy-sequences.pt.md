---
title: Sequências preguiçosas
version: 1
---

Como um gerador só roda quando lhe pedem, **ele pode descrever uma sequência que nunca termina**, e só
a parte que alguém de fato pega chega a ser calculada. Isso se chama **preguiça**, e deixa um programa
montar uma linha de passos sem construir cada lista intermediária:

```javascript
let produced = 0;

function* naturals() {
  let n = 1;
  while (true) {
    produced += 1;
    yield n++;
  }
}

function* filter(items, keep) {
  for (const item of items) {
    if (keep(item)) yield item;
  }
}

function* map(items, change) {
  for (const item of items) yield change(item);
}

function* take(items, count) {
  if (count <= 0) return;
  for (const item of items) {
    yield item;
    if (--count === 0) return;
  }
}

const result = take(map(filter(naturals(), (n) => n % 7 === 0), (n) => n * n), 4);
console.log([...result]);
console.log("numbers produced:", produced);
```

```
ana@dev:~/js$ node lazy.js
[ 49, 196, 441, 784 ]
numbers produced: 28
```

`naturals` é um laço infinito, e o programa terminou. **A linha puxou os valores um por vez**: `take`
pediu um valor a `map`, `map` pediu a `filter`, `filter` pediu a `naturals` até receber um múltiplo
de 7, e o quadrado subiu de volta. Quando `take` tinha quatro, ele terminou, e ninguém mais pediu
nada a `naturals`.

`numbers produced: 28` é o ponto. **Quatro resultados precisaram de exatamente 28 números naturais,
porque 28 é o quarto múltiplo de 7**, e foram esses que se fizeram. A mesma linha escrita com arrays,
`filter`, depois `map`, depois `slice`, precisaria de um array finito para começar, e construiria
cada array intermediário inteiro.

## Quando vale a pena

A preguiça compensa quando a fonte é grande, lenta ou sem fim: linhas de um arquivo grande, linhas de
um banco de dados, páginas de uma API, as jogadas de um jogo. **Para um array de cem itens já na
memória, os métodos de array da aula 4 são mais simples e rápidos o bastante**, e é isso que a maior
parte do código deve usar. A linha de geradores é a ferramenta para quando construir a lista inteira
antes é o problema.
