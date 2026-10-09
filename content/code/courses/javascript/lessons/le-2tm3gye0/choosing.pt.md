---
title: Escolhendo uma coleção
version: 2
---

Seis formatos agora guardam dados nos seus programas, e **escolher o certo deixa mais curto o
código que o usa**. A pergunta a fazer é o que você vai fazer com os dados com mais frequência.

| você mais | use | porque |
|---|---|---|
| lê partes fixas e nomeadas: o título e o ano de um livro | **objeto** | os nomes são conhecidos quando você escreve o código |
| guarda itens em ordem e os percorre | **array** | ordem e posição são a razão de ser dele |
| busca valores por uma chave que é dado: uma palavra, um id, um objeto | **`Map`** | qualquer tipo de chave, sem nomes herdados, um `size` |
| pergunta se já viu um valor, ou tira duplicatas | **`Set`** | um de cada, e um `has` rápido |
| anexa informação a objetos que não são seus | **`WeakMap`** | não mantém esses objetos vivos |
| marca objetos como visitados ou processados | **`WeakSet`** | o mesmo, sem um valor |

## O teste que separa objeto de `Map`

**Se as chaves estão escritas no seu código-fonte, é um objeto. Se vêm dos dados, é um `Map`.**
`book.title` é uma propriedade que você escolheu. Uma palavra num texto, um id de um banco de dados
ou um usuário são chaves que você nunca viu antes de o programa rodar, e pertencem a um `Map`.

A exceção são dados que precisam virar JSON (aula 16), já que o JSON tem objetos e arrays e nada
mais. Mesmo assim a conversão é uma linha, como a seção de `Map` mostrou, então faça o trabalho com
a coleção certa e converta na borda.

## Como são os dados em formato de JSON

A maior parte dos dados de um servidor é um array de objetos. **Um `Map` indexado pelo id é o jeito
comum de tornar a busca rápida**:

```javascript
const books = [
  { id: 7, title: "Iracema" },
  { id: 12, title: "Dom Casmurro" },
];
const byId = new Map(books.map((b) => [b.id, b]));
console.log(byId.get(12).title, byId.size);
```

```
ana@dev:~/js$ node byid.js
Dom Casmurro 2
```

O `map` transforma cada livro num par `[id, livro]`, e o `Map` se constrói a partir dos pares.
Depois disso, `byId.get(12)` substitui um `find` que percorria o array inteiro. A aula 16 faz isso
com livros buscados num servidor.
