---
title: Quando os dois se encontram
version: 1
---

**Um ES module consegue importar um módulo CommonJS, e no Node 22 um módulo CommonJS consegue fazer
`require` da maioria dos ES modules.** As duas coisas acontecem o tempo todo, porque o seu código é
de um tipo e metade das suas dependências é do outro. Aqui está a mesma função pequena escrita dos
dois jeitos:

```javascript
// slug.cjs
function slugify(text) {
  return text.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}
module.exports = { slugify, version: 1 };
```

```javascript
// slug.mjs
export function slugify(text) {
  return text.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}
export default slugify;
```

## import de CommonJS

```javascript
// use-cjs.mjs
import slug, { slugify } from "./slug.cjs";
console.log(slug, slugify("Hello, World"));
```

```
ana@dev:~/server/modules/mix$ node use-cjs.mjs
{ slugify: [Function: slugify], version: 1 } hello-world
```

**O import default é o `module.exports`, inteiro.** O import nomeado também funcionou, e isso é um
palpite, não uma garantia: o Node varre o texto do arquivo CommonJS procurando padrões como
`module.exports = { slugify }` e oferece os nomes que encontra. Um pacote que monta as exportações
num laço, ou numa função, não oferece nenhum pelo nome, e aí `import pkg from "pkg"` seguido de
`pkg.slugify` é a forma que sempre funciona.

## require de um ES module

```javascript
// use-esm.cjs
const mod = require("./slug.mjs");
console.log(mod);
console.log(mod.slugify("Hello, World"));
```

```
ana@dev:~/server/modules/mix$ node use-esm.cjs
[Module: null prototype] {
  __esModule: true,
  default: [Function: slugify],
  slugify: [Function: slugify]
}
hello-world
```

O `require` devolveu o **objeto namespace do módulo**: cada exportação pelo nome, a default em
`default`, e uma marca `__esModule` que as ferramentas usam para distinguir os dois. Antes do Node
22.12 esta linha falhava com `ERR_REQUIRE_ESM`, e você ainda vai encontrar esse erro, e o conselho de
usar `import()` no lugar, por toda a internet.

Há um caso que ele não consegue. Um módulo com `await` no topo não pode ser carregado pelo
`require`, porque o `require` precisa retornar na hora:

```javascript
// later.mjs
await new Promise((resolve) => setTimeout(resolve, 10));
export const ready = true;
```

```
ana@dev:~/server/modules/mix$ node -e 'require("./later.mjs")' 2>&1 | grep -E '^Error'
Error [ERR_REQUIRE_ASYNC_MODULE]: require() cannot be used on an ESM graph with top-level await. Use import() instead. To see where the top-level await comes from, use --experimental-print-required-tla.
```

**O `import()`, a forma de função, funciona em todo lugar** — em CommonJS e em ES modules, no topo ou
dentro de uma função — e devolve uma promise do namespace. Quando o `require` recusa, ele é o
caminho.
