---
title: Dados que podem não estar lá
version: 1
---

Dados de fora do seu programa têm buracos. Um livro sem autor, um usuário sem endereço, uma lista de
resenhas vazia. **Ler uma propriedade que falta dá `undefined`, e ler uma propriedade de `undefined`
lança erro**:

```javascript
const fromApi = { title: "Iracema", reviews: [] };
console.log(fromApi.author);
console.log(fromApi.author.name);
```

```
ana@dev:~/js$ node missing.js 2>&1 | head -n 6
undefined
/home/ana/js/missing.js:3
console.log(fromApi.author.name);
                           ^

TypeError: Cannot read properties of undefined (reading 'name')
```

Este é o erro de execução mais comum do JavaScript, e vale aprender a ler a mensagem. **`Cannot read
properties of undefined (reading 'name')` significa que a coisa à esquerda de `.name` era
`undefined`**, aqui `fromApi.author`. O conserto nunca está do lado do `name`; está em descobrir por
que o lado esquerdo faltou.

## O `?.`

Quando uma parte ausente é uma possibilidade normal e não um bug, o **encadeamento opcional** diz
isso. O `?.` lê a propriedade se o lado esquerdo tiver valor, e **para e dá `undefined` se o lado
esquerdo for `null` ou `undefined`**, em vez de lançar erro:

```javascript
const fromApi = { title: "Iracema", reviews: [] };

console.log(fromApi.author?.name);
console.log(fromApi.author?.name ?? "unknown author");
console.log(fromApi.reviews?.[0]?.stars);
console.log(fromApi.format?.());

const withAuthor = { title: "Iracema", author: { name: "José de Alencar" } };
console.log(withAuthor.author?.name);
```

```
ana@dev:~/js$ node optional.js
undefined
unknown author
undefined
undefined
José de Alencar
```

- `fromApi.author?.name` parou no autor que faltava;
- **o `?.` faz par com o `??` da aula 2** para dar um reserva na mesma expressão:
  `"unknown author"`;
- `?.[0]` é a forma com colchetes, para um índice ou um nome computado. `reviews` existia e estava
  vazio, então `[0]` era `undefined`, e o segundo `?.` parou ali;
- `?.()` chama uma função só se ela existir. `fromApi.format` não existe, então nada foi chamado;
- quando os dados estão completos, o `?.` é um `.` comum, como mostra a última linha.

## Onde não usar

**O `?.` esconde o erro, então só cabe onde um valor ausente é esperado.** Espalhá-lo por todo ponto
transforma um bug num espaço em branco numa tela. Se um livro precisa ter autor, deixe o programa
falhar no lugar em que encontra um sem, onde a mensagem é clara, e não três telas depois, onde um
nome vazio é tudo o que alguém consegue ver.
