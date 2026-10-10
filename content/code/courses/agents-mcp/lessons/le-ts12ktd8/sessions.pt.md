---
title: "Sessões: uma conversa que dura mais que uma execução"
version: 2
---

Todo agente até aqui esquecia tudo no fim de uma execução: a conversa era uma variável local. Um cliente que escreve uma segunda mensagem espera que o agente lembre da primeira. As **sessões** do SDK guardam o histórico entre execuções e o mandam com cada nova.

```python
"""Two turns of one conversation, with and without the SDK's session memory."""
import sys

from agents import Agent, Runner, SQLiteSession, set_tracing_disabled

from oa_tools import get_order, search_help

set_tracing_disabled(True)

agent = Agent(name="Support", model="llama3.2:3b", tools=[get_order, search_help],
              instructions="You remember the conversation in the OpenAI Agents SDK lesson. Use the tools.")
session = SQLiteSession("bia", "sessions.db") if sys.argv[1] == "--session" else None
for message in sys.argv[2:]:
    result = Runner.run_sync(agent, message, session=session)
    print(f"> {message}\n< {result.final_output}")
```

`SQLiteSession("bia", "sessions.db")` guarda a conversa sob o id `bia` num arquivo SQLite. Dois turnos, sem e com ela:

```
ana@lab:~/agents$ python oa_session.py --none "Where is my order M-1042?" "Can I still return it?"
> Where is my order M-1042?
< Your order M-1042 has been delivered on September 24, 2026. The tracking number for your order is BR5512340002. You can track the status of your order by visiting the tracking page for this number. The total cost of your order, including taxes and shipping, was $3,480. The order includes the book with ID b39. There is no outstanding refund for your order.
> Can I still return it?
< Unfortunately, I'm not sure which specific return policy you're referring to, but it seems that you can still return items that have been shipped, especially if you've received them in the condition they were sent. However, the exact process and time frame for return vary depending on the product, store, and location.

To get more accurate information, I would recommend checking the specific return policy for the item you're trying to return, either on the store's website or by contacting their customer service directly. They should be able to provide you with more detailed instructions and any necessary forms or labels for returning the item.
ana@lab:~/agents$ python oa_session.py --session "Where is my order M-1042?" "Can I still return it?"
> Where is my order M-1042?
< Your order M-1042 was successfully processed. According to our records, the order was placed on September 20, 2026, and was delivered on September 24, 2026. The tracking number for your order is BR5512340002. Your order includes a book with the ID b39, which was shipped to you for a total of $34,80. Please note that the order has been delivered and there are no outstanding refunds.
> Can I still return it?
< You are eligible for a return within 30 days of delivery. Since your order was delivered on September 24, 2026, you have until October 24, 2026, to initiate a return. To initiate a return, please contact our customer service team and they will guide you through the return process. Please note that the book is in good condition and you will receive a full refund of the original purchase price, minus any shipping costs. Additionally, you will need to arrange for the return of the book at your own expense.
```

Sem sessão, a segunda execução começou do zero: *"Can I still return it?"* não nomeia pedido nenhum, então o modelo falou de políticas de devolução em geral e mandou o cliente para "the store's website". Com a sessão, a segunda execução levou o primeiro turno junto, a consulta do M-1042 incluída, e a resposta a usou: entregue em 24 de setembro, então devoluções até 24 de outubro. **A memória é a própria conversa, reenviada**, que é a regra da aula 1: a API não guarda nada, então tudo o que o modelo lembra viaja no pedido.

Isso tem as consequências que a aula 1 mediu. Cada turno é maior que o anterior, e uma sessão longa cresce até ficar cara ou não caber mais. O SDK oferece jeitos de aparar e compactar o histórico de uma sessão; qualquer que você use, é uma decisão sobre o que o agente esquece, e deve ser tomada de propósito.

Uma sessão também é dado pessoal guardado: o `sessions.db` agora tem as mensagens da Bia e os detalhes do pedido M-1042. Ele pertence ao mesmo inventário que o rastro (aula 3, seção 06): quem pode lê-lo, por quanto tempo é mantido, e como é apagado quando um cliente pede. A regra deste repositório para as tabelas dele vale também para as sessões de um agente: **um depósito de dados pessoais que o caminho de exclusão não alcança é um defeito.**
