---
title: Arrays: listas ordenadas
version: 1
---

**Um array é um objeto cujas propriedades são numeradas a partir de 0**, com um `length` e um
conjunto de métodos para listas. Colchetes criam um e leem dele:

```javascript
const shelf = ["Iracema", "Dom Casmurro", "O Cortiço"];
console.log(shelf[0], shelf.length, shelf[shelf.length - 1], shelf.at(-1));
console.log(shelf[10]);

shelf.push("Macunaíma");
const removed = shelf.shift();
console.log(removed, shelf);

console.log(shelf.includes("O Cortiço"), shelf.indexOf("Iracema"));
console.log(shelf.slice(0, 2), shelf.length);
shelf.splice(1, 1);
console.log(shelf);
```

```
ana@dev:~/js$ node arrays.js
Iracema 3 O Cortiço O Cortiço
undefined
Iracema [ 'Dom Casmurro', 'O Cortiço', 'Macunaíma' ]
true -1
[ 'Dom Casmurro', 'O Cortiço' ] 3
[ 'Dom Casmurro', 'Macunaíma' ]
```

## Ler

`shelf[0]` é o primeiro item e `shelf.length - 1` o índice do último; `shelf.at(-1)` diz a mesma
coisa com menos caracteres, contando do fim. Um índice além do fim é lido como `undefined`, como
uma propriedade que falta, **e não lança erro**.

## Mudar

`push` acrescenta no fim e `pop` tira do fim; `unshift` e `shift` fazem o mesmo no começo. `shift`
devolveu `"Iracema"` e o array subiu. **`splice(início, quantidade)` remove itens no lugar**, e aqui
tirou o do índice 1. `slice(início, fim)` é o gêmeo próximo que não muda nada: devolve um array
novo, e `shelf.length` continuava 3 depois.

O par `splice` e `slice` é a confusão mais comum com arrays, e a regra por baixo é a que vale
guardar: **alguns métodos mudam o array em que são chamados, e alguns devolvem um novo.** `push`,
`pop`, `shift`, `unshift`, `splice`, `sort` e `reverse` mudam. Todo o resto desta aula devolve algo
novo.

## Ordenar

```javascript
const years = [1899, 1865, 1928, 1890];
const sizes = [10, 9, 1, 100];

console.log(sizes.sort());
console.log(sizes.sort((a, b) => a - b));

const sorted = years.toSorted((a, b) => a - b);
console.log(sorted, years);

const authors = ["Érico", "Clarice", "Jorge", "Ana"];
console.log(authors.toSorted());
console.log(authors.toSorted((a, b) => a.localeCompare(b, "pt-BR")));
```

```
ana@dev:~/js$ node sort.js
[ 1, 10, 100, 9 ]
[ 1, 9, 10, 100 ]
[ 1865, 1890, 1899, 1928 ] [ 1899, 1865, 1928, 1890 ]
[ 'Ana', 'Clarice', 'Jorge', 'Érico' ]
[ 'Ana', 'Clarice', 'Érico', 'Jorge' ]
```

Três surpresas num programa:

- **`sort()` sem argumento compara os itens como strings**, então `100` fica antes de `9`, pelo
  motivo que a aula 2 deu: `"1"` vem antes de `"9"`. Passe uma função de comparação,
  `(a, b) => a - b`, que devolve um número negativo quando `a` deve vir primeiro;
- `sort` mudou o próprio `sizes`. **`toSorted` devolve uma cópia ordenada e deixa o original**, como
  mostra `years`. Ele chegou em 2023, junto com `toReversed` e `toSpliced`;
- a ordem padrão das strings é pelo código do caractere, o que põe `Érico` depois de `Jorge`. **Para
  texto que uma pessoa vai ler, compare com `localeCompare`**, que sabe que `É` se ordena junto com
  `E` em português.
