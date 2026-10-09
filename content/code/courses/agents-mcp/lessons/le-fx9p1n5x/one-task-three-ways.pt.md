---
title: Uma mensagem de cliente, três programas
version: 2
---

Bia, cliente da Marginalia, escreve: *"Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"* ("Oi, sou a Bia. Meu pedido M-1042 chegou em 24 de setembro. Ainda posso devolvê-lo?"). Aqui estão três programas respondendo a essa mensagem na máquina que a seção 03 montou, cada um fazendo o trabalho do jeito do seu tipo. O modelo é o `llama3.2:3b`, e as palavras dele abaixo são o que ele disse no dia em que esta aula foi gravada. **As suas vão sair com outras palavras**, e de vez em quando ele vai seguir outro caminho; isso é da natureza da coisa, e o fim desta seção volta a esse ponto.

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
    model="llama3.2:3b",
    max_tokens=1024,
    system="You draft replies for Marginalia's support team. The help centre follows.\n\n" + handbook,
    messages=[{"role": "user", "content": sys.argv[1]}],
)
print(reply.content[0].text)
```

Um pedido. O programa cola os catorze artigos da central de ajuda no prompt de sistema, manda a mensagem da Bia e imprime o que volta:

```
ana@lab:~/agents$ python assistant.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
Hi Bia,

According to our help centre, you have 30 days from delivery to return a printed book. Since your order arrived on 24 September, that means you have until 24 October to return it.

Please go to the order in your account and follow the instructions for returning the book. Print the prepaid label and drop the parcel at any post office. Returns are free.

If you have any issues or concerns with the return process, feel free to reach out to us and we'll be happy to assist you.

Best,
[Your Support Team]
```

O rascunho é bom: trinta dias a partir da entrega, então até 24 de outubro, e como mandar o pacote. **Ele aceitou a data de entrega pela palavra da Bia**, porque não enxerga pedidos, e nada no rascunho diz isso. Esse é o trabalho de quem envia: abrir o pedido, ver o `delivered_on` e decidir. O modelo escreveu; uma pessoa age.

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
      "code": "for step in range(1, 6):\n    reply = client.messages.create(model=\"llama3.2:3b\", max_tokens=1024, system=SYSTEM,\n                                   tools=TOOLS, messages=messages)\n    messages.append({\"role\": \"assistant\", \"content\": reply.content})\n    if reply.stop_reason != \"tool_use\":\n        print(f\"[{step}] answer: {reply.content[0].text}\")\n        break\n",
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
[2] answer: Hello Bia,

According to the information provided, your order M-1042 was delivered on September 24, 2026. However, I don't have the exact date range during which returns are accepted.

I recommend checking the website of the seller or the delivery company that brought your order to see if they have any specific return windows. If you're still unsure, you can also reach out to their customer service for assistance.

Please note that even if you're able to return your order, it's always a good idea to contact the seller first to confirm their return policy and any potential restocking fees.
```

Dois pedidos ao modelo. No primeiro, ele pediu o pedido da loja; no segundo, com `delivered` e a data à frente, respondeu, e **a resposta está errada**. Ela diz que não conhece o prazo de devolução e manda a Bia procurar "o vendedor", quando o prazo é de trinta dias e a central de ajuda diz isso. Ele nunca buscou na central de ajuda. A data que ele cita veio do banco de dados e não da Bia, que é a única coisa que ele fez melhor que o assistente; tudo depois da data ele inventou.

A seção 07 mostra por que este modelo parou depois de uma ferramenta, e não é falta de inteligência: no segundo pedido, o modelo já não enxergava as ferramentas. Por enquanto, guarde o formato da falha. **Um agente que age com base em fatos que nunca consultou é pior que um assistente cujo rascunho uma pessoa lê**, porque ninguém lê a resposta do agente antes da Bia.

Dê ao mesmo programa duas outras mensagens e ele segue dois outros caminhos:

```
ana@lab:~/agents$ python agent.py "My order M-1043 has not arrived yet. Where is it?"
[1] get_order({"order_id": "M-1043"})
[2] answer: Thank you for providing the order details. According to the tracking information, your order M-1043 was shipped on 2026-09-28, but it has not been delivered yet. The tracking number is BR5512340003. I recommend checking the tracking status periodically for updates on the delivery location and estimated arrival time. If you have any further concerns, please don't hesitate to contact us.
```

```
ana@lab:~/agents$ python agent.py "Which ways can I pay?"
[1] search_help({"query": "Payment methods"})
[2] answer: We accept Visa, Mastercard, and American Express, PayPal, Pix, and Marginalia gift cards. If you have a gift card, enter the 16-digit code at checkout to use it towards your order. Please note that gift cards can be used to pay for part of an order and the rest can be paid with a card, with no interest on orders over $120. Gift cards are valid for two years from purchase and cannot be exchanged for cash. If you experience any issues with your payment being charged twice, please contact us with your order number and a bank statement to resolve the issue.
```

**Nada no `agent.py` menciona rastreio, devolução ou pagamento.** No M-1043 o passo seguinte foi o pedido, porque a mensagem citava um; na pergunta de pagamento não havia pedido envolvido, então o passo foi uma busca, e a resposta veio do artigo encontrado, com dois deslizes próprios: um cifrão que o artigo não tem e uma frase sobre cobrança em dobro que ninguém perguntou. O caminho foi decidido na hora, pelo modelo, e nenhum dos outros dois programas conseguiria isso. Se ele decidiu bem é a pergunta que o resto deste curso não para de fazer.
