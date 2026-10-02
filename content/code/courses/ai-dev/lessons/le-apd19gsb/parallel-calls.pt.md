---
title: Várias chamadas numa resposta
version: 1
---

Uma pergunta sobre dois produtos não precisa de duas idas e voltas. **Uma resposta pode levar vários
blocos `tool_use` de uma vez**, e o host responde a todos antes de perguntar ao modelo de novo. O
`stock.py` da aula 8 seção 02 já trata disso, porque percorre todos os blocos da resposta.

## Dois produtos, uma resposta

```
ana@dev:~/shop$ python stock.py "Are MUG-01 and GLASS-03 in stock?"
<- stop_reason: tool_use
   {"text": "I will check both.", "type": "text"}
   {"id": "toolu_lab_0006_1", "input": {"sku": "MUG-01"}, "name": "get_stock", "type": "tool_use"}
   {"id": "toolu_lab_0006_2", "input": {"sku": "GLASS-03"}, "name": "get_stock", "type": "tool_use"}
-> user:
   {"type": "tool_result", "tool_use_id": "toolu_lab_0006_1", "content": "{\"in_stock\": 37, \"unit_price\": 3990}"}
   {"type": "tool_result", "tool_use_id": "toolu_lab_0006_2", "content": "{\"in_stock\": 0, \"unit_price\": 2490}"}
<- stop_reason: end_turn
   {"text": "MUG-01 is in stock, 37 units at 39.90. GLASS-03 is out of stock.", "type": "text"}
```

A primeira resposta tem três blocos: uma frase, depois duas chamadas com ids terminando em `_1` e
`_2`. **Os dois resultados voltam numa só mensagem `user`**, cada um com o id da chamada que
responde. A resposta do modelo então usa os dois, e diz que o GLASS-03 está sem estoque porque o
segundo resultado disse `"in_stock": 0`.

A ordem dos resultados não importa para a API; os ids importam. Um host que roda as duas chamadas
ao mesmo tempo, em threads ou com `asyncio`, pode acrescentar os resultados na ordem em que
terminarem.

## Deixando uma de fora

O erro que quebra isto é responder só às chamadas a que você chegou:

```python
"""The mistake: the model asked for two calls and the host sends back one result."""
import anthropic

from shop_tools import TOOLS

model = anthropic.Anthropic()
messages = [{"role": "user", "content": "Are MUG-01 and GLASS-03 in stock?"}]
r = model.messages.create(model="scripted-1", max_tokens=300, tools=TOOLS, messages=messages)
calls = [b for b in r.content if b.type == "tool_use"]
messages += [
    {"role": "assistant", "content": r.content},
    {"role": "user", "content": [{"type": "tool_result", "tool_use_id": calls[0].id, "content": "37"}]},
]
try:
    model.messages.create(model="scripted-1", max_tokens=300, tools=TOOLS, messages=messages)
except anthropic.BadRequestError as e:
    print(e.status_code, e.body["error"]["message"])
```

```
ana@dev:~/shop$ python one_result.py
400 messages.2: tool_use ids without a tool_result in the next message: toolu_lab_0008_2
```

**A API recusa a requisição.** A frase é do labllm, e um provedor de verdade também recusa isto, com
as próprias palavras. Seja como for, a falha é barulhenta e imediata, que é o caso bom: a
alternativa seria um modelo informado sobre um produto, perguntado sobre dois, e livre para chutar
o outro. Uma chamada que falha no seu código ainda recebe um resultado. Recebe um com `is_error`
ligado, como na aula 8 seção 04.

## Quando as chamadas dependem umas das outras

Duas chamadas numa resposta são chamadas que o modelo achou que podia fazer **sem ver nenhum dos
resultados**. Quando a segunda precisa da primeira, como em "consulte o pedido, depois o estoque do
que está nele", o modelo faz uma chamada, lê o resultado e faz a próxima numa resposta seguinte.
Esse é o laço da aula 7 de novo, e é por isso que um host que trata uma chamada por resposta não
basta.

## Desligando

As duas APIs com que este curso fala deixam quem chama pedir uma chamada por resposta: a da
Anthropic pelo `disable_parallel_tool_use` dentro do `tool_choice`, a da OpenAI pelo
`parallel_tool_calls`. **Use isso quando as chamadas mudam algo e a ordem delas importa**, como dois
reembolsos no mesmo pedido em que o segundo confere o que o primeiro deixou. Para leituras,
chamadas paralelas são só menos idas e voltas.
