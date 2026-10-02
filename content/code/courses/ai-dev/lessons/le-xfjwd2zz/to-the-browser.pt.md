---
title: Do modelo a um navegador
version: 1
---

Uma página num navegador não consegue chamar a API do modelo sozinha: **a requisição precisaria da
chave da API, e qualquer coisa mandada a um navegador pode ser lida por quem o usa**. Então um
servidor seu fica no meio. Ele guarda a chave, faz a requisição em streaming e repassa os pedaços ao
navegador conforme chegam, num stream próprio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 160\" role=\"img\" aria-label=\"Três partes. O navegador manda uma pergunta ao seu relay e lê os eventos do próprio relay: text, done, error. O relay guarda a chave da API, faz a requisição em streaming à API do modelo e repassa cada pedaço. A chave nunca sai do servidor.\"><defs><marker id=\"ry-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o navegador</text><text x=\"95.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a página</text><rect x=\"285\" y=\"50\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">o seu relay</text><text x=\"360.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">guarda a chave</text><rect x=\"550\" y=\"50\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a API do modelo</text><text x=\"625.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o provedor</text><path d=\"M172 66 L283 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ry-ah)\"></path><text x=\"228\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pergunta</text><path d=\"M283 96 L172 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ry-ah)\"></path><text x=\"228\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">text, done, error</text><path d=\"M437 66 L548 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ry-ah)\"></path><text x=\"492\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requisição em streaming + chave</text><path d=\"M548 96 L437 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ry-ah)\"></path><text x=\"492\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">server-sent events</text></svg>", "caption": "A chave fica no seu servidor. A página vê os seus eventos, não os do provedor.", "same": ["server-sent events"]}
```

## O relay

```schooling-example
{
  "language": "python",
  "file": "relay.py",
  "parts": [
    {
      "code": "\"\"\"A relay between a browser and the model: the key stays here, the words go through.\"\"\"\nimport json\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport anthropic\n\n"
    },
    {
      "code": "model = anthropic.Anthropic()\n\n\n",
      "note": "**A chave é lida aqui, no servidor**, do ambiente; ela nunca chega à página."
    },
    {
      "code": "class Relay(BaseHTTPRequestHandler):\n    def send_event(self, name, data):\n        self.wfile.write(f\"event: {name}\\ndata: {json.dumps(data)}\\n\\n\".encode())\n        self.wfile.flush()\n\n",
      "note": "**Um evento, escrito e despejado na hora.** Sem o flush, os pedaços esperam num buffer e a página os vê aos trancos."
    },
    {
      "code": "    def do_POST(self):\n        question = json.loads(self.rfile.read(int(self.headers[\"Content-Length\"])))[\"question\"]\n        self.send_response(200)\n        self.send_header(\"Content-Type\", \"text/event-stream\")\n        self.send_header(\"Cache-Control\", \"no-cache\")\n        self.end_headers()\n",
      "note": "**A resposta começa antes de a resposta existir**: status, tipo de conteúdo e cabeçalhos saem primeiro."
    },
    {
      "code": "        try:\n            with model.messages.stream(model=\"scripted-1\", max_tokens=300,\n                                       messages=[{\"role\": \"user\", \"content\": question}]) as stream:\n                for text in stream.text_stream:\n                    self.send_event(\"text\", {\"text\": text})\n            self.send_event(\"done\", {\"stop_reason\": stream.get_final_message().stop_reason})\n",
      "note": "**Cada pedaço do modelo vira um evento para a página**, e o fim vira `done`."
    },
    {
      "code": "        except anthropic.APIError as e:\n            self.send_event(\"error\", {\"message\": \"the answer stopped halfway; please ask again\"})\n            self.log_error(\"model stream failed: %s\", e)\n\n",
      "note": "**Uma falha no meio vira um evento `error`**, com uma frase para uma pessoa; o detalhe do provedor vai para o log do servidor."
    },
    {
      "code": "    def log_message(self, *args):\n        pass\n\n\n"
    },
    {
      "code": "ThreadingHTTPServer((\"127.0.0.1\", 8500), Relay).serve_forever()",
      "note": "**Uma thread por requisição**, para duas páginas poderem receber ao mesmo tempo."
    }
  ]
}
```

Iniciado em segundo plano, consultado com `curl`, parado com `kill`:

```
ana@dev:~/shop$ python relay.py & sleep 1; curl -sN -X POST localhost:8500/ask -d '{"question": "Say hello in five words."}'; kill $!
event: text
data: {"text": "Hello"}

