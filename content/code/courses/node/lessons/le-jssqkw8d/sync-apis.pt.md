---
title: As funções Sync, e quando elas estão certas
version: 1
---

**A maior parte do `node:fs` vem em duas formas: uma que entrega o trabalho ao pool e chama você de
volta, e uma terminada em `Sync` que faz o trabalho na thread principal e devolve a resposta.** O
`readFileSync` é mais simples de escrever, e enquanto ele roda, nada mais no processo roda.

Isso nem sempre está errado. **Na inicialização nada mais está acontecendo ainda**, então ler um
arquivo de configuração ou um certificado com `readFileSync` antes de o servidor escutar não custa
nada a ninguém. Dentro de um handler de requisição custa a todas as requisições do processo, pelo
tempo que o disco levar. No SSD de um notebook isso são microssegundos; num disco de rede ocupado em
produção pode ser os dois segundos da seção anterior.

## Uma flag que as encontra

O `node --trace-sync-io` imprime um aviso, com stack trace, toda vez que uma função síncrona roda
depois da primeira volta do loop — ou seja, em todo lugar menos na inicialização. Este servidor lê o
banner uma vez na inicialização e o mesmo arquivo de novo a cada requisição. `echo "hello" > motd.txt`
cria o arquivo que ele lê:

```javascript
// motd.js: the message of the day, read from a file.
const fs = require("node:fs");
const http = require("node:http");

const banner = fs.readFileSync("motd.txt").toString(); // once, at start-up

http
  .createServer((req, res) => {
    const motd = fs.readFileSync("motd.txt").toString(); // on every request
    res.end(banner === motd ? motd : `${motd}(changed since start-up)\n`);
  })
  .listen(3000, "127.0.0.1");
```

```
ana@dev:~/server/loop$ node --trace-sync-io motd.js
(node:13168) WARNING: Detected use of sync API
    at openSync (node:fs:560:18)
    at readFileSync (node:fs:444:35)
    at /home/ana/server/loop/motd.js:9:21
    at emit (node:events:519:28)
    at parserOnIncoming (node:_http_server:1186:12)
    at parserOnHeadersComplete (node:_http_common:122:17)

(node:13168) WARNING: Detected use of sync API
    at tryStatSync (node:fs:390:25)
    at readFileSync (node:fs:446:17)
    at /home/ana/server/loop/motd.js:9:21
    at emit (node:events:519:28)
    at parserOnIncoming (node:_http_server:1186:12)
    at parserOnHeadersComplete (node:_http_common:122:17)

(node:13168) WARNING: Detected use of sync API
    at readSync (node:fs:739:18)
    at tryReadSync (node:fs:416:20)
    at readFileSync (node:fs:462:19)
    at /home/ana/server/loop/motd.js:9:21
    at emit (node:events:519:28)
    at parserOnIncoming (node:_http_server:1186:12)
    at parserOnHeadersComplete (node:_http_common:122:17)

(node:13168) WARNING: Detected use of sync API
    at closeSync (node:fs:517:11)
    at readFileSync (node:fs:479:8)
    at /home/ana/server/loop/motd.js:9:21
    at emit (node:events:519:28)
    at parserOnIncoming (node:_http_server:1186:12)
    at parserOnHeadersComplete (node:_http_common:122:17)

^C
```

Esse é o terminal do servidor depois de um `curl http://127.0.0.1:3000/` vindo do outro. A leitura
da inicialização não imprimiu nada, como prometido. **A leitura no handler imprimiu quatro avisos**,
porque o `readFileSync` são quatro chamadas de sistema: open, stat, read e close. A linha que cita o
`motd.js` é a que precisa ser corrigida.

## O que a flag não vê

Escreva as mesmas duas leituras com uma codificação, `readFileSync("motd.txt", "utf8")`, que é como
a maioria do código as escreve. A linha do `sed` abaixo faz essa cópia do arquivo, o `grep` conta as
duas linhas que ela mudou, e com a cópia rodando no primeiro terminal, o `curl` pergunta uma vez:

```
ana@dev:~/server/loop$ sed 's/("motd.txt").toString()/("motd.txt", "utf8")/' motd.js > motd-utf8.js
ana@dev:~/server/loop$ grep -c utf8 motd-utf8.js
2
ana@dev:~/server/loop$ curl -s http://127.0.0.1:3000/
hello
```

No primeiro terminal, o servidor não imprimiu nada antes de o Ctrl-C pará-lo:

```
ana@dev:~/server/loop$ node --trace-sync-io motd-utf8.js
^C
```

**Nada.** No Node 22, ler um arquivo como texto com uma codificação passa por um caminho interno
mais rápido que a flag não vigia, e o handler continua tão síncrono quanto antes. Vale rodar a flag,
e o silêncio dela não é prova. O hábito que é prova é o que este curso mantém: **`Sync` na
inicialização, a forma com promise ou callback em todo o resto.** A aula 8 usa a forma com promise,
`node:fs/promises`.
