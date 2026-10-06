---
title: WeakSet: marcando objetos
version: 1
---

**Um `WeakSet` está para um `Set` como um `WeakMap` está para um `Map`**: só objetos, sem tamanho,
sem laço, e não mantém os membros vivos. Ele responde uma pergunta, "este objeto está marcado?", e
o uso clássico é percorrer uma estrutura que pode apontar de volta para si mesma.

Dados de verdade dão voltas. Um autor tem livros, e cada livro tem o seu autor. Uma função que
percorre uma estrutura assim sem cuidado dá voltas para sempre, ou até a pilha acabar (a aula 13
mostra como isso fica). **O conserto é lembrar que objetos você já visitou**:

```javascript
function countObjects(value, seen = new WeakSet()) {
  if (typeof value !== "object" || value === null) return 0;
  if (seen.has(value)) return 0;
  seen.add(value);
  let n = 1;
  for (const child of Object.values(value)) {
    n += countObjects(child, seen);
  }
  return n;
}

const author = { name: "Machado de Assis", books: [] };
const book = { title: "Dom Casmurro", author };
author.books.push(book);

console.log(countObjects(book));
```

```
ana@dev:~/js$ node weakset.js
3
```

Três objetos: o livro, o autor e o array `books` do autor. Quando a caminhada chega ao livro pela
segunda vez, por `author.books`, `seen.has(value)` é verdadeiro e ela devolve 0 em vez de dar outra
volta.

## Por que fraco, aqui

Um `Set` comum funcionaria para esta chamada. **O `WeakSet` importa quando as marcas sobrevivem à
chamada**: um conjunto de elementos já inicializados numa página, ou de requisições já registradas.
Esses objetos vêm e vão; com um `Set`, todos ficariam na memória enquanto o set existisse, porque o
próprio set aponta para eles. O `WeakSet` deixa cada um ir embora quando o resto do programa termina
com ele.

Você vai escrever um `WeakSet` bem menos que os outros três. Quando encontrar um numa biblioteca,
ele quase sempre está fazendo isto: **guardar uma lista de objetos sem virar o motivo de eles
existirem.**
