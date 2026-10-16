---
title: Lendo um corpo
version: 1
---

**O corpo de uma requisição não está no objeto da requisição; ele chega por ele, em pedaços, depois
de o seu handler ter sido chamado.** A requisição é um stream de leitura, e o `for await` a lê pedaço
por pedaço. Um servidor que lê JSON tem três conferências a fazer, e cada uma tem o próprio código de
status:

```schooling-example
{"language": "javascript", "file": "body.js", "parts": [
 {"code": "import http from \"node:http\";\n\nasync function readJson(req, limit = 1024) {\n  if (!(req.headers[\"content-type\"] || \"\").startsWith(\"application/json\")) {\n    return { status: 415, error: \"send JSON, with content-type: application/json\" };\n  }", "note": "**O que ele diz ser.** Um cliente diz o que está mandando no `content-type`. Qualquer coisa que não seja JSON é recusada antes de um byte dela ser lido: 415, Unsupported Media Type."},
 {"code": "  const chunks = [];\n  let size = 0;\n  for await (const chunk of req) {\n    size += chunk.length;\n    if (size > limit) return { status: 413, error: `a body may be at most ${limit} bytes` };\n    chunks.push(chunk);\n  }", "note": "**O tamanho.** Os pedaços são Buffers. Contá-los à medida que chegam para um cliente que manda um gigabyte antes de o gigabyte estar na memória: 413, Content Too Large."},
 {"code": "  try {\n    return { value: JSON.parse(Buffer.concat(chunks).toString(\"utf8\")) };\n  } catch {\n    return { status: 400, error: \"the body is not valid JSON\" };\n  }\n}", "note": "**Se ele é lido.** Só quando todos os pedaços chegaram o texto é decodificado e lido; um pedaço pode terminar no meio de um caractere. JSON ruim é erro do cliente: 400."},
 {"code": "http\n  .createServer(async (req, res) => {\n    const body = await readJson(req);\n    res.statusCode = body.status ?? 200;\n    res.end(JSON.stringify(body.error ? { error: body.error } : { received: body.value }) + \"\\n\");\n  })\n  .listen(3000, \"127.0.0.1\");", "note": "O handler espera o corpo, depois responde com o que encontrou."}
]}
```

Quatro requisições, uma para cada resultado. O `-d` faz o `curl` mandar um corpo, e o `-H` define o
tipo dele:

```
ana@dev:~/server/native$ curl -s -H 'content-type: application/json' -d '{"url": "https://example.com/"}' http://127.0.0.1:3000/
{"received":{"url":"https://example.com/"}}
ana@dev:~/server/native$ curl -s -d 'url=https://example.com/' http://127.0.0.1:3000/
{"error":"send JSON, with content-type: application/json"}
ana@dev:~/server/native$ curl -s -H 'content-type: application/json' -d '{"url": ' http://127.0.0.1:3000/
{"error":"the body is not valid JSON"}
ana@dev:~/server/native$ head -c 2000 /dev/zero | tr '\0' 'a' | curl -s -H 'content-type: application/json' -d @- http://127.0.0.1:3000/
{"error":"a body may be at most 1024 bytes"}
```

O limite é a linha desta seção que um servidor esquece. **Sem ele, o tamanho de uma requisição é
decisão do cliente**, e alguns clientes mandando um corpo grande cada um conseguem encher a memória do
processo. 1024 bytes sobram para um link; o próprio parser de JSON do Express, na aula 7, usa 100
kilobytes por padrão, e todo serviço deve escolher o próprio número de propósito.

A quarta requisição mandou 2000 bytes, e a resposta voltou na hora, depois do primeiro pedaço que
passou do limite. `head -c 2000 /dev/zero | tr '\0' 'a'` é um jeito de fazer dois mil `a` sem
digitá-los, e o `-d @-` diz ao curl para ler o corpo do que chega pelo pipe.
