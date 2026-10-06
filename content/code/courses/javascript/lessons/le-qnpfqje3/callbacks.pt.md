---
title: Callbacks
version: 1
---

O jeito mais antigo de dizer "faça isto quando o trabalho terminar" é **passar a função que deve
rodar nessa hora**. As funções de arquivo originais do Node funcionam assim, e criaram uma convenção
que você ainda vai ver: o primeiro parâmetro do callback é um erro, ou `null` se não houve nenhum.

```javascript
const fs = require("node:fs");

console.log("asking for book 12");
fs.readFile("books/12.json", "utf8", (err, text) => {
  if (err) {
    console.log("could not read the book:", err.code);
    return;
  }
  const book = JSON.parse(text);
  fs.readFile(`authors/${book.authorId}.json`, "utf8", (err, text) => {
    if (err) {
      console.log("could not read the author:", err.code);
      return;
    }
    console.log(book.title, "by", JSON.parse(text).name);
  });
});
console.log("asked; carrying on");

fs.readFile("books/99.json", "utf8", (err) => {
  console.log("book 99:", err.code);
});
```

```
ana@dev:~/js$ node callbacks.js
asking for book 12
asked; carrying on
book 99: ENOENT
Dom Casmurro by Machado de Assis
```

Leia a ordem das linhas. **`asked; carrying on` saiu antes de qualquer arquivo ser lido**: o
`readFile` começou o trabalho, retornou na hora, e o programa seguiu. Cada callback rodou depois, como
tarefa (aula 13), quando o seu arquivo ficou pronto. O livro 99 não existe, e o erro dele, `ENOENT`,
"no such entry", chegou até antes do livro que existe, porque um arquivo que falta é encontrado mais
rápido do que um arquivo é lido.

## O que dói

Duas leituras que dependem uma da outra, o livro e depois o autor, significaram **um callback dentro
de um callback**, e cada nível teve de conferir o seu próprio `err`. Acrescente um terceiro e um
quarto passo e o código desliza para a direita, uma indentação por passo; esse formato tem nome,
callback hell. Pior que o formato:

- **uma conferência de erro que você esquece é um erro que some**. Nada obriga você a olhar o `err`;
- **um `throw` dentro de um callback não pode ser pego por um `try` em volta da chamada**, porque
  quando o callback roda, o `try` já terminou faz tempo. A aula 17 mostra isso acontecendo.

Callbacks ainda estão em toda parte para eventos, onde uma função roda muitas vezes (aula 12). **Para
um único resultado que chega depois, as promessas da próxima seção os substituíram**, e o Node
oferece toda função de arquivo nessa forma também.
