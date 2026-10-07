---
title: ES modules: import e export
version: 3
---

Um ES module diz o que oferece com **`export`** e do que precisa com **`import`**. No Node, um arquivo
é tratado como módulo quando o nome termina em `.mjs`, ou quando o `package.json` mais próximo diz
isso, o que o fim desta seção mostra.

```javascript
console.log("books.mjs is running");

export const books = [
  { title: "Iracema", year: 1865 },
  { title: "Dom Casmurro", year: 1899 },
];

export function byYear(list) {
  return list.toSorted((a, b) => a.year - b.year);
}

export default class Catalogue {
  constructor(items) {
    this.items = items;
  }
  get size() {
    return this.items.length;
  }
}
```

```javascript
import Catalogue, { books, byYear as sortByYear } from "./books.mjs";
import * as everything from "./books.mjs";

console.log(sortByYear(books).map((b) => b.title));
console.log(new Catalogue(books).size);
console.log(Object.keys(everything));
console.log(typeof byYear, this);
```

```
ana@dev:~/js$ node esm/main.mjs
books.mjs is running
[ 'Iracema', 'Dom Casmurro' ]
2
[ 'books', 'byYear', 'default' ]
undefined undefined
```

## Dois tipos de export

- **Exports nomeados**, `export const books` e `export function byYear`, são importados pelo nome,
  entre chaves: `{ books, byYear }`. O `as` renomeia na entrada, então `byYear as sortByYear` criou
  um nome local que não colide com nada em `main.mjs`;
- **um export default** por módulo, `export default class Catalogue`, é importado sem chaves, com o
  nome que quem importa escolher. Essa liberdade é também o defeito dele: dois arquivos podem chamar
  a mesma coisa por dois nomes, e uma busca por um não acha o outro. Muitas equipes preferem exports
  nomeados por esse motivo;
- `import * as everything` junta todo export num objeto, e o default aparece nele com o nome
  `default`.

## O que a saída diz sobre módulos

`books.mjs is running` saiu **uma vez, antes de qualquer coisa de `main.mjs`**, embora `main.mjs`
tenha importado o arquivo duas vezes. Um módulo roda uma vez, na primeira vez que algo o importa, e
todos os que importam dividem os exports dele. `typeof byYear` foi `undefined` em `main.mjs`: só o
`sortByYear` renomeado existe ali. E **`this` no topo de um módulo é `undefined`**, porque código de
módulo é modo estrito (aula 20) e não é chamado como método de ninguém.

## Erros que o sistema pega por você

Dois arquivos de uma linha ao lado de `books.mjs`, cada um com um erro. `esm/wrong-name.mjs`:

```javascript
import { byTitle } from "./books.mjs";
```

e `esm/no-extension.mjs`:

```javascript
import { books } from "./books";
```

```
ana@dev:~/js$ node esm/wrong-name.mjs 2>&1 | grep Error
SyntaxError: The requested module './books.mjs' does not provide an export named 'byTitle'
ana@dev:~/js$ node esm/no-extension.mjs 2>&1 | grep Error
Error [ERR_MODULE_NOT_FOUND]: Cannot find module '/home/ana/js/esm/books' imported from /home/ana/js/esm/no-extension.mjs
```

**Importar um nome que o módulo não exporta é um `SyntaxError`**, encontrado antes de qualquer código
rodar, porque os imports são resolvidos lendo os arquivos antes. Um nome de função escrito errado num
programa grande é pego na partida, e não no momento em que alguém clica no botão que o usa. O segundo
erro é o mais comum no Node: **um import de ES module precisa da extensão do arquivo**, `./books.mjs`,
escrita por inteiro.

## `"type": "module"`

Uma pasta `typed` tem um `package.json` e o `hello.js`, que tem duas linhas:

```javascript
import { basename } from "node:path";
console.log(basename(import.meta.filename), typeof require);
```

```
ana@dev:~/js$ cat typed/package.json
{
  "name": "typed",
  "type": "module"
}
ana@dev:~/js$ node typed/hello.js
hello.js undefined
```

Com `"type": "module"` no `package.json` mais próximo, **arquivos `.js` comuns são ES modules**. É
assim que a maioria dos projetos novos é montada. Dentro de um, `require` não existe, como mostra a
última linha; `import.meta.filename` é o caminho do próprio módulo, a resposta dos ES modules a uma
pergunta que o CommonJS da próxima seção responde de outro jeito.
