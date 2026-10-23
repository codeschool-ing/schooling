---
title: Fluxos nos dois sentidos
version: 1
---

Uma chamada unária é uma requisição e uma resposta. Os outros dois tipos que o boxoffice usa mantêm a
chamada aberta enquanto as mensagens passam, e **em Go um fluxo é um laço**: um lado chama `Send` sempre
que tem algo a dizer, o outro chama `Recv` até o fluxo acabar.

## Streaming do servidor: Watch

O `Watch` é para uma tela na bilheteria que mostra quantos lugares restam e deve mudar no instante em
que alguém compra. O servidor manda o número atual na hora, e de novo só quando ele muda:

```go
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
```

O método recebe a requisição e um fluxo, e **só retorna quando o fluxo acaba**: um erro do store, um erro
do `Send` porque o cliente foi embora, ou o contexto do fluxo terminando. A cada meio segundo ele lê o
evento e só manda se o `available` mudou. Isso é polling dentro do servidor, honesto e simples para um
evento e poucos observadores; a aula 13 mostra jeitos de o servidor empurrar a novidade no instante da
venda, sem perguntar ao banco duas vezes por segundo.

**O `select` em `ctx.Done()` é o que encerra o laço quando o cliente sai.** Sem ele, o método continuaria
lendo o banco para um cliente que parou de escutar, e todo observador que já desconectou deixaria uma
goroutine para trás, o vazamento de que tratou a aula 6 do `go-concurrency`.

O watch abaixo rodou por quatro segundos num terminal enquanto duas compras eram feitas por HTTP em
outro:

```
ana@vm:~/boxoffice$ ./seats watch 1 4
19:12:30 event 1: 120 available
19:12:32 event 1: 118 available
19:12:33 event 1: 115 available
error: DeadlineExceeded stream terminated by RST_STREAM with error code: CANCEL
```

```
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"ticket_id":1,"event_id":1,"quantity":2,"email":"ana@example.com","remaining":118}
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 3, "email": "rui@example.com"}' localhost:8080/events/1/tickets
{"ticket_id":2,"event_id":1,"quantity":3,"email":"rui@example.com","remaining":115}
```

**120, depois 118 um segundo mais tarde, depois 115**: cada venda HTTP chegou ao observador gRPC dentro
do intervalo de meio segundo, porque os dois servidores leem a mesma tabela. Aos quatro segundos, o prazo
do cliente encerrou a chamada, o que a seção 08 lê com mais calma.

## Streaming do cliente: Scan

O `Scan` é para o leitor da porta. Ele manda cada ingresso conforme é lido e, quando a fila acaba, pede o
resultado uma vez:

```go
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
```

O `Recv` devolve `io.EOF` quando o cliente fechou o lado dele, e então o servidor responde uma vez com
`SendAndClose`. No cliente, as chamadas correspondentes são `Send` para cada ingresso e `CloseAndRecv`
no fim, como faz o `cmd/seats`.

```
ana@vm:~/boxoffice$ ./seats watch 9 4
error: NotFound event 9: no such event
ana@vm:~/boxoffice$ ./seats scan 1 2 3 99 2
admitted 3, refused 2
```

Os ingressos 1 e 2 foram vendidos acima; **o ingresso 2 foi mostrado duas vezes e aceito duas vezes**, e
o 3 e o 99 não existem. Uma porta de verdade lembraria quem já entrou e recusaria a segunda leitura;
esta só confere que o ingresso foi vendido, que é o que o `HasTicket` pergunta. O watch de um evento que
não existe recebeu o mesmo `NotFound` de uma chamada unária, vindo do primeiro `store.Get` do laço.

## E o bidirecional

Uma chamada bidirecional são os dois laços ao mesmo tempo: o cliente manda e recebe no mesmo fluxo, cada
lado de forma independente, em geral a partir de duas goroutines. Ela serve a conversas, um chat ou um
jogo, em que nenhum lado espera o outro terminar. O boxoffice não tem essa necessidade, e o padrão é a
combinação dos dois acima.
