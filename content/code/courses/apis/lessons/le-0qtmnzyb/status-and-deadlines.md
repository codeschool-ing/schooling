---
title: Status codes, deadlines and metadata
version: 1
---

**Every gRPC call ends with one status: a code from a fixed list of seventeen, and a message.** The
codes are gRPC's own, numbered 0 to 16, and they are not HTTP's. The section on HTTP/2 shows that the
HTTP status of a failed gRPC call is still 200; what a client acts on is this code, and the
`except grpc.RpcError` in the client prints it with its message.

Three refusals from the warehouse, each with a different code: a book that does not exist, a
reservation of no copies, and a reservation of more copies than A Hora da Estrela has:

```
ana@api:~/shelf$ python3 stock_client.py get 9786500000099
NOT_FOUND no book with ISBN '9786500000099'
ana@api:~/shelf$ python3 stock_client.py reserve 9786500000016 0
INVALID_ARGUMENT copies must be 1 or more
ana@api:~/shelf$ python3 stock_client.py reserve 9786500000030 5
FAILED_PRECONDITION only 2 copies on the shelf
```

The wrong idea worth naming here is that the second and third are the same mistake. **`INVALID_ARGUMENT`
says the request is wrong whatever the state of the system**: zero copies is never a reservation.
**`FAILED_PRECONDITION` says the request is fine and the system is not in a state to accept it**:
five copies become possible the day a delivery arrives. A client shows the first to whoever typed
it, and handles the second by waiting, restocking, or offering fewer.

## The codes, against HTTP's

| gRPC code | number | means | nearest HTTP |
|---|---|---|---|
| `OK` | 0 | it worked | 200 |
| `INVALID_ARGUMENT` | 3 | the request is wrong as it stands | 400 |
| `DEADLINE_EXCEEDED` | 4 | the client stopped waiting | 504 |
| `NOT_FOUND` | 5 | the thing named does not exist | 404 |
| `ALREADY_EXISTS` | 6 | it would create a second one | 409 |
| `PERMISSION_DENIED` | 7 | known caller, not allowed | 403 |
| `RESOURCE_EXHAUSTED` | 8 | a quota or a limit ran out | 429 |
| `FAILED_PRECONDITION` | 9 | not in this state | 400 |
| `UNIMPLEMENTED` | 12 | no such method here | 501 |
| `INTERNAL` | 13 | the server broke | 500 |
| `UNAVAILABLE` | 14 | could not reach it, or it is shedding load | 503 |
| `UNAUTHENTICATED` | 16 | no valid credentials | 401 |

The rest are `CANCELLED`, `UNKNOWN`, `ABORTED`, `OUT_OF_RANGE` and `DATA_LOSS`. The column on the
right is the mapping a JSON gateway uses, and it is not one to one: several gRPC codes land on 400.

## A failure inside a stream

`Restock` runs the whole delivery in one transaction. Send a box of Dom Casmurro and then a box for
a book that does not exist, and the call fails on the second:

```
ana@api:~/shelf$ python3 stock_client.py restock 9786500000016 5 9786500000099 1
NOT_FOUND no book with ISBN '9786500000099'
ana@api:~/shelf$ python3 stock_client.py get 9786500000016
isbn: "9786500000016"
title: "Dom Casmurro"
copies: 10
availability: IN_STOCK
```

Dom Casmurro still has the ten copies it had before. **The first box was rolled back with the
second**, because `abort` raised inside the server's `with` block, and that is a decision the server
made rather than something gRPC does for you: a server that committed box by box would have kept
the five.

## UNAVAILABLE: nobody answered

Stop the server with `Ctrl+C` in the second terminal and call it again:

```
ana@api:~/shelf$ python3 stock_client.py get 9786500000016; echo "exit $?"
UNAVAILABLE failed to connect to all addresses; last error: UNKNOWN: ipv4:127.0.0.1:50051: Failed to connect to remote host: Connection refused
exit 1
```

**`UNAVAILABLE` is the code to retry**, after a pause that grows each time, because the request was
fine and, here, never reached a server. It is the only code in this section that says to try again.
For a call that changes something, like `Reserve`, a retry is safe only when the failure came before
the server saw the call, as this one did. Retrying `NOT_FOUND`
asks the same question of the same data; retrying `INVALID_ARGUMENT` sends the same mistake again.
Start the server again before going on.

## Deadlines

**A deadline is the moment the client stops waiting, and in gRPC it travels with the call.** The
client's `timeout=2` becomes a `grpc-timeout` header, so the server knows how long it has; in
Python, `context.time_remaining()` returns it. When the time is up, the client gets
`DEADLINE_EXCEEDED`, which is the line that ended the watch in the previous section, and the server
sees the call cancelled, which is why `is_active()` turned false and the loop stopped.

The common wrong idea is that a timeout is the client's private business. Here it is part of the
call, for a reason that shows up with three services in a row: when the warehouse calls a supplier
to answer a till, it should pass on **what is left** of the till's deadline, not start a fresh one.
Otherwise the supplier keeps working for an answer that nobody is waiting for any more.

Two warnings come with it. **gRPC sets no deadline unless you do**, and a call without one can wait
forever on a server that has stopped answering. And **`DEADLINE_EXCEEDED` does not mean nothing
happened**: a `Reserve` whose deadline passes may have taken the copies a millisecond earlier, and
only asking again tells the client which.

## Metadata

**Metadata is a list of keys and values that travels beside the message**, in the HTTP/2 headers,
and it is where things go that are about the call rather than about the book. The client sends
`x-till: till-1` with every call, and the server's interceptor printed it on every line. Here is
the second terminal as it stood before you stopped the server:

```
/shelf.stock.v1.Stock/GetStock from till-1
/shelf.stock.v1.Stock/Reserve from till-1
/shelf.stock.v1.Stock/GetStock from till-1
/shelf.stock.v1.Stock/WatchStock from till-1
/shelf.stock.v1.Stock/Reserve from till-1
/shelf.stock.v1.Stock/Reserve from till-1
/shelf.stock.v1.Stock/Restock from till-1
/shelf.stock.v1.Stock/GetStock from till-1
/shelf.stock.v1.Stock/Reserve from till-1
/shelf.stock.v1.Stock/Reserve from till-1
/shelf.stock.v1.Stock/Restock from till-1
/shelf.stock.v1.Stock/GetStock from till-1
```

Keys are lowercase, and a key ending in `-bin` carries bytes rather than text. **Credentials go
here**, in an `authorization` entry, which is lesson 7's subject; a token inside the request message
would have to be added to every message the service has.
