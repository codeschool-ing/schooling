---
title: Instruções entram, itens saem
version: 1
---

A Responses API mora ao lado da Chat Completions no mesmo endereço, com a mesma chave e o mesmo SDK,
e a seção 05 da aula 8 deixou a escolha entre as duas em aberto. O api.openai.com foi recusado pela
rede da máquina em que este curso foi gravado, e o Ollama também responde nesse formato, então as
respostas desta aula são do llama3.2:3b. Esta aula é sobre o formato, e sobre o que a própria
biblioteca da OpenAI documenta; onde o Ollama faz outra coisa, a aula diz, e essa diferença vale
saber por si só.

Todo programa desta aula passa pelo relay da seção 03 da aula 9, para que o que a biblioteca manda
possa ser lido de volta. Suba o relay num segundo terminal e, no terminal em que você trabalha,
mande as duas bibliotecas para ele:

```
ana@desk:~/desk$ export OPENAI_BASE_URL=http://127.0.0.1:8500/v1 ANTHROPIC_BASE_URL=http://127.0.0.1:8500
```

O `resp_sort.py` classifica um dos casos da ana com a Responses API:

```python
import json

from openai import OpenAI

client = OpenAI()
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

r = client.responses.create(model="llama3.2:3b", instructions=prompt, input=case["text"])
print(r.output_text)
print([item.type for item in r.output], [part.type for part in r.output[0].content])
print(r.usage.input_tokens, "in,", r.usage.output_tokens, "out, of which reasoning:",
      r.usage.output_tokens_details.reasoning_tokens)
```

```
ana@desk:~/desk$ python resp_sort.py
other.
['message'] ['output_text']
75 in, 3 out, of which reasoning: 0
ana@desk:~/desk$ python relay.py show --body
{
  "model": "llama3.2:3b",
  "input": "Do you have a physical shop I can visit in Curitiba?",
  "instructions": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n"
}
```

A requisição é o que a biblioteca de verdade mandou, e o formato é o que interessa:

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
