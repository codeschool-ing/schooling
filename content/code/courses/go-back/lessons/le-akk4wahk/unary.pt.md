---
title: O servidor e uma chamada unária
version: 1
---

O servidor é um tipo Go que satisfaz o `SeatsServer` gerado. Os três métodos estão num arquivo só,
porque compartilham os auxiliares; esta seção lê o começo dele e o `GetEvent`, e as duas seguintes leem
o resto.

```go
// boxoffice/grpc.go
package main

import (
	"context"
	"errors"
	"io"
	"log"
	"time"

	"example.com/boxoffice/internal/seatspb"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// seatsStore is what the gRPC service needs: the Store, and a way to check a ticket.
type seatsStore interface {
	Store
	HasTicket(ctx context.Context, id int) (bool, error)
}

type seatsServer struct {
	seatspb.UnimplementedSeatsServer
	store seatsStore
}

// toStatus turns an error from the store into a gRPC status.
func toStatus(err error) error {
	switch {
	case errors.Is(err, ErrNotFound):
		return status.Error(codes.NotFound, err.Error())
	case errors.Is(err, context.Canceled), errors.Is(err, context.DeadlineExceeded):
		return status.FromContextError(err).Err()
	default:
		log.Printf("unexpected error: %v", err)
		return status.Error(codes.Internal, "internal error")
	}
}

func (s *seatsServer) GetEvent(ctx context.Context, req *seatspb.GetEventRequest) (*seatspb.Event, error) {
	e, err := s.store.Get(ctx, int(req.GetId()))
	if err != nil {
		return nil, toStatus(err)
	}
	return &seatspb.Event{Id: int32(e.ID), Name: e.Name, Seats: int32(e.Seats), Sold: int32(e.Sold)}, nil
}

func (s *seatsServer) Watch(req *seatspb.WatchRequest, stream grpc.ServerStreamingServer[seatspb.Availability]) error {
	ctx := stream.Context()
	tick := time.NewTicker(500 * time.Millisecond)
	defer tick.Stop()
	last := -1
	for {
		e, err := s.store.Get(ctx, int(req.GetEventId()))
		if err != nil {
			return toStatus(err)
		}
		if left := e.Seats - e.Sold; left != last {
			if err := stream.Send(&seatspb.Availability{EventId: int32(e.ID), Available: int32(left)}); err != nil {
				return err
			}
			last = left
		}
		select {
		case <-ctx.Done():
			return toStatus(ctx.Err())
		case <-tick.C:
		}
	}
}

func (s *seatsServer) Scan(stream grpc.ClientStreamingServer[seatspb.ScanRequest, seatspb.ScanSummary]) error {
	var sum seatspb.ScanSummary
	for {
		req, err := stream.Recv()
		if err == io.EOF {
			return stream.SendAndClose(&sum)
		}
		if err != nil {
			return err
		}
		ok, err := s.store.HasTicket(stream.Context(), int(req.GetTicketId()))
		if err != nil {
			return toStatus(err)
		}
		if ok {
			sum.Admitted++
		} else {
			sum.Refused++
		}
	}
}

// logCalls is a unary interceptor: the gRPC shape of lesson 2's logRequests.
func logCalls(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
	start := time.Now()
	resp, err := handler(ctx, req)
	log.Printf("grpc %s %s %s", info.FullMethod, status.Code(err), time.Since(start).Round(time.Microsecond))
	return resp, err
}

func newGRPCServer(store seatsStore) *grpc.Server {
	srv := grpc.NewServer(grpc.UnaryInterceptor(logCalls))
	seatspb.RegisterSeatsServer(srv, &seatsServer{store: store})
	return srv
}
```

- **`seatsServer` embute `UnimplementedSeatsServer`**, como a seção 05 exigiu, e guarda um store.
  `seatsStore` é o `Store` da aula 6 mais um método, `HasTicket`, de que só o `Scan` da porta precisa;
  é uma interface à parte para que os handlers HTTP e o store em memória não tenham de crescer com ele.
- **`GetEvent` é um handler com outra assinatura**: um contexto e uma requisição tipada entram, uma
  resposta tipada e um erro saem. Não há `ResponseWriter` nem nada para decodificar. Ele chama o mesmo
  `store.Get` que o handler HTTP chama e copia o resultado para o `Event` gerado.
