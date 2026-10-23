---
title: ES modules, do jeito que o Node os roda
version: 1
---

**Um ES module é carregado em dois passos: o Node lê todo `import` do grafo inteiro primeiro, e
depois roda o código.** Essa ordem é o que a aula 9 do javascript chamou de estática, e num servidor
ela tem três consequências práticas.

## Um arquivo ausente é encontrado antes de qualquer coisa rodar

```javascript
// start.mjs
console.log("starting the server");
import { prices } from "./prices.mjs";
console.log(prices);
```

```
ana@dev:~/server/modules/esm$ node start.mjs
node:internal/modules/esm/resolve:274
    throw new ERR_MODULE_NOT_FOUND(
          ^

Error [ERR_MODULE_NOT_FOUND]: Cannot find module '/home/ana/server/modules/esm/prices.mjs' imported from /home/ana/server/modules/esm/start.mjs
    at finalizeResolution (node:internal/modules/esm/resolve:274:11)
    at moduleResolve (node:internal/modules/esm/resolve:859:10)
    at defaultResolve (node:internal/modules/esm/resolve:983:11)
    at #cachedDefaultResolve (node:internal/modules/esm/loader:731:20)
    at ModuleLoader.resolve (node:internal/modules/esm/loader:708:38)
    at ModuleLoader.getModuleJobForImport (node:internal/modules/esm/loader:310:38)
    at ModuleJob._link (node:internal/modules/esm/module_job:182:49) {
  code: 'ERR_MODULE_NOT_FOUND',
  url: 'file:///home/ana/server/modules/esm/prices.mjs'
}

Node.js v22.22.0
```

O `starting the server` nunca apareceu, embora seja a primeira linha. O `import` foi resolvido antes
de qualquer código rodar, e o `prices.mjs` ainda não existe. **Um erro de digitação num import para o
processo na inicialização, não na primeira requisição que precisar do arquivo**, que é a hora em que
você quer descobrir. As declarações `import` também são içadas, então a convenção é escrever todas no
topo, onde elas são honestas sobre quando acontecem.

## Await no topo

Como carregar e rodar são separados, um módulo pode usar `await` no nível de cima, fora de qualquer
função. Quem o importa espera até ele terminar:

```javascript
// prices.mjs
import { readFile } from "node:fs/promises";

export const prices = JSON.parse(await readFile(new URL("./prices.json", import.meta.url), "utf8"));
```

```
ana@dev:~/server/modules/esm$ echo '{"tea": 4.5, "cake": 7}' > prices.json
ana@dev:~/server/modules/esm$ node start.mjs
starting the server
{ tea: 4.5, cake: 7 }
```

Este é o jeito limpo de carregar algo de que um servidor precisa antes de começar. **Não é o jeito
de fazer trabalho lento**: um módulo que espera uma requisição de rede no topo atrasa todo módulo que
o importa, e uma falha ali para o programa antes de qualquer coisa ter começado.

## JSON, com um atributo

O `require` carrega um arquivo `.json` diretamente. Um `import` de JSON precisa dizer o que espera,
para que um servidor que mande JavaScript onde se pediu JSON não consiga rodar código:

```javascript
// menu.mjs
import prices from "./prices.json" with { type: "json" };
console.log(Object.keys(prices));
```

```
ana@dev:~/server/modules/esm$ node menu.mjs
[ 'tea', 'cake' ]
ana@dev:~/server/modules/esm$ sed 's/ with { type: "json" }//' menu.mjs > bare.mjs
ana@dev:~/server/modules/esm$ node bare.mjs 2>&1 | grep -E "^TypeError"
TypeError [ERR_IMPORT_ATTRIBUTE_MISSING]: Module "file:///home/ana/server/modules/esm/prices.json" needs an import attribute of "type: json"
```

O `with { type: "json" }` é um **atributo de importação**. Tire-o e o Node se recusa a carregar o
arquivo, dizendo qual atributo queria. Para um arquivo lido na inicialização da sua própria pasta, o
`readFile` com `JSON.parse`, como no `prices.mjs`, faz o mesmo trabalho e funciona igual nos dois
sistemas de módulos.
