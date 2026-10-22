---
title: De onde vem a notícia
version: 1
---

Um lugar é vendido no `Sell`, dentro da transação que a aula 9 escreveu. O lugar óbvio para anunciar a
venda é ali mesmo: depois do commit, avisar todo mundo que está olhando. Isso funciona com um processo e
quebra na primeira mudança de formato. Duas cópias do boxoffice atrás de um balanceador de carga veem cada
uma metade das vendas. O serviço gRPC da aula 10 escreve pelo mesmo store. Um gerente corrigindo uma linha
à mão no `psql` passa por fora do programa inteiro.

**O banco é o único lugar por onde toda venda passa**, e o PostgreSQL sabe anunciar mudanças sozinho. O
`NOTIFY` manda uma mensagem curta num canal com nome; toda sessão que rodou `LISTEN` nesse canal a recebe.
Um gatilho faz o banco mandar uma sempre que `sold` muda, e assim nada em Go precisa se lembrar de fazer
isso:

```sql
-- boxoffice/migrations/00003_availability_notify.sql
-- +goose Up
-- +goose StatementBegin
CREATE FUNCTION notify_availability() RETURNS trigger AS $$
BEGIN
    PERFORM pg_notify('availability', NEW.id || ' ' || (NEW.seats - NEW.sold));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- +goose StatementEnd

CREATE TRIGGER events_availability AFTER UPDATE OF sold ON events
    FOR EACH ROW EXECUTE FUNCTION notify_availability();

-- +goose Down
DROP TRIGGER events_availability ON events;
DROP FUNCTION notify_availability();
```

A função roda depois de todo `UPDATE` que mexe em `sold`, uma vez por linha, e o `pg_notify` enfileira
uma mensagem no canal `availability` com o id do evento e os lugares que restam, como texto: `1 118`. Três
propriedades fazem disso uma boa fonte de notícias, e não só uma fonte cômoda:

- **A mensagem é entregue quando a transação faz commit, e nunca se ela é desfeita.** Uma venda que falhou
  no meio não anuncia nada, então uma página não mostra como vendido um lugar que ainda está à venda.
- **A mensagem diz o que é verdade agora**, quantos lugares restam, e não "mais três vendidos". Quem perdeu
  uma mensagem é corrigido pela seguinte.
- **Não custa infraestrutura nova.** A conexão que o boxoffice já tem é o canal.

O conteúdo da mensagem tem de ficar abaixo de 8000 bytes, e é por isso que ela leva um id e um número, não
o evento inteiro. As marcas `StatementBegin` e `StatementEnd` são do goose. Ele manda uma migration ao
banco um comando de cada vez, cortando nos pontos e vírgulas, e o corpo de uma função está cheio deles;
entre as duas marcas, ele manda tudo como um comando só.

## Um hub dentro do processo

A outra metade é Go. Uma goroutine escuta, e um hub entrega cada mensagem a todo handler que está olhando
aquele evento:

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
}

