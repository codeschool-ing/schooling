---
title: x
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "shelf/stock_server.py",
  "parts": [
    {
      "code": "# shelf/stock_server.py\n\"\"\"The warehouse as a gRPC service, on 127.0.0.1:50051.\n\nGenerate stock_pb2.py and stock_pb2_grpc.py from stock.proto before running it.\n\"\"\"\nimport time\nfrom concurrent import futures\n\nimport grpc\n\nimport db\nimport stock_pb2\nimport stock_pb2_grpc",
      "note": "`grpc` is the library, `db` is lesson 1's database, and the two `stock_pb2` modules are the ones `protoc` generated in the previous section. Nothing here describes a message or a method by hand: both come from `stock.proto`."
    },
    {
      "code": "\n\ndef level(row):\n    if row[\"stock\"] == 0:\n        availability = stock_pb2.SOLD_OUT\n    elif row[\"stock\"] <= 3:\n        availability = stock_pb2.LOW\n    else:\n        availability = stock_pb2.IN_STOCK\n    return stock_pb2.StockLevel(isbn=row[\"isbn\"], title=row[\"title\"],\n                                copies=row[\"stock\"], availability=availability)",
      "note": "A row of `books` becomes a `StockLevel`. Three copies or fewer is `LOW`, none is `SOLD_OUT`. The enum's values are constants of the generated module, so a typo is an `AttributeError` here and not a wrong number on the wire."
    },
    {
      "code": "\n\ndef find(conn, isbn, context):\n    row = conn.execute(\"SELECT * FROM books WHERE isbn = ?\", (isbn,)).fetchone()\n    if row is None:\n        context.abort(grpc.StatusCode.NOT_FOUND, f\"no book with ISBN {isbn!r}\")\n    return row",
      "note": "**`context.abort` ends the call with a status code** and a message, by raising an exception, so nothing after it runs. Every method that names a book goes through here, so every one of them answers `NOT_FOUND` the same way."
    },
    {
      "code": "\n\nclass Stock(stock_pb2_grpc.StockServicer):\n\n    def GetStock(self, request, context):\n        with db.connect() as conn:\n            return level(find(conn, request.isbn, context))",
      "note": "The class the generated code expects, one method per `rpc`. A unary method takes the request message and returns the response message; the library does the encoding on both sides."
    },
    {
      "code": "\n    def Reserve(self, request, context):\n        if request.copies <= 0:\n            context.abort(grpc.StatusCode.INVALID_ARGUMENT, \"copies must be 1 or more\")\n        with db.connect() as conn:\n            row = find(conn, request.isbn, context)\n            taken = conn.execute(\"UPDATE books SET stock = stock - ? WHERE isbn = ? AND stock >= ?\",\n                                 (request.copies, request.isbn, request.copies)).rowcount\n            if not taken:\n                context.abort(grpc.StatusCode.FAILED_PRECONDITION,\n                              f\"only {row['stock']} copies on the shelf\")\n            left = find(conn, request.isbn, context)[\"stock\"]\n        return stock_pb2.Reservation(isbn=request.isbn, copies=request.copies, left=left)",
      "note": "The check and the subtraction are one `UPDATE`, with `stock >= ?` in its `WHERE`. Two reservations arriving together cannot both see the last copy, because the database decides which one changed the row."
    },
    {
      "code": "\n    def WatchStock(self, request, context):\n        last = None\n        while context.is_active():\n            with db.connect() as conn:\n                now = level(find(conn, request.isbn, context))\n            if now != last:\n                yield now\n                last = now\n            time.sleep(0.2)",
      "note": "**A server-streaming method is a generator**: each `yield` sends one message. It looks at the row five times a second and sends only when the level changed, until the client goes away or its deadline passes, which is what `is_active()` reports."
    },
    {
      "code": "\n    def Restock(self, request_iterator, context):\n        summary = stock_pb2.RestockSummary()\n        with db.connect() as conn:\n            for box in request_iterator:\n                find(conn, box.isbn, context)\n                if box.copies <= 0:\n                    context.abort(grpc.StatusCode.INVALID_ARGUMENT, \"a box holds 1 copy or more\")\n                conn.execute(\"UPDATE books SET stock = stock + ? WHERE isbn = ?\",\n                             (box.copies, box.isbn))\n                summary.boxes += 1\n                summary.copies += box.copies\n                if box.isbn not in summary.isbns:\n                    summary.isbns.append(box.isbn)\n        return summary",
      "note": "A client-streaming method receives an iterator and returns one message. The whole delivery runs in one transaction: if any box names a book that does not exist, `abort` raises inside the `with` and none of the boxes before it are counted either."
    },
    {
      "code": "\n\nclass Log(grpc.ServerInterceptor):\n    def intercept_service(self, continuation, details):\n        metadata = dict(details.invocation_metadata)\n        print(details.method, \"from\", metadata.get(\"x-till\", \"?\"), flush=True)\n        return continuation(details)",
      "note": "An interceptor sees every call before its method does. This one prints the method's full name and the `x-till` entry of the call's **metadata**, which is how a client sends something that is not part of the message."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = grpc.server(futures.ThreadPoolExecutor(max_workers=8), interceptors=[Log()])\n    stock_pb2_grpc.add_StockServicer_to_server(Stock(), server)\n    server.add_insecure_port(\"127.0.0.1:50051\")\n    server.start()\n    print(\"stock on 127.0.0.1:50051\", flush=True)\n    server.wait_for_termination()",
      "note": "Eight worker threads, one call on each, and a port with no TLS, on 127.0.0.1 only. A client that watches holds one of those threads for as long as it watches."
    }
  ]
}
```

```python
# shelf/stock_client.py
"""Ask the warehouse something: get, reserve, watch or restock.

    python3 stock_client.py get ISBN
    python3 stock_client.py reserve ISBN COPIES
    python3 stock_client.py watch ISBN SECONDS
    python3 stock_client.py restock ISBN COPIES [ISBN COPIES ...]
"""
import sys

import grpc

import stock_pb2
import stock_pb2_grpc

TILL = [("x-till", "till-1")]


def main(command, *args):
    with grpc.insecure_channel("127.0.0.1:50051") as channel:
        stock = stock_pb2_grpc.StockStub(channel)
        try:
            if command == "get":
                print(stock.GetStock(stock_pb2.BookRef(isbn=args[0]),
                                     timeout=2, metadata=TILL), end="")
            elif command == "reserve":
                order = stock_pb2.ReserveRequest(isbn=args[0], copies=int(args[1]))
                print(stock.Reserve(order, timeout=2, metadata=TILL), end="")
            elif command == "watch":
                levels = stock.WatchStock(stock_pb2.BookRef(isbn=args[0]),
                                          timeout=float(args[1]), metadata=TILL)
                for level in levels:
                    print(level.copies, stock_pb2.Availability.Name(level.availability))
            elif command == "restock":
                boxes = (stock_pb2.Delivery(isbn=isbn, copies=int(copies))
                         for isbn, copies in zip(args[::2], args[1::2]))
                print(stock.Restock(boxes, timeout=2, metadata=TILL), end="")
        except grpc.RpcError as e:
            print(e.code().name, e.details())
            sys.exit(1)


if __name__ == "__main__":
    main(*sys.argv[1:])
```
