---
title: O processo, e os sinais que ele recebe
version: 1
---

**Todo `node` que você inicia é um processo: um programa rodando, com um número próprio, a memória
que recebeu e um pai que o iniciou.** O `process` é a visão que o Node tem disso, e vale ver algumas
das propriedades dele uma vez. Os programas desta aula ficam numa pasta própria, `~/server/procs`:

```javascript
// proc.js: what a process knows about itself.
console.log("pid", process.pid, "started by", process.ppid);
console.log("node", process.version, "on", process.platform, process.arch);
console.log("arguments", process.argv.slice(2));
console.log("folder", process.cwd());
const { rss, heapUsed } = process.memoryUsage();
console.log(`memory: ${Math.round(rss / 2 ** 20)} MB in all, ${Math.round(heapUsed / 2 ** 20)} MB of JavaScript objects`);
console.log("running for", process.uptime().toFixed(3), "s");
```

```
ana@dev:~/server/procs$ node proc.js one two
pid 14498 started by 14496
node v22.22.0 on linux x64
arguments [ 'one', 'two' ]
folder /home/ana/server/procs
memory: 42 MB in all, 4 MB of JavaScript objects
running for 0.014 s
ana@dev:~/server/procs$ node -e 'process.exitCode = 3'; echo "exit code $?"
exit code 3
```

O **pid** é o número do processo, e o **ppid** é o do pai, aqui o shell. O `rss` é toda a memória que
o processo ocupa, runtime incluído, e o `heapUsed` é a parte que os seus objetos ocupam: um Node que
não fez nada já ocupa uns 40 MB. **O código de saída é a última palavra do processo**: 0 para sucesso,
qualquer outro para falha, e o `process.exitCode` o define sem parar nada, então o programa termina
quando o trabalho dele termina e informa o código nessa hora. O `process.exit(code)` para na hora,
com escritas e timers ainda pendentes, e é por isso que este curso só recorre a ele quando não há mais
nada a perder.

## Sinais

**Um sinal é uma mensagem que o sistema operacional entrega a um processo de fora**, e é assim que se
pede a um processo que pare. Quatro importam para um servidor:

| sinal | quem manda | o programa pode tratar? |
|---|---|---|
| `SIGINT` | o Ctrl-C no terminal | sim |
| `SIGTERM` | o `kill`, e todo gerenciador de serviço que para um serviço | sim |
| `SIGHUP` | o terminal fechando | sim |
| `SIGKILL` | `kill -KILL`, ou `kill -9` | **não**: o processo é encerrado pelo sistema |

O padrão do Node para os três primeiros é sair. Um programa pode escutá-los no lugar disso, e este
escuta e não faz nada, para mostrar que os ouve:

```javascript
// signals.js: a program that says which signal it was sent.
console.log(`pid ${process.pid}: waiting`);
for (const sig of ["SIGINT", "SIGTERM", "SIGHUP"]) {
  process.on(sig, () => console.log(`got ${sig}, and carrying on`));
}
setInterval(() => {}, 1000);
```

Rode-o num terminal e mande sinais a ele de um segundo terminal, com o pid que ele imprimiu:

```
ana@dev:~/server/procs$ kill -INT 14529
ana@dev:~/server/procs$ kill -TERM 14529
ana@dev:~/server/procs$ kill -HUP 14529
ana@dev:~/server/procs$ kill -KILL 14529
```

```
ana@dev:~/server/procs$ node signals.js; echo "exit code $?"
pid 14529: waiting
got SIGINT, and carrying on
got SIGTERM, and carrying on
got SIGHUP, and carrying on
bash: line 1: 14529 Killed                  node signals.js
exit code 137
```

**O `SIGKILL` não pode ser ouvido**: o programa não roda nem mais uma linha, e o shell informa o
código de saída 137, que é 128 mais o número do sinal, 9. Um programa que ignorasse o `SIGTERM` como
este ignora seria morto assim por todo gerenciador de serviço depois de uma espera, no meio de uma
escrita. A próxima seção é o que um servidor faz com o `SIGTERM` em vez disso.
