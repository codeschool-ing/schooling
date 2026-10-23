---
title: Terminando o que foi começado
version: 1
---

A aula 16 terminou com o `docker stop` levando um quinto de segundo, porque o boxoffice não fazia nada com
o `SIGTERM` e o padrão do Go é sair na hora. Uma compra no meio da sua transação é desfeita pelo banco, e
uma que acabou de fazer commit perde a resposta, então o cliente dela vê um erro numa venda que aconteceu.
**Um desligamento gracioso é a ordem contrária**: parar de aceitar trabalho novo, terminar o trabalho em
andamento, e então sair. Todo deploy para o processo antigo, então este não é um caminho raro; ele roda
toda vez que uma versão nova sai.

## A ordem das coisas

O `main`, na seção 07, espera o sinal com `signal.NotifyContext`, que devolve um contexto que termina no
primeiro `SIGINT` ou `SIGTERM`. Então, em ordem:

1. **A prontidão diz não.** O `draining` é marcado, o `/readyz` responde 503, e um balanceador que pergunta
   para de mandar requisições novas para cá.
2. **O `srv.Shutdown` fecha os listeners**, então nenhuma conexão nova é aceita, fecha as ociosas, e espera
   as ativas terminarem suas requisições, até o timeout de desligamento.
3. **O `GracefulStop` do servidor gRPC** faz o mesmo com as chamadas gRPC, com o mesmo prazo.
4. O servidor de ops para por último, para a prontidão poder ser perguntada até o fim, e o `main` retorna,
   fechando o pool no caminho.

Um segundo sinal durante isso não é mais capturado, porque o `stop` foi chamado depois do primeiro; ele
mata o processo, que é o que quer dizer alguém apertando Ctrl-C duas vezes.

## Streams nunca terminam

O `Shutdown` espera as requisições terminarem, e os streams da aula 13 são requisições feitas para nunca
terminar. **Deixado como está, todo stream aberto seguraria o desligamento até o prazo e então seria
cortado.** O `Shutdown` também não rastreia conexões sequestradas (hijacked), então todo WebSocket seria
simplesmente derrubado quando o `main` retornasse. O `RegisterOnShutdown` roda uma função quando o
desligamento começa, e o hub ganha uma para rodar: o `close` fecha um canal, o `done`, e todo handler de
stream o vigia.

```go
// boxoffice/live.go
package main

import (
	"context"
	"fmt"
	"log/slog"
	"sync"

	"github.com/jackc/pgx/v5/pgxpool"
)

// hub hands each change of an event's availability to everybody watching it.
type hub struct {
	mu   sync.Mutex
	subs map[int]map[chan int]struct{}
	done chan struct{} // closed when the server shuts down
	once sync.Once
}

func newHub() *hub {
	return &hub{subs: map[int]map[chan int]struct{}{}, done: make(chan struct{})}
}

// close tells every stream to end. It is safe to call more than once.
func (h *hub) close() {
	h.once.Do(func() { close(h.done) })
}

// count is how many subscriptions are open, for the metrics.
func (h *hub) count() int {
	h.mu.Lock()
	defer h.mu.Unlock()
	n := 0
	for _, subs := range h.subs {
		n += len(subs)
	}
	return n
}

// subscribe returns a channel of availabilities for one event, and the
// function that ends the subscription.
func (h *hub) subscribe(id int) (chan int, func()) {
	ch := make(chan int, 8)
	h.mu.Lock()
	if h.subs[id] == nil {
		h.subs[id] = map[chan int]struct{}{}
	}
	h.subs[id][ch] = struct{}{}
	h.mu.Unlock()
	return ch, func() {
		h.mu.Lock()
		delete(h.subs[id], ch)
		h.mu.Unlock()
	}
}

func (h *hub) publish(id, available int) {
	h.mu.Lock()
	defer h.mu.Unlock()
	for ch := range h.subs[id] {
		select {
		case ch <- available:
		default: // a watcher that is not keeping up misses this one, and nobody waits for it
		}
	}
}

// listen relays PostgreSQL's availability notifications to the hub until ctx ends.
func listen(ctx context.Context, pool *pgxpool.Pool, h *hub) error {
	conn, err := pool.Acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	if _, err := conn.Exec(ctx, "LISTEN availability"); err != nil {
		return err
	}
	for {
		n, err := conn.Conn().WaitForNotification(ctx)
		if ctx.Err() != nil {
			return nil // shutting down is not a failure
		}
		if err != nil {
			return err
		}
		var id, available int
		if _, err := fmt.Sscan(n.Payload, &id, &available); err != nil {
			slog.Warn("unreadable notification", "payload", n.Payload)
			continue
		}
		h.publish(id, available)
	}
}
```

