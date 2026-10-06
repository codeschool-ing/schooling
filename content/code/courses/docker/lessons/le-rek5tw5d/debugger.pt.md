---
title: Um depurador, por uma porta
version: 1
---

**Um depurador se liga a um programa rodando por uma conexão, e num container essa conexão é mais uma
porta.** O Node tem um embutido: o `--inspect` abre um endpoint de depuração que as ferramentas de
desenvolvedor do Chrome e o VS Code falam.

```
ana@vm:~$ docker run -d --name hello -v "$PWD/hello":/app -w /app -p 127.0.0.1:3000:3000 -p 127.0.0.1:9229:9229 node:24-alpine node --watch --inspect=0.0.0.0:9229 server.js
341c613ed741d55966b4fcd68c8b8551cd1a97532adde8d3cf92ad9dc97a61c2
ana@vm:~$ docker logs hello 2>&1 | head -2
Debugger listening on ws://0.0.0.0:9229/c2189153-c10b-4126-9732-df71aed83d0c
For help, see: https://nodejs.org/learn/getting-started/debugging
ana@vm:~$ curl -s localhost:9229/json/list | jq ".[] | {title, url, webSocketDebuggerUrl}"
{
  "title": "server.js",
  "url": "file:///app/server.js",
  "webSocketDebuggerUrl": "ws://localhost:9229/c2189153-c10b-4126-9732-df71aed83d0c"
}
```

Dois detalhes o tornam alcançável, e um o mantém seguro:

- **`--inspect=0.0.0.0:9229` dentro do container.** Por padrão o Node escuta o depurador em
  `127.0.0.1`, e dentro de um container esse é o loopback do próprio container (aula 23), que uma porta
  publicada nunca alcança.
- **`-p 127.0.0.1:9229:9229` no host.** O endpoint aparece em `/json/list`, com o endereço WebSocket a
  que um editor se conecta.
- **O lado do host fica no endereço de loopback.** Um depurador consegue ler qualquer variável e rodar
  qualquer código no programa: uma porta de depuração aberta num endereço de rede entrega isso a quem a
  alcançar. É uma flag de desenvolvimento, e nunca aparece na imagem nem no arquivo do Compose que vão
  para produção.

Ligar-se a ele é feito no editor: a configuração "Attach" do VS Code com a porta 9229, ou o
`chrome://inspect` do Chrome, os dois apontando para `localhost:9229`. **Esse passo não foi executado no
laboratório**, que não tem editor gráfico; o que a captura mostra é o endpoint a que eles se conectam.

## Para Go

O depurador do Go é o **Delve**, `dlv`, e funciona do mesmo jeito: `dlv debug --headless --listen=:2345`
num container de desenvolvimento feito a partir da `golang:1.25` com o Delve instalado, a porta
publicada no endereço de loopback, e o editor se ligando a ela. Também não foi executado aqui, já que
instalar o Delve precisa da rede que os containers do laboratório não têm. O `dlv debug` compila o
próprio programa, sem otimizações, para as variáveis não sumirem na otimização e as linhas baterem com o
que o depurador mostra. Um binário feito assim é mais lento e maior, mais um motivo para uma montagem de
depuração morar num arquivo de desenvolvimento e nunca na imagem que vai para produção.
