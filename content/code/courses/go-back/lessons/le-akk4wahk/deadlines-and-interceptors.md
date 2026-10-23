---
title: Deadlines, and gRPC's middleware
version: 1
---

## The deadline travels with the call

Every call in `cmd/seats` runs under `context.WithTimeout`. **In gRPC that limit is not only the client's
business: it is sent to the server with the call**, in a header, and the server's context for that call
gets the same deadline. A server that calls a database, or another gRPC service, passes its context on,
and the deadline goes with it; at every hop, everybody stops when the original caller has stopped
waiting. That is the propagation `go-concurrency` lesson 11 described for one process, extended across
the network.

The watch of section 07 ended this way:

```
ana@vm:~/boxoffice$ ./seats watch 1 4
19:12:30 event 1: 120 available
19:12:32 event 1: 118 available
19:12:33 event 1: 115 available
error: DeadlineExceeded stream terminated by RST_STREAM with error code: CANCEL
```

**`DeadlineExceeded` is a status code of its own**, distinct from an error in the server, so the client
can tell "the server failed" from "I gave up". The message after it depends on which side noticed first:
here the stream was reset as the client cancelled it, and on another run of the same command it read
`context deadline exceeded`. On the server, `Watch`'s `select` saw `ctx.Done()` at the same moment and
returned. **Choose deadlines on purpose**: a unary call to a service on the same network should take
milliseconds, and a five-second deadline on it is a ceiling, not an expectation. A call with no deadline
at all waits for ever if the server never answers.

## Interceptors

gRPC has no `http.Handler`, so lesson 2's middlewares cannot wrap it. **Its equivalent is an interceptor**:
a function the server calls around every method, given the context, the request, information about the
method and the handler to call. `logCalls` in section 06 is lesson 2's `logRequests` in that shape:

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

**Two lines for the two unary calls, with the full method name and the status code**, beside the HTTP
lines of lesson 2's middleware. The watch and the scan are not there: `grpc.UnaryInterceptor` wraps only
unary calls, and streams have their own kind, `grpc.StreamInterceptor`, with a different signature. A
service logs both, and libraries of ready interceptors exist for logging, metrics, recovery from panics
and authentication.

Authentication in gRPC travels as **metadata**, gRPC's name for headers: a token sent by the client with
`metadata.AppendToOutgoingContext` and read by an interceptor on the server, which refuses with
`codes.Unauthenticated` before the method runs. It is lesson 2's `requireStaff` again, in this shape.
boxoffice's gRPC port listens on `localhost` only, and this lesson leaves it without authentication.
