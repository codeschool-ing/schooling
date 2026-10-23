---
title: Looking inside a call
version: 1
---

When something goes wrong with a REST API, the first tool is `curl`, and nothing has to be installed or
known in advance. **The same move against a gRPC port tells you almost nothing**:

```
ana@vm:~/boxoffice$ curl -s localhost:8080/events/1
{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0,"available":120}
ana@vm:~/boxoffice$ curl -s localhost:9090/boxoffice.v1.Seats/GetEvent; echo "exit $?"
exit 1
ana@vm:~/boxoffice$ curl -si --http2-prior-knowledge -X POST -H "content-type: application/grpc" --data-binary @/dev/null localhost:9090/boxoffice.v1.Seats/GetEvent
HTTP/2 200 
content-type: application/grpc
grpc-status: 13
grpc-message: cardinality violation: received no request message from non-client-streaming RPC

```

The first request is lesson 3's API, readable at a glance. The second went to the gRPC port in HTTP/1.1,
which gRPC does not speak, and `curl` got no answer it could use, exit status 1. The third spoke HTTP/2 and
said it was gRPC, and got an answer: **status 200, with the real outcome in the `grpc-status` header**,
13, `Internal`, because the call carried no message at all. That is how every gRPC error travels: the
HTTP status is 200 and the gRPC status comes in `grpc-status`, normally a trailer after the body, and
here among the headers because there was no body to follow. A proxy or a log that only looks at HTTP statuses sees
every gRPC failure as a success.

## grpcurl

The tool built for this is **`grpcurl`**: `curl` for gRPC, which takes a request written as JSON, encodes it
with the contract, makes the call, and prints the answer back as JSON. It installs like every Go tool in
this course; it brought about thirty modules with it, cut here to the first two lines:

```
ana@vm:~$ go install github.com/fullstorydev/grpcurl/cmd/grpcurl@v1.9.4
...
```

It needs the contract, given here with `-proto`:

```
ana@vm:~/boxoffice$ grpcurl -plaintext -proto proto/seats.proto -d '{"id": 1}' localhost:9090 boxoffice.v1.Seats/GetEvent
{
  "id": 1,
  "name": "Jazz at the Docks",
  "seats": 120
}
ana@vm:~/boxoffice$ grpcurl -plaintext -proto proto/seats.proto -d '{"id": 9}' localhost:9090 boxoffice.v1.Seats/GetEvent
ERROR:
  Code: NotFound
  Message: event 9: no such event
ana@vm:~/boxoffice$ grpcurl -plaintext localhost:9090 list
Failed to list services: server does not support the reflection API
```

**The answer has no `"sold"`**. Event 1 has sold nothing, and the standard way of turning Protocol Buffers
into JSON leaves out fields at their zero value, because the binary form never sent them. A reader of that
JSON has to know that a missing number means zero, which is exactly the ambiguity lesson 3 section 04 met.
The `NotFound` came through with the message `toStatus` wrote, and `describe` printed the service as the
`.proto` declares it, comments included.

## Reflection

`grpcurl list` without `-proto` failed: **the server does not support the reflection API**. Reflection is
an optional service a gRPC server can register, one line with `reflection.Register(srv)`, through which it
describes its own contract to anyone who asks; tools then need no `.proto` file. It is convenient in
development and on internal networks, and **it is a map of your API handed to whoever reaches the port**,
so many teams turn it on only outside production. boxoffice leaves it off and keeps the contract in the
repository, where every client gets it anyway.
