---
title: O LangSmith, e o que o SDK dele manda
version: 2
---

O LangSmith é a plataforma da LangChain para os mesmos trabalhos: traces de chamadas a modelo,
conjuntos de dados, avaliações, prompts, e filas em que pessoas revisam execuções. É um serviço
hospedado, nos Estados Unidos ou na União Europeia, e instalá-lo nas próprias máquinas é oferecido a
clientes corporativos. **Ele não é rodado neste curso.** O que pode ser rodado é o SDK de Python dele,
que é código aberto e é a parte que mora na sua aplicação. Aponte-o para um programa seu que responda
como o endpoint de ingestão do LangSmith e guarde cada corpo que recebe, e o que chegar ali é
exatamente o que teria saído da sua máquina.

Esse programa é o `recorder.py`. Ele é um **dublê**, com menos de noventa linhas, e não é o LangSmith:
responde a única pergunta que o SDK faz antes de mandar, e anota o resto. Salve-o em `~/obs`:

```python
"""recorder.py: a stand-in for LangSmith's ingest endpoint, on 127.0.0.1:8700, for lesson 6.

LangSmith is a hosted service, and installing it on your own machines is
something LangChain offers to enterprise customers only, so the course could
not run it. What the lesson CAN show is what the LangSmith SDK sends, which is
the part that leaves your machine. So the SDK is pointed here, and this
program does three things and nothing else:

    GET  /info          answers as an ingest endpoint does, so the SDK sends
    POST /runs/...      every body it receives is kept, as it arrived, one JSON
                        line per request in recorder/requests.jsonl: the path,
                        the content type and the body (decoded if it is JSON
                        or multipart, so a person can read it)
    anything else       202, so the SDK carries on

It stores nothing else, shows nothing, and is not LangSmith. What LangSmith
does with a run after it arrives is not shown here.
"""
import json
import os
from email.parser import BytesParser
from email.policy import HTTP
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

DIR = "recorder"


def decode(ctype, raw):
    if ctype.startswith("application/json"):
        return json.loads(raw or b"null")
    if ctype.startswith("multipart/"):
        msg = BytesParser(policy=HTTP).parsebytes(b"Content-Type: " + ctype.encode() + b"\r\n\r\n" + raw)
        parts = []
        for p in msg.iter_parts():
            body = p.get_payload(decode=True) or b""
            try:
                body = json.loads(body)
            except ValueError:
                body = body.decode("utf-8", "replace")
            parts.append({"name": p.get_param("name", header="content-disposition"), "body": body})
        return parts
    return raw.decode("utf-8", "replace")


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def reply(self, status, obj):
        data = json.dumps(obj).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path.split("?")[0].rstrip("/") == "/info":
            return self.reply(200, {"version": "recorder", "batch_ingest_config": {
                "use_multipart_endpoint": True, "scale_up_qsize_trigger": 1000, "scale_up_nthreads_limit": 16,
                "scale_down_nempty_trigger": 4, "size_limit": 100, "size_limit_bytes": 20971520}})
        self.reply(200, {})

    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        if self.headers.get("Content-Encoding") == "zstd":
            raw = b""  # compressed bodies are not decoded; the lesson turns compression off
        ctype = self.headers.get("Content-Type", "")
        os.makedirs(DIR, exist_ok=True)
        with open(os.path.join(DIR, "requests.jsonl"), "a") as f:
            f.write(json.dumps({"path": self.path, "content_type": ctype.split(";")[0],
                                "body": decode(ctype, raw)}, ensure_ascii=False) + "\n")
        self.reply(202, {})

    do_PATCH = do_PUT = do_POST


def main():
    srv = ThreadingHTTPServer(("127.0.0.1", 8700), Handler)
    srv.daemon_threads = True
    print("recorder listening on http://127.0.0.1:8700", flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main()
```

Inicie-o em segundo plano, a partir de `~/obs`, e deixe-o rodando enquanto lê esta seção:

```sh
python recorder.py &
```

O `ls_ask.py` rastreia uma pergunta dos dois jeitos que o SDK oferece: uma função decorada com
`@traceable`, e o cliente da OpenAI embrulhado com `wrap_openai`, que registra cada chamada feita por
ele.