- **`toStatus` é o `fail` da aula 3 para o gRPC.** Um erro gRPC é um *status*: um código de uma lista
  fixa de dezessete, e uma mensagem. `ErrNotFound` vira `codes.NotFound`, um contexto cancelado ou
  vencido mantém o próprio código, e qualquer coisa não prevista vai para o log e é respondida como
  `codes.Internal`, sem detalhe.
- **`newGRPCServer`** monta o servidor, registra o serviço e instala o `logCalls`, assunto da seção 08.

O `HasTicket` fica no `pgStore`, num arquivo próprio, com mais uma consulta para o sqlc:

```go
// boxoffice/tickets.go
package main

import (
	"context"
	"math"
)

// HasTicket says whether a ticket with this id was sold.
func (s *pgStore) HasTicket(ctx context.Context, id int) (bool, error) {
	if id < 1 || id > math.MaxInt32 {
		return false, nil
	}
	return s.q().HasTicket(ctx, int32(id))
}
```

```sql
-- boxoffice/queries.sql

-- name: ListEvents :many
SELECT id, name, seats, sold FROM events ORDER BY id;

-- name: GetEvent :one
SELECT id, name, seats, sold FROM events WHERE id = $1;

-- name: AddEvent :one
INSERT INTO events (name, seats) VALUES ($1, $2)
RETURNING id, name, seats, sold;

-- name: SellSeats :one
UPDATE events SET sold = sold + sqlc.arg(quantity)
WHERE id = sqlc.arg(id) AND seats - sold >= sqlc.arg(quantity)
RETURNING id, name, seats, sold;

-- name: SearchEvents :many
SELECT id, name, seats, sold FROM events
WHERE (sqlc.narg(min_available)::int IS NULL OR seats - sold >= sqlc.narg(min_available)::int)
  AND (sqlc.narg(name_like)::text IS NULL OR name ILIKE sqlc.narg(name_like)::text)
ORDER BY id;

-- name: InsertTicket :one
INSERT INTO tickets (event_id, email, quantity) VALUES ($1, $2, $3)
RETURNING id;

-- name: HasTicket :one
SELECT EXISTS (SELECT 1 FROM tickets WHERE id = $1);
```

## Dois servidores num processo só

O `main` agora inicia também o servidor gRPC, na porta dele, numa goroutine, porque o `Serve` bloqueia
como o `ListenAndServe`:

```go
// boxoffice/main.go
package main

import (
	"context"
	"log"
	"net"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	tokens := map[string]string{}
	for role, name := range map[string]string{
		"manager": "BOXOFFICE_MANAGER_TOKEN",
		"door":    "BOXOFFICE_DOOR_TOKEN",
	} {
		if t := os.Getenv(name); t != "" {
			tokens[t] = role
		}
	}
	if len(tokens) == 0 {
		log.Fatal("no staff tokens: set BOXOFFICE_MANAGER_TOKEN")
	}

	url := os.Getenv("DATABASE_URL")
	if url == "" {
		log.Fatal("no database: set DATABASE_URL")
	}
	ctx := context.Background()
	if err := migrate(ctx, url); err != nil {
		log.Fatalf("database: %v", err)
	}
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	cfg.MaxConns = 10
	cfg.MaxConnIdleTime = 5 * time.Minute
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("database: %v", err)
	}
	store := &pgStore{pool: pool}

	lis, err := net.Listen("tcp", "localhost:9090")
	if err != nil {
		log.Fatalf("grpc: %v", err)
	}
	go func() {
		log.Printf("grpc listening on %s", lis.Addr())
		if err := newGRPCServer(store).Serve(lis); err != nil {
			log.Fatalf("grpc: %v", err)
		}
	}()

	srv := &http.Server{
		Addr:              "localhost:8080",
		Handler:           routes(store, tokens),
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("boxoffice listening on %s", srv.Addr)
	log.Fatal(srv.ListenAndServe())
}
```

**Os dois servidores compartilham um `store`, e portanto um pool.** Uma venda feita por HTTP é vista na
hora por um `GetEvent` via gRPC, porque os dois leem as mesmas linhas. O `net.Listen` abre a porta antes
de a goroutine começar, então uma porta já ocupada para o programa no início com uma mensagem clara, como
acontece com o HTTP.

