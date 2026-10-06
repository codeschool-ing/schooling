---
title: A pilha de chamadas
version: 1
---

Para saber o que "o código que está rodando" significa a cada momento, o motor mantém uma **pilha de
chamadas**: uma lista das funções que foram chamadas e ainda não retornaram. Chamar uma função empilha
um quadro no topo; retornar o desempilha. O `console.trace` imprime a pilha na linha em que roda:

```javascript
function format(book) {
  console.trace("inside format");
  return `${book.title} (${book.year})`;
}

function render(books) {
  return books.map(format);
}

function main() {
  render([{ title: "Iracema", year: 1865 }]);
}

main();
```

```
ana@dev:~/js$ node stack.js 2>&1 | head -n 6
Trace: inside format
    at format (/home/ana/js/stack.js:2:11)
    at Array.map (<anonymous>)
    at render (/home/ana/js/stack.js:7:16)
    at main (/home/ana/js/stack.js:11:3)
    at Object.<anonymous> (/home/ana/js/stack.js:14:1)
```

**Leia uma pilha de cima para baixo: a linha do topo é onde você está, e cada linha abaixo é a chamada
que levou até ali.** `format` foi chamada por `map`, embutido nos arrays e por isso mostrado como
`<anonymous>`; `map` por `render`; `render` por `main`; e `main` pelo próprio nível de cima do
arquivo. Todo erro deste curso imprimiu uma dessas embaixo da mensagem, e a aula 17 trata de lê-las.

## A pilha tem tamanho

```javascript
function countDown(n) {
  return n === 0 ? 0 : 1 + countDown(n - 1);
}
console.log(countDown(1000));
console.log(countDown(1_000_000));
```

```
ana@dev:~/js$ node overflow.js 2>&1 | head -n 6
1000
/home/ana/js/overflow.js:1
function countDown(n) {
                  ^

RangeError: Maximum call stack size exceeded
```

Cada chamada que ainda não retornou ocupa um quadro, e **a pilha tem espaço para um número limitado
de quadros**. Mil chamadas aninhadas couberam; um milhão não coube, e o motor parou com
`RangeError: Maximum call stack size exceeded`. É o mesmo erro que a aula 7 obteve espalhando um
milhão de argumentos numa chamada. Na prática quase sempre significa uma recursão que nunca chega ao
fim, como percorrer uma estrutura que aponta de volta para si mesma, contra o que o `WeakSet` da
aula 5 protegia.

## Vazia é o estado importante

**Quando o último quadro retorna, a pilha fica vazia, e só então outra coisa pode rodar.** É o momento
que o navegador espera: o handler de clique da seção anterior ficou numa fila até a ordenação retornar
e a pilha ficar vazia. O event loop, duas seções adiante, é a regra do que roda em seguida.