```python
"""ls_ask.py: one question, traced with the LangSmith SDK, which sends its runs to LANGSMITH_ENDPOINT."""
import sys

from langsmith import Client, traceable
from langsmith.wrappers import wrap_openai
from openai import OpenAI

import redact

if "--redact" in sys.argv:   # LangSmith's own hooks, applied before anything is sent
    client = Client(hide_inputs=lambda d: {k: redact.redact(str(v)) for k, v in d.items()},
                    hide_outputs=lambda d: {k: redact.redact(str(v)) for k, v in d.items()},
                    omit_traced_runtime_info=True)
else:
    client = Client()
openai = wrap_openai(OpenAI())


@traceable(name="ask", client=client)
def ask(question):
    reply = openai.chat.completions.create(model="llama3.2:3b", temperature=0, messages=[{"role": "user", "content": question}])
    return reply.choices[0].message.content


print(ask("Hi, I'm Joana Prado (joana.prado@example.com). How long is a gift card valid?"))
client.flush()
```

O SDK é configurado pelo ambiente: `LANGSMITH_TRACING` o liga, `LANGSMITH_ENDPOINT` diz para onde
mandar, `LANGSMITH_PROJECT` dá nome ao projeto. A compressão é desligada para que o gravador consiga
ler os corpos. O `sent.py` imprime o que chegou:

```python
"""sent.py: what the recorder received, one line per run, with what each carried."""
import json

for request in map(json.loads, open("recorder/requests.jsonl")):
    for part in request["body"]:
        op, run, *field = part["name"].split(".")
        body = part["body"]
        if not field:
            print(f"{op:5} run {run[:8]} {body['name']} ({body['run_type']})")
        elif body:
            print(f"        {field[0]}: {json.dumps(body, ensure_ascii=False)[:110]}")
```

```
ana@dev:~/obs$ LANGSMITH_TRACING=true LANGSMITH_ENDPOINT=http://127.0.0.1:8700 LANGSMITH_API_KEY=the-recorder-ignores-it LANGSMITH_PROJECT=marginalia-assistant LANGSMITH_DISABLE_RUN_COMPRESSION=true python ls_ask.py
Hello Joana!

The validity period of a gift card can vary depending on the issuer and the type of card. Some gift cards may be valid for a specific period, such as 1-2 years, while others may be valid for a longer or shorter period.

Typically, gift cards are valid for:

* 1-2 years from the date of purchase
* 3-5 years from the date of purchase (for premium or high-value cards)
* Until the balance is depleted (in some cases)

It's always best to check the specific terms and conditions of the gift card issuer, as they may have different policies. You can usually find this information on the gift card itself, on the issuer's website, or by contacting their customer service.

If you're unsure about the validity of your gift card, I recommend reaching out to the issuer to confirm the expiration date.

Hope this helps, Joana!
ana@dev:~/obs$ python sent.py
post  run 01a1191a ask (chain)
        inputs: {"question": "Hi, I'm Joana Prado (joana.prado@example.com). How long is a gift card valid?"}
        extra: {"metadata": {"ls_method": "traceable", "LANGSMITH_PROJECT": "marginalia-assistant", "LANGSMITH_TRACING": "tru
post  run 01a1191a ChatOpenAI (llm)
        inputs: {"messages": [{"role": "user", "content": "Hi, I'm Joana Prado (joana.prado@example.com). How long is a gift c
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ll
        serialized: {"name": "ChatOpenAI"}
patch run 01a1191a ask (chain)
        outputs: {"output": "Hello Joana!\n\nThe validity period of a gift card can vary depending on the issuer and the type o
        extra: {"metadata": {"ls_method": "traceable", "LANGSMITH_PROJECT": "marginalia-assistant", "LANGSMITH_TRACING": "tru
patch run 01a1191a ChatOpenAI (llm)
        outputs: {"id": "chatcmpl-339", "choices": [{"finish_reason": "stop", "index": 0, "logprobs": null, "message": {"conten
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ll
```

A palavra do LangSmith para um span é **run** (execução), e cada run é mandado duas vezes: um `post`
quando começa, com as entradas, e um `patch` quando termina, com as saídas. A função é um run do tipo
`chain`, a chamada ao modelo um run do tipo `llm` dentro dela.

Primeiro, a resposta. O `ls_ask.py` pergunta direto ao modelo, sem nenhum documento da Marginalia, e
o `llama3.2:3b` responde com o que aprendeu em outro lugar: vales-presente em geral, de um a cinco
anos, confirme com quem emitiu. A resposta da própria Marginalia, dois anos, está num documento que
ele nunca viu. Não é disso que esta seção trata, mas é por isso que o assistente busca nos
documentos antes de perguntar.

