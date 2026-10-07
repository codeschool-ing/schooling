---
title: Rerank, aquilo pelo que a Cohere é conhecida
version: 1
---

Um **reranker** é um modelo com uma tarefa só: dada uma pergunta e uma lista de documentos, pôr os
documentos em ordem de quão bem eles a respondem. Ele não escreve nada. É o segundo estágio da
recuperação, o conserto que a aula 1 seção 11 apontou para fatos ausentes: uma busca rápida acha
cinquenta trechos que podem ser relevantes, e um reranker escolhe os cinco que valem ir para o
prompt. `embeddings-vectors` e `rag`, os dois cursos depois deste, constroem esse caminho; esta
seção é sobre o que o modelo é e como ele é vendido.

A tabela dá preço ao reranker da Cohere numa unidade diferente de todo modelo de chat até aqui:

```
ana@desk:~/desk$ python sheet.py show rerank-v4.0-pro | grep -E "^(input_cost_per_query|max_input|mode|source)"
input_cost_per_query                       0.0025
max_input_tokens                           32768
mode                                       rerank
source                                     https://cohere.com/pricing
```

**US$ 0,0025 por consulta**, não por token: uma busca é cobrada como uma unidade, seja qual for o
número de documentos. A janela dele, 32.768 tokens, limita quanto texto uma consulta consegue
ordenar.

## Como é uma requisição de rerank

O SDK da própria Cohere, `cohere`, é o cliente, e ele traz um problema junto. Ele fixa uma versão
antiga de uma biblioteca de que a aula 19 precisa, e instalá-lo no ambiente da mesa troca essa
biblioteca sem perguntar:

```
ana@desk:~/desk$ pip install -q cohere==7.2.0; pip list | grep -iE "^(cohere|huggingface)"
cohere                             7.2.0
huggingface_hub                    1.33.0
```

O `huggingface_hub` estava em 2.1.1 quando a aula 1 o instalou e agora está em 1.33.0, e nada disse
isso. **Uma biblioteca que fixa outra pode rebaixá-la em silêncio**, e o programa que quebra é
outro, semanas depois. O conserto é um ambiente só para a biblioteca que fixa, e o da mesa refeito:

```
ana@desk:~/desk$ python3 -m venv .venv-cohere && .venv-cohere/bin/pip install -q cohere==7.2.0
ana@desk:~/desk$ rm -rf .venv && python3 -m venv .venv && .venv/bin/pip install -q openai==3.24.0 anthropic==1.11.0 ollama==0.6.3 google-genai==2.28.0 mistralai==3.0.0 huggingface_hub==2.1.1 && .venv/bin/pip list | grep -iE "^(cohere|huggingface)"
huggingface_hub                    2.1.1
```

Nada neste computador é um reranker: o Ollama não tem endpoint de rerank, e sem uma chave da Cohere
não há a quem perguntar. O que dá para ver é a requisição, e para isso este curso tem um programa
pequeno que as aulas 14 a 21 usam de novo. O `relay.py` fica entre um programa e o Ollama, repassa
toda requisição e anota cada uma em `wire.jsonl`. Duas opções fazem ele se comportar mal de
propósito, para as aulas sobre erros e limites:

