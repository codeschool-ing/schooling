---
title: WebSockets
version: 1
---

Um **WebSocket** começa como uma requisição HTTP com `Upgrade: websocket`. O servidor concorda com um
`101 Switching Protocols`, e daí em diante a conexão TCP deixa de ser HTTP: é um canal de mensagens, texto
ou binárias, em que **qualquer um dos lados pode mandar a qualquer momento**. Conecte o cliente, que diz
olá, e publique um evento enquanto ele escuta:

```
ana@vm:~/lab/live$ $W ws://live-a:8000/ws 3 & sleep 1.5; curl -s -X POST localhost:8001/publish -d "o-1 out for delivery" > /dev/null; wait
a: received 'hello'
a: o-1 out for delivery
```

O servidor respondeu a mensagem do cliente, depois empurrou o evento no momento em que chegou. Essa parte
nos dois sentidos é para o que os WebSockets servem: chat, edição colaborativa, jogos com vários
jogadores, um leilão ao vivo em que todo lance vai e vem. Para uma página de status de pedido, que só
escuta, ele não faz nada que o SSE não faça.

E custa mais para operar, porque saiu do HTTP:

- **Reconectar é trabalho seu.** O `WebSocket` do navegador não reconecta, e não há `Last-Event-ID`; a
  aplicação tem de perceber uma conexão caída, reconectar com backoff, e pedir o que perdeu.
- **Conexões paradas são cortadas.** Balanceadores e proxies fecham conexões quietas por um tempo, muitas
  vezes 60 segundos. Os dois lados mandam **pings** para mantê-la viva e para perceber um par morto; o
  servidor do laboratório pinga a cada 20 segundos (`heartbeat=20`).
- **Toda camada tem de deixá-lo passar.** Alguns proxies e redes corporativas bloqueiam o upgrade, por isso
  bibliotecas como o Socket.IO e o SignalR recorrem ao long polling.
- **Nada de cache, compressão ou códigos de status do HTTP** nas mensagens; o que se parecer com eles é
  construído pela aplicação.