O `close` usa `sync.Once`, porque fechar um canal já fechado causa panic. O `count` é o que o gauge da
seção 04 lê. E o `listen` agora devolve `nil` quando o contexto dele terminou, já que um desligamento não é
um erro que mereça ser registrado como tal.

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
			case <-h.done:
				return // the server is shutting down; EventSource will reconnect elsewhere
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

O handler de server-sent events retorna, o que encerra a resposta de forma limpa; o `EventSource` reconecta
e, com outra cópia do boxoffice atrás do balanceador, cai nela.

```go
// boxoffice/ws.go
package main

import (
	"context"
	"net/http"
	"time"

	"github.com/coder/websocket"
	"github.com/coder/websocket/wsjson"
)

type availability struct {
	EventID   int `json:"event_id"`
	Available int `json:"available"`
}

// liveSocket sends an event's availability over a WebSocket, now and on every
// change. Pages from site, a host such as tickets.example.com, may open one.
func liveSocket(store Store, h *hub, site string) http.HandlerFunc {
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
		c, err := websocket.Accept(w, r, &websocket.AcceptOptions{
			OriginPatterns: []string{site},
		})
		if err != nil {
			return // Accept has already answered the client
		}
		defer c.CloseNow()

		ctx := c.CloseRead(r.Context()) // nothing is read; a close from the client ends ctx
		send := func(n int) error {
			wctx, cancel := context.WithTimeout(ctx, 5*time.Second)
			defer cancel()
			return wsjson.Write(wctx, c, availability{EventID: id, Available: n})
		}
		if send(e.Seats-e.Sold) != nil {
			return
		}
		for {
			select {
			case <-ctx.Done():
				c.Close(websocket.StatusNormalClosure, "")
				return
			case <-h.done:
				c.Close(websocket.StatusGoingAway, "server shutting down")
				return
			case n := <-ch:
				if send(n) != nil {
					return
				}
			}
		}
	}
}
```

O WebSocket manda um frame de fechamento com status 1001, `GoingAway`, o código que o protocolo define para
um servidor saindo do ar, para o cliente saber que deve reconectar em vez de tratar aquilo como erro.

## Vendo acontecer

Quatro terminais: o servidor, iniciado em primeiro plano desta vez para a saída dele aparecer na tela; um
stream; uma compra enviada devagar, vinte bytes por segundo, para ainda estar em andamento quando o sinal
chegar; e o próprio sinal, seguido de uma verificação de prontidão. O stream:

```
ana@vm:~/boxoffice$ curl -sN localhost:8080/events/1/live; echo "exit $?"
data: 120

exit 0
```

Ele recebeu a disponibilidade atual, e terminou quando o desligamento começou, com status 0 do curl: o
servidor fechou a resposta direito em vez de derrubar a conexão. A compra lenta:

```
ana@vm:~/boxoffice$ curl -s -w ' %{http_code} after %{time_total}s\n' --limit-rate 20 --json '{"quantity": 1, "email": "slow@example.com"}' localhost:8080/events/1/tickets
{"ticket_id":1,"event_id":1,"quantity":1,"email":"slow@example.com","remaining":119}
 201 after 2.200352s
```

**201, depois de 2,2 segundos, mais de um segundo após o sinal.** O sinal e a verificação de prontidão:

```
ana@vm:~/boxoffice$ kill -TERM $(pgrep -x boxoffice); sleep 0.2; curl -s localhost:9100/readyz
{"status":"shutting down"}
```

E o terminal do servidor, que estava rodando ele:

```
ana@vm:~/boxoffice$ BOXOFFICE_MANAGER_TOKEN_FILE=~/.config/boxoffice/manager-token ./boxoffice 2>&1 | cut -c1-200; echo "exit ${PIPESTATUS[0]}"
{"time":"2026-10-22T20:12:57.615841138-03:00","level":"INFO","msg":"starting","version":"dev","config":{"http":"localhost:8080","grpc":"localhost:9090","ops":"localhost:9100","max_conns":10,"write_tim
{"time":"2026-10-22T20:12:57.6236321-03:00","level":"INFO","msg":"grpc listening on 127.0.0.1:9090"}
{"time":"2026-10-22T20:12:57.623719353-03:00","level":"INFO","msg":"boxoffice listening on localhost:8080"}
{"time":"2026-10-22T20:12:59.130443613-03:00","level":"INFO","msg":"shutting down","timeout":"8s"}
{"time":"2026-10-22T20:12:59.130644811-03:00","level":"INFO","msg":"request","request_id":"b2ba5fd8a498ad9d","method":"GET","path":"/events/1/live","status":200,"bytes":11,"duration_ms":1299.89}
{"time":"2026-10-22T20:13:00.140507093-03:00","level":"INFO","msg":"request","request_id":"ba6d47aedaf8a80a","method":"POST","path":"/events/1/tickets","status":201,"bytes":85,"duration_ms":2005.712}
{"time":"2026-10-22T20:13:00.17202297-03:00","level":"INFO","msg":"stopped"}
exit 0
```

Leia os horários. O sinal chegou em :59.130, e a requisição do stream foi registrada no mesmo
milissegundo, encerrada pelo hub. A compra terminou um segundo depois, com o 201 registrado em :00.140, e
só então o processo informou `stopped` e saiu com status 0. **Nada em andamento se perdeu, e nada novo foi
aceito.** O `cut` encurta toda linha para 200 caracteres, o que só a primeira precisava; e o
`PIPESTATUS[0]` é o status de saída do boxoffice, não o do `cut`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 220\" role=\"img\" aria-label=\"Uma linha do tempo do desligamento da seção 06, do sinal em 0 à saída em 1,04 segundo. Em 0, o SIGTERM: a prontidão vira 503, os listeners fecham, e o hub encerra o stream aberto na hora. A compra lenta, que começou 1,0 segundo antes do sinal, segue e recebe 201 em 1,01 segundo. O processo registra stopped e sai com status 0 em 1,04 segundo.\"><defs><marker id=\"gb-l17-shutdown-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M 30 170 L 680 170\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M 116.9 165 L 116.9 175\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"116.9\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">−1.0 s</text><path d=\"M 373.3 165 L 373.3 175\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"373.3\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M 501.5 165 L 501.5 175\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"501.5\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.5 s</text><path d=\"M 640.0 165 L 640.0 175\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"640.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1.04 s</text><rect x=\"116.9\" y=\"112\" width=\"515.4\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"124.9\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">compra lenta, 20 bytes por segundo</text><text x=\"626.3\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">201</text><rect x=\"40.0\" y=\"76\" width=\"333.3\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"48.0\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">stream</text><path d=\"M 373.3 22 L 373.3 72\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><path d=\"M 373.3 142 L 373.3 165\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"379.3\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SIGTERM</text><text x=\"379.3\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">/readyz 503 · listeners fechados · hub fechado</text><path d=\"M 640.0 60 L 640.0 165\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"634.0\" y=\"66\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">stopped, exit 0</text></svg>", "caption": "A execução da seção 06, medida a partir do sinal. Trabalho novo para na hora; o que está em andamento vai até o fim.", "same": ["stream", "stopped, exit 0"]}
```

## Quanto esperar

O timeout de desligamento é de oito segundos por padrão, uma configuração da aula 14 como as outras, e
precisa ser menor que o tempo que a plataforma dá antes de mandar `SIGKILL`: dez segundos no `docker stop`,
trinta no Kubernetes, por padrão. Um processo ainda drenando quando o `SIGKILL` chega perde tudo o que
estava fazendo, e o timeout existe para o boxoffice cortar os últimos retardatários ele mesmo, de forma
limpa, antes.

O Kubernetes acrescenta mais um detalhe: ele tira um pod que está parando do balanceador e manda o sinal
quase no mesmo momento, então por um ou dois segundos ainda chegam requisições depois que o listener
fechou. Uma resposta comum é continuar servindo por alguns segundos depois que a prontidão vira 503, antes
de chamar o `Shutdown`. O boxoffice não faz isso, e numa plataforma que precise, esse atraso é mais uma
configuração.
