---
title: Duas promessas que a API faz
version: 1
---

## Longo demais falha, a não ser que você peça o corte

A seção 04 da aula 14 mandou ao Ollama uma conversa maior que a janela dele e recebeu uma resposta
comum de um modelo que tinha lido só parte dela. A Responses API documenta o padrão oposto:

```
ana@desk:~/desk$ python lab/doc.py truncation
truncation: The truncation strategy to use for the model response.

    - `auto`: If the input to this Response exceeds the model's context window size,
      the model will truncate the response to fit the context window by dropping
      items from the beginning of the conversation.
    - `disabled` (default): If the input size will exceed the context window size
      for a model, the request will fail with a 400 error.
```

O `lab/long.py` manda trinta rodadas dos exemplos resolvidos da ana, mais que a janela de 32.768
tokens do `standin-small`, primeiro com o padrão e depois com `truncation` em `auto`:

```python
import json
import sys

from openai import OpenAI, BadRequestError

client = OpenAI()
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]

# thirty rounds of every case as a worked example: far more than standin-small's window
items = []
for _ in range(30):
    for c in cases[:39]:
        items += [{"role": "user", "content": c["text"]}, {"role": "assistant", "content": c["label"]}]
items.append({"role": "user", "content": cases[39]["text"]})

extra = {"truncation": sys.argv[1]} if len(sys.argv) > 1 else {}
try:
    r = client.responses.create(model="standin-small", instructions=prompt, input=items, **extra)
    print(f"{len(items)} items sent, {r.usage.input_tokens} tokens read -> {r.output_text}")
except BadRequestError as e:
    print(f"{len(items)} items sent -> {e.status_code}: {e.body['message']}")
```

```
ana@desk:~/desk$ python lab/long.py
2341 items sent -> 400: prompt is too long: 31980 tokens + 1024 max tokens > 32768 maximum
```

```
ana@desk:~/desk$ python lab/long.py auto
2341 items sent, 31737 tokens read -> order-status
```

O texto do 400 é do substituto; o comportamento é o documentado. **Por padrão, longo demais é um
erro que a ana vê**, e o corte só acontece quando ela pede, descartando os itens mais antigos. A
janela conta também o espaço da resposta, e é por isso que o `auto` parou em 31.737 tokens: o
substituto reserva 1.024 para a saída, o padrão dele quando `max_output_tokens` não é dado.

## Um schema vira um objeto

A seção 09 da aula 5 conferiu a extração lendo o JSON do modelo e comparando o número do pedido. O
SDK pode fazer a leitura, a partir de uma classe:

```
ana@desk:~/desk$ python lab/doc.py text
text: Configuration options for a text response from the model. Can be plain text or
    structured JSON data. Learn more:

    - [Text inputs and outputs](https://developers.openai.com/api/docs/guides/text)
    - [Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs)
```

```python
import json

from openai import OpenAI
from pydantic import BaseModel


class Order(BaseModel):
    order: str | None


client = OpenAI()
prompt = open("prompts/extract.txt").read()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}

for cid in ("c01", "c05"):
    r = client.responses.parse(model="standin-small", instructions=prompt, input=cases[cid]["text"],
                               text_format=Order)
    print(cid, repr(r.output_parsed), " expected:", cases[cid]["order"])
```

```
ana@desk:~/desk$ python lab/parse.py
c01 Order(order='LB-20417')  expected: LB-20417
c05 Order(order=None)  expected: None
```

O que foi pelo fio foi a classe, transformada num JSON Schema com `strict` ligado:

```
ana@desk:~/desk$ wire --body | python -c "import json, sys; print(json.dumps(json.load(sys.stdin)[\"text\"], indent=2))"
{
  "format": {
    "type": "json_schema",
    "strict": true,
    "name": "Order",
    "schema": {
      "properties": {
        "order": {
          "anyOf": [
            {
              "type": "string"
            },
            {
              "type": "null"
            }
          ],
          "title": "Order"
        }
      },
      "required": [
        "order"
      ],
      "title": "Order",
      "type": "object",
      "additionalProperties": false
    }
  }
}
```

Há duas promessas em jogo, feitas por partes diferentes. **O SDK promete a leitura**: o
`output_parsed` é um `Order` ou a chamada levanta erro. **O provedor promete o schema**: com
`strict`, um modelo que suporta saída estruturada escreve JSON que bate com ele, que é o `S` nos
indicadores da tabela. O substituto não faz essa promessa; respondeu pela tabela dele, que por acaso
batia. Nenhuma das promessas cobre o valor: um `{"order": "LB-20471"}` bem formado para um e-mail
sobre o `LB-20417` passa nas duas, e só a comparação da aula 5 com a resposta esperada pega isso.
