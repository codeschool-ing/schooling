---
title: Contents, parts e um papel chamado model
version: 1
---

A aula 7 escolheu entre os modelos Gemini e leu onde eles são vendidos. Esta aula é a API pela
qual eles respondem, chamada pela própria biblioteca do Google, a `google-genai`. A API do Google
responde da máquina em que este curso foi gravado, mas só com uma chave, e uma chave é uma conta que
um curso não pode distribuir. O Ollama não fala esta API. Então cada programa aqui roda duas vezes:
uma pelo relay da seção 03 da aula 9, para ler o que a biblioteca manda, e outra direto para o
Google, para ler o que o Google responde sem chave. Se você tem uma chave do Google AI Studio,
ponha-a em `GOOGLE_API_KEY` e a segunda execução responde com um rótulo.

O `gemini_sort.py` classifica um dos casos da ana com o `gemini-3.5-flash`, um modelo da tabela da
aula 7:

```python
import json

from google import genai
from google.genai import errors, types

client = genai.Client()
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

try:
    r = client.models.generate_content(
        model="gemini-3.5-flash", contents=case["text"],
        config=types.GenerateContentConfig(system_instruction=prompt, max_output_tokens=16, temperature=0))
    print(repr(r.text), r.candidates[0].finish_reason)
    print(r.usage_metadata.prompt_token_count, "in,", r.usage_metadata.candidates_token_count, "out")
except errors.APIError as e:
    print(e.code, e.status, e.message)
```

Com o relay rodando num segundo terminal, mande a biblioteca para ele. O `GOOGLE_GEMINI_BASE_URL` é
o endereço que ela lê, e o `genai.Client()` se recusa a começar sem alguma chave, então um valor de
mentira vai no `GOOGLE_API_KEY`:

```
ana@desk:~/desk$ export GOOGLE_GEMINI_BASE_URL=http://127.0.0.1:8500 GOOGLE_API_KEY=ollama
ana@desk:~/desk$ python gemini_sort.py
Direct use of automatic function calling (AFC) in Models.generate_content is not recommended. Instead, we recommend to use AFC in Chat.send_message. Similarly, direct use of AFC in Models.generate_content_stream is not recommended. Instead, we recommend to use AFC in Chat.send_message_stream.
404 Not Found 404 page not found
```

A primeira linha é da própria biblioteca, sobre chamada automática de funções, que este programa não
usa; ela sai em toda chamada a `generate_content` e aqui pode ser ignorada. A segunda é o Ollama
dizendo que não tem esse endereço. O que foi pelo fio:

```
ana@desk:~/desk$ python relay.py show --headers x-goog-api-key,user-agent
POST /v1beta/models/gemini-3.5-flash:generateContent
x-goog-api-key: ollama…
user-agent: google-genai-sdk/2.28.0 gl-python/3.13.16

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

Quatro coisas para ler nela:

- **O modelo está no caminho**, `/v1beta/models/gemini-3.5-flash:generateContent`, não no corpo.
- **`contents` é uma lista de turnos, e cada turno uma lista de `parts`.** Uma parte pode ser texto,
  uma imagem ou um arquivo, e é assim que uma requisição leva as entradas com que o curso
  `multimodal` trabalha.
- **O prompt de sistema é `systemInstruction`**, ao lado do conteúdo e não no meio dele, e os
  ajustes ficam em `generationConfig`.
- **A biblioteca escreve em camelCase.** O programa diz `max_output_tokens` e o fio diz
  `maxOutputTokens`: os nomes em Python são da biblioteca, e uma requisição escrita à mão, ou lida
  num log, usa os da API.

Uma resposta volta como mais um turno, e o papel dela não é o `assistant` das outras APIs. A
descrição do campo na própria biblioteca diz isso, e o `field.py` a imprime para qualquer campo:

```python
import inspect
import sys

from google.genai import types

# what the installed library says about one of its own fields: field.py Class.field
cls, name = sys.argv[1].split(".")
print(inspect.cleandoc(getattr(types, cls).model_fields[name].description))
```

```
ana@desk:~/desk$ python field.py Content.role
Optional. The producer of the content. Must be either 'user' or 'model'. If not set, the service will default to 'user'.
```

Agora o mesmo programa, direto para o Google. Tire o endereço e a biblioteca vai para o padrão
dela, o generativelanguage.googleapis.com:

```
ana@desk:~/desk$ unset GOOGLE_GEMINI_BASE_URL
ana@desk:~/desk$ python gemini_sort.py
Direct use of automatic function calling (AFC) in Models.generate_content is not recommended. Instead, we recommend to use AFC in Chat.send_message. Similarly, direct use of AFC in Models.generate_content_stream is not recommended. Instead, we recommend to use AFC in Chat.send_message_stream.
400 INVALID_ARGUMENT API key not valid. Please pass a valid API key.
```

**O Google leu a requisição e recusou a chave**, com um 400 e uma palavra de status própria,
`INVALID_ARGUMENT`. A chave vai no `x-goog-api-key`, o terceiro nome de cabeçalho que este curso vê
para a mesma função, depois do `x-api-key` da Anthropic e do `Authorization: Bearer` de todo o
resto.
