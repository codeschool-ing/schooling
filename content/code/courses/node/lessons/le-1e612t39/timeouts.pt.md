---
title: Timeouts, e o cliente que nunca termina
version: 1
---

**Uma conexão que não manda nada ainda custa algo a um servidor**: um socket, um pouco de memória, um
lugar na lista que o `epoll` vigia. Um cliente que abre centenas de conexões e manda cada requisição
um byte de cada vez, sem nunca terminar, consegue segurar a capacidade de um servidor sem nunca
completar uma requisição. A defesa do Node são três timeouts no objeto do servidor:

```
ana@dev:~/server/native$ node -p 'const s = require("node:http").createServer(); [s.headersTimeout, s.requestTimeout, s.keepAliveTimeout]'
[ 60000, 300000, 5000 ]
```

| configuração | padrão | o que ela limita |
|---|---|---|
| `headersTimeout` | 60 000 ms | quanto tempo um cliente pode levar para mandar a linha da requisição e os cabeçalhos |
| `requestTimeout` | 300 000 ms | quanto tempo ele pode levar para mandar a requisição inteira, com o corpo |
| `keepAliveTimeout` | 5 000 ms | quanto tempo uma conexão ociosa fica aberta, esperando uma próxima requisição |

O terceiro é o `Keep-Alive: timeout=5` que o primeiro servidor da aula 1 mandou: o Node diz ao cliente
quanto tempo vai manter a conexão depois de uma resposta.

## Vendo um disparar

Para ver um timeout sem esperar um minuto, um servidor com o `headersTimeout` em dois segundos, e um
cliente que manda meia linha de requisição e depois nada:

```javascript
// slow.js
import http from "node:http";
import net from "node:net";

const server = http.createServer({ connectionsCheckingInterval: 500 }, (req, res) => res.end("hello\n"));
server.headersTimeout = 2000;
server.requestTimeout = 2000;

server.listen(3000, "127.0.0.1", () => {
  const start = Date.now();
  const socket = net.connect(3000, "127.0.0.1", () => socket.write("GET / HTTP/1.1\r\nHost: loc"));
  socket.on("data", (d) => console.log(`after ${Date.now() - start} ms the server sent:\n${d}`));
  socket.on("close", () => server.close());
});
```

O `node:net` é a camada TCP por baixo do `node:http`, e aqui ele faz o papel de um cliente que escreve
bytes à mão.

```
ana@dev:~/server/native$ node slow.js
after 2504 ms the server sent:
HTTP/1.1 408 Request Timeout
Connection: close
```

**O servidor esperou, depois respondeu `408 Request Timeout` e fechou a conexão.** O Node não vigia
cada conexão ao milissegundo: ele confere todas num timer próprio, a cada
`connectionsCheckingInterval`, que é de 30 segundos a não ser que o servidor seja criado com outro, e
este pede meio segundo. É por isso que a resposta veio um pouco depois dos dois segundos e não neles,
e por que, com o padrão, um timeout de dois segundos pode levar até trinta e dois.

Em produção os padrões são um começo razoável, e um proxy na frente do Node, que o `servers-cache`
monta, costuma impor timeouts mais apertados antes de um cliente lento chegar até ele. O que importa é
saber que eles existem, para que um upload longo que falha em exatamente cinco minutos seja
reconhecido como `requestTimeout` e não caçado no seu código.
