---
title: O que a versão inicial fazia
version: 1
---

No passo 7, o loanbook tinha as suas regras e os seus testes, e ninguém tinha ainda experimentado os
caminhos laterais. Duas requisições mostram isso. Um endereço que não existe, e um corpo que não é JSON:

```
ana@laptop:~/loanbook$ curl -s -i localhost:8000/api/nothing
HTTP/1.0 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sun, 27 Sep 2026 06:34:30 GMT
Connection: close
Content-Type: text/html;charset=utf-8
Content-Length: 330

<!DOCTYPE HTML>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <title>Error response</title>
    </head>
    <body>
        <h1>Error response</h1>
        <p>Error code: 404</p>
        <p>Message: Not Found.</p>
        <p>Error code explanation: 404 - Nothing matches the given URI.</p>
    </body>
</html>

ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/loan -d 'not json'
```

A primeira responde com **uma página HTML**, que é o que a biblioteca do Python manda por padrão. A página é
correta, e inútil: a página do loanbook espera JSON e lê um campo `error`, então falharia ao interpretar a
resposta e não mostraria nada. A segunda responde com **nada**. O `curl` não imprimiu saída porque o servidor
fechou a conexão sem responder. O log do servidor diz por quê:

```
ana@laptop:~/loanbook$ cat app.log
loanbook on http://127.0.0.1:8000
GET /api/nothing Not Found
GET /api/nothing 404
----------------------------------------
Exception occurred during processing of request from ('127.0.0.1', 56956)
Traceback (most recent call last):
  File "/usr/lib/python3.12/socketserver.py", line 692, in process_request_thread
    self.finish_request(request, client_address)
  File "/usr/lib/python3.12/socketserver.py", line 362, in finish_request
    self.RequestHandlerClass(request, client_address, self)
  File "/usr/lib/python3.12/socketserver.py", line 761, in __init__
    self.handle()
  File "/usr/lib/python3.12/http/server.py", line 436, in handle
    self.handle_one_request()
  File "/usr/lib/python3.12/http/server.py", line 424, in handle_one_request
    method()
  File "/home/ana/loanbook/app.py", line 115, in do_POST
    body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/__init__.py", line 346, in loads
    return _default_decoder.decode(s)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/decoder.py", line 337, in decode
    obj, end = self.raw_decode(s, idx=_w(s, 0).end())
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/json/decoder.py", line 355, in raw_decode
    raise JSONDecodeError("Expecting value", s, err.value) from None
json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
----------------------------------------
```

`json.loads` levantou uma exceção que nada capturou, o tratamento da requisição morreu, e a biblioteca
escreveu o traceback no log e desligou. **Para o usuário isso é indistinguível de um servidor fora do ar.**
Para quem avalia e experimentou, diz que quem fez testou só o caminho que pretendia.

Nenhum dos dois teria sido encontrado pelos testes do passo 7, que chamam `lend` e `give_back` diretamente e
nunca mandam uma requisição malformada. Esses testes fazem o trabalho deles, que são as regras. Os caminhos
infelizes da camada HTTP só são encontrados mandando HTTP.
