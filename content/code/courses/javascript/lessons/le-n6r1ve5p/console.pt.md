---
title: O console, além do log
version: 1
---

**`console.log` é um de uns vinte métodos, e alguns dos outros economizam tempo de verdade.** Eles
existem no navegador e no Node do mesmo jeito. Este programa roda no Node, porque o Node os imprime
como texto, e o navegador desenha as mesmas chamadas como painéis interativos:

```javascript
const books = [
  { id: 1, title: "Dom Casmurro", year: 1899, author: { name: "Machado de Assis", born: 1839 } },
  { id: 2, title: "Grande Sertão: Veredas", year: 1956, author: { name: "João Guimarães Rosa", born: 1908 } },
  { id: 3, title: "A Hora da Estrela", year: 1977, author: { name: "Clarice Lispector", born: 1920 } },
];

console.table(books, ["title", "year"]);

console.log(books[0]);
console.dir(books[0], { depth: 0 });

for (const book of books) {
  if (book.year > 1950) console.count("after 1950");
}

console.group("checking years");
console.assert(books.every((b) => b.year > 1900), "a book from before 1900");
console.assert(books.length === 3, "three books");
console.groupEnd();

function render(book) {
  console.trace("render", book.id);
}
render(books[1]);
```

```
ana@dev:~/js$ node consoles.js 2>&1 | head -n 21
┌─────────┬──────────────────────────┬──────┐
│ (index) │ title                    │ year │
├─────────┼──────────────────────────┼──────┤
│ 0       │ 'Dom Casmurro'           │ 1899 │
│ 1       │ 'Grande Sertão: Veredas' │ 1956 │
│ 2       │ 'A Hora da Estrela'      │ 1977 │
└─────────┴──────────────────────────┴──────┘
{
  id: 1,
  title: 'Dom Casmurro',
  year: 1899,
  author: { name: 'Machado de Assis', born: 1839 }
}
{ id: 1, title: 'Dom Casmurro', year: 1899, author: [Object] }
after 1950: 1
after 1950: 2
checking years
  Assertion failed: a book from before 1900
Trace: render 2
    at render (/home/ana/js/consoles.js:22:11)
    at Object.<anonymous> (/home/ana/js/consoles.js:24:1)
```

`2>&1 | head -n 21` junta a saída de erro à saída normal e fica com as 21 primeiras linhas, por um
motivo que o último método deixa claro.

## Para que serve cada um

- **`console.table`** desenha um array de objetos como uma grade. O segundo argumento escolhe as
  colunas. Para uma lista de registros é mais rápido de ler que qualquer `log`;
- **`console.dir`** com `depth` decide até onde imprimir dentro de objetos aninhados. Na
  profundidade 0 o autor virou `[Object]`. No navegador, `dir` de um elemento mostra as
  propriedades dele em vez do HTML;
- **`console.count`** conta quantas vezes um rótulo foi alcançado. Responde "quantas vezes isto
  roda?" sem uma variável contadora;
- **`console.group`** indenta tudo até o `groupEnd`, para que a saída de um passo se leia como um
  bloco;
- **`console.assert`** só imprime quando a condição é falsa. A primeira asserção falhou e disse
  isso; a segunda passou e não imprimiu nada. Ela não para o programa, ao contrário de uma asserção
  num teste;
- **`console.trace`** imprime a pilha de chamadas a partir de onde foi chamado. Os dois primeiros
  quadros são o código da ana; as linhas que o `head` cortou eram o Node carregando o arquivo, e
  por isso foram cortadas.

`console.warn` e `console.error` imprimem como o `log`, na saída de erro. No navegador eles são
coloridos e podem ser filtrados, e o comando `page` do laboratório os marca com `[warn]` e
`[error]`.

## Onde o log deixa de bastar

`console.log` responde uma pergunta por execução, decidida antes da execução. Quando a resposta
levanta outra pergunta, você edita e roda de novo. Quando o bug mora na terceira volta de um laço
dentro de um callback, são muitas execuções. O resto desta aula é sobre fazer essas perguntas com o
programa parado.
