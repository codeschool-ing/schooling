---
title: Números, e por que 0.1 + 0.2 não é 0.3
version: 1
---

JavaScript tem um tipo para todo número comum, e **ele é um número binário de ponto flutuante de 64
bits**, o mesmo formato que a maioria das linguagens chama de double. Essa escolha explica quase
toda surpresa desta seção.

```
ana@dev:~/js$ node -p '0.1 + 0.2'
0.30000000000000004
ana@dev:~/js$ node -p '0.1 + 0.2 === 0.3'
false
ana@dev:~/js$ node -p '(0.1 + 0.2).toFixed(2)'
0.30
```

**O binário não consegue guardar um décimo exatamente**, do mesmo jeito que o decimal não consegue
guardar um terço: 0.1 é guardado como o valor mais próximo que o formato tem, que fica um fio fora.
Dois desses somados caem num número que não é o mais próximo de 0.3, e `===` compara os valores
guardados exatamente. O terceiro comando mostra o conserto de costume para exibir: `toFixed(2)`
arredonda para duas casas e devolve uma **string**, porque está produzindo texto para uma pessoa
ler.

## Dinheiro se conta em centavos

Arredondar para exibir está certo. Arredondar enquanto calcula é como um total termina um centavo
longe do recibo. **Guarde dinheiro como um número inteiro da menor unidade**, e divida só para
imprimir:

```javascript
const priceCents = 1990;    // R$ 19,90
const quantity = 3;
const totalCents = priceCents * quantity;

console.log(totalCents);
console.log((totalCents / 100).toFixed(2));
console.log(0.1 * 3, 1 * 3 / 10);
```

```
ana@dev:~/js$ node cents.js
5970
59.70
0.30000000000000004 0.3
```

Números inteiros são exatos nesse formato até um limite bem grande, então `1990 * 3` é exatamente
`5970`. A última linha mostra que a ordem das operações importa com frações: `0.1 * 3` sai torto,
e `1 * 3 / 10` não, porque multiplica inteiros primeiro e divide uma vez só.

## Os valores das bordas

```javascript
console.log(1 / 0, -1 / 0, 0 / 0);
console.log(typeof NaN);
console.log(Number.MAX_SAFE_INTEGER);
console.log(2 ** 53, 2 ** 53 + 1);
console.log(2n ** 53n + 1n);
console.log(7 % 3, -7 % 3);
console.log(Number.isInteger(5.0), Number.isInteger(5.5));
```

```
ana@dev:~/js$ node special.js
Infinity -Infinity NaN
number
9007199254740991
9007199254740992 9007199254740992
9007199254740993n
1 -1
true false
```

Linha por linha:

- dividir por zero dá `Infinity` ou `-Infinity`, e **zero dividido por zero é `NaN`**, "not a
  number", que é ele mesmo do tipo `number`. `NaN` é o que um cálculo produz quando não tem
  resposta, e a seção de igualdade desta aula mostra como testá-lo;
- `Number.MAX_SAFE_INTEGER` é o maior número inteiro que o formato guarda exatamente. **Depois
  dele, `2 ** 53 + 1` volta como `2 ** 53`**: o `+ 1` se perdeu. Ids de um banco de dados que usa
  inteiros de 64 bits podem ser desse tamanho, e é por isso que APIs costumam mandá-los como
  strings;
- um **BigInt**, escrito com um `n`, não tem esse limite, e acertou `9007199254740993n`. BigInts e
  números comuns não se misturam numa conta; você converte um no outro de propósito;
- `%` é o resto, e **ele mantém o sinal do lado esquerdo**: `-7 % 3` é `-1`, não `2`;
- `Number.isInteger` pergunta se um número não tem parte fracionária. `5.0` é o mesmo número que
  `5`.
