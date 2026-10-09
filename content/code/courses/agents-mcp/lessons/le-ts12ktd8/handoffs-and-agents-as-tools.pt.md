---
title: Passagens e agentes como ferramentas
version: 2
---

A aula 6 construiu as duas formas multiagente à mão. O SDK tem as duas como recursos de uma linha: `handoffs=[...]` num agente, e `agent.as_tool(...)`.

```python
"""Two ways to combine agents in the OpenAI Agents SDK: a handoff, and an agent used as a tool."""
import sys

from agents import Agent, Runner, set_tracing_disabled

from oa_tools import get_order, search_help

set_tracing_disabled(True)

orders = Agent(name="Orders specialist", model="llama3.2:3b", tools=[get_order, search_help],
               instructions="You are the orders specialist of the OpenAI Agents SDK lesson. Answer about orders.",
               handoff_description="Questions about a customer's orders: status, delivery, changes.")

triage = Agent(name="Triage", model="llama3.2:3b", handoffs=[orders],
               instructions="You are the triage agent of the OpenAI Agents SDK lesson. Hand off to the right agent.")

front_desk = Agent(name="Front desk", model="llama3.2:3b",
                   instructions="You are the front desk of the OpenAI Agents SDK lesson. Ask the specialist, then answer.",
                   tools=[orders.as_tool(tool_name="ask_orders",
                                         tool_description="Ask the orders specialist one question about an order.")])

agent = triage if sys.argv[2] == "handoff" else front_desk
result = Runner.run_sync(agent, sys.argv[1])
for item in result.new_items:
    print(f"{item.agent.name:18} {type(item).__name__:20} {str(getattr(item, 'raw_item', ''))[:56]}")
print(f"last agent: {result.last_agent.name}")
print("answer:", result.final_output)
```

## Uma passagem

```
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python oa_team.py "My order M-1046 has not shipped. Why?" handoff
Triage             HandoffCallItem      ResponseFunctionToolCall(arguments='{}', call_id='call_8
Triage             HandoffOutputItem    {'call_id': 'call_84lpl9va', 'output': '{"assistant": "O
Orders specialist  MessageOutputItem    ResponseOutputMessage(id='msg_343825', content=[Response
last agent: Orders specialist
answer: I've checked on the status of your order M-1046. Unfortunately, it still hasn't shipped. I apologize for the inconvenience this has caused. The status of your order is currently listed as "backorder" which indicates that the item is out of stock or not yet available for shipping. I recommend checking the status again in a few hours or contacting our customer service department directly to inquire about the latest shipping information.
ana@lab:~/agents$ sed -n 2p requests.jsonl | python -c 'import json, sys; r = json.loads(sys.stdin.read())["request"]; print("instructions", r["instructions"][:80]); [print(i.get("role", i.get("type")), str(i.get("content", i.get("output", i.get("arguments"))))[:80]) for i in r["input"]]'
instructions You are the orders specialist of the OpenAI Agents SDK lesson. Answer about orde
user My order M-1046 has not shipped. Why?
function_call {}
function_call_output {"assistant": "Orders specialist"}
```

O SDK transformou `handoffs=[orders]` numa ferramenta chamada `transfer_to_orders_specialist`, a partir do nome do agente, e o agente de triagem a chamou. Os itens mostram o momento em que o controle mudou de mãos: um `HandoffCallItem` e um `HandoffOutputItem` pertencem à Triage, e todo item depois deles pertence ao Orders specialist, que respondeu. `result.last_agent` diz quem terminou. A maquinaria funcionou; a resposta, não. O especialista não chamou nenhuma ferramenta e disse ao cliente que o pedido está em "backorder", um status que os pedidos da Marginalia não têm: M-1046 diz `received`.

O segundo comando imprime as mensagens do primeiro pedido do especialista, que é o que atravessou a fronteira (aula 6, seção 07). O especialista recebeu a mensagem do cliente, **mais a chamada de ferramenta do agente de triagem e o resultado dela**, `{"assistant": "Orders specialist"}`. Esse é o padrão do SDK: a conversa até ali, passagem incluída. Um `input_filter` na passagem muda o que é passado, por exemplo para descartar chamadas de ferramenta anteriores; essa é a decisão que a aula 6 mandou tomar em código.

## Um agente como ferramenta

```
ana@lab:~/agents$ python oa_team.py "My order M-1046 has not shipped. Why?" tool
Front desk         ToolCallItem         ResponseFunctionToolCall(arguments='{"input":"My order M
Front desk         ToolCallOutputItem   {'call_id': 'call_41z6t84v', 'output': 'Based on the too
Front desk         MessageOutputItem    ResponseOutputMessage(id='msg_924597', content=[Response
last agent: Front desk
answer: {"name": "ask_tracking_numbers", "parameters": {"input":"What tracking information is available for order M-1046?"}}
```

O `orders.as_tool(...)` embrulhou o especialista como uma ferramenta chamada `ask_orders` com um argumento string, `input`. A recepção a chamou, o especialista rodou o próprio laço com as próprias ferramentas, e a resposta final dele voltou como saída da ferramenta. Depois a recepção escreveu a resposta ao cliente, e a resposta é uma chamada de ferramenta em texto: `{"name": "ask_tracking_numbers", ...}`, para uma ferramenta que não existe, que nenhum hospedeiro rodou porque chegou como palavras. É o que a constatação da aula 1 sobre o template prevê: depois de um resultado de ferramenta o modelo não vê mais as ferramentas, e às vezes escreve uma chamada mesmo assim, como texto. Todos os itens pertencem à recepção: os passos do próprio especialista estão dentro da chamada de ferramenta, não no histórico da recepção, que é de novo a fronteira da aula 6. **Nada das evidências do especialista atravessa a menos que você passe**: o invólucro `as_tool` devolve a saída final por padrão, e um extrator de saída próprio pode devolver mais.
