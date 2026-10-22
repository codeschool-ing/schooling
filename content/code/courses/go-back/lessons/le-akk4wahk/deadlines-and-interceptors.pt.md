---
title: Prazos, e o middleware do gRPC
version: 1
---

## O prazo viaja com a chamada

Toda chamada do `cmd/seats` roda sob `context.WithTimeout`. **No gRPC esse limite não é assunto só do
cliente: ele é mandado ao servidor junto com a chamada**, num cabeçalho, e o contexto do servidor para
aquela chamada recebe o mesmo prazo. Um servidor que chama um banco, ou outro serviço gRPC, repassa o
contexto, e o prazo vai junto; em cada salto, todo mundo para quando quem chamou primeiro parou de
esperar. É a propagação que a aula 11 do `go-concurrency` descreveu para um processo, estendida através
da rede.

O watch da seção 07 terminou assim:

```
ana@vm:~/boxoffice$ ./seats watch 1 4
19:12:30 event 1: 120 available
19:12:32 event 1: 118 available
19:12:33 event 1: 115 available
error: DeadlineExceeded stream terminated by RST_STREAM with error code: CANCEL
```

**`DeadlineExceeded` é um código de status próprio**, diferente de um erro no servidor, então o cliente
distingue "o servidor falhou" de "eu desisti". A mensagem depois dele depende de que lado percebeu
primeiro: aqui o fluxo foi reiniciado quando o cliente o cancelou, e em outra execução do mesmo comando
ela dizia `context deadline exceeded`. No servidor, o `select` do `Watch` viu o `ctx.Done()` no mesmo
momento e retornou. **Escolha prazos de propósito**: uma chamada unária a um serviço na mesma rede deve
levar milissegundos, e um prazo de cinco segundos nela é um teto, não uma expectativa. Uma chamada sem
prazo nenhum espera para sempre se o servidor nunca responder.

## Interceptors

O gRPC não tem `http.Handler`, então os middlewares da aula 2 não conseguem envolvê-lo. **O equivalente
dele é um interceptor**: uma função que o servidor chama em volta de cada método, recebendo o contexto, a
requisição, informações sobre o método e o handler a chamar. O `logCalls` da seção 06 é o
`logRequests` da aula 2 nesse formato:

```go
func logCalls(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
	start := time.Now()
	resp, err := handler(ctx, req)
	log.Printf("grpc %s %s %s", info.FullMethod, status.Code(err), time.Since(start).Round(time.Microsecond))
	return resp, err
}
```

```
ana@vm:~/boxoffice$ cat .server.log
2026/10/22 19:12:30 boxoffice listening on localhost:8080
2026/10/22 19:12:30 grpc listening on 127.0.0.1:9090
2026/10/22 19:12:30 grpc /boxoffice.v1.Seats/GetEvent OK 1.241ms
2026/10/22 19:12:30 grpc /boxoffice.v1.Seats/GetEvent NotFound 218µs
2026/10/22 19:12:31 POST /events/1/tickets 201 84B 2.547ms
2026/10/22 19:12:33 POST /events/1/tickets 201 84B 1.468ms
```

**Duas linhas para as duas chamadas unárias, com o nome completo do método e o código de status**, ao
lado das linhas HTTP do middleware da aula 2. O watch e o scan não estão lá: o `grpc.UnaryInterceptor`
envolve só chamadas unárias, e os fluxos têm um tipo próprio, o `grpc.StreamInterceptor`, com outra
assinatura. Um serviço registra os dois, e existem bibliotecas de interceptors prontos para log,
métricas, recuperação de pânico e autenticação.

A autenticação no gRPC viaja como **metadata**, o nome que o gRPC dá aos cabeçalhos: um token mandado
pelo cliente com `metadata.AppendToOutgoingContext` e lido por um interceptor no servidor, que recusa com
`codes.Unauthenticated` antes de o método rodar. É o `requireStaff` da aula 2 de novo, nesse formato. A
porta gRPC do boxoffice escuta só no `localhost`, e esta aula a deixa sem autenticação.
