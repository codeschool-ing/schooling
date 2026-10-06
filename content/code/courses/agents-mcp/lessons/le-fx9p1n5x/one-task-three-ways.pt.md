---
title: Uma mensagem de cliente, três programas
version: 1
---

Bia, cliente da Marginalia, escreve: *"Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"* ("Oi, sou a Bia. Meu pedido M-1042 chegou em 24 de setembro. Ainda posso devolvê-lo?"). Aqui estão três programas respondendo a essa mensagem no laboratório, cada um fazendo o trabalho do jeito do seu tipo. **As palavras do modelo nesta seção foram escritas pelo curso**, como a seção 07 explica; os programas, os dados e a busca são reais.

## Automação

```python
"""Automation: the programmer wrote the path, and the program follows it."""
import sys
from datetime import date, timedelta

import shop

RETURN_DAYS = 30

order = shop.get_order(sys.argv[1])
if order["status"] != "delivered":
    print(f"{order['id']}: not delivered yet ({order['status']}), nothing to return")
else:
    last = date.fromisoformat(order["delivered_on"]) + timedelta(days=RETURN_DAYS)
    if shop.TODAY <= last:
        print(f"{order['id']}: can be returned until {last}")
    else:
        print(f"{order['id']}: the return window closed on {last}")
```

Toda decisão nele foi tomada por quem o escreveu: a janela é de 30 dias, um pedido que não está `delivered` não tem o que devolver, e a entrada é um id de pedido. Diante do que ele espera, é rápido, de graça e certo toda vez:

```
ana@lab:~/agents$ python automation.py M-1042
M-1042: can be returned until 2026-10-24
ana@lab:~/agents$ python automation.py M-1044
M-1044: the return window closed on 2026-09-13
ana@lab:~/agents$ python automation.py M-1043
M-1043: not delivered yet (shipped), nothing to return
ana@lab:~/agents$ python automation.py "the book I bought last week"
Traceback (most recent call last):
  File "/home/ana/agents/automation.py", line 9, in <module>
    order = shop.get_order(sys.argv[1])
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/agents/shop.py", line 29, in get_order
    raise LookupError(f"no order {order_id}")
LookupError: no order the book I bought last week
```

A quarta execução é a limitação inteira num traceback. Clientes escrevem frases, e esta nomeou o pedido pela data em que foi comprado. **Nada no programa consegue decidir tratar uma frase de outro jeito**, então a frase foi direto para o `get_order` como se fosse um id. Um programador pode acrescentar um ramo para isso, e depois outro para a próxima surpresa, e essa é a vida de uma automação: correta dentro dos seus caminhos e indefesa fora deles.

## Assistente

```python
"""Assistant: one request. The model writes a draft, and a person decides what to send."""
import json
import sys

import anthropic

articles = [json.loads(line) for line in open("data/help.jsonl")]
handbook = "\n\n".join(f"# {a['title']}\n{a['body']}" for a in articles)

client = anthropic.Anthropic()
reply = client.messages.create(
    model="scripted-1",
    max_tokens=1024,
    system="You draft replies for Marginalia's support team. The help centre follows.\n\n" + handbook,
    messages=[{"role": "user", "content": sys.argv[1]}],
)
print(reply.content[0].text)
```

Um pedido. O programa cola os quarenta artigos da central de ajuda no prompt de sistema, manda a mensagem da Bia e imprime o que volta:

```
ana@lab:~/agents$ python assistant.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
Draft reply: Hi Bia, printed books can be returned within 30 days of delivery, free of charge: start the return from the order in your account, print the prepaid label and drop the parcel at any post office. If M-1042 arrived on 24 September, you have until 24 October. [For the support team: I cannot see orders. Check the delivery date before sending this.]
```

O rascunho é bom, e é cuidadoso com a única coisa que não podia saber. **Ele aceitou a data de entrega pela palavra da Bia**, porque não consegue ver pedidos, e diz isso a quem vai enviá-lo. Essa pessoa é a verificação: abre o pedido, vê o `delivered_on` e decide. O modelo escreveu; um humano age.

## Agente

