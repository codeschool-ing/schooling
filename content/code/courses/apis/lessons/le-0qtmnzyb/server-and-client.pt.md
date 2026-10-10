---
title: Um servidor e um cliente
version: 1
---

**O servidor é uma classe com um método por `rpc`, e o cliente é um stub cujos métodos parecem
locais.** Tudo o que há entre eles, a conexão, a codificação e o status, é da biblioteca. São dois
arquivos curtos, os dois em `~/shelf` ao lado dos gerados, e o servidor lê o mesmo `shelf.db` que o
`db.py` da aula 1 cria.

## O servidor

Salve-o como `stock_server.py`. Cada parte tem uma nota ao lado; o botão de copiar leva o arquivo
inteiro, sem as notas.

```schooling-example
{
  "language": "python",
  "file": "shelf/stock_server.py",
  "parts": [
    {
      "code": "# shelf/stock_server.py\n\"\"\"The warehouse as a gRPC service, on 127.0.0.1:50051.\n\nGenerate stock_pb2.py and stock_pb2_grpc.py from stock.proto before running it.\n\"\"\"\nimport time\nfrom concurrent import futures\n\nimport grpc\n\nimport db\nimport stock_pb2\nimport stock_pb2_grpc",
      "note": "`grpc` é a biblioteca, `db` é o banco da aula 1, e os dois módulos `stock_pb2` são os que o `protoc` gerou na seção anterior. Nada aqui descreve uma mensagem ou um método à mão: as duas coisas vêm do `stock.proto`."
    },
    {
      "code": "\n\ndef level(row):\n    if row[\"stock\"] == 0:\n        availability = stock_pb2.SOLD_OUT\n    elif row[\"stock\"] <= 3:\n        availability = stock_pb2.LOW\n    else:\n        availability = stock_pb2.IN_STOCK\n    return stock_pb2.StockLevel(isbn=row[\"isbn\"], title=row[\"title\"],\n                                copies=row[\"stock\"], availability=availability)",
      "note": "Uma linha de `books` vira um `StockLevel`. Três exemplares ou menos é `LOW`, nenhum é `SOLD_OUT`. Os valores do enum são constantes do módulo gerado, então um erro de digitação vira um `AttributeError` aqui, e não um número errado no fio."
    },
    {
      "code": "\n\ndef find(conn, isbn, context):\n    row = conn.execute(\"SELECT * FROM books WHERE isbn = ?\", (isbn,)).fetchone()\n    if row is None:\n        context.abort(grpc.StatusCode.NOT_FOUND, f\"no book with ISBN {isbn!r}\")\n    return row",
      "note": "**`context.abort` encerra a chamada com um código de status** e uma mensagem, levantando uma exceção, então nada depois dele roda. Todo método que recebe um livro passa por aqui, e por isso todos respondem `NOT_FOUND` do mesmo jeito."
    },
    {
      "code": "\n\nclass Stock(stock_pb2_grpc.StockServicer):\n\n    def GetStock(self, request, context):\n        with db.connect() as conn:\n            return level(find(conn, request.isbn, context))",
      "note": "A classe que o código gerado espera, um método por `rpc`. Um método unário recebe a mensagem da requisição e devolve a mensagem da resposta; a biblioteca faz a codificação dos dois lados."
    },
    {
      "code": "\n    def Reserve(self, request, context):\n        if request.copies <= 0:\n            context.abort(grpc.StatusCode.INVALID_ARGUMENT, \"copies must be 1 or more\")\n        with db.connect() as conn:\n            row = find(conn, request.isbn, context)\n            taken = conn.execute(\"UPDATE books SET stock = stock - ? WHERE isbn = ? AND stock >= ?\",\n                                 (request.copies, request.isbn, request.copies)).rowcount\n            if not taken:\n                context.abort(grpc.StatusCode.FAILED_PRECONDITION,\n                              f\"only {row['stock']} copies on the shelf\")\n            left = find(conn, request.isbn, context)[\"stock\"]\n        return stock_pb2.Reservation(isbn=request.isbn, copies=request.copies, left=left)",
      "note": "A verificação e a subtração são um único `UPDATE`, com `stock >= ?` no `WHERE`. Duas reservas chegando juntas não conseguem as duas ver o último exemplar, porque é o banco que decide qual delas alterou a linha."
    },
    {
      "code": "\n    def WatchStock(self, request, context):\n        last = None\n        while context.is_active():\n            with db.connect() as conn:\n                now = level(find(conn, request.isbn, context))\n            if now != last:\n                yield now\n                last = now\n            time.sleep(0.2)",
      "note": "**Um método com streaming do servidor é um gerador**: cada `yield` envia uma mensagem. Ele olha a linha cinco vezes por segundo e só envia quando o nível mudou, até o cliente ir embora ou o prazo dele vencer, que é o que `is_active()` informa."
    },
    {
      "code": "\n    def Restock(self, request_iterator, context):\n        summary = stock_pb2.RestockSummary()\n        with db.connect() as conn:\n            for box in request_iterator:\n                find(conn, box.isbn, context)\n                if box.copies <= 0:\n                    context.abort(grpc.StatusCode.INVALID_ARGUMENT, \"a box holds 1 copy or more\")\n                conn.execute(\"UPDATE books SET stock = stock + ? WHERE isbn = ?\",\n                             (box.copies, box.isbn))\n                summary.boxes += 1\n                summary.copies += box.copies\n                if box.isbn not in summary.isbns:\n                    summary.isbns.append(box.isbn)\n        return summary",
      "note": "Um método com streaming do cliente recebe um iterador e devolve uma mensagem. A entrega inteira roda numa transação só: se uma caixa cita um livro que não existe, o `abort` levanta a exceção dentro do `with` e nenhuma das caixas anteriores é contada."
    },
    {
      "code": "\n\nclass Log(grpc.ServerInterceptor):\n    def intercept_service(self, continuation, details):\n        metadata = dict(details.invocation_metadata)\n        print(details.method, \"from\", metadata.get(\"x-till\", \"?\"), flush=True)\n        return continuation(details)",
      "note": "Um interceptor vê toda chamada antes do método dela. Este imprime o nome completo do método e a entrada `x-till` dos **metadados** da chamada, que é como um cliente envia algo que não faz parte da mensagem."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = grpc.server(futures.ThreadPoolExecutor(max_workers=8), interceptors=[Log()])\n    stock_pb2_grpc.add_StockServicer_to_server(Stock(), server)\n    server.add_insecure_port(\"127.0.0.1:50051\")\n    server.start()\n    print(\"stock on 127.0.0.1:50051\", flush=True)\n    server.wait_for_termination()",
      "note": "Oito threads de trabalho, uma chamada em cada, e uma porta sem TLS, só em 127.0.0.1. Um cliente que observa ocupa uma dessas threads enquanto observa."
    }
  ]
}
```

