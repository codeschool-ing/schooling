---
title: A resposta, e os cabeçalhos que o Node escreve por você
version: 1
---

**Uma resposta é uma linha de status, cabeçalhos e um corpo, nessa ordem, e o Node impõe a ordem.**
Até o primeiro byte do corpo ser escrito, o status e os cabeçalhos ainda podem mudar; depois dele, já
foram para o cliente e não podem mais. Três rotas mostram os três jeitos de escrever uma:

```schooling-example
{"language": "javascript", "file": "respond.js", "parts": [
 {"code": "import http from \"node:http\";\n\nhttp\n  .createServer((req, res) => {\n    if (req.url === \"/whole\") return res.end(\"all at once\\n\");", "note": "O jeito curto: `end` com o corpo inteiro. O Node acrescenta o status 200, um `Date`, os cabeçalhos de conexão, e **um `Content-Length` que ele mesmo conta**, porque tem o corpo inteiro na mão."},
 {"code": "    if (req.url === \"/json\") {\n      const body = JSON.stringify({ ok: true }) + \"\\n\";\n      res.writeHead(201, {\n        \"content-type\": \"application/json; charset=utf-8\",\n        \"content-length\": Buffer.byteLength(body),\n      });\n      return res.end(body);\n    }", "note": "O jeito explícito: o `writeHead` define o status e os cabeçalhos numa chamada. Um corpo JSON precisa do próprio `content-type`; sem ele, o cliente fica adivinhando o que são aqueles bytes."},
 {"code": "    if (req.url === \"/pieces\") {\n      res.write(\"first piece\\n\");\n      setTimeout(() => res.end(\"last piece\\n\"), 500);\n      return;\n    }", "note": "**O corpo em pedaços.** Depois do primeiro `write` o Node não tem como saber o tamanho final, então passa para `Transfer-Encoding: chunked`: cada pedaço vai com o próprio tamanho na frente."},
 {"code": "    res.write(\"too late for headers\\n\");\n    try {\n      res.setHeader(\"x-late\", \"yes\");\n    } catch (err) {\n      console.log(err.code);\n    }\n    res.end();\n  })\n  .listen(3000, \"127.0.0.1\");", "note": "Um cabeçalho definido depois de o corpo começar chega tarde demais, e o Node lança um erro em vez de mandá-lo para lugar nenhum."}
]}
```

```
ana@dev:~/server/native$ curl -si http://127.0.0.1:3000/whole
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 23:08:41 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Content-Length: 12

all at once
ana@dev:~/server/native$ curl -si http://127.0.0.1:3000/json
HTTP/1.1 201 Created
content-type: application/json; charset=utf-8
content-length: 12
Date: Fri, 16 Oct 2026 23:08:41 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"ok":true}
ana@dev:~/server/native$ curl -si http://127.0.0.1:3000/pieces
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 23:08:41 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

first piece
last piece
ana@dev:~/server/native$ curl -s http://127.0.0.1:3000/late
too late for headers
```

**O `Content-Length` e o `Transfer-Encoding: chunked` são os dois jeitos de um cliente saber onde um
corpo termina**, e uma resposta sempre tem um deles. O Node escolheu por você em cada caso. Dois detalhes nos cabeçalhos valem saber. O tamanho é `Buffer.byteLength(body)` e não `body.length`,
porque o cabeçalho conta bytes e o `"olá"` da aula 1 tem três caracteres e quatro bytes. E os nomes que você
escreveu em minúsculas saíram em minúsculas, enquanto o `Date` e o `Connection` do próprio Node saíram
com maiúscula. As duas coisas estão certas, porque nomes de cabeçalho não diferenciam maiúsculas.

A quarta rota, no terminal do servidor:

```
ana@dev:~/server/native$ node respond.js
ERR_HTTP_HEADERS_SENT
^C
```

**O `ERR_HTTP_HEADERS_SENT` é o erro de um handler que responde duas vezes**: um `res.end` dentro de
um `if` seguido de outro no fim, ou uma resposta mandada de um callback depois que o caminho principal
já mandou uma. A solução é um `return` antes de toda resposta, e é por isso que toda rota acima
começa com `return res.end` ou termina com um `return`.
