---
title: Uma classe entra, um objeto sai
version: 1
---

Na seção 05 da aula 16, a biblioteca da OpenAI transformou uma classe num schema e a resposta de
volta num objeto. A biblioteca do Google faz o mesmo, pela configuração. O `lab/gemini_extract.py`
também conta os tokens de cada e-mail antes de mandá-lo:

```python
import json

from google import genai
from google.genai import types
from pydantic import BaseModel


class Order(BaseModel):
    order: str | None


client = genai.Client()
prompt = open("prompts/extract.txt").read()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}

for cid in ("c01", "c05"):
    text = cases[cid]["text"]
    n = client.models.count_tokens(model="standin-small", contents=text).total_tokens
    r = client.models.generate_content(
        model="standin-small", contents=text,
        config=types.GenerateContentConfig(system_instruction=prompt, temperature=0,
                                           response_mime_type="application/json", response_schema=Order))
    print(cid, f"{n} tokens counted first;", repr(r.parsed), " expected:", cases[cid]["order"])
```

```
ana@desk:~/desk$ python lab/gemini_extract.py
Direct use of automatic function calling (AFC) in Models.generate_content is not recommended. Instead, we recommend to use AFC in Chat.send_message. Similarly, direct use of AFC in Models.generate_content_stream is not recommended. Instead, we recommend to use AFC in Chat.send_message_stream.
c01 33 tokens counted first; Order(order='LB-20417')  expected: LB-20417
c05 15 tokens counted first; Order(order=None)  expected: None
```

```
ana@desk:~/desk$ wire --body | python -c "import json, sys; print(json.dumps(json.load(sys.stdin)[\"generationConfig\"], indent=2))"
{
  "temperature": 0.0,
  "responseMimeType": "application/json",
  "responseSchema": {
    "properties": {
      "order": {
        "nullable": true,
        "title": "Order",
        "type": "STRING"
      }
    },
    "required": [
      "order"
    ],
    "title": "Order",
    "type": "OBJECT"
  }
}
```

O schema no fio é **o dialeto do próprio Google**, não o JSON Schema que a OpenAI recebeu para a
mesma classe: `"type": "STRING"` em maiúsculas, e `"nullable": true` onde a aula 16 tinha
`"anyOf": [{"type": "string"}, {"type": "null"}]`. A biblioteca traduziu uma classe Python para o
formato de dois provedores, que é o trabalho que um programa faria à mão, e o motivo de um schema
copiado da documentação de um provedor para a requisição de outro poder ser recusado.

O `count_tokens` perguntou à API, antes da requisição, quantos tokens o e-mail tem. É uma chamada à
parte, com a própria ida e volta, e útil onde o tamanho decide alguma coisa: para que modelo mandar
uma mensagem longa, ou se ela cabe. O número é a contagem do próprio provedor, feita com o
tokenizador do modelo, o que nenhuma biblioteca local pode prometer para um modelo fechado.

O `r.parsed` é de novo trabalho da biblioteca, feito do lado da ana a partir do texto que voltou. A
mesma ressalva da aula 16 vale: o substituto ignorou o schema e respondeu pela tabela dele, e só a
comparação com o pedido esperado diz se o valor está certo.
