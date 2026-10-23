---
title: Um módulo roda uma vez
version: 1
---

**O primeiro `require` ou `import` de um arquivo o roda. Todos os seguintes recebem as mesmas
exportações, sem rodá-lo de novo.** O Node guarda cada módulo carregado num cache indexado pelo
caminho completo:

```javascript
// counter.js
console.log("counter.js runs");
let count = 0;
module.exports = { next: () => ++count };
```

```javascript
// main.js
const a = require("./counter");
const b = require("./counter.js");
console.log(a === b, a.next(), b.next());
console.log(Object.keys(require.cache).map((f) => f.split("/").pop()));
```

```
ana@dev:~/server/modules/cache$ node main.js
counter.js runs
true 1 2
[ 'main.js', 'counter.js' ]
```

O `counter.js runs` apareceu uma vez para dois `require` escritos de dois jeitos. Os dois resolveram
para o mesmo caminho, então `a` e `b` são **o mesmo objeto**, e a contagem é compartilhada: 1, depois
2. O cache guarda os dois arquivos que rodaram, indexados pelo caminho completo; a última linha
imprimiu só o fim de cada um.

Este é o fato mais útil da aula para um servidor. **Um módulo é um singleton de graça.** Um pool de
banco de dados, um objeto de configuração lido do ambiente, um cache: crie no topo de um módulo,
exporte, e todo arquivo que o importar compartilha a mesma cópia. O módulo de configuração da aula 9
é construído assim. O mesmo vale para os ES modules, cujo cache é separado e não fica exposto como
objeto.

A exceção a ter em mente: a chave é o **caminho**. Duas cópias de um pacote em dois caminhos de
`node_modules`, o que o npm às vezes instala, são dois módulos com dois estados. Um singleton que
parece se reiniciar sozinho costuma ter sido carregado duas vezes de dois lugares.

## Quando dois módulos precisam um do outro

Um ciclo — o `a.js` pede o `b.js`, que pede o `a.js` — não entra em laço para sempre. O cache o
interrompe, com um preço:

```javascript
// a.js
exports.ready = false;
const b = require("./b");
console.log(`in a.js, b.ready is ${b.ready}`);
exports.ready = true;
```

```javascript
// b.js
exports.ready = false;
const a = require("./a");
console.log(`in b.js, a.ready is ${a.ready}`);
exports.ready = true;
```

```
ana@dev:~/server/modules/cache$ node a.js
in b.js, a.ready is false
in a.js, b.ready is true
```

Quando o `b.js` pediu o `a.js`, o `a.js` já estava no cache, rodado pela metade, então o `b.js`
recebeu as exportações dele **como estavam naquele momento**: `ready` ainda `false`. Nada falhou.
**Um ciclo entrega a alguém um módulo inacabado e não diz nada.** Nos ES modules o mesmo ciclo dá um
`ReferenceError`, se o nome carregado pela metade for lido cedo demais, o que pelo menos faz barulho.
A solução é a mesma nos dois: mover o que os dois arquivos precisam para um terceiro módulo que
nenhum deles peça de volta.
