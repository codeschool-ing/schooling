---
title: Lendo um erro
version: 1
---

**Um erro do Node é três coisas: o que aconteceu, onde, e como o programa chegou lá.** A maioria
das pessoas lê a primeira linha e chuta. Ler as três é mais rápido.

## Um stack trace

Este programa soma preços dados como texto, e a segunda lista tem uma palavra no meio:

```javascript
// total.js
function parsePrice(text) {
  const value = Number(text);
  if (Number.isNaN(value)) throw new Error(`not a price: "${text}"`);
  return value;
}

function total(lines) {
  return lines.map(parsePrice).reduce((a, b) => a + b, 0);
}

console.log(total(["12.50", "7.25"]));
console.log(total(["12.50", "seven"]));
```

```
ana@dev:~/server/errors$ node total.js; echo "exit code $?"
19.75
/home/ana/server/errors/total.js:4
  if (Number.isNaN(value)) throw new Error(`not a price: "${text}"`);
                           ^

Error: not a price: "seven"
    at parsePrice (/home/ana/server/errors/total.js:4:34)
    at Array.map (<anonymous>)
    at total (/home/ana/server/errors/total.js:9:16)
    at Object.<anonymous> (/home/ana/server/errors/total.js:13:13)
    at Module._compile (node:internal/modules/cjs/loader:1706:14)
    at Object..js (node:internal/modules/cjs/loader:1839:10)
    at Module.load (node:internal/modules/cjs/loader:1441:32)
    at Function._load (node:internal/modules/cjs/loader:1263:12)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)

Node.js v22.22.0
exit code 1
```

Leia de cima para baixo:

1. **As primeiras linhas apontam para o código.** O Node imprime o arquivo e a linha onde o erro
   foi lançado, a própria linha, e um acento circunflexo embaixo do ponto.
2. **A mensagem** é a do próprio `Error`: `not a price: "seven"`. Escrever uma mensagem que diz qual
   foi o valor ruim é a depuração mais barata que existe.
3. **A pilha**, as linhas que começam com `at`, é a cadeia de chamadas que levou até ali, da mais
   interna para fora: `parsePrice` foi chamada pelo `Array.map`, que foi chamado por `total`, que
   foi chamada do topo do arquivo, linha 13. As linhas que citam `node:internal` são o código do
   próprio Node carregando o seu arquivo, e você pode pulá-las.

O primeiro `console.log` imprimiu `19.75` antes de o segundo lançar o erro. **Um erro que ninguém
captura para o processo inteiro**, imprime isto, e termina com código de saída 1. Num servidor isso
quer dizer que toda requisição em andamento morre junto, que é o assunto da seção sobre erros nos
handlers da aula 5.

## Um erro vindo do sistema

Quando o Node pede algo ao sistema operacional e é recusado, o erro carrega o nome que o próprio
sistema dá ao motivo. Este programa lê um arquivo indicado na linha de comando:

```javascript
// open.js
const fs = require("node:fs");

const file = process.argv[2];
const text = fs.readFileSync(file, "utf8");
console.log(`${file}: ${text.trim()}`);
```

```
ana@dev:~/server/errors$ node open.js prices.txt; echo "exit code $?"
node:fs:440
    return binding.readFileUtf8(path, stringToFlags(options.flag));
                   ^

Error: ENOENT: no such file or directory, open 'prices.txt'
    at Object.readFileSync (node:fs:440:20)
    at Object.<anonymous> (/home/ana/server/errors/open.js:5:17)
    at Module._compile (node:internal/modules/cjs/loader:1706:14)
    at Object..js (node:internal/modules/cjs/loader:1839:10)
    at Module.load (node:internal/modules/cjs/loader:1441:32)
    at Function._load (node:internal/modules/cjs/loader:1263:12)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)
    at node:internal/main/run_main_module:36:49 {
  errno: -2,
  code: 'ENOENT',
  syscall: 'open',
  path: 'prices.txt'
}

Node.js v22.22.0
exit code 1
ana@dev:~/server/errors$ echo "12.50" > prices.txt
ana@dev:~/server/errors$ node open.js prices.txt
prices.txt: 12.50
```

Abaixo da pilha, o Node imprimiu as propriedades do erro. **`code` é a que um programa confere**:
`ENOENT` é o "arquivo ou diretório inexistente" do sistema, e é a mesma string em todo sistema
operacional onde o Node roda, enquanto a redação da mensagem não é. `syscall` diz o que foi pedido,
`open`, e `path` qual arquivo. A aula 8 trata cada um dos códigos comuns; por enquanto, quando um
erro tem `code`, essa é a palavra a procurar.

Erros que vêm do próprio Node, e não do sistema, também têm um código, começando com `ERR_`, como o
`ERR_MODULE_NOT_FOUND` da aula 3. Todos estão listados, um por um, na documentação, que é a próxima
seção.