Depois, leia o que foi junto. **A mensagem do cliente, endereço incluído, inteira**, nos dois runs.
A resposta inteira do modelo. E em `extra`, metadados que o SDK acrescenta por conta própria: as
variáveis de ambiente que o configuraram, com nome e valor, e detalhes de execução que o `sent.py`
corta na borda da tela: a versão do SDK, a versão do Python, o sistema operacional e a descrição da
plataforma da máquina. Nada disso é segredo aqui. Tudo isso sai da máquina, e uma equipe que não
olhou não vai saber.

## Os ganchos do próprio SDK

O cliente do LangSmith aceita funções que veem as entradas e as saídas antes de serem mandadas:
`hide_inputs`, `hide_outputs`, e um `anonymizer` para padrões; e `omit_traced_runtime_info` deixa de
fora os detalhes de execução. A execução com `--redact` passa o `redact()` da aula 2 para os dois
primeiros:

```
ana@dev:~/obs$ rm recorder/requests.jsonl
ana@dev:~/obs$ LANGSMITH_TRACING=true LANGSMITH_ENDPOINT=http://127.0.0.1:8700 LANGSMITH_API_KEY=the-recorder-ignores-it LANGSMITH_PROJECT=marginalia-assistant LANGSMITH_DISABLE_RUN_COMPRESSION=true python ls_ask.py --redact
Hello Joana!

The validity period of a gift card can vary depending on the issuer and the type of card. Some gift cards may be valid for a specific period, such as 1-2 years, while others may be valid for a longer or shorter period.

Typically, gift cards are valid for:

* 1-2 years from the date of purchase
* 3-5 years from the date of purchase (for premium or high-value cards)
* Until the balance is depleted (in some cases)

It's always best to check the specific terms and conditions of the gift card issuer, as they may have different policies. You can usually find this information on the gift card itself, on the issuer's website, or by contacting their customer service.

If you're unsure about the validity of your gift card, I recommend reaching out to the issuer to confirm the expiration date.

Hope this helps, Joana!
ana@dev:~/obs$ python sent.py
post  run 01a1191b ask (chain)
        inputs: {"question": "Hi, I'm Joana Prado ([email]). How long is a gift card valid?"}
        extra: {"metadata": {"ls_method": "traceable"}}
post  run 01a1191b ChatOpenAI (llm)
        inputs: {"messages": "[{'role': 'user', 'content': \"Hi, I'm Joana Prado ([email]). How long is a gift card valid?\"}]
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ll
        serialized: {"name": "ChatOpenAI"}
patch run 01a1191b ask (chain)
        outputs: {"output": "Hello Joana!\n\nThe validity period of a gift card can vary depending on the issuer and the type o
        extra: {"metadata": {"ls_method": "traceable"}}
patch run 01a1191b ChatOpenAI (llm)
        outputs: {"id": "chatcmpl-883", "choices": "[{'finish_reason': 'stop', 'index': 0, 'logprobs': None, 'message': {'conte
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ll
```

O endereço sumiu das entradas, e as variáveis de ambiente e os detalhes de execução sumiram de
`extra`. **O nome dela não.** "Joana Prado" continua na pergunta, porque os padrões da aula 2 acham
o que tem forma e um nome não tem, e o modelo, tendo o nome, o usou: "Hello Joana!" abre a resposta,
que também foi mandada. Limpar a entrada não faz nada pelo que o modelo escreve de volta com ela.

Mais duas coisas valem ser notadas. Os ganchos recebem as entradas como um dicionário, e o `str(v)` simples
do `ls_ask.py` transformou a lista de mensagens no texto de uma lista, que uma tela vai mostrar como
texto e não como mensagens; um gancho cuidadoso limpa dentro da estrutura. E o run do próprio modelo
manteve o `ls_model_name` e os metadados do fornecedor, o que está certo, e lembra que **só uma
inspeção do que chegou** diz o que uma configuração cobre.

É o mesmo padrão do exportador da aula 2, oferecido pelo fornecedor: limpar no processo, antes de
mandar qualquer coisa. Confiar no gancho de um fornecedor ou no próprio é uma questão de julgamento;
testar qualquer um dos dois com um canário não é.
