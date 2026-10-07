---
title: Respondendo a um gerador
version: 1
---

O `yield` é uma porta de mão dupla. **O valor passado para `next(valor)` vira o resultado da
expressão `yield` em que o gerador está pausado**, então um gerador pode receber respostas além de
produzir valores:

```javascript
function* conversation() {
  const name = yield "What is your name?";
  const book = yield `Hello, ${name}. Which book?`;
  return `${name} is reading ${book}`;
}

const c = conversation();
console.log(c.next().value);
console.log(c.next("ana").value);
console.log(c.next("Iracema"));
```

```
ana@dev:~/js$ node talk.js
What is your name?
Hello, ana. Which book?
{ value: 'ana is reading Iracema', done: true }
```

O primeiro `next()` rodou até o primeiro `yield` e trouxe a pergunta; o que lhe fosse passado seria
jogado fora, porque nenhum `yield` estava esperando ainda. **`next("ana")` retomou o `yield` pausado
com `"ana"` como valor**, então `name` virou `"ana"`, e o corpo rodou até a segunda pergunta.
`next("Iracema")` respondeu essa, e o `return` terminou a conversa.

## Parar cedo, e arrumar

```javascript
function* pages() {
  try {
    yield "page 1";
    yield "page 2";
    yield "page 3";
  } finally {
    console.log("closing the file");
  }
}

for (const p of pages()) {
  console.log(p);
  if (p === "page 2") break;
}

function* everything() {
  yield* ["cover", "contents"];
  yield* pages();
  yield "back cover";
}
console.log([...everything()]);
```

```
ana@dev:~/js$ node cleanup.js
page 1
page 2
closing the file
closing the file
[ 'cover', 'contents', 'page 1', 'page 2', 'page 3', 'back cover' ]
```

O laço parou em `page 2` com `break`, e **`closing the file` saiu mesmo assim**. Quando um laço
`for…of` sai cedo, ele avisa o gerador chamando o método `return()` dele, e o gerador roda o bloco
`finally` em que estiver antes de terminar. É assim que um gerador que abriu um arquivo ou uma
conexão consegue fechá-lo, seja como for que o laço que o usava tenha terminado.

A segunda metade mostra **o `yield*`, que passa a vez a outro iterável** e entrega tudo o que ele
produz: as duas strings de um array, depois cada página de um gerador `pages()` novo, depois mais um
valor. Esse segundo `pages()` rodou até o fim, então o `finally` dele imprimiu `closing the file`
uma segunda vez, logo antes da lista.
