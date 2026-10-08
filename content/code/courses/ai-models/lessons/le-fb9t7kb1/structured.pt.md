---
title: Uma classe entra, um objeto sai
version: 1
---

Na seção 05 da aula 16 a biblioteca da OpenAI transformou uma classe num schema e a resposta de
volta num objeto. A biblioteca do Google faz o mesmo, pela configuração. O `gemini_extract.py` pede
o número do pedido em dois casos da ana, como um `Order`:

```python
import json

from google import genai
from google.genai import errors, types
from pydantic import BaseModel


class Order(BaseModel):
    order: str | None


client = genai.Client()
prompt = open("prompts/extract.txt").read()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}

for cid in ("c01", "c05"):
    try:
        r = client.models.generate_content(
            model="gemini-3.5-flash", contents=cases[cid]["text"],
            config=types.GenerateContentConfig(system_instruction=prompt, temperature=0,
                                               response_mime_type="application/json", response_schema=Order))
        print(cid, repr(r.parsed), " expected:", cases[cid]["order"])
    except errors.APIError as e:
        print(cid, e.code, e.status)
```

Pelo relay, como na seção 02, o Ollama responde os dois com o 404 dele, e a requisição é a parte
que vale ler:

```
ana@desk:~/desk$ export GOOGLE_GEMINI_BASE_URL=http://127.0.0.1:8500 GOOGLE_API_KEY=ollama
ana@desk:~/desk$ python gemini_extract.py
Direct use of automatic function calling (AFC) in Models.generate_content is not recommended. Instead, we recommend to use AFC in Chat.send_message. Similarly, direct use of AFC in Models.generate_content_stream is not recommended. Instead, we recommend to use AFC in Chat.send_message_stream.
c01 404 Not Found
c05 404 Not Found
ana@desk:~/desk$ python relay.py show --body | python -c "import json, sys; print(json.dumps(json.load(sys.stdin)[\"generationConfig\"], indent=2))"
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
`"anyOf": [{"type": "string"}, {"type": "null"}]`. A descrição do campo na biblioteca diz de onde
vem o dialeto, e o que fazer quando ele não basta:

```
ana@desk:~/desk$ python field.py GenerateContentConfig.response_schema
The `Schema` object allows the definition of input and output data types.
These types can be objects, but also primitives and arrays.
Represents a select subset of an [OpenAPI 3.0 schema
object](https://spec.openapis.org/oas/v3.0.3#schema).
If set, a compatible response_mime_type must also be set.
Compatible mimetypes: `application/json`: Schema for JSON response.

If `response_schema` doesn't process your schema correctly, try using
`response_json_schema` instead.
```

Um subconjunto do OpenAPI 3.0, que é de onde vem o `nullable`. A biblioteca traduziu uma classe
Python para os formatos de dois provedores, que é o trabalho que um programa faria à mão, e o
motivo de um schema copiado da documentação de um provedor para a requisição de outro poder ser
recusado.

O `r.parsed` é trabalho da biblioteca de novo, feito do lado da ana a partir do texto que volta:

```
ana@desk:~/desk$ python field.py GenerateContentResponse.parsed
First candidate from the parsed response if response_schema is provided. Not available for streaming.
```

"O primeiro candidato", então ele tem a mesma fraqueza do texto de que é feito, que é o assunto da
seção 04. E vale a mesma ressalva da aula 16: um schema promete o formato, e só a comparação com o
pedido esperado diz se o valor está certo. Nesta máquina não houve valor nenhum para comparar, o
que lembra onde essa conferência tem de morar: no harness da ana, rodando contra o provedor que a
mesa paga.
