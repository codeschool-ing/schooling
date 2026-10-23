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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"O corpo de um pedido passando por três conferências em ordem. Primeiro o content-type: qualquer coisa que não seja JSON é respondida com 415 antes de se ler um byte. Depois o tamanho, contado conforme os pedaços chegam: além do limite, 413. Depois a leitura, quando todos os pedaços chegaram: JSON ruim é 400. Um corpo que passa pelas três é o valor lido, e a resposta é 200.\"><rect x=\"20\" y=\"50\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o que diz ser</text><text x=\"95\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">content-type</text><line x1=\"170\" y1=\"80\" x2=\"198\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,80.0 190.6,83.1 190.6,76.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"95\" y1=\"110\" x2=\"95\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"95.0,150.0 91.9,142.6 98.1,142.6\" fill=\"var(--amber)\"></polygon><text x=\"95\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">415</text><rect x=\"200\" y=\"50\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o tamanho</text><text x=\"275\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">contado por pedaço</text><line x1=\"350\" y1=\"80\" x2=\"378\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"378.0,80.0 370.6,83.1 370.6,76.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"275\" y1=\"110\" x2=\"275\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"275.0,150.0 271.9,142.6 278.1,142.6\" fill=\"var(--amber)\"></polygon><text x=\"275\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">413</text><rect x=\"380\" y=\"50\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">se é válido</text><text x=\"455\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">JSON.parse</text><line x1=\"530\" y1=\"80\" x2=\"558\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,80.0 550.6,83.1 550.6,76.9\" fill=\"var(--phosphor)\"></polygon><line x1=\"455\" y1=\"110\" x2=\"455\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"455.0,150.0 451.9,142.6 458.1,142.6\" fill=\"var(--amber)\"></polygon><text x=\"455\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">400</text><rect x=\"560\" y=\"50\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o valor</text><text x=\"630\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">200</text><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o pedido chega</text><text x=\"290\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cada recusa tem o seu código de status</text></svg>", "caption": "O mais barato primeiro: o tipo não custa nada, o tamanho é conferido durante a leitura, a leitura vem por último."}
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