func newHub() *hub {
	return &hub{subs: map[int]map[chan int]struct{}{}}
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

**O `listen` tira uma conexão do pool e nunca a devolve.** O `LISTEN` pertence a uma sessão do banco, e uma
conexão devolvida ao pool depois dele levaria a inscrição para a consulta que a pegasse emprestada em
seguida. Assim, o pool que a aula 9 dimensionou em dez fica com nove para consultas, e o
`WaitForNotification` dorme na décima até chegar uma mensagem ou o contexto terminar.

O hub é um mapa do id de um evento para os canais dos handlers que o observam. O `subscribe` cria um canal
e o devolve junto com a função que o tira de novo; o `publish` oferece o número a cada canal daquele
evento. **A oferta não espera.** Cada canal guarda oito valores, e um observador cujos oito ainda não foram
lidos perde este. A alternativa é pior: o `publish` segura a trava enquanto envia, então um navegador numa
conexão ruim pararia as notícias de todo mundo. Descartar sai barato aqui porque toda mensagem é o número
inteiro de lugares, e a próxima venda traz o próximo. O que isso custa está na seção 08.

## Vendo acontecer

Compile o boxoffice e inicie-o como antes. Ele aplica a migration nova ao subir:

```
ana@vm:~/boxoffice$ go vet ./... && go build -o boxoffice . && echo built
built
ana@vm:~/boxoffice$ head -4 .server.log
{"time":"2026-10-22T19:35:32.257885238-03:00","level":"INFO","msg":"migration 00003_availability_notify.sql applied in 3.114951ms"}
{"time":"2026-10-22T19:35:32.261131988-03:00","level":"INFO","msg":"boxoffice listening on localhost:8080"}
{"time":"2026-10-22T19:35:32.26119697-03:00","level":"INFO","msg":"grpc listening on 127.0.0.1:9090"}
```

O `psql` também sabe escutar, o que mostra a metade do banco funcionando antes de qualquer Go entrar.
Peça que ele escute e depois durma por dois segundos:

```
ana@vm:~/boxoffice$ psql boxoffice -c 'LISTEN availability' -c 'SELECT pg_sleep(2)'
LISTEN
 pg_sleep 
----------
 
(1 row)

Asynchronous notification "availability" with payload "1 118" received from server process with PID 22518.
```

Enquanto ele dorme, compre dois lugares de um terceiro terminal, como na aula 3:

```sh
curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
```

A notificação aparece depois da pausa, porque o `psql` só procura por elas entre um comando e outro.
**`1 118` é o evento 1 com 118 lugares restantes**, e o id de processo é o do backend do PostgreSQL que
atende a conexão do boxoffice, aquela cujo `UPDATE` disparou o gatilho. O `listen` do próprio boxoffice
recebeu a mesma mensagem no mesmo instante; a próxima seção lhe dá para onde ir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Uma venda vai de buyTickets e Sell ao PostgreSQL, onde o UPDATE dispara um gatilho que chama pg_notify. No commit, a notificação chega ao listen, que segura uma conexão com LISTEN availability. O listen a entrega ao hub, e o hub ao liveEvents, que escreve linhas data numa página com EventSource, e ao liveSocket, que escreve mensagens JSON num cliente WebSocket.\"><defs><marker id=\"gb-l13-flow-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"30\" width=\"150\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">buyTickets</text><text x=\"90\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Sell</text><path d=\"M 165 55 L 213 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l13-flow-ah)\"></path><rect x=\"215\" y=\"15\" width=\"200\" height=\"80\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"315\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UPDATE events</text><text x=\"315\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">pg_notify('availability')</text><path d=\"M 415 55 L 473 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l13-flow-ah)\"></path><text x=\"444\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">commit</text><rect x=\"475\" y=\"30\" width=\"200\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">listen</text><text x=\"575\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">LISTEN availability</text><path d=\"M 575 80 L 575 143\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l13-flow-ah)\"></path><rect x=\"520\" y=\"145\" width=\"110\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">hub</text><path d=\"M 520 158 L 480 158 L 480 137 L 427 137\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l13-flow-ah)\"></path><path d=\"M 520 176 L 480 176 L 480 207 L 427 207\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l13-flow-ah)\"></path><rect x=\"255\" y=\"115\" width=\"170\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"340\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">liveEvents</text><text x=\"340\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">data: 118</text><rect x=\"255\" y=\"185\" width=\"170\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"340\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">liveSocket</text><text x=\"340\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">{\"available\":118}</text><path d=\"M 255 137 L 167 137\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l13-flow-ah)\"></path><path d=\"M 255 207 L 167 207\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l13-flow-ah)\"></path><rect x=\"15\" y=\"115\" width=\"150\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"90\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma página</text><text x=\"90\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">EventSource</text><rect x=\"15\" y=\"185\" width=\"150\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"90\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um cliente</text><text x=\"90\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">WebSocket</text></svg>", "caption": "Toda venda passa pelo banco, então o banco a anuncia. Uma conexão escuta, e o hub entrega o número a cada página aberta.", "same": ["PostgreSQL", "commit"]}
```
