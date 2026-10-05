---
title: A conversa guardada para você
version: 1
---

Na Chat Completions uma conversa é trabalho do cliente: toda requisição leva todas as mensagens
anteriores, e a API não lembra de nada. A Responses API pode lembrar no lugar dele. A documentação
dos parâmetros que vem dentro da própria biblioteca, que o `lab/doc.py` imprime do pacote instalado,
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
ana@desk:~/desk$ python lab/doc.py previous_response_id instructions
previous_response_id: The unique ID of the previous response to the model. Use this to create
    multi-turn conversations. Learn more about
    [conversation state](https://developers.openai.com/api/docs/guides/conversation-state).
    Cannot be used in conjunction with `conversation`.
instructions: A system (or developer) message inserted into the model's context.

    When using along with `previous_response_id`, the instructions from a previous
    response will not be carried over to the next response. This makes it simple to
    swap out system (or developer) messages in new responses.
```

O `lab/chain.py` classifica um caso e depois manda um segundo caso como o turno seguinte, uma vez sem
as instruções e outra com elas:

```python
import json

from openai import OpenAI

client = OpenAI()
prompt = open("prompts/triage.txt").read()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}

first = client.responses.create(model="standin-small", instructions=prompt, input=cases["c05"]["text"])
print("first: ", first.id, first.output_text, first.usage.input_tokens, "tokens in")

# the next turn sends only what is new, and the id of what came before
second = client.responses.create(model="standin-small", previous_response_id=first.id,
                                 input=cases["c12"]["text"])
print("second:", second.id, second.usage.input_tokens, "tokens in, instructions:", second.instructions)

third = client.responses.create(model="standin-small", previous_response_id=first.id,
                                instructions=prompt, input=cases["c12"]["text"])
print("third: ", third.id, third.output_text, third.usage.input_tokens, "tokens in")
```

```
ana@desk:~/desk$ python lab/chain.py
first:  resp_lab_0003 other 51 tokens in
second: resp_lab_0004 49 tokens in, instructions: None
third:  resp_lab_0005 refund. 85 tokens in
```

```
ana@desk:~/desk$ wire --body | head -9
{
  "model": "standin-small",
  "input": "The book arrived soaked from the rain and the cover is ruined. I don't want a replacement, just the refund. LB-20415",
  "instructions": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n",
  "previous_response_id": "resp_lab_0003"
}
```

A terceira requisição mandou um e-mail e um id, e o modelo leu 85 tokens: o primeiro turno, a
resposta dele, as instruções e o e-mail novo. **O histórico veio do lado da OpenAI, não do lado da
ana.** A segunda requisição é a armadilha de que a documentação avisa: leu o histórico mas não as
instruções, 49 tokens, porque instruções não são levadas adiante. Um programa que define o prompt de
sistema só no primeiro turno tem, do segundo turno em diante, um modelo sem instruções.

A resposta do substituto à terceira é `refund.`, com ponto final, que é o que a tabela dele manda o
`standin-small` escrever para esse caso; a pontuação estrita da seção 04 da aula 5 a contaria como
errada, e a frouxa, como certa.

Para a classificação da ana, em que todo e-mail é uma pergunta nova, não há conversa a guardar, e
nada disto é necessário. Importa para uma resposta redigida em vários turnos, e aí a economia está no
que o cliente manda, não no que é cobrado: o modelo continua lendo o histórico inteiro, e o
`input_tokens` o conta toda vez.
