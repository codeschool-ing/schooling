---
title: Server-sent events, só com net/http
version: 1
---

Server-sent events são um `GET` comum cuja resposta nunca termina. O servidor responde com o tipo de
conteúdo `text/event-stream` e depois escreve mensagens conforme elas acontecem, cada uma uma linha
`data:` seguida de uma linha vazia:

```
data: 118

data: 115

```

Um navegador lê esse fluxo com o `EventSource`, que já vem embutido, e chama uma função a cada mensagem.
Este é todo o lado da página, dado um elemento `seatsLeft` onde escrever o número:

```javascript
const live = new EventSource("/events/1/live");
live.onmessage = (e) => { seatsLeft.textContent = e.data; };
```

**Se a conexão cai, o `EventSource` a abre de novo sozinho**, alguns segundos depois. O formato também
tem linhas `id:`, para que um navegador que se reconecta diga qual foi a última mensagem que viu, e
linhas `event:`, para dar nome a vários tipos de mensagem num mesmo fluxo. O boxoffice não precisa de
nenhuma das duas: toda mensagem é o número inteiro de lugares restantes, então a primeira mensagem depois
de uma reconexão é tudo de que a página precisa.

## O handler

```go
// boxoffice/sse.go
package main

import (
	"fmt"
	"net/http"
	"time"
)

// liveEvents streams an event's availability as server-sent events.
func liveEvents(store Store, h *hub) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := pathID(w, r)
		if !ok {
			return
		}
		ch, unsubscribe := h.subscribe(id) // before reading, so no sale falls between the two
		defer unsubscribe()
		e, err := store.Get(r.Context(), id)
		if err != nil {
			fail(w, err)
			return
		}

		rc := http.NewResponseController(w)
		rc.SetWriteDeadline(time.Time{}) // this response is meant to outlive WriteTimeout
		w.Header().Set("Content-Type", "text/event-stream")
		w.Header().Set("Cache-Control", "no-store")
		fmt.Fprintf(w, "data: %d\n\n", e.Seats-e.Sold)
		rc.Flush()
		for {
			select {
			case <-r.Context().Done():
				return
			case n := <-ch:
				fmt.Fprintf(w, "data: %d\n\n", n)
				if err := rc.Flush(); err != nil {
					return
				}
			}
		}
	}
}
```

Leia-o em quatro passos.

- **Ele se inscreve antes de ler.** A primeira mensagem é a disponibilidade como está, para que uma página
  aberta entre duas vendas não fique em branco até a próxima. Ler primeiro e se inscrever depois deixaria
  uma brecha em que uma venda não está em nenhum dos dois, e essa página mostraria um número velho até a
  venda seguinte. Esta ordem, no pior caso, entrega o mesmo número duas vezes.
- **`SetWriteDeadline(time.Time{})` suspende o `WriteTimeout` da aula 1 para esta resposta.** A seção 08
  da aula 1 fixou dez segundos como o máximo que uma resposta tem para ser escrita, e prometeu que esta
  rota seria a exceção. O tempo zero quer dizer sem prazo. Todas as outras rotas mantêm os seus dez
  segundos.
- **`Flush` envia agora o que já foi escrito**, em vez de quando o buffer enche ou o handler retorna, o que
  neste handler não acontece nunca. Sem ele, o navegador ficaria um bom tempo sem receber nada.
- **`r.Context().Done()` encerra o laço quando o visitante sai.** Fechar a aba fecha a conexão, o net/http
  cancela o contexto da requisição, e o `unsubscribe` adiado tira o canal do hub.

Tanto `SetWriteDeadline` quanto `Flush` pertencem à conexão, e o handler não tem nas mãos o writer da
conexão: tem o `statusRecorder` da aula 2, que o embrulha. O `http.ResponseController` acha o verdadeiro
chamando `Unwrap`, que é o método que a seção 03 da aula 2 acrescentou ao `statusRecorder` para esta aula.

## Um fluxo no terminal

A seção 05 põe a rota no `routes.go` ao lado da do WebSocket. Com as duas no lugar, o `curl -N` desliga o
buffer do próprio curl e imprime cada mensagem quando ela chega:

```
ana@vm:~/boxoffice$ curl -sN localhost:8080/events/1/live
data: 118

data: 115

data: 114
```

Enquanto ele rodava, duas compras foram feitas de outro terminal, com onze segundos entre elas:

```
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 3, "email": "rui@example.com"}' localhost:8080/events/1/tickets
{"ticket_id":2,"event_id":1,"quantity":3,"email":"rui@example.com","remaining":115}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 1, "email": "bea@example.com"}' localhost:8080/events/1/tickets
{"ticket_id":3,"event_id":1,"quantity":1,"email":"bea@example.com","remaining":114}
```

O 118 chegou na hora, o 115 com os três lugares do Rui e o 114 com o da Bea. O fluxo durou catorze
segundos, até o curl ser parado. **Isso passa dos dez que o `WriteTimeout` permite**, então o prazo
suspenso cumpriu seu papel; o log de acesso da aula 12, mostrado na seção 05, registra a requisição com
pouco menos de 14.000 milissegundos e 33 bytes, as três mensagens de onze bytes cada.

Um proxy na frente do servidor desfaz tudo isso se guardar a resposta num buffer até ela terminar, o que
para esta resposta quer dizer para sempre. O nginx, por exemplo, faz buffer por padrão e precisa ser
instruído a não fazer nessas rotas. Se os eventos chegam todos juntos quando a conexão fecha, um buffer em
algum ponto do caminho é a primeira coisa a procurar.
