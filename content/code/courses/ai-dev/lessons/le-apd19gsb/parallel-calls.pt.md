---
title: Várias chamadas numa resposta
version: 2
---

Uma pergunta sobre dois produtos não precisa de duas idas e voltas. **Uma resposta pode levar vários
blocos `tool_use` de uma vez**, e o host responde a todos antes de perguntar ao modelo de novo. O
`stock.py` da aula 8 seção 02 já trata disso, porque percorre todos os blocos da resposta.

## Dois produtos, uma resposta

```
ana@dev:~/shop$ python stock.py "Are MUG-01 and GLASS-03 in stock?"
<- stop_reason: tool_use
   {"id": "call_8xfkxfof", "input": {"sku": "MUG-01"}, "name": "get_stock", "type": "tool_use"}
   {"id": "call_6rxmxd6y", "input": {"sku": "GLASS-03"}, "name": "get_stock", "type": "tool_use"}
-> user:
   {"type": "tool_result", "tool_use_id": "call_8xfkxfof", "content": "{\"in_stock\": 37, \"unit_price\": 3990}"}
   {"type": "tool_result", "tool_use_id": "call_6rxmxd6y", "content": "{\"in_stock\": 0, \"unit_price\": 2490}"}
<- stop_reason: end_turn
   {"text": "MUG-01 is currently in stock with 37 units available, priced at $3990 per unit.\n\nUnfortunately, GLASS-03 is currently out of stock.", "type": "text"}
```

A primeira resposta tem dois blocos, duas chamadas, cada uma com o próprio id. **Os dois resultados
voltam numa só mensagem `user`**, cada um com o id da chamada que responde. A resposta do modelo então
usa os dois: o GLASS-03 está sem estoque porque o segundo resultado disse `"in_stock": 0`. Ela também
põe a caneca a $3990, que são os centavos da seção 02 lidos como dólares de novo.

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
r = model.messages.create(model="llama3.2:3b", max_tokens=300, tools=TOOLS, messages=messages, extra_body={"temperature": 0})
calls = [b for b in r.content if b.type == "tool_use"]
print("asked for:", ", ".join(f"{c.name}({c.input['sku']})" for c in calls))
messages += [
    {"role": "assistant", "content": r.content},
    {"role": "user", "content": [{"type": "tool_result", "tool_use_id": calls[0].id, "content": "37"}]},
]
try:
    r = model.messages.create(model="llama3.2:3b", max_tokens=300, tools=TOOLS, messages=messages, extra_body={"temperature": 0})
    print("accepted, and answered:", r.content[0].text)
except anthropic.BadRequestError as e:
    print(e.status_code, e.body["error"]["message"])
```

```
ana@dev:~/shop$ python one_result.py
asked for: get_stock(MUG-01), get_stock(GLASS-03)
accepted, and answered: Unfortunately, I couldn't find any information on the stock levels of MUG-01 and GLASS-03. However, I can suggest checking with the manufacturer or a authorized distributor for the most up-to-date information on availability.
```

**O Ollama aceitou.** A segunda requisição passou com uma das duas chamadas sem resposta, e o modelo,
informado de que o resultado do MUG-01 era 37, respondeu que não achou nada sobre nenhum dos dois
produtos. A própria API da Anthropic recusa uma requisição assim com um erro 400 que nomeia a
chamada sem resultado, e o `one_result.py` imprime esse erro quando recebe um; aqui não recebeu,
porque o Ollama não confere. **A falha foi silenciosa**: uma resposta que parece uma resposta e joga
fora o único fato que recebeu. Um host não pode contar com o servidor para perceber, então responde
toda chamada, sempre: uma chamada que falha no seu código ainda recebe um resultado, um com
`is_error` ligado, como na aula 8 seção 04.

## Quando as chamadas dependem umas das outras

Duas chamadas numa resposta são chamadas que o modelo achou que podia fazer **sem ver nenhum dos
resultados**. Quando a segunda precisa da primeira, como em "consulte o pedido, depois o estoque do
que está nele", o modelo tem de fazer uma chamada, ler o resultado e fazer a próxima numa resposta
seguinte. Esse é o laço da aula 7 de novo, e a aula 7 seção 03 achou que o `llama3.2:3b` no Ollama
não faz isso: depois de um resultado, o template dele não lhe mostra ferramenta nenhuma. O que ele
precisar, tem de pedir na primeira resposta.

## Desligando

As duas APIs com que este curso fala deixam quem chama pedir uma chamada por resposta: a da
Anthropic pelo `disable_parallel_tool_use` dentro do `tool_choice`, a da OpenAI pelo
`parallel_tool_calls`. **Use isso quando as chamadas mudam algo e a ordem delas importa**, como dois
reembolsos no mesmo pedido em que o segundo confere o que o primeiro deixou. Para leituras,
chamadas paralelas são só menos idas e voltas.
