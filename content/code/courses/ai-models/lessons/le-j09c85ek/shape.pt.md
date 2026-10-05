---
title: Instruções entram, itens saem
version: 1
---

A Responses API mora ao lado da Chat Completions no mesmo endereço, com a mesma chave e o mesmo SDK,
e a seção 05 da aula 8 deixou a escolha entre as duas em aberto. O `lab/resp_sort.py` classifica um
dos casos da ana com ela:

```python
import json

from openai import OpenAI

client = OpenAI()
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

r = client.responses.create(model="standin-small", instructions=prompt, input=case["text"])
print(r.output_text)
print([item.type for item in r.output], [part.type for part in r.output[0].content])
print(r.usage.input_tokens, "in,", r.usage.output_tokens, "out, of which reasoning:",
      r.usage.output_tokens_details.reasoning_tokens)
```

```
ana@desk:~/desk$ python lab/resp_sort.py
other
['message'] ['output_text']
51 in, 1 out, of which reasoning: 0
```

```
ana@desk:~/desk$ wire --body
{
  "model": "standin-small",
  "input": "Do you have a physical shop I can visit in Curitiba?",
  "instructions": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n"
}
```

O api.openai.com estava fora de alcance na máquina em que este curso foi gravado, então as respostas
são do substituto do lab. A requisição é o que a biblioteca de verdade mandou, e o formato é o que
importa:

| | Chat Completions | Responses |
|---|---|---|
| o prompt de sistema | uma mensagem com papel `system` | `instructions` |
| o que responder | `messages`, uma lista | `input`, uma string ou uma lista de itens |
| a resposta | `choices[0].message.content` | `output`, uma lista de itens tipados; `output_text` junta o texto deles |
| tokens | `prompt_tokens`, `completion_tokens` | `input_tokens`, `output_tokens` |

O `output` é uma lista porque uma resposta pode ter mais de um tipo de item: uma mensagem, um resumo
de raciocínio, uma chamada a uma ferramenta. O `output_text` é uma conveniência do SDK que junta as
partes de texto, e é o que a maioria dos programas precisa. O uso separa os **tokens de
raciocínio** dos visíveis, o pensamento escondido da seção 03 da aula 8, que é cobrado como saída e
aqui é zero.

Nada disso muda o que o harness da ana mede. Muda o código que lê a resposta, e é por isso que um
programa escrito para um formato não roda no outro sem mudanças.
