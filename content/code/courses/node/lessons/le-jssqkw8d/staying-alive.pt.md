---
title: Quando um processo decide que terminou
version: 1
---

**Um processo Node termina quando o loop não tem mais nada para esperar.** Não quando o arquivo
acaba: o arquivo acaba muito antes de a maioria dos programas terminar. O que mantém o loop andando é
qualquer coisa que ainda possa produzir um callback — um timer, um servidor aberto, um socket, uma
leitura de arquivo pendente — e a libuv chama cada um desses de **handle** ou **request**
*referenciado*.

```javascript
// alive.js
const timer = setInterval(() => console.log("tick"), 1000);
if (process.argv[2] === "unref") timer.unref();

process.on("beforeExit", () => console.log("beforeExit: nothing left to wait for"));
process.on("exit", (code) => console.log(`exit with code ${code}`));
console.log("end of the file");
```

```
ana@dev:~/server/loop$ timeout 3.5 node alive.js; echo "exit code $?"
end of the file
tick
tick
tick
exit code 124
```

O intervalo mantém o processo vivo enquanto existir. O `timeout 3.5` o parou de fora depois de três
ticks, e o código de saída 124 é o jeito do `timeout` dizer que precisou fazer isso. Nenhum dos dois
eventos imprimiu: **um processo morto de fora não roda nada do próprio código de saída**, que é o
assunto da seção da aula 10 sobre encerrar direito.

## unref

O `timer.unref()` diz ao loop para não contar este timer ao decidir se continua vivo. O timer ainda
dispara se o processo por acaso estiver rodando; ele só não o mantém rodando:

```
ana@dev:~/server/loop$ node alive.js unref
end of the file
beforeExit: nothing left to wait for
exit with code 0
```

Sem mais nada para esperar, o loop terminou na hora. O **`beforeExit`** disparou porque o loop
esvaziou; um handler ali pode agendar mais trabalho, e o processo continua se agendar. O **`exit`**
disparou por último, e nada assíncrono pode acontecer dentro dele, então ele é o lugar de uma última
linha de log e de mais nada. Servidores, sockets e processos filhos têm todos um `unref()` com o
mesmo sentido. É assim que um timer em segundo plano que despeja estatísticas evita manter vivo um
programa que já terminou.

## O quebra-cabeça ao contrário

Um programa que devia terminar e não termina tem algo ainda referenciado: uma conexão de banco que
ninguém fechou, um `setInterval` que ninguém limpou, um servidor ainda escutando. Um teste que nunca
acaba é o sintoma comum, e o test runner da aula 4 vai mostrá-lo a você. Achar o culpado começa por
listar o que você abriu, porque o loop do Node não sai enquanto qualquer coisa disso ainda estiver
lá.