event: text
data: {"text": " from"}

event: text
data: {"text": " the"}

event: text
data: {"text": " shop"}

event: text
data: {"text": "'s"}

event: text
data: {"text": " assistant"}

event: text
data: {"text": "."}

event: done
data: {"stop_reason": "end_turn"}

```

**Os eventos do relay são dele**, menores que os do provedor: `text`, `done` e `error`. O navegador
não precisa saber que provedor está atrás do relay, nem que existe um, e o relay pode trocar de
provedor sem mudar a página.

## O lado da página

Um navegador tem dois jeitos de ler um stream. O `EventSource` foi feito para server-sent events,
mas só manda requisições `GET`, sem corpo. O `fetch` consegue fazer `POST` de uma pergunta e ler a
resposta conforme chega. Esta é a versão com `fetch`, rodada com Node, cujo `fetch` é a mesma API
que um navegador tem:

```schooling-example
{
  "language": "javascript",
  "file": "client.mjs",
  "parts": [
    {
      "code": "// What a browser page does with the relay, run here with Node's fetch, which is the same API.\n"
    },
    {
      "code": "const response = await fetch(\"http://127.0.0.1:8500/ask\", {\n  method: \"POST\",\n  headers: { \"Content-Type\": \"application/json\" },\n  body: JSON.stringify({ question: process.argv[2] }),\n});\n",
      "note": "**O `fetch` consegue mandar a pergunta no corpo**, o que o `EventSource` não consegue."
    },
    {
      "code": "const reader = response.body.pipeThrough(new TextDecoderStream()).getReader();\nlet buffer = \"\";\nlet shown = \"\";\nfor (;;) {\n  const { value, done } = await reader.read();\n  if (done) break;\n",
      "note": "**O corpo é lido conforme chega**, decodificado de bytes para texto no caminho."
    },
    {
      "code": "  buffer += value;\n  const events = buffer.split(\"\\n\\n\");\n  buffer = events.pop();\n",
      "note": "**Um evento termina numa linha em branco.** O que vem depois da última é meio evento, guardado para a próxima leitura."
    },
    {
      "code": "  for (const raw of events) {\n    const name = raw.match(/^event: (.*)$/m)[1];\n    const data = JSON.parse(raw.match(/^data: (.*)$/m)[1]);\n    if (name === \"text\") shown += data.text;\n    if (name === \"done\") console.log(`${shown}\\n[done: ${data.stop_reason}]`);\n    if (name === \"error\") console.log(`${shown}\\n[error: ${data.message}]`);\n  }\n}",
      "note": "**Cada evento completo é tratado**: texto é acrescentado, `done` e `error` encerram a resposta."
    }
  ]
}
```

```
ana@dev:~/shop$ python relay.py & sleep 1; node client.mjs "Explain in a paragraph why the cart stores prices in cents."; kill $!
The cart stores prices as integer cents because a float cannot hold most decimal amounts exactly. In binary floating point, 0.1 plus 0.2 is not 0.3, and a total built from many such sums drifts by a cent here and there. Integers add exactly, so the cart adds cents and formats them only at the edge, when it prints a price for a person.
[done: end_turn]
```

Numa página, o `shown` iria para um elemento a cada evento `text`, em vez de ser impresso no fim.
**O buffer é a parte que as pessoas esquecem.** Uma leitura da rede pode terminar no meio de um
evento, então o código guarda o que vem depois da última linha em branco e espera o resto.

## O que mais o relay precisa fazer

- **Conferir quem pergunta.** O relay gasta dinheiro a cada pergunta. Um aberto a qualquer um na
  internet é uma chave de API com passos extras.
- **Limitar a pergunta.** O tamanho dela, e com que frequência um usuário pode perguntar. Os limites
  da chave, da aula 2, valem para todos os usuários juntos, então um usuário consegue gastar o de
  todos.
- **Desligar buffers no caminho.** Um proxy ou um framework que junta a resposta antes de mandá-la
  entrega ao navegador a resposta inteira de uma vez, e o stream some sem erro nenhum. O
  `Cache-Control: no-cache` é o começo; alguns proxies precisam de um cabeçalho próprio também.
