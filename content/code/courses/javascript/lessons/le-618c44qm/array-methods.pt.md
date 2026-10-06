---
title: map, filter, find e reduce
version: 1
---

A maioria dos laços sobre um array faz uma de quatro coisas: transformar cada item, ficar com
alguns, procurar um, ou combinar todos num único valor. **Cada uma tem um método que recebe uma
função e faz o laço por você**, e lê-los é mais fácil que ler o laço, porque o nome do método diz
qual das quatro é:

```schooling-example
{
  "language": "javascript",
  "file": "methods.js",
  "parts": [
    {
      "code": "const books = [\n  { title: \"Iracema\", year: 1865, pages: 112 },\n  { title: \"Dom Casmurro\", year: 1899, pages: 256 },\n  { title: \"Macunaíma\", year: 1928, pages: 208 },\n  { title: \"O Cortiço\", year: 1890, pages: 304 },\n];",
      "note": "Os dados: quatro livros, cada um um objeto. Esse formato, um array de objetos, é o que a maioria das APIs manda."
    },
    {
      "code": "const titles = books.map((b) => b.title);\nconsole.log(titles);",
      "note": "`map` chama a função uma vez por item e constrói um array novo com o que ela devolver. Quatro livros entram, quatro títulos saem."
    },
    {
      "code": "const older = books.filter((b) => b.year < 1900);\nconsole.log(older.length);",
      "note": "`filter` fica com os itens para os quais a função devolve algo truthy. Três livros são anteriores a 1900."
    },
    {
      "code": "const first = books.find((b) => b.pages > 250);\nconsole.log(first.title);",
      "note": "`find` devolve o primeiro item que bate, ou `undefined` se nenhum bater. `findIndex` devolve a posição no lugar."
    },
    {
      "code": "console.log(books.some((b) => b.year > 1920), books.every((b) => b.pages > 100));",
      "note": "`some` pergunta se pelo menos um item bate, `every` se todos batem. Os dois param assim que sabem."
    },
    {
      "code": "const totalPages = books.reduce((sum, b) => sum + b.pages, 0);\nconsole.log(totalPages);",
      "note": "`reduce` carrega um valor pelo array. Ele começa em `0`, o segundo argumento, e cada chamada devolve o próximo total parcial. 112 + 256 + 208 + 304 é 880."
    },
    {
      "code": "const report = books\n  .filter((b) => b.year < 1900)\n  .toSorted((a, b) => a.year - b.year)\n  .map((b) => `${b.year} ${b.title}`);\nconsole.log(report);",
      "note": "Os métodos se encadeiam, porque cada um devolve um array. Leia de cima para baixo: fique com os antigos, ordene por ano, transforme cada um numa linha de texto. Usa-se `toSorted` em vez de `sort` para que nada mude o array de livros."
    }
  ],
  "output": "[ 'Iracema', 'Dom Casmurro', 'Macunaíma', 'O Cortiço' ]\n3\nDom Casmurro\ntrue true\n880\n[ '1865 Iracema', '1890 O Cortiço', '1899 Dom Casmurro' ]"
}
```

**Nenhum deles muda `books`.** Eles devolvem arrays ou valores novos, e é isso que torna seguro
encadeá-los: cada passo trabalha sobre o resultado do passo anterior.

## O `forEach` não é um deles

```javascript
const titles = ["Iracema", "Dom Casmurro"];
const result = titles.forEach((t) => t.toUpperCase());
console.log(result);

for (const t of titles) {
  console.log(t.length);
}
```

```
ana@dev:~/js$ node foreach.js
undefined
7
12
```

O `forEach` chama a função para cada item e **devolve `undefined`**, então o que a função calculou
é jogado fora. Ele existe para efeitos colaterais, como imprimir ou mandar cada item para algum
lugar. Quando você quer fazer algo com cada item, o `for…of`, o laço de baixo, faz o mesmo trabalho
e ainda deixa você sair cedo com `break`, o que o `forEach` não consegue. A aula 10 explica por que
o `for…of` funciona em arrays e em muito mais coisa.

## Qual usar

| você quer | use |
|---|---|
| um array novo, um item por item antigo | `map` |
| alguns dos itens | `filter` |
| o primeiro que bate | `find` |
| sim ou não | `some`, `every` |
| um valor a partir de muitos | `reduce`, ou um laço se o `reduce` ficar difícil de ler |
| fazer algo com cada um, sem nada de volta | `for…of` |

**O `reduce` é o que as pessoas usam demais.** Uma soma fica clara; um `reduce` que monta um objeto
aninhado com três condições dentro costuma ficar mais claro como um laço `for…of` com uma variável.