```python
"""relay.py: a door in front of Ollama that writes down every request.

    python relay.py                 listen on 127.0.0.1:8500 and pass every request on to Ollama
    python relay.py --fail 529:2    answer the next two requests with 529 instead (lesson 17)
    python relay.py --rpm 5         allow five requests a minute, and 429 the rest (lesson 21)
    python relay.py show [--headers H,H] [--body] [--count N]
                                    print the last request, or a line for each of the last N

Each request is one line of wire.jsonl: the method, the path, the headers (keys
cut short), the body and the status it got. Standard library only.
"""
import argparse
import http.client
import http.server
import json
import time

LOG = "wire.jsonl"
OLLAMA = ("127.0.0.1", 11434)
SECRET = {"authorization", "x-api-key", "x-goog-api-key"}
SKIP = {"host", "content-length", "connection", "accept-encoding"}
DROP = {"transfer-encoding", "connection", "content-length", "date", "server"}  # set again below


class Relay(http.server.BaseHTTPRequestHandler):
    fail, fail_left, rpm, seen = 0, 0, 0, []

    def handle_one(self):
        body = self.rfile.read(int(self.headers.get("content-length") or 0))
        now, cls = time.time(), type(self)
        cls.seen = [t for t in cls.seen if now - t < 60]
        if cls.fail_left:
            cls.fail_left -= 1
            status, data, headers = cls.fail, b'{"type": "error", "error": {"type": "overloaded_error"}}', []
        elif cls.rpm and len(cls.seen) >= cls.rpm:
            wait = int(60 - (now - cls.seen[0])) + 1
            status, data, headers = 429, b'{"error": "rate limited"}', [("retry-after", str(wait))]
        else:
            cls.seen.append(now)
            up = http.client.HTTPConnection(*OLLAMA, timeout=600)
            sent = {k: v for k, v in self.headers.items() if k.lower() != "host"}
            up.request(self.command, self.path, body, sent)
            r = up.getresponse()
            status, data = r.status, r.read()
            headers = [(k, v) for k, v in r.getheaders() if k.lower() not in DROP]
        seen = {k.lower(): (v[:12] + "…" if k.lower() in SECRET else v) for k, v in self.headers.items()}
        with open(LOG, "a") as f:
            f.write(json.dumps({"method": self.command, "path": self.path, "headers": seen,
                                "request": json.loads(body) if body else None, "status": status}) + "\n")
        self.send_response(status)
        for k, v in headers:
            self.send_header(k, v)
        self.send_header("content-length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    do_GET = do_POST = do_DELETE = handle_one

    def log_message(self, *args):
        pass


def show(a):
    rows = [json.loads(line) for line in open(LOG)]
    if a.count:
        for r in rows[-a.count:]:
            print(f"{r['method']} {r['path']} -> {r['status']} {(r['request'] or {}).get('model', '')}")
        return
    r = rows[-1]
    if not a.body:
        print(f"{r['method']} {r['path']}")
        wanted = [h.strip().lower() for h in a.headers.split(",") if h.strip()]
        for k, v in r["headers"].items():
            if (k in wanted) if wanted else (k not in SKIP):
                print(f"{k}: {v}")
        print()
    print(json.dumps(r["request"], indent=2, ensure_ascii=False))


p = argparse.ArgumentParser(prog="relay.py")
p.add_argument("cmd", nargs="?", choices=["show"])
p.add_argument("--fail", default="")
p.add_argument("--rpm", type=int, default=0)
p.add_argument("--headers", default="")
p.add_argument("--body", action="store_true")
p.add_argument("--count", type=int, default=0)
a = p.parse_args()
if a.cmd == "show":
    show(a)
else:
    if a.fail:
        Relay.fail, Relay.fail_left = (int(x) for x in a.fail.split(":"))
    Relay.rpm = a.rpm
    print(f"relay on 127.0.0.1:8500, to Ollama on {OLLAMA[1]}, writing {LOG}", flush=True)
    http.server.ThreadingHTTPServer(("127.0.0.1", 8500), Relay).serve_forever()
```

Suba-o num segundo terminal, em `~/desk`, e deixe-o rodando:

```
ana@desk:~/desk$ python relay.py
relay on 127.0.0.1:8500, to Ollama on 11434, writing wire.jsonl
```

O `rerank.py` faz a pergunta que o e-mail de um cliente levanta contra quatro linhas da política da
loja, mandando-a ao relay:

```python
import cohere

# no Cohere key, so the relay is the address: it writes the request down and passes it to Ollama
co = cohere.ClientV2(api_key="ollama", base_url="http://127.0.0.1:8500")
policies = [
    "Orders ship from our warehouse within two working days of payment.",
    "Refunds for damaged or misprinted books are paid to the original card within ten days.",
    "Gift vouchers are sent by e-mail on the date the buyer chooses.",
    "An address can be changed until the order leaves the warehouse.",
]
r = co.rerank(model="rerank-v4.0-pro", query="my book arrived damaged, I want my money back",
              documents=policies, top_n=2)
for hit in r.results:
    print(f"{hit.relevance_score:.4f}  {policies[hit.index]}")
```

```
ana@desk:~/desk$ .venv-cohere/bin/python rerank.py 2>&1 | tail -1
cohere.core.api_error.ApiError: headers: {'server': 'BaseHTTP/0.6 Python/3.13.16', 'date': 'Wed, 07 Oct 2026 17:00:51 GMT', 'content-type': 'text/plain', 'content-length': '18'}, status_code: 404, body: 404 page not found
```

O **404** é o Ollama dizendo que não tem esse caminho; com uma chave e o endereço da Cohere, o mesmo
programa imprime duas políticas com nota. A requisição é o que o SDK mandou, seja quem for que a
responda:

```
ana@desk:~/desk$ python relay.py show --headers user-agent,authorization
POST /v2/rerank
user-agent: cohere/7.2.0
authorization: Bearer ollam…

{
  "model": "rerank-v4.0-pro",
  "query": "my book arrived damaged, I want my money back",
  "documents": [
    "Orders ship from our warehouse within two working days of payment.",
    "Refunds for damaged or misprinted books are paid to the original card within ten days.",
    "Gift vouchers are sent by e-mail on the date the buyer chooses.",
    "An address can be changed until the order leaves the warehouse."
  ],
  "top_n": 2
}
```

A requisição é a interface inteira: um modelo, uma pergunta, os documentos como strings simples, e
quantos devolver. A resposta, como os próprios tipos do SDK a descrevem, dá a cada resultado dois
campos:

```
ana@desk:~/desk$ .venv-cohere/bin/python -c "import cohere; print(list(cohere.V2RerankResponseResultsItem.model_fields))"
['index', 'relevance_score']
```

**Um índice na lista que você mandou e uma nota de relevância**, não o texto, então o programa volta
para os próprios documentos, como o `rerank.py` faz com `policies[hit.index]`.