## Um cliente

A outra ponta é um programa pequeno no mesmo módulo, `cmd/seats`, que chama cada método do serviço pela
linha de comando:

```go
// boxoffice/cmd/seats/main.go
package main

import (
	"context"
	"fmt"
	"io"
	"os"
	"strconv"
	"time"

	"example.com/boxoffice/internal/seatspb"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
)

// seats is a small client of boxoffice's gRPC service:
//
//	seats get ID | seats watch ID SECONDS | seats scan TICKET...
func main() {
	conn, err := grpc.NewClient("localhost:9090", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		fail(err)
	}
	defer conn.Close()
	client := seatspb.NewSeatsClient(conn)

	limit := 5 * time.Second
	if os.Args[1] == "watch" {
		limit = time.Duration(number(os.Args[3])) * time.Second
	}
	ctx, cancel := context.WithTimeout(context.Background(), limit)
	defer cancel()

	switch os.Args[1] {
	case "get":
		e, err := client.GetEvent(ctx, &seatspb.GetEventRequest{Id: number(os.Args[2])})
		if err != nil {
			fail(err)
		}
		fmt.Printf("%d %s: %d of %d sold\n", e.GetId(), e.GetName(), e.GetSold(), e.GetSeats())
	case "watch":
		stream, err := client.Watch(ctx, &seatspb.WatchRequest{EventId: number(os.Args[2])})
		if err != nil {
			fail(err)
		}
		for {
			a, err := stream.Recv()
			if err == io.EOF {
				return
			}
			if err != nil {
				fail(err)
			}
			fmt.Printf("%s event %d: %d available\n", time.Now().Format("15:04:05"), a.GetEventId(), a.GetAvailable())
		}
	case "scan":
		stream, err := client.Scan(ctx)
		if err != nil {
			fail(err)
		}
		for _, arg := range os.Args[2:] {
			if err := stream.Send(&seatspb.ScanRequest{TicketId: number(arg)}); err != nil {
				fail(err)
			}
		}
		sum, err := stream.CloseAndRecv()
		if err != nil {
			fail(err)
		}
		fmt.Printf("admitted %d, refused %d\n", sum.GetAdmitted(), sum.GetRefused())
	}
}

// number reads an id, refusing what does not fit the int32 the contract declares.
func number(s string) int32 {
	n, err := strconv.ParseInt(s, 10, 32)
	if err != nil {
		fmt.Println("error:", err)
		os.Exit(2)
	}
	return int32(n)
}

func fail(err error) {
	st := status.Convert(err)
	fmt.Println("error:", st.Code(), st.Message())
	os.Exit(1)
}
```

O `grpc.NewClient` prepara uma conexão com o endereço; **`insecure.NewCredentials()` quer dizer sem
TLS**, o que está certo no `localhost` e errado em qualquer outro lugar, onde o gRPC deve rodar sobre TLS
como qualquer outro protocolo. Toda chamada leva um contexto com limite, cinco segundos a não ser que o
comando diga outra coisa. O `number` recusa um id que não cabe no `int32` do contrato, pelo motivo que a
seção 06 da aula 8 descobriu do jeito difícil.

```
ana@vm:~/boxoffice$ go vet ./...
ana@vm:~/boxoffice$ go build -o seats ./cmd/seats
ana@vm:~/boxoffice$ ./seats get 1
1 Jazz at the Docks: 0 of 120 sold
ana@vm:~/boxoffice$ ./seats get 9
error: NotFound event 9: no such event
ana@vm:~/boxoffice$ ./seats get 4294967297
error: strconv.ParseInt: parsing "4294967297": value out of range
```

**O evento 1 voltou como uma struct tipada**, e o evento 9 como um status que o cliente conseguiu ler: o
código, `NotFound`, e a mensagem que o `toStatus` do servidor escreveu. O último nem saiu do cliente: o
`strconv.ParseInt` com tamanho de 32 bits o recusou. Sem essa verificação, a conversão para `int32` teria
pedido ao servidor o evento 1, exatamente o bug da aula 8, agora do lado do cliente do contrato.
