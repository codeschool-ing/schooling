---
title: Falhas, e as novas tentativas que as escondem
version: 2
---

Um fornecedor recusa pedidos. Ele está sobrecarregado (503, ou o 529 da Anthropic), está limitando a
taxa desta chave (429), ou algo do lado dele quebrou (500). A maioria disso se resolve num segundo, e é
por isso que todo SDK tenta de novo, e por isso que uma falha no fornecedor em geral não é uma falha
para o cliente. A pergunta para o monitoramento é se alguém ainda consegue vê-la.

O Ollama no seu próprio computador não faz nada disso, a não ser que algo esteja muito errado, e uma
aula não pode esperar pela tarde ruim de um fornecedor. Então o `flaky.py` fica entre o assistente e o
Ollama e falha de propósito, quando mandado. É um proxy pequeno, escrito só com a biblioteca padrão do
Python: todo pedido que recebe ele repassa ao Ollama e devolve a resposta, a não ser que tenha sido
mandado recusá-lo ou cortar o stream no meio. Salve-o em `~/obs`:

```python
"""flaky.py: a proxy in front of Ollama that fails on purpose, for lesson 4.

    python flaky.py                      # listens on 127.0.0.1:11435, forwards to 127.0.0.1:11434
    curl -s -X POST 127.0.0.1:11435/flaky -d '{"fail_rate": 0.3}'

A real provider refuses requests and drops streams on days nobody chooses.
This one does it when told to, so the assistant's retries can be watched.
Only requests for a chat completion are touched; embeddings go straight through.
POST /flaky sets any of: fail_rate (share of chat requests refused at random),
fail (refuse the next N), status (what a refusal answers, 503 by default),
cut_after (end the next stream after N pieces, without a finish), seed.
Every request it forwards or refuses is one line in flaky.log.
"""
import json
import random
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

UPSTREAM = "http://127.0.0.1:11434"
config = {"fail_rate": 0.0, "fail": 0, "status": 503, "cut_after": None, "seed": 7}
rng = random.Random(config["seed"])
count = 0


class Proxy(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def log(self, status):
        with open("flaky.log", "a") as f:
            f.write(json.dumps({"n": count, "path": self.path, "status": status}) + "\n")

    def answer(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        global count, rng
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        if self.path == "/flaky":
            config.update(json.loads(body or b"{}"))
            rng = random.Random(config["seed"])
            return self.answer(200, config)
        count += 1
        chat = self.path.endswith("/chat/completions")
        if chat and (config["fail"] > 0 or rng.random() < config["fail_rate"]):
            config["fail"] = max(0, config["fail"] - 1)
            self.log(config["status"])
            return self.answer(config["status"], {"error": {
                "message": "flaky.py refused this request on purpose", "type": "overloaded_error"}})
        request = urllib.request.Request(UPSTREAM + self.path, body, {"Content-Type": "application/json"})
        try:
            upstream = urllib.request.urlopen(request)
        except urllib.error.HTTPError as e:
            self.log(e.code)
            return self.answer(e.code, json.loads(e.read() or b"{}"))
        self.log(upstream.status)
        self.send_response(upstream.status)
        self.send_header("Content-Type", upstream.headers["Content-Type"])
        self.send_header("Connection", "close")
        self.end_headers()
        cut, pieces = config["cut_after"], 0
        for line in upstream:
            if cut is not None and line.startswith(b"data: {"):
                pieces += 1
                if pieces > cut:
                    config["cut_after"] = None
                    break
            self.wfile.write(line)
            self.wfile.flush()
        self.close_connection = True


ThreadingHTTPServer(("127.0.0.1", 11435), Proxy).serve_forever()
```

Inicie-o num segundo terminal, com o ambiente ativo, e deixe-o rodando:

```sh
python flaky.py
```

De volta ao primeiro terminal, aponte o SDK para ele em vez do Ollama, e mande-o recusar três pedidos
de chat em cada dez, ao acaso. O `ten.py` então faz dez das perguntas da semana, uma linha cada:

```python
"""ten.py: ten questions through the assistant, one line each."""
import json

import assistant
import telemetry

telemetry.setup()
for q in [x["phrasings"][0] for x in json.load(open("data/topics.json"))[:10]]:
    try:
        reply, _, trace = assistant.ask(q)
        print(f"{trace[:8]}  ok      {reply[:60]}")
    except Exception as e:
        print(f"{'':8}  FAILED  {type(e).__name__}: {e}")
```

```
ana@dev:~/obs$ export OPENAI_BASE_URL=http://127.0.0.1:11435/v1
ana@dev:~/obs$ curl -s -X POST 127.0.0.1:11435/flaky -d '{"fail_rate": 0.3}'; echo
{"fail_rate": 0.3, "fail": 0, "status": 503, "cut_after": null, "seed": 7}
ana@dev:~/obs$ rm -f spans.jsonl; python ten.py
4b9557ba  ok      You have 30 days from the date of delivery to return a print
81c6bd42  ok      According to source [1], express delivery costs R$ 29.90.
a13fa2e0  ok      According to [1], we refund within three working days of the
e5f2bca5  ok      According to [1], standard delivery is free on orders over R
42a9eacc  ok      You can read your e-books on up to six devices at the same t
b60268f5  ok      According to [1], a gift card is valid for two years from th
6219b0fe  ok      I could not find that in our documents.
1f352d57  ok      I could not find that in our documents.
d6617692  ok      According to [1], a standard parcel is considered lost when 
11aa7cdf  ok      According to [1], the customer pays for the return postage.
```

Dez perguntas, dez respostas. Nada do que o cliente viu falhou. O `errors.py` lê os spans:

```python
"""errors.py: the model attempts in spans.jsonl, and what became of the requests that made them."""
import json
from collections import Counter

spans = [json.loads(line) for line in open("spans.jsonl")]
chats = [s for s in spans if s["name"].startswith("chat ")]
asks = [s for s in spans if s["name"] == "ask"]
gens = [s for s in spans if s["name"] == "generate"]
print(f"attempts {len(chats)}, failed {sum(s['status'] == 'ERROR' for s in chats)}")
print("requests by attempts needed:", dict(sorted(Counter(s["attributes"]["app.attempts"] for s in gens).items())))
print(f"requests {len(asks)}, failed {sum(s['status'] == 'ERROR' for s in asks)}")
```

```
ana@dev:~/obs$ python errors.py
attempts 17, failed 8
requests by attempts needed: {1: 3, 2: 4, 3: 2}
requests 10, failed 0
```

**Oito das dezessete tentativas falharam, e nenhum dos dez pedidos falhou.** Três pedidos precisaram
de uma tentativa, quatro precisaram de duas, dois precisaram de três, e um foi recusado pela busca
antes de qualquer chamada a modelo. Um dos traces com nova tentativa:

```
ana@dev:~/obs$ python tree.py 81c6bd42
trace 81c6bd425c703c9d91087c4a37d4f72e   start(ms) took(ms)
      0   3,807 ms  ask
      0     175 ms    embed
    175       0 ms    search
    175   3,631 ms    generate
    175       9 ms      chat llama3.2:3b  ERROR InternalServerError: Error code: 503 - {'error': {'message': 'flaky.py refused this request on purpose', 'type': 'overloaded_error'}}
    685   3,121 ms      chat llama3.2:3b
  3,807       0 ms    check_citations
ana@dev:~/obs$ python tree.py --attrs 81c6bd42 | grep -E "ERROR|attempts"
                       app.attempts = 2
    175       9 ms      chat llama3.2:3b  ERROR InternalServerError: Error code: 503 - {'error': {'message': 'flaky.py refused this request on purpose', 'type': 'overloaded_error'}}
```

A primeira tentativa foi recusada com um 503 em 9 ms. O assistente esperou meio segundo, o seu
primeiro recuo, e pediu de novo; a segunda tentativa foi respondida. O pedido levou 3.807 ms, meio
segundo deles esperando para tentar de novo, e o cliente só viu uma resposta mais lenta.

## Duas taxas de erro

A semana precisa das duas, e elas significam coisas diferentes:

- **A taxa de erro por tentativa**, chamadas a modelo que falharam sobre todas as chamadas: 8 em 17
  aqui, mais que os três em dez pedidos ao flaky.py, como uma amostra pequena tirada ao acaso muitas
  vezes fica. É a saúde do fornecedor. Quando sobe, o fornecedor está num dia ruim, e as novas tentativas
  estão absorvendo.
- **A taxa de erro por pedido**, pedidos que chegaram ao cliente como erro: 0 em 10. É a experiência
  do cliente. Quando sobe, as novas tentativas se esgotaram.

Um alerta só na segunda dispara quando já é tarde demais. Um alerta só na primeira dispara a cada
soluço do fornecedor que as novas tentativas absorveram e ninguém percebeu. **Uma taxa de erro por
tentativa subindo com a taxa por pedido estável é um aviso; as duas subindo é um incidente.** A aula 16
transforma isso em regras.

## Uma nova tentativa que o trace não vê

O assistente tenta de novo no próprio código para que cada tentativa seja um span. A maior parte do
código deixa isso para o SDK, cujo padrão é duas novas tentativas. O `sdk_retry.py` faz uma chamada
desse jeito, com um span em volta, enquanto o flaky.py recusa os dois próximos pedidos:

```python
"""sdk_retry.py: the SDK retrying inside one span, where the trace cannot see it."""
from openai import OpenAI

import telemetry

telemetry.setup()
client = OpenAI(max_retries=2)
with telemetry.span("chat llama3.2:3b", **{"gen_ai.request.model": "llama3.2:3b"}):
    client.chat.completions.create(model="llama3.2:3b", temperature=0, max_tokens=60,
                                   messages=[{"role": "user", "content": "How long is a gift card valid?"}])
```

```
ana@dev:~/obs$ rm -f spans.jsonl; python sdk_retry.py; python tree.py
trace d0a37dc5e36ef0ffd41382477b17df5a   start(ms) took(ms)
      0   8,096 ms  chat llama3.2:3b
ana@dev:~/obs$ tail -3 flaky.log
{"n": 28, "path": "/v1/chat/completions", "status": 503}
{"n": 29, "path": "/v1/chat/completions", "status": 503}
{"n": 30, "path": "/v1/chat/completions", "status": 200}
```

O trace mostra **um span de 8.096 ms, e nenhum erro**. O log do flaky.py mostra o que aconteceu: os
pedidos 28 e 29 foram recusados com 503, e o 30 foi respondido. O SDK esperou, tentou de novo duas
vezes e devolveu sucesso, e de dentro da aplicação nada disso é visível. O span não está errado, a
chamada deu certo mesmo, mas uma semana disso mostraria um fornecedor ficando mais lento quando na
verdade ele estava falhando um terço das vezes.

Duas saídas. Tentar de novo no próprio código, como faz o `assistant.py`, com `max_retries=0` no
cliente. Ou manter as novas tentativas do SDK e instrumentar por baixo delas: uma instrumentação no
nível do HTTP vê cada pedido que o SDK manda, novas tentativas incluídas, como um span próprio. De
qualquer jeito, **as falhas do fornecedor têm de ser contadas em algum lugar, ou o primeiro sinal delas
vai ser um cliente**.
