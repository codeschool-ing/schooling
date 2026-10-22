---
title: Streams in both directions
version: 1
---

A unary call is a request and a response. The other two kinds that boxoffice uses keep the call open
while messages flow, and **in Go a stream is a loop**: one side calls `Send` as often as it has something
to say, the other calls `Recv` until the stream ends.

## Server streaming: Watch

`Watch` is for a screen in the box office that shows how many seats are left and should change the moment
somebody buys. The server sends the current number at once, then again only when it changes:

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

The method receives the request and a stream, and **returns only when the stream is over**: an error from
the store, an error from `Send` because the client went away, or the stream's context ending. Every
half-second it reads the event and sends only if `available` moved. This is polling inside the server,
which is honest and simple for one event and a few watchers; lesson 13 shows ways for the server to push
the moment a sale happens, without asking the database twice a second.

**The `select` on `ctx.Done()` is what ends the loop when the client leaves.** Without it the method would
go on reading the database for a client that stopped listening, and every watcher that ever disconnected
would leave a goroutine behind, the leak `go-concurrency` lesson 6 was about.

The watch below ran for four seconds in one terminal while two purchases were made over HTTP in another:

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

**120, then 118 a second later, then 115**: each HTTP sale reached the gRPC watcher within the half-second
tick, because both servers read the same table. At four seconds the client's deadline ended the call, which
section 08 reads more closely.

## Client streaming: Scan

`Scan` is for the scanner at the door. It sends each ticket as it is scanned and, when the queue is through,
asks for the result once:

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

`Recv` returns `io.EOF` when the client has closed its side, and then the server answers once with
`SendAndClose`. On the client, the matching calls are `Send` per ticket and `CloseAndRecv` at the end, as
`cmd/seats` does.

```
ana@vm:~/boxoffice$ ./seats watch 9 4
error: NotFound event 9: no such event
ana@vm:~/boxoffice$ ./seats scan 1 2 3 99 2
admitted 3, refused 2
```

Tickets 1 and 2 were sold above; **ticket 2 was shown twice and admitted twice**, and 3 and 99 do not exist.
A real door would remember what it has admitted and refuse a second scan; this one only checks that a
ticket was sold, which is what `HasTicket` asks. The watch of an event that does not exist got the same
`NotFound` as a unary call, from the first `store.Get` of the loop.

## And bidirectional

A bidirectional call is both loops at once: the client sends and receives on the same stream, each side
independently, typically from two goroutines. It fits conversations, a chat or a game, where neither side
waits for the other to finish. boxoffice has no such need, and the pattern is the two above combined.