## O cliente

O cliente recebe um comando e os argumentos dele, faz uma chamada e imprime o que voltou. Salve-o como
`stock_client.py`:

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

Cada ramo monta uma mensagem de requisição e chama um método de `stock`, o stub. Uma mensagem de
resposta impressa com `print` sai no mesmo formato de texto que o `protoc` leu na seção anterior.
Dois argumentos aparecem em toda chamada: `timeout`, que é um **prazo**, e `metadata`, que diz qual
caixa está perguntando. A seção sobre códigos de status trata dos dois, e do `except` no fim.

## Rodando os dois

O servidor roda até você pará-lo, então ganha um terminal só dele, como o `rest.py` na aula 1. No
segundo terminal:

```sh
cd ~/shelf && python3 stock_server.py
```

Ele imprime `stock on 127.0.0.1:50051` e espera. **50051 é a porta que os exemplos do próprio gRPC
usam**, e ela deixa o depósito longe do `rest.py` na 8000, então os dois podem rodar juntos. Os
números abaixo partem dos seis livros que o `db.py` põe num `shelf.db` novo; se os seus mudaram, a
aula 1 diz como recomeçar a partir deles. No primeiro terminal, peça Dom Casmurro e depois reserve
dois exemplares dele:

```
ana@api:~/shelf$ python3 stock_client.py get 9786500000016
isbn: "9786500000016"
title: "Dom Casmurro"
copies: 12
availability: IN_STOCK
ana@api:~/shelf$ python3 stock_client.py reserve 9786500000016 2
isbn: "9786500000016"
copies: 2
left: 10
```

A reserva respondeu com os exemplares tirados e os que sobraram. O segundo terminal imprimiu uma
linha por chamada, vinda do interceptor:

```
/shelf.stock.v1.Stock/GetStock from till-1
/shelf.stock.v1.Stock/Reserve from till-1
```

**A primeira palavra é o nome completo do método**: o pacote, o serviço e o método, unidos por um
ponto e uma barra. Também é o caminho da requisição HTTP/2 que levou a chamada, que a seção sobre
HTTP/2 mostra de fora.