```schooling-example
{
  "language": "python",
  "file": "agent.py",
  "parts": [
    {
      "code": "\"\"\"Agent: the model chooses the next step, the program runs it, until the model answers.\"\"\"\nimport json\nimport sys\n\nimport anthropic\n\nimport shop\n\n"
    },
    {
      "code": "TOOLS = [\n    {\"name\": \"get_order\",\n     \"description\": \"Look up one Marginalia order by its id, such as M-1042: status, dates, lines and amounts in cents.\",\n     \"input_schema\": {\"type\": \"object\", \"properties\": {\"order_id\": {\"type\": \"string\"}}, \"required\": [\"order_id\"]}},\n    {\"name\": \"search_help\",\n     \"description\": \"Search Marginalia's help centre by meaning and return the three closest articles.\",\n     \"input_schema\": {\"type\": \"object\", \"properties\": {\"query\": {\"type\": \"string\"}}, \"required\": [\"query\"]}},\n]\n",
      "note": "**Duas ferramentas, descritas em palavras e num esquema.** O modelo nunca vê o `shop.py`; vê esses nomes, descrições e formatos de argumento, e nada mais."
    },
    {
      "code": "RUN = {\n    \"get_order\": lambda args: shop.get_order(args[\"order_id\"]),\n    \"search_help\": lambda args: [{\"title\": a[\"title\"], \"body\": a[\"body\"]} for a in shop.search_help(args[\"query\"])],\n}\n",
      "note": "**O que de fato roda.** Uma tabela do nome da ferramenta para o Python que a executa. Esta é a metade do contrato que cabe ao programa."
    },
    {
      "code": "SYSTEM = \"You answer Marginalia's customers. Use the tools to find facts, and never guess an order's details.\"\n\n",
      "note": "**Uma instrução**, e ela importa: consultar os fatos em vez de adivinhá-los."
    },
    {
      "code": "client = anthropic.Anthropic()\nmessages = [{\"role\": \"user\", \"content\": sys.argv[1]}]\n",
      "note": "**A conversa começa com a mensagem da Bia**, e cresce uma resposta e um lote de resultados a cada passo."
    },
    {
      "code": "for step in range(1, 6):\n    reply = client.messages.create(model=\"scripted-1\", max_tokens=1024, system=SYSTEM,\n                                   tools=TOOLS, messages=messages)\n    messages.append({\"role\": \"assistant\", \"content\": reply.content})\n    if reply.stop_reason != \"tool_use\":\n        print(f\"[{step}] answer: {reply.content[0].text}\")\n        break\n",
      "note": "**O laço.** Mandar tudo até aqui, ler a resposta e parar se o modelo não pediu ferramenta. Cinco passos no máximo, queira o modelo ou não."
    },
    {
      "code": "    results = []\n    for block in reply.content:\n        if block.type == \"tool_use\":\n            print(f\"[{step}] {block.name}({json.dumps(block.input)})\")\n            output = RUN[block.name](block.input)\n            results.append({\"type\": \"tool_result\", \"tool_use_id\": block.id, \"content\": json.dumps(output)})\n    messages.append({\"role\": \"user\", \"content\": results})",
      "note": "**Executar o que foi pedido** e devolver cada resultado, amarrado ao seu pedido pelo `tool_use_id`."
    }
  ]
}
```

```
ana@lab:~/agents$ python agent.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
[1] get_order({"order_id": "M-1042"})
[2] search_help({"query": "return a book"})
[3] answer: Yes, Bia. Order M-1042 was delivered on 24 September 2026, and printed books can be returned within 30 days of delivery, so you have until 24 October. Start the return from the order in your account, print the prepaid label and drop the parcel at any post office. Returns are free.
```

Três pedidos ao modelo. No primeiro, ele pediu o pedido da loja; no segundo, com `delivered` e a data à frente, pediu o artigo de devolução; no terceiro, respondeu. **A data na resposta veio do banco de dados, não da Bia**, e essa é a diferença em relação ao rascunho do assistente.

Dê ao mesmo programa duas outras mensagens e ele segue dois outros caminhos:

```
ana@lab:~/agents$ python agent.py "My order M-1043 has not arrived yet. Where is it?"
[1] get_order({"order_id": "M-1043"})
[2] search_help({"query": "tracking a parcel"})
[3] answer: Order M-1043 is on its way: it has shipped and has not been delivered yet. The carrier's tracking code is BR5512340003, and the tracking link in your shipping email updates at each step of the journey.
```

```
ana@lab:~/agents$ python agent.py "Which ways can I pay?"
[1] search_help({"query": "payment methods"})
[2] answer: We accept Visa, Mastercard and American Express, PayPal, Pix and Marginalia gift cards. A card payment can be split into up to three instalments with no interest on orders over 120. We do not accept cash on delivery.
```

**Nada no `agent.py` menciona rastreio, devolução ou pagamento.** No M-1043 o pedido voltou `shipped`, e o passo seguinte virou uma busca sobre rastreio; na pergunta de pagamento não havia pedido envolvido, então não houve consulta nenhuma, e dois pedidos bastaram. O caminho foi decidido na execução, pelo modelo, um passo depois do outro, e nenhum dos outros dois programas conseguia fazer isso.
