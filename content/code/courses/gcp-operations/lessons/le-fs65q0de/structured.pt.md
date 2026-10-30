---
title: Uma linha de log que o Cloud Logging consegue ler
version: 1
---

**O Cloud Logging guarda entradas, e uma entrada é ou uma string ou uma estrutura.** Cloud Run, GKE e Cloud
Functions coletam o que um contêiner escreve na saída padrão e na saída de erro e mandam ao Cloud Logging
sem agente nem biblioteca. O que vira cada linha depende do formato dela: uma linha que é um objeto JSON vira
uma entrada **estruturada**, `jsonPayload`, cujos campos podem ser buscados um a um, e alguns desses campos
significam algo para o próprio Cloud Logging; qualquer outra linha vira `textPayload`, uma string, buscável
só como texto. **Nada nesta lição chega ao Cloud Logging**: não há emulador para ele. O que roda aqui é o
programa que escreve as linhas, e as perguntas que o Cloud Logging responderia, feitas a essas linhas no seu
computador.

O programa abaixo escreve duas linhas do jeito que a API da loja deve, e uma do jeito que não deve. Escreva-o
em `~/gcp/logdemo.py`:

```python
# logdemo.py
"""logdemo.py: three lines of the shop's API, written the way Cloud Logging reads them.

Cloud Run and GKE send whatever a container writes on stdout to Cloud Logging.
A line that is a JSON object becomes a structured entry, and a few of its
fields have a meaning there; anything else becomes plain text.
"""
import json
import sys


def log(severity, message, **fields):
    entry = {"severity": severity, "message": message, **fields}
    print(json.dumps(entry), file=sys.stdout, flush=True)


log("INFO", "order placed", order_id="o-1001", total_cents=4380,
    httpRequest={"requestMethod": "POST", "requestUrl": "/orders",
                 "status": 201, "latency": "0.084s"},
    **{"logging.googleapis.com/trace":
       "projects/planner-dev/traces/4bf92f3577b34da6a3ce929d0e0e4736"})
log("WARNING", "payment retried", order_id="o-1002", attempt=2)
print("level=error msg=\"stock lookup failed\" product=p-002", flush=True)
```

```
ana@laptop:~/gcp$ python3 logdemo.py
{"severity": "INFO", "message": "order placed", "order_id": "o-1001", "total_cents": 4380, "httpRequest": {"requestMethod": "POST", "requestUrl": "/orders", "status": 201, "latency": "0.084s"}, "logging.googleapis.com/trace": "projects/planner-dev/traces/4bf92f3577b34da6a3ce929d0e0e4736"}
{"severity": "WARNING", "message": "payment retried", "order_id": "o-1002", "attempt": 2}
level=error msg="stock lookup failed" product=p-002
```

## O que o Cloud Logging faz de cada linha

O Cloud Logging transformaria as duas primeiras linhas em entradas estruturadas e a terceira numa string. A
mesma conversão, feita no seu computador com `jq`, mostra qual seria a severidade de cada entrada:

```
ana@laptop:~/gcp$ python3 logdemo.py | jq -c -R 'fromjson? // {textPayload: .}' | jq -c '{severity: (.severity // "DEFAULT"), message: (.message // .textPayload)}'
{"severity":"INFO","message":"order placed"}
{"severity":"WARNING","message":"payment retried"}
{"severity":"DEFAULT","message":"level=error msg=\"stock lookup failed\" product=p-002"}
```

**A terceira linha diz `level=error` e chega com severidade `DEFAULT`.** O Cloud Logging só lê uma
severidade de um campo JSON chamado `severity`; uma linha que não é JSON, ou um JSON que o chama de `level`,
não tem nenhuma, e um alerta de "erros" nunca a vê. É o erro mais comum desta lição e é invisível: a linha
está lá, legível, com a palavra *error* dentro, e filtrada para fora por toda consulta que pede erros. O
próprio logger desta plataforma tinha exatamente esse defeito, escrevendo `level` onde o Cloud Logging lê
`severity`, até alguém ler um log por outro motivo.

Os campos a que o Cloud Logging dá significado, numa linha JSON:

| campo | vira |
|---|---|
| `severity` | a severidade da entrada: `DEBUG`, `INFO`, `NOTICE`, `WARNING`, `ERROR`, `CRITICAL`, `ALERT`, `EMERGENCY` |
| `message` | o texto mostrado para a entrada numa lista de resultados |
| `httpRequest` | a requisição HTTP da entrada: método, URL, status, latência, que o console desenha como requisição |
| `logging.googleapis.com/trace` | o trace a que esta entrada pertence, que a lição 11 segue de uma linha de log até um trace |
| `logging.googleapis.com/labels` | rótulos na entrada, buscáveis sem ler o payload |

Todo o resto fica em `jsonPayload`, buscável pelo nome: `jsonPayload.order_id="o-1002"`. **Uma linha, um
objeto JSON, sem quebra de linha dentro.** Um stack trace impresso em vinte linhas chega como vinte entradas
de texto puro; a lição 11 é sobre escrevê-lo dentro de uma entrada só.
