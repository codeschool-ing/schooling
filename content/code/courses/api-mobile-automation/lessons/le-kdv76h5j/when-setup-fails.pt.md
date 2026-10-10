---
title: Quando a instalação falha
version: 1
---

Instalar é onde a maioria das pessoas desiste de um curso como este, quase sempre por uma linha de
saída que parecia uma catástrofe e era uma coisa pequena. Estas são as falhas que aparecem seguindo
as duas últimas seções, cada uma com o que imprime e o que a corrige. Todas foram provocadas de
propósito, na máquina de onde vêm as transcrições.

## `node: command not found`

O terminal foi aberto antes de o `~/.bashrc` aprender onde o Node mora:

```
ana@laptop:~/boxoffice$ node --version
bash: node: command not found
```

Um terminal lê o `~/.bashrc` uma vez, quando abre. **Abra um terminal novo**, ou rode `source
~/.bashrc` neste. Se um terminal novo ainda não o encontra, `ls /opt/node/bin` diz se a descompactação
funcionou, e `tail -1 ~/.bashrc` mostra se a linha do `export` está lá. No Ubuntu Desktop a mensagem é
mais longa e sugere `sudo apt install nodejs`. Não aceite a sugestão: esse é o Node 18 antigo que a
seção anterior contornou.

## `Failed to connect`

O curl perguntou e ninguém respondeu:

```
ana@laptop:~/boxoffice$ curl localhost:8080/health
curl: (7) Failed to connect to localhost port 8080 after 0 ms: Couldn't connect to server
ana@laptop:~/boxoffice$ echo $?
7
```

O código de saída 7 é o jeito de o curl dizer que a conexão foi recusada, o que significa que
**nada está escutando naquela porta**. O boxoffice não está rodando: o terminal dele foi fechado, ou
um Ctrl-C o parou, ou ele foi iniciado em outro diretório e falhou ali. Olhe o segundo terminal; se a
última linha é um prompt em vez de uma requisição, inicie o servidor de novo.

## `EADDRINUSE`

O boxoffice foi iniciado uma segunda vez enquanto o primeiro ainda rodava, em outro terminal ou numa
aba esquecida:

```
ana@laptop:~/boxoffice$ node boxoffice.mjs
node:events:497
      throw er; // Unhandled 'error' event
      ^

Error: listen EADDRINUSE: address already in use 0.0.0.0:8080
    at Server.setupListenHandle [as _listen2] (node:net:1940:16)
    at listenInCluster (node:net:1997:12)
    at Server.listen (node:net:2102:7)
    at file:///home/ana/boxoffice/boxoffice.mjs:230:4
    at ModuleJob.run (node:internal/modules/esm/module_job:343:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:665:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:117:5)
Emitted 'error' event on Server instance at:
    at emitErrorNT (node:net:1976:8)
    at process.processTicksAndRejections (node:internal/process/task_queues:90:21) {
  code: 'EADDRINUSE',
  errno: -98,
  syscall: 'listen',
  address: '0.0.0.0',
  port: 8080
}

Node.js v22.22.0
```

Leia a primeira linha do erro: `EADDRINUSE`, endereço em uso. Só um programa pode escutar numa porta,
e o primeiro boxoffice já tem a 8080. Ache o terminal onde ele roda e aperte Ctrl-C ali, ou inicie
este em outra porta com `PORT=8081 node boxoffice.mjs` e mande suas requisições para
`localhost:8081`.

## `SyntaxError: Unexpected end of input`

O arquivo termina antes do fim. Este foi salvo de uma colagem que perdeu a última linha:

```
ana@laptop:~/boxoffice$ node boxoffice.mjs
file:///home/ana/boxoffice/boxoffice.mjs:230



SyntaxError: Unexpected end of input
    at compileSourceTextModule (node:internal/modules/esm/utils:346:16)
    at ModuleLoader.moduleStrategy (node:internal/modules/esm/translators:107:18)
    at #translate (node:internal/modules/esm/loader:546:20)
    at afterLoad (node:internal/modules/esm/loader:596:29)
    at ModuleLoader.loadAndTranslate (node:internal/modules/esm/loader:601:12)
    at #createModuleJob (node:internal/modules/esm/loader:624:36)
    at #getJobFromResolveResult (node:internal/modules/esm/loader:343:34)
    at ModuleLoader.getModuleJobForImport (node:internal/modules/esm/loader:311:41)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:664:25)

Node.js v22.22.0
```

O Node lê o arquivo inteiro antes de rodar qualquer parte, então um colchete faltando no final é
apontado no final, `boxoffice.mjs:230`, por mais acima que tenha sido o corte de verdade. **Copie o
arquivo de novo com o botão do bloco** e salve por cima do antigo, em vez de caçar o pedaço que
falta.
