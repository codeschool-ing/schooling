---
title: A conversa guardada para você
version: 1
---

Na Chat Completions uma conversa é trabalho do cliente: toda requisição leva todas as mensagens
anteriores, e a API não lembra de nada. A Responses API pode lembrar no lugar dele. A documentação
dos parâmetros que vem dentro da própria biblioteca, que o `doc.py` imprime do pacote instalado,
diz como:

```python
import re
import sys

import openai.resources.responses.responses as module

# the docstring of Responses.create, as the installed library carries it
source = open(module.__file__).read()
for name in sys.argv[1:]:
    m = re.search(rf"^ {{10}}{name}: .*?(?=\n\n {{10}}\w+: )", source, re.S | re.M)
    print(re.sub(r"(?m)^ {10}", "", m.group(0)) if m else f"{name}: not documented")
```

```
ana@desk:~/desk$ python doc.py previous_response_id instructions
previous_response_id: The unique ID of the previous response to the model. Use this to create
    multi-turn conversations. Learn more about
    [conversation state](https://developers.openai.com/api/docs/guides/conversation-state).
    Cannot be used in conjunction with `conversation`.
instructions: A system (or developer) message inserted into the model's context.

    When using along with `previous_response_id`, the instructions from a previous
    response will not be carried over to the next response. This makes it simple to
    swap out system (or developer) messages in new responses.
```

O `chain.py` classifica um caso e depois manda um segundo caso como o turno seguinte, uma vez sem
as instruções e outra com elas:

```python
import json

from openai import OpenAI

client = OpenAI()
prompt = open("prompts/triage.txt").read()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}

first = client.responses.create(model="llama3.2:3b", instructions=prompt, input=cases["c05"]["text"])
print("first: ", first.id, first.output_text, first.usage.input_tokens, "tokens in")

# the next turn sends only what is new, and the id of what came before
second = client.responses.create(model="llama3.2:3b", previous_response_id=first.id,
                                 input=cases["c12"]["text"])
print("second:", second.id, second.usage.input_tokens, "tokens in, instructions:", second.instructions)

third = client.responses.create(model="llama3.2:3b", previous_response_id=first.id,
                                instructions=prompt, input=cases["c12"]["text"])
print("third: ", third.id, third.output_text, third.usage.input_tokens, "tokens in")
```

```
ana@desk:~/desk$ python chain.py
first:  resp_884996 order-status, other. 75 tokens in
second: resp_100132 53 tokens in, instructions: None
third:  resp_719864 refund 89 tokens in
```

```
ana@desk:~/desk$ python relay.py show --body | head -6
{
  "model": "llama3.2:3b",
  "input": "The book arrived soaked from the rain and the cover is ruined. I don't want a replacement, just the refund. LB-20415",
  "instructions": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n",
  "previous_response_id": "resp_884996"
}
```

A terceira requisição mandou um e-mail e um id, e o relay mostra que o id foi junto. O modelo leu 89
tokens. Na OpenAI, a docstring acima diz para que serve esse id: o servidor acha o primeiro turno e
a resposta dele e os põe antes do e-mail novo, então **o histórico vem do lado do provedor, não do
lado da ana**. Aqui ele não veio de lado nenhum. A primeira requisição, com as instruções e um
e-mail, teve 75 tokens; a terceira, com as instruções e outro e-mail, tem 89, que é mais ou menos o
tamanho dessa requisição sozinha. **O Ollama aceitou o `previous_response_id` e o ignorou**, e a
resposta não deu sinal disso.

A segunda requisição é a armadilha de que a documentação avisa, e essa aparece em qualquer servidor:
ela não mandou instruções, e `instructions` voltou `None`, porque instruções não são levadas
adiante. Um programa que define o prompt de sistema só no primeiro turno tem, do segundo turno em
diante, um modelo sem instruções.

Para a classificação da ana, em que todo e-mail é uma pergunta nova, não há conversa a guardar, e
nada disto é necessário. Importa para uma resposta redigida em vários turnos, e aí a economia está
no que o cliente manda, não no que é cobrado: o modelo continua lendo o histórico inteiro, e o
`input_tokens` o conta toda vez. E é o caso mais claro deste curso do assunto da aula 20: **um
servidor que aceita uma requisição não é um servidor que honra todo campo dela.**
