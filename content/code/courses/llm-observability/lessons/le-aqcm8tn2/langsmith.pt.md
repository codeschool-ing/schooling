---
title: O LangSmith, e o que o SDK dele manda
version: 1
---

O LangSmith é a plataforma da LangChain para os mesmos trabalhos: traces de chamadas a modelo,
conjuntos de dados, avaliações, prompts, e filas em que pessoas revisam execuções. É um serviço
hospedado, nos Estados Unidos ou na União Europeia, e instalá-lo nas próprias máquinas é oferecido a
clientes corporativos. **Ele não foi rodado para este curso.** O que pôde ser rodado é o SDK de Python
dele, que é código aberto e é a parte que mora na sua aplicação, apontado para o `lab/recorder.py`: um
pequeno programa na porta 8700 que responde como o endpoint de ingestão do LangSmith e guarda cada corpo
que recebe. O que chega ali é exatamente o que teria saído da máquina.

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
    reply = openai.chat.completions.create(model="extract-1", messages=[{"role": "user", "content": question}])
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

for request in map(json.loads, open("/var/lib/recorder/requests.jsonl")):
    for part in request["body"]:
        op, run, *field = part["name"].split(".")
        body = part["body"]
        if not field:
            print(f"{op:5} run {run[:8]} {body['name']} ({body['run_type']})")
        elif body:
            print(f"        {field[0]}: {json.dumps(body, ensure_ascii=False)[:110]}")
```

```
ana@lab:~/obs$ LANGSMITH_TRACING=true LANGSMITH_ENDPOINT=http://127.0.0.1:8700 LANGSMITH_API_KEY=lab-langsmith-key-0001 LANGSMITH_PROJECT=marginalia-assistant LANGSMITH_DISABLE_RUN_COMPRESSION=true python ls_ask.py
Marginalia gift cards are valid for one year from purchase.
ana@lab:~/obs$ python sent.py
post  run 01a11042 ask (chain)
        inputs: {"question": "Hi, I'm Joana Prado (joana.prado@example.com). How long is a gift card valid?"}
        extra: {"metadata": {"ls_method": "traceable", "LANGSMITH_PROJECT": "marginalia-assistant", "LANGSMITH_TRACING": "tru
post  run 01a11042 ChatOpenAI (llm)
        inputs: {"messages": [{"role": "user", "content": "Hi, I'm Joana Prado (joana.prado@example.com). How long is a gift c
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ex
        serialized: {"name": "ChatOpenAI"}
patch run 01a11042 ask (chain)
        outputs: {"output": "Marginalia gift cards are valid for one year from purchase."}
        extra: {"metadata": {"ls_method": "traceable", "LANGSMITH_PROJECT": "marginalia-assistant", "LANGSMITH_TRACING": "tru
patch run 01a11042 ChatOpenAI (llm)
        outputs: {"id": "chatcmpl-lab0867", "choices": [{"finish_reason": "stop", "index": 0, "logprobs": null, "message": {"co
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ex
```

A palavra do LangSmith para um span é **run** (execução), e cada run é mandado duas vezes: um `post`
quando começa, com as entradas, e um `patch` quando termina, com as saídas. A função é um run do tipo
`chain`, a chamada ao modelo um run do tipo `llm` dentro dela.

Leia o que foi junto. **A mensagem do cliente, endereço incluído, inteira**, nos dois runs. A resposta
inteira do modelo. E em `extra`, metadados que o SDK acrescenta por conta própria: as variáveis de
ambiente que o configuraram, com nome e valor, e detalhes de execução que o `sent.py` corta na borda da
tela: a versão do SDK, a versão do Python, o sistema operacional e a descrição da plataforma da máquina.
Nada disso é segredo aqui. Tudo isso sai da máquina, e uma equipe que não olhou não vai saber.

## Os ganchos do próprio SDK

O cliente do LangSmith aceita funções que veem as entradas e as saídas antes de serem mandadas:
`hide_inputs`, `hide_outputs`, e um `anonymizer` para padrões; e `omit_traced_runtime_info` deixa de
fora os detalhes de execução. A execução com `--redact` passa o `redact()` da aula 2 para os dois
primeiros:

```
ana@lab:~/obs$ LANGSMITH_TRACING=true LANGSMITH_ENDPOINT=http://127.0.0.1:8700 LANGSMITH_API_KEY=lab-langsmith-key-0001 LANGSMITH_PROJECT=marginalia-assistant LANGSMITH_DISABLE_RUN_COMPRESSION=true python ls_ask.py --redact
Marginalia gift cards are valid for one year from purchase.
ana@lab:~/obs$ python sent.py
post  run 01a11042 ask (chain)
        inputs: {"question": "Hi, I'm Joana Prado ([email]). How long is a gift card valid?"}
        extra: {"metadata": {"ls_method": "traceable"}}
post  run 01a11042 ChatOpenAI (llm)
        inputs: {"messages": "[{'role': 'user', 'content': \"Hi, I'm Joana Prado ([email]). How long is a gift card valid?\"}]
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ex
        serialized: {"name": "ChatOpenAI"}
patch run 01a11042 ask (chain)
        outputs: {"output": "Marginalia gift cards are valid for one year from purchase."}
        extra: {"metadata": {"ls_method": "traceable"}}
patch run 01a11042 ChatOpenAI (llm)
        outputs: {"id": "chatcmpl-lab0868", "choices": "[{'finish_reason': 'stop', 'index': 0, 'logprobs': None, 'message': {'c
        extra: {"metadata": {"ls_method": "traceable", "ls_provider": "openai", "ls_model_type": "chat", "ls_model_name": "ex
```

O endereço sumiu das entradas, e as variáveis de ambiente e os detalhes de execução sumiram de `extra`.
Duas coisas valem ser notadas. Os ganchos recebem as entradas como um dicionário, e o `str(v)` simples
do `ls_ask.py` transformou a lista de mensagens no texto de uma lista, que uma tela vai mostrar como
texto e não como mensagens; um gancho cuidadoso limpa dentro da estrutura. E o run do próprio modelo
manteve o `ls_model_name` e os metadados do fornecedor, o que está certo, e lembra que **só uma
inspeção do que chegou** diz o que uma configuração cobre.

É o mesmo padrão do exportador da aula 2, oferecido pelo fornecedor: limpar no processo, antes de
mandar qualquer coisa. Confiar no gancho de um fornecedor ou no próprio é uma questão de julgamento;
testar qualquer um dos dois com um canário não é.
