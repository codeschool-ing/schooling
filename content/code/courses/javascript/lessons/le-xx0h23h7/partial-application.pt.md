---
title: Fixando argumentos de antemão
version: 1
---

O `bind` aceita mais que um `this`. **Todo argumento depois do primeiro também fica fixo, e vem antes
do que a chamada posterior passar.** Uma função com alguns dos argumentos preenchidos de antemão se
chama **aplicação parcial**:

```javascript
function price(currency, cents) {
  return `${currency} ${(cents / 100).toFixed(2)}`;
}

const inReais = price.bind(null, "BRL");
const inEuros = price.bind(null, "EUR");
console.log(inReais(1990), "/", inEuros(1990));
console.log(inReais.length);

const inDollars = (cents) => price("USD", cents);
console.log(inDollars(1990));
```

```
ana@dev:~/js$ node partial.js
BRL 19.90 / EUR 19.90
1
USD 19.90
```

`price` recebe uma moeda e um valor. `price.bind(null, "BRL")` criou uma função com a moeda já
preenchida, então `inReais(1990)` rodou como `price("BRL", 1990)`. O `null` está lá porque `price`
não usa `this`, e **o `bind` sempre recebe o `this` primeiro, mesmo quando ninguém precisa dele**. O
`length` da função vinculada é 1, os parâmetros que ela ainda espera.

## A arrow faz o mesmo

`inDollars` faz o mesmo trabalho com uma arrow e sem `bind`, e essa é a forma que você mais vai
encontrar em código novo: **uma closure (aula 6) que chama a função com a parte fixa escrita
dentro.** É mais fácil de ler, pode fixar qualquer argumento e não só os primeiros, e dispensa o
`null` de enfeite.

A ideia em si é o que vale guardar. Uma função que recebe uma configuração e depois os dados é comum
em código de configuração, e fixar a configuração uma vez te dá uma função pequena e específica para
passar adiante: um formatador para uma moeda, um logger para um módulo, uma requisição para um
servidor. Escrever isso com `bind` ou com uma arrow é questão de estilo; o código que a equipe já tem
costuma decidir.
