---
title: Passagens e agentes como ferramentas
version: 1
---

A aula 6 construiu as duas formas multiagente à mão. O SDK tem as duas como recursos de uma linha: `handoffs=[...]` num agente, e `agent.as_tool(...)`.

```python
"""Two ways to combine agents in the OpenAI Agents SDK: a handoff, and an agent used as a tool."""
import sys

from agents import Agent, Runner, set_default_openai_api, set_tracing_disabled

from oa_tools import get_order, search_help

set_default_openai_api("chat_completions")
set_tracing_disabled(True)

orders = Agent(name="Orders specialist", model="scripted-1", tools=[get_order, search_help],
               instructions="You are the orders specialist of the OpenAI Agents SDK lesson. Answer about orders.",
               handoff_description="Questions about a customer's orders: status, delivery, changes.")

triage = Agent(name="Triage", model="scripted-1", handoffs=[orders],
               instructions="You are the triage agent of the OpenAI Agents SDK lesson. Hand off to the right agent.")

front_desk = Agent(name="Front desk", model="scripted-1",
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

**As decisões de roteamento foram escritas pelo curso**; a maquinaria de passagem, o histórico que ela passa e o invólucro de agente como ferramenta são do SDK.

## Uma passagem

```
ana@lab:~/agents$ python oa_team.py "My order M-1046 has not shipped. Why?" handoff
Triage             HandoffCallItem      ResponseFunctionToolCall(arguments='{}', call_id='call_l
Triage             HandoffOutputItem    {'call_id': 'call_lab_0017_1', 'output': '{"assistant": 
Orders specialist  ToolCallItem         ResponseFunctionToolCall(arguments='{"order_id": "M-1046
Orders specialist  ToolCallOutputItem   {'call_id': 'call_lab_0018_1', 'output': "{'id': 'M-1046
Orders specialist  MessageOutputItem    ResponseOutputMessage(id='__fake_id__', content=[Respons
last agent: Orders specialist
answer: Order M-1046 still says Received, so it has not been packed yet. The tracking link comes by email when it ships.
ana@lab:~/agents$ sed -n 2p /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(m["role"], str(m.get("content"))[:90]) for m in json.loads(sys.stdin.read())["request"]["messages"]]'
system You are the orders specialist of the OpenAI Agents SDK lesson. Answer about orders.
user My order M-1046 has not shipped. Why?
assistant None
tool {"assistant": "Orders specialist"}
```

O SDK transformou `handoffs=[orders]` numa ferramenta chamada `transfer_to_orders_specialist`, a partir do nome do agente, e o agente de triagem a chamou. Os itens mostram o momento em que o controle mudou de mãos: um `HandoffCallItem` e um `HandoffOutputItem` pertencem à Triage, e todo item depois deles pertence ao Orders specialist, que respondeu. `result.last_agent` diz quem terminou.

O segundo comando imprime as mensagens do primeiro pedido do especialista, que é o que atravessou a fronteira (aula 6, seção 07). O especialista recebeu a mensagem do cliente, **mais a chamada de ferramenta do agente de triagem e o resultado dela**, `{"assistant": "Orders specialist"}`. Esse é o padrão do SDK: a conversa até ali, passagem incluída. Um `input_filter` na passagem muda o que é passado, por exemplo para descartar chamadas de ferramenta anteriores; essa é a decisão que a aula 6 mandou tomar em código.

## Um agente como ferramenta

```
ana@lab:~/agents$ python oa_team.py "My order M-1046 has not shipped. Why?" tool
Front desk         ToolCallItem         ResponseFunctionToolCall(arguments='{"input": "What is t
Front desk         ToolCallOutputItem   {'call_id': 'call_lab_0020_1', 'output': 'Order M-1046 s
Front desk         MessageOutputItem    ResponseOutputMessage(id='__fake_id__', content=[Respons
last agent: Front desk
answer: Your order M-1046 has been received and is not packed yet; you will get a tracking link by email when it ships.
```

O `orders.as_tool(...)` embrulhou o especialista como uma ferramenta chamada `ask_orders` com um argumento string, `input`. A recepção a chamou, o especialista rodou o próprio laço com as próprias ferramentas, e a resposta final dele voltou como saída da ferramenta; a recepção respondeu ao cliente. Todos os itens pertencem à recepção: os passos do próprio especialista estão dentro da chamada de ferramenta, não no histórico da recepção, que é de novo a fronteira da aula 6. **Nada das evidências do especialista atravessa a menos que você passe**: o invólucro `as_tool` devolve a saída final por padrão, e um extrator de saída próprio pode devolver mais.
