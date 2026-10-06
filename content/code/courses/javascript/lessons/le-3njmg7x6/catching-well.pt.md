---
title: Pegando só o que você consegue tratar
version: 1
---

Pegar um erro é uma decisão: **este código sabe o que fazer com esta falha**. O erro mais comum é pegar
tudo e não fazer nada útil com isso:

```javascript
function loadSettings(text) {
  try {
    return JSON.parse(text);
  } catch {
    return {};
  }
}

const settings = loadSettings('{"perPage": 50,}');
console.log(settings.perPage ?? 20);
```

```
ana@dev:~/js$ node swallow.js
20
```

O texto de configuração tinha uma vírgula sobrando no fim, o que o JSON não permite. `loadSettings`
pegou o `SyntaxError`, devolveu `{}`, e o programa seguiu com **o padrão de 20 em vez dos 50 que
alguém escreveu**. Nada foi impresso, nenhum log registrou, e a próxima pessoa que estranhar por que a
sua configuração é ignorada vai passar uma tarde atrás de uma vírgula. Isso é um **erro engolido**, e é
pior que uma queda, porque uma queda pelo menos diz onde.

## Pegue o esperado, relance o resto

```javascript
class NotFound extends Error {
  name = "NotFound";
}

function findBook(id) {
  if (id === 9) throw new NotFound(`no book ${id}`);
  if (id === 13) throw new TypeError("Cannot read properties of undefined (reading 'shelf')");
  return { id, title: "Iracema" };
}

function titleOrPlaceholder(id) {
  try {
    return findBook(id).title;
  } catch (err) {
    if (err instanceof NotFound) return "(no such book)";
    throw err;
  }
}

console.log(titleOrPlaceholder(7));
console.log(titleOrPlaceholder(9));
console.log(titleOrPlaceholder(13));
```

```
ana@dev:~/js$ node rethrow.js 2>&1 | head -n 9
Iracema
(no such book)
/home/ana/js/rethrow.js:16
    throw err;
    ^

TypeError: Cannot read properties of undefined (reading 'shelf')
    at findBook (/home/ana/js/rethrow.js:7:24)
    at titleOrPlaceholder (/home/ana/js/rethrow.js:13:12)
```

`titleOrPlaceholder` sabe o que fazer com uma coisa: **um livro que não existe ganha um texto
substituto.** Ela confere o tipo com `instanceof`, trata esse tipo, e **relança todo o resto sem
mudança**. O livro 13 bateu num bug de verdade, um `TypeError`, que passou pelo `catch` e parou o
programa com a pilha intacta, apontando para `findBook` na linha 7. Se o `catch` devolvesse um
substituto para todo erro, esse bug apareceria como um título faltando em alguma tela, sem rastro de
onde veio.

## Uma lista curta

- **pegue onde você consegue fazer algo**: mostrar uma mensagem, usar uma alternativa que seja de fato
  certa, tentar de novo (aula 16), ou acrescentar contexto e relançar;
- **confira o tipo** antes de tratar, com `instanceof` ou `name`;
- **nunca deixe um `catch` vazio** sem um comentário dizendo por que o silêncio é a resposta certa, e
  registre o que pegou quando não for;
- deixe o resto viajar. Um erro que chega ao topo do programa, fazendo barulho, é um bug que é
  consertado.
