---
title: The service, and the code generated from it
version: 1
---

**The `service` block lists the procedures, and a compiler turns it into code for both sides.**
Each `rpc` line names a method, the message it takes and the message it returns, with `stream` in
front of either one when that side sends more than one. From those four lines of `stock.proto` the
compiler writes a **stub** for the client, an object whose methods make the calls, and a
**servicer** for the server, a class whose methods you fill in.

The wrong picture here is lesson 1's: that a client builds a request, picks a path and a method,
sets a header and parses what comes back. In gRPC nobody writes any of that. The client calls
`stock.GetStock(request)` and gets a `StockLevel` back, and the path, the headers and the bytes are
the generated code's business. **Both sides are generated from one file, so they cannot disagree
about a field's number or a method's name** without one of them being generated from a different
file.

## Generating the Python

`python3-grpc-tools`, from lesson 1's `apt-get` line, carries a copy of `protoc` with the Python
gRPC plugin built in. In `~/shelf`:

```
ana@api:~/shelf$ python3 -m grpc_tools.protoc -I . --python_out=. --grpc_python_out=. stock.proto
/usr/lib/python3/dist-packages/grpc_tools/protoc.py:17: DeprecationWarning: pkg_resources is deprecated as an API. See https://setuptools.pypa.io/en/latest/pkg_resources.html
  import pkg_resources
```

**The two lines it printed are a warning about the tool's own packaging**, not about your file:
`grpc_tools` imports a module that Python's setuptools has marked as on its way out. The command
did its work, and it wrote two files:

```
ana@api:~/shelf$ ls stock*
stock.proto
stock_client.py
stock_pb2.py
stock_pb2_grpc.py
stock_server.py
ana@api:~/shelf$ wc -l stock_pb2.py stock_pb2_grpc.py
  416 stock_pb2.py
   97 stock_pb2_grpc.py
  513 total
```

`-I .` says where to look for `.proto` files that this one imports; it imports none, so the current
directory is enough. `--python_out` asks for the messages, in `stock_pb2.py`, and `--grpc_python_out`
for the service, in `stock_pb2_grpc.py`. That is 513 generated lines from the 56 of `stock.proto`,
and **you never edit them**: when `stock.proto` changes, you run the same command again and they
are written over. The service file holds the three things the next section uses:

```
ana@api:~/shelf$ grep -n '^class\|^def ' stock_pb2_grpc.py
7:class StockStub(object):
39:class StockServicer(object):
72:def add_StockServicer_to_server(servicer, server):
```

| generated | used by | what it does |
|---|---|---|
| `StockStub` | the client | one method per `rpc`; calling one sends the call |
| `StockServicer` | the server | a class to inherit, one method per `rpc` to fill in |
| `add_StockServicer_to_server` | the server | connects your class to a running server |

## Every language from one file

The same `stock.proto` produces the same three things in the other languages of the back-end track:
`protoc` has plugins for Go and Java, and Node.js reads a `.proto` either through a generator or
directly at start-up. A Go server and a Java client written by two teams who never met agree on every
byte, because both were generated from the file they share. **The `.proto` is the thing a team
publishes**, the way a REST team publishes its documentation in lesson 6, except that here the
compiler checks it.

Whether the generated files are kept in the repository or produced by the build is a team's choice,
and both are common. What matters is that nobody edits them by hand, because the next generation
wipes the edit out without a word.
