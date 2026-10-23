---
title: Erros que ninguém capturou
version: 1
---

**Um erro lançado que nada captura encerra o processo, e o mesmo faz uma promise rejeitada que
ninguém trata.** A aula 1 mostrou o primeiro. O segundo surpreende mais, porque o código que criou a
promise já seguiu em frente:

```javascript
// reject.js
async function loadPrices() {
  throw new Error("the price list is unreachable");
}

loadPrices(); // nobody waits for it, nobody catches it
setTimeout(() => console.log("one second later"), 1000);
```

```
ana@dev:~/server/loop$ node reject.js; echo "exit code $?"
/home/ana/server/loop/reject.js:3
  throw new Error("the price list is unreachable");
        ^

Error: the price list is unreachable
    at loadPrices (/home/ana/server/loop/reject.js:3:9)
    at Object.<anonymous> (/home/ana/server/loop/reject.js:6:1)
    at Module._compile (node:internal/modules/cjs/loader:1706:14)
    at Object..js (node:internal/modules/cjs/loader:1839:10)
    at Module.load (node:internal/modules/cjs/loader:1441:32)
    at Function._load (node:internal/modules/cjs/loader:1263:12)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)
    at node:internal/main/run_main_module:36:49

Node.js v22.22.0
exit code 1
```

O timer nunca imprimiu. O Node notou uma rejeição sem handler depois que as microtasks rodaram, e
**desde o Node 15 o padrão é tratar isso exatamente como um throw não capturado**: imprimir e sair
com código 1. Conselhos antigos que dizem que uma rejeição não tratada é só um aviso descrevem o Node
14 e anteriores.

A solução é a que a aula 14 do javascript deu para o navegador, e aqui ela importa mais: toda
promise é esperada com `await` ou ganha um `.catch`. O `loadPrices()` sozinho na linha é o bug, mesmo
que `loadPrices` costume dar certo.

## A última linha de defesa

Dois eventos do processo veem esses erros antes de o Node agir:

```javascript
// last-resort.js
process.on("unhandledRejection", (reason) => {
  console.error(`unhandled rejection: ${reason.message}`);
  process.exit(1);
});
process.on("uncaughtException", (err) => {
  console.error(`uncaught exception: ${err.message}`);
  process.exit(1);
});

Promise.reject(new Error("the price list is unreachable"));
setTimeout(() => null.total, 10);
```

```
ana@dev:~/server/loop$ node last-resort.js; echo "exit code $?"
unhandled rejection: the price list is unreachable
exit code 1
```

Só o primeiro erro foi impresso, porque o handler dele encerrou o processo antes de o timer rodar.
**Os dois handlers registram e saem, e essa é a única coisa segura para eles fazerem.** Depois de
uma exceção não capturada o programa está num estado que ninguém planejou: uma requisição respondida
pela metade, um arquivo escrito pela metade, uma trava nunca liberada. Um handler que registra e
segue mantém um processo quebrado atendendo tráfego. Registrar o que aconteceu e sair, para que
quem reinicia o processo comece um limpo, é o padrão; a aula 10 trata de quem faz o reinício.
