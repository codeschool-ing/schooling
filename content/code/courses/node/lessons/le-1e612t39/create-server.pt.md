---
title: Escutando numa porta
version: 1
---

**O `http.createServer(handler)` cria um servidor, e o `server.listen(porta, host)` abre a porta.** O
primeiro retorna na hora e não abre nada; o segundo pede a porta ao sistema operacional, e o callback
roda quando a recebe. Todo projeto em `~/server/native` diz `"type": "module"`, então faça disso o
`package.json` dele antes de qualquer coisa:

```
ana@dev:~/server/native$ echo '{ "name": "native", "private": true, "type": "module" }' > package.json
```

```javascript
// listen.js
import http from "node:http";

const server = http.createServer((req, res) => res.end("hello\n"));

server.listen(Number(process.argv[2] ?? 3000), process.argv[3] ?? "127.0.0.1", () => {
  console.log("listening on", server.address());
});
```

## Qual endereço

O host decide **quem consegue alcançar o servidor**, e é o argumento de maior consequência desta
aula:

| host | quem consegue se conectar |
|---|---|
| `127.0.0.1` | só programas deste computador |
| `0.0.0.0` | qualquer um que alcance algum endereço que este computador tenha, em qualquer rede em que ele esteja |
| deixar de fora | o Node escuta em todos os endereços, IPv6 incluído, o mesmo que `0.0.0.0` e mais amplo |

**Todo servidor deste curso escuta em `127.0.0.1`.** Um servidor de desenvolvimento em `0.0.0.0` num
notebook num café é um servidor com que qualquer pessoa do café consegue falar, com as rotas de
depuração que ele tiver. Em produção um processo costuma ficar atrás de um proxy na mesma máquina, e
escuta em `127.0.0.1` para ele, o que o curso `servers-cache` monta; dentro de um contêiner ele precisa
escutar em `0.0.0.0`, porque o loopback do próprio contêiner não é onde as requisições chegam, e o
curso `docker` diz por quê.

## Porta 0

A porta 0 significa *qualquer porta livre*, e o sistema operacional escolhe uma:

```
ana@dev:~/server/native$ node listen.js 0
listening on { address: '127.0.0.1', family: 'IPv4', port: 35755 }
^C
```

O `server.address()` diz qual porta foi dada. Um teste usa isso, para que dois arquivos de teste
rodando ao mesmo tempo nunca briguem pela porta 3000. No Linux, portas abaixo de 1024 exigem root, e é
por isso que servidores de desenvolvimento moram em 3000 e 8080 e não em 80. O `Ctrl-C` o para.
