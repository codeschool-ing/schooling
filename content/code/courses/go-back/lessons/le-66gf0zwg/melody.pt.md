---
title: Melody, um hub que você não escreve
version: 1
---

A seção 03 escreveu um hub: um conjunto de conexões, um jeito de entrar e sair, e um envio para todas elas
que não espera pelas lentas. Quase todo servidor de WebSocket tem um, e o **Melody** é esse hub como
biblioteca. Ele fica sobre o gorilla/websocket e dá sessões, broadcasts e uma função para chamar quando
algo acontece.

A menor coisa que vale a pena construir com ele é uma sala, onde toda mensagem que alguém manda vai para
todo mundo. É um programa à parte, em `~/room`:

```go
// room/main.go
package main

import (
	"log"
	"net/http"

	"github.com/olahol/melody"
)

func main() {
	m := melody.New()
	m.HandleConnect(func(s *melody.Session) {
		log.Printf("joined: %d in the room", m.Len())
	})
	m.HandleMessage(func(s *melody.Session, msg []byte) {
		m.Broadcast(msg)
	})
	m.HandleDisconnect(func(s *melody.Session) {
		log.Printf("left: %d in the room", m.Len())
	})

	mux := http.NewServeMux()
	mux.HandleFunc("GET /room", func(w http.ResponseWriter, r *http.Request) {
		m.HandleRequest(w, r)
	})
	log.Fatal(http.ListenAndServe("localhost:8081", mux))
}
```

Três funções descrevem a sala. `HandleConnect` e `HandleDisconnect` registram quantos há, e
`HandleMessage` manda o que chegar para todas as sessões, inclusive a de quem enviou. `HandleRequest` faz o
upgrade e depois mantém a sessão até ela terminar.

```
ana@vm:~/room$ go mod init example.com/room
go: creating new go.mod: module example.com/room
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/room$ go mod tidy
go: finding module for package github.com/olahol/melody
go: found github.com/olahol/melody in github.com/olahol/melody v1.4.0
```

Com a sala rodando em outro terminal, dois clientes da seção 05 entram nela: o primeiro só escuta, por dois
segundos, e o segundo entra meio segundo depois e diz uma coisa:

```
ana@vm:~/room$ ~/boxoffice/watchws ws://localhost:8081/room 2s
connected: 101 Switching Protocols
19:36:01 doors open at 19:00
stopped: context deadline exceeded
ana@vm:~/room$ ~/boxoffice/watchws ws://localhost:8081/room 1s 'doors open at 19:00'
connected: 101 Switching Protocols
19:36:01 doors open at 19:00
stopped: context deadline exceeded
```

Os dois receberam a mensagem, o segundo porque o `Broadcast` inclui quem enviou; o `BroadcastOthers` deixa
quem enviou de fora. O log da própria sala conta as entradas e saídas:

```
ana@vm:~/room$ cat .server.log
2026/10/22 19:36:00 joined: 1 in the room
2026/10/22 19:36:01 joined: 2 in the room
2026/10/22 19:36:02 left: 1 in the room
2026/10/22 19:36:02 left: 0 in the room
```

## O que ele decide por você

Uma biblioteca que guarda conexões toma as decisões que a seção 03 teve de tomar, e vale lê-las antes de
confiar nela. Estes são os padrões do Melody, do `config.go` dele:

| configuração | padrão | o que quer dizer |
|---|---|---|
| `MessageBufferSize` | 256 | mensagens esperando por sessão; passando disso, as novas são descartadas e o handler de erro é chamado |
| `WriteWait` | 10 s | o tempo que uma única escrita tem |
| `PingPeriod` e `PongWait` | 54 s e 60 s | um ping a cada 54 segundos, e uma sessão calada por 60 é fechada |
| `MaxMessageSize` | 512 bytes | uma mensagem maior vinda de um cliente fecha a conexão dele |

**O buffer que descarta é a mesma decisão da seção 03**, tomada com 256 em vez de 8. Os pings são algo que
o handler do boxoffice não faz, e a seção 08 explica por que eles importam.

**Um padrão está errado para produção.** O `melody.New` monta o upgrader com um `CheckOrigin` que aceita
qualquer origem, o oposto do padrão do coder/websocket, então a página de qualquer site entra na sala.
Antes de um servidor Melody encarar a internet, ele ganha uma verificação própria:

```go
m.Upgrader.CheckOrigin = func(r *http.Request) bool {
	return r.Header.Get("Origin") == "https://tickets.example.com"
}
```

## Qual dos dois

**O Melody se encaixa quando o formato é salas e broadcasts**: chats, um painel ao vivo que todo
espectador vê igual, o saguão de um jogo. O `BroadcastFilter` envia para as sessões que uma função
escolhe, e `Set` e `Get` guardam valores numa sessão, como o evento que um espectador observa, então o hub
do boxoffice se escreveria com ele em poucas linhas. O coder/websocket se encaixa quando cada conexão é uma
conversa própria com um handler, como na seção 05, onde um contexto encerra tudo e não há sala para
administrar. Os dois ficam a poucas centenas de linhas dos bytes no fio, e trocar de um para o outro depois
é coisa de uma tarde.
