---
title: Um primeiro servidor
version: 1
---

**Um servidor web é um programa que espera uma requisição e escreve uma resposta.** O Node tem um
na biblioteca padrão, então o primeiro não precisa de nada instalado. Crie uma pasta para ele e
salve isto como `~/server/hello/hello.mjs`:

```javascript
// hello.mjs
import http from "node:http";

const server = http.createServer((request, response) => {
  console.log(request.method, request.url);
  response.end(`hello from Node ${process.version}, you asked for ${request.url}\n`);
});

server.listen(3000, "127.0.0.1", () => {
  console.log("listening on http://127.0.0.1:3000");
});
```

Você ainda não precisa acompanhar cada linha; a aula 5 desmonta isto. Em linhas gerais, o
`createServer` recebe uma função que o Node chama uma vez **para cada requisição**, com a requisição
e a resposta como os dois argumentos. O `listen` abre a porta 3000 em `127.0.0.1` e chama a própria
função quando a porta está aberta. O arquivo termina em `.mjs` porque usa `import`; a aula 3 trata
de por que essa terminação importa.

## Dois terminais

Um servidor não termina. Ele fica ali esperando, então precisa de um terminal só para ele. No
primeiro, vá até a pasta e inicie-o:

```
ana@dev:~/server/hello$ node hello.mjs
listening on http://127.0.0.1:3000
```

O terminal agora está ocupado; o prompt não volta. Abra um segundo terminal e peça algo ao
servidor:

```
ana@dev:~/server/hello$ curl -s http://127.0.0.1:3000/
hello from Node v22.22.0, you asked for /
ana@dev:~/server/hello$ curl -si http://127.0.0.1:3000/anything
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:19:57 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Content-Length: 50

hello from Node v22.22.0, you asked for /anything
```

O `curl` mandou uma requisição e imprimiu o corpo da resposta; o `-s`, de silent, impede que ele
desenhe uma barra de progresso quando a saída não é uma tela. Com `-i` ele imprime também a linha de
status e os cabeçalhos da resposta, e **o Node escreveu todos esses cabeçalhos sozinho**: a data, o
tamanho do corpo, e dois que dizem que a conexão pode continuar aberta para a próxima requisição. A
aula 5 diz para que serve cada um.

De volta ao primeiro terminal, o servidor imprimiu uma linha por requisição, e o **Ctrl-C** o
parou:

```
ana@dev:~/server/hello$ node hello.mjs
listening on http://127.0.0.1:3000
GET /
GET /anything
^C
```

## Um programa por porta

Uma porta pertence a um programa de cada vez. Inicie o servidor enquanto outra cópia ainda está
rodando, e a segunda falha antes de servir qualquer coisa:

```
ana@dev:~/server/hello$ node hello.mjs
node:events:497
      throw er; // Unhandled 'error' event
      ^

Error: listen EADDRINUSE: address already in use 127.0.0.1:3000
    at Server.setupListenHandle [as _listen2] (node:net:1940:16)
    at listenInCluster (node:net:1997:12)
    at node:net:2206:7
    at process.processTicksAndRejections (node:internal/process/task_queues:90:21)
Emitted 'error' event on Server instance at:
    at emitErrorNT (node:net:1976:8)
    at process.processTicksAndRejections (node:internal/process/task_queues:90:21) {
  code: 'EADDRINUSE',
  errno: -98,
  syscall: 'listen',
  address: '127.0.0.1',
  port: 3000
}

Node.js v22.22.0
```

**`EADDRINUSE`, endereço em uso, é o erro que você mais vai encontrar neste curso.** Quase sempre
significa que uma cópia anterior do servidor continua rodando em outro terminal. Encontre esse
terminal e aperte Ctrl-C nele. O resto da mensagem é um stack trace, que é o assunto da seção depois
da próxima.
