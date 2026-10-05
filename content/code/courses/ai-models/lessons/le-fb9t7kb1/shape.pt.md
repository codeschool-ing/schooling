---
title: Contents, parts e um papel chamado model
version: 1
---

A aula 7 escolheu entre os modelos Gemini e leu onde eles são vendidos. Esta aula é a API pela qual
eles respondem, chamada pela biblioteca do próprio Google, a `google-genai`. A API do Google estava
fora de alcance na máquina em que este curso foi gravado; o substituto do lab responde no endereço
que a biblioteca lê de `GOOGLE_GEMINI_BASE_URL`, e o que a biblioteca manda é real.

O `lab/gemini_sort.py` classifica um dos casos da ana:

```python
import json

from google import genai
from google.genai import types

client = genai.Client()
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

r = client.models.generate_content(
    model="standin-small", contents=case["text"],
    config=types.GenerateContentConfig(system_instruction=prompt, max_output_tokens=16, temperature=0))
print(repr(r.text), r.candidates[0].finish_reason)
print(r.usage_metadata.prompt_token_count, "in,", r.usage_metadata.candidates_token_count, "out")
```

```
ana@desk:~/desk$ python lab/gemini_sort.py
Direct use of automatic function calling (AFC) in Models.generate_content is not recommended. Instead, we recommend to use AFC in Chat.send_message. Similarly, direct use of AFC in Models.generate_content_stream is not recommended. Instead, we recommend to use AFC in Chat.send_message_stream.
'other' FinishReason.STOP
51 in, 1 out
```

A primeira linha é da própria biblioteca, sobre chamada automática de funções, que este programa
não usa; ela sai em toda chamada a `generate_content` e pode ser ignorada aqui. O que foi pelo fio:

```
ana@desk:~/desk$ wire --headers x-goog-api-key,user-agent
POST /v1beta/models/standin-small:generateContent
x-goog-api-key: lab-google-k…
user-agent: google-genai-sdk/2.28.0 gl-python/3.11.15

{
  "contents": [
    {
      "parts": [
        {
          "text": "Do you have a physical shop I can visit in Curitiba?"
        }
      ],
      "role": "user"
    }
  ],
  "systemInstruction": {
    "parts": [
      {
        "text": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n"
      }
    ],
    "role": "user"
  },
  "generationConfig": {
    "temperature": 0.0,
    "maxOutputTokens": 16
  }
}
```

Quatro coisas a ler ali:

- **O modelo está no caminho**, `/v1beta/models/standin-small:generateContent`, não no corpo.
- **`contents` é uma lista de turnos, e cada turno uma lista de `parts`.** Uma parte pode ser texto,
  imagem ou arquivo, que é como uma requisição leva as entradas com que o curso `multimodal`
  trabalha. Uma resposta volta com o papel `model`, onde as outras APIs dizem `assistant`.
- **O prompt de sistema é `systemInstruction`**, ao lado dos contents e não entre eles, e os ajustes
  ficam em `generationConfig`.
- **A biblioteca escreve em camelCase.** O programa diz `max_output_tokens` e o fio diz
  `maxOutputTokens`: os nomes em Python são da biblioteca, e uma requisição escrita à mão, ou lida
  num log, usa os da API.

A chave viaja em `x-goog-api-key`, o terceiro nome de cabeçalho que este curso vê para a mesma
função, depois do `x-api-key` da Anthropic e do `Authorization: Bearer` de todo o resto.
