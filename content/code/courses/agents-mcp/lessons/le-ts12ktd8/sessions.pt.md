---
title: "Sessões: uma conversa que dura mais que uma execução"
version: 1
---

Todo agente até aqui esquecia tudo no fim de uma execução: a conversa era uma variável local. Um cliente que escreve uma segunda mensagem espera que o agente lembre da primeira. As **sessões** do SDK guardam o histórico entre execuções e o mandam com cada nova.

```python
"""Two turns of one conversation, with and without the SDK's session memory."""
import sys

from agents import Agent, Runner, SQLiteSession, set_default_openai_api, set_tracing_disabled

from oa_tools import get_order, search_help

set_default_openai_api("chat_completions")
set_tracing_disabled(True)

agent = Agent(name="Support", model="scripted-1", tools=[get_order, search_help],
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
< Order M-1042 was delivered on 24 September 2026.
> Can I still return it?
< Which order do you mean? Please send me its number, such as M-1042.
ana@lab:~/agents$ python oa_session.py --session "Where is my order M-1042?" "Can I still return it?"
> Where is my order M-1042?
< Order M-1042 was delivered on 24 September 2026.
> Can I still return it?
< Yes. M-1042 was delivered on 24 September, and books can be returned within 30 days of delivery, so until 24 October.
```

Sem sessão, a segunda execução começou do zero: *"Can I still return it?"* não nomeia pedido nenhum, então o modelo (roteirizado pelo curso para se comportar com bom senso) perguntou qual. Com a sessão, a segunda execução levou o primeiro turno junto, a consulta do M-1042 incluída, e a resposta usou os dois. **A memória é a própria conversa, reenviada**, que é a regra da aula 1: a API não guarda nada, então tudo o que o modelo lembra viaja no pedido.

Isso tem as consequências que a aula 1 mediu. Cada turno é maior que o anterior, e uma sessão longa cresce até ficar cara ou não caber mais. O SDK oferece jeitos de aparar e compactar o histórico de uma sessão; qualquer que você use, é uma decisão sobre o que o agente esquece, e deve ser tomada de propósito.

Uma sessão também é dado pessoal guardado: o `sessions.db` agora tem as mensagens da Bia e os detalhes do pedido M-1042. Ele pertence ao mesmo inventário que o rastro (aula 3, seção 06): quem pode lê-lo, por quanto tempo é mantido, e como é apagado quando um cliente pede. A regra deste repositório para as tabelas dele vale também para as sessões de um agente: **um depósito de dados pessoais que o caminho de exclusão não alcança é um defeito.**
