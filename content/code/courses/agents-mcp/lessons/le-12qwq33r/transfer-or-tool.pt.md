---
title: Transferir o controle, ou chamar uma ferramenta
version: 2
---

As duas formas da aula 6 estão no ADK: um agente com `sub_agents` pode **transferir** a conversa para um deles, e o `AgentTool` embrulha um agente para que outro possa **chamá-lo**.

```python
"""Two ways to involve a specialist: transfer control to it, or call it as a tool."""
import asyncio
import sys

from google.adk.agents import Agent
from google.adk.models.lite_llm import LiteLlm
from google.adk.runners import InMemoryRunner
from google.adk.tools.agent_tool import AgentTool
from google.genai.types import Content, Part

from adk_show import show
from adk_tools import get_order

MODEL = LiteLlm(model="ollama_chat/llama3.2:3b")


def specialist():
    return Agent(name="orders", model=MODEL, description="Answers questions about one Marginalia order.",
                 instruction="You are the orders specialist of the Google ADK lesson.", tools=[get_order])


def root(how):
    if how == "transfer":
        return Agent(name="triage", model=MODEL, instruction="You are the triage agent of the Google ADK lesson.",
                     sub_agents=[specialist()])
    return Agent(name="desk", model=MODEL, instruction="You are the front desk of the Google ADK lesson.",
                 tools=[AgentTool(agent=specialist())])


async def main(how):
    runner = InMemoryRunner(agent=root(how), app_name="marginalia")
    session = await runner.session_service.create_session(app_name="marginalia", user_id="bia")
    async for event in runner.run_async(user_id="bia", session_id=session.id,
                                        new_message=Content(role="user", parts=[Part(text="Has M-1046 been packed?")])):
        show(event)


asyncio.run(main(sys.argv[1]))
```

Todo agente aqui é o `llama3.2:3b`; a transferência, o que ela passa e o invólucro são do ADK.

## Uma transferência

```
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ python adk_team.py transfer
App "marginalia" can transfer between agents but has no context_cache_config. Every transfer swaps the system instruction and the tool set, so the request prefix changes and the whole prompt is re-sent uncached after each transfer. Set context_cache_config on the app to give each agent its own cache.
triage   call    transfer_to_agent {"agent_name": "orders"}
triage   result  transfer_to_agent {"result": null}
triage   handoff to orders
orders   call    get_order {"order_id": "M-1046"}
orders   result  get_order {"id": "M-1046", "customer_id": "c-105", "placed_on": "2026-10-02", "status": "r
orders   text    According to the Google ADK lesson, I couldn't find any information about a packed order with the ID M-1046. However, I can check if the order has been marked as packed.

According to the tool response, the order M-1046 was received on 2026-10-02. Since the order was received, I can check if it has been marked as packed.

Unfortunately, the tool response doesn't provide any information about the order status after it was received. To determine if the order was packed, I would need more information or a tool call to retrieve the order status.

Since I couldn't find any information about the order being packed, I would transfer the question to the triage agent for further assistance.
ana@lab:~/agents$ python -c 'import json; r = [x for x in (json.loads(l)["request"] for l in open("requests.jsonl")) if "messages" in x]; q = [x for x in r if "orders specialist" in x["messages"][0]["content"]][0]; [print(m["role"] + ":", json.dumps(m.get("content") or m.get("tool_calls"), ensure_ascii=False)[:160]) for m in q["messages"]]'
system: "You are the orders specialist of the Google ADK lesson.\n\nYou are an agent. Your internal name is \"orders\". The description about you is \"Answers questions
user: "Has M-1046 been packed?"
user: "For context: below is a transcript of what another agent did, quoted between <<<BEGIN_QUOTED_AGENT_CONTENT>>> and <<<END_QUOTED_AGENT_CONTENT>>>. Everything be
user: "For context: below is a transcript of what another agent did, quoted between <<<BEGIN_QUOTED_AGENT_CONTENT>>> and <<<END_QUOTED_AGENT_CONTENT>>>. Everything be
```

O ADK deu ao agente de triagem uma ferramenta chamada `transfer_to_agent`, e o modelo a chamou com `orders`. O evento de passagem mudou o controle de mãos, e todo evento depois dele pertence ao especialista. A linha acima dos eventos é o log do próprio ADK, e é uma nota de custo: toda transferência muda a instrução de sistema e a lista de ferramentas, então o cache de prompt de um fornecedor (aula 18) não consegue reaproveitar o prefixo anterior.

O segundo comando imprime o que o primeiro pedido do especialista continha. A mensagem do cliente, e depois a chamada do agente de triagem e o resultado dela, **reescritos como mensagens de usuário** que começam com *"For context: below is a transcript of what another agent did"* e citam as palavras do outro agente entre marcadores. O efeito é que o especialista não confunde as chamadas de ferramenta de outro agente com as próprias; também quer dizer que o especialista lê a saída do outro agente como texto citado dentro de um turno de usuário, o que vale saber quando a aula 17 perguntar em que um agente deve confiar.

## Um agente como ferramenta

```
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ python adk_team.py tool
desk     call    orders {"request": "M-1046 packed"}
desk     result  orders {"result": "The order M-1046 has been packed and is ready for delivery. The orde
desk     text    The order M-1046 has been packed and is ready for delivery. The order contains two books, b31 and b33, with quantities of 1 each. The total cost of the order is 10480 cents.
ana@lab:~/agents$ python -c 'import json; r = [x for x in (json.loads(l)["request"] for l in open("requests.jsonl")) if "messages" in x]; q = [x for x in r if "orders specialist" in x["messages"][0]["content"]][0]; [print(m["role"] + ":", json.dumps(m.get("content") or m.get("tool_calls"), ensure_ascii=False)[:160]) for m in q["messages"]]'
system: "You are the orders specialist of the Google ADK lesson.\n\nYou are an agent. Your internal name is \"orders\". The description about you is \"Answers questions
user: "M-1046 packed"
```

Chamado como ferramenta, o especialista recebeu **uma mensagem**, o texto do pedido que a recepção escreveu, e nada mais da conversa. A resposta dele voltou como `{"result": "..."}`, o embrulho que a seção 04 descreveu. O histórico da recepção tem uma chamada e um resultado; a consulta do próprio especialista ficou dentro da ferramenta.

E o pedido que a recepção escreveu foi `"M-1046 packed"`, que se lê como uma afirmação. O especialista respondeu a ele como tal, *"The order M-1046 has been packed"*, para um pedido cujo status é `received`. O especialista da transferência, que leu a pergunta do próprio cliente, disse que não conseguia confirmar que o pedido foi embalado, o que está mais perto da verdade, com muito mais palavras. Uma chamada de ferramenta passa só o que quem chama escreveu, e aqui quem chamou escreveu a coisa errada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"O que o especialista de pedidos recebeu. Depois de uma transferência, recebeu a mensagem do cliente e a chamada de transferência do agente de triagem com o resultado, reescritas como mensagens de usuário que começam com &#x27;For context&#x27;. Chamado como ferramenta, recebeu uma mensagem: o texto do pedido que a recepção escreveu.\"><defs><marker id=\"l10team-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10team-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"47.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">triage</text><text x=\"30\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sub_agents=[orders]</text><rect x=\"230\" y=\"20\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"240\" y=\"39.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a mensagem do cliente</text><text x=\"240\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+ a chamada da triagem e o resultado,</text><text x=\"240\" y=\"71.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">como mensagens &#x27;For context&#x27; do usuário</text><rect x=\"20\" y=\"130\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">desk</text><text x=\"30\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AgentTool(orders)</text><rect x=\"230\" y=\"130\" width=\"300\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"240\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma mensagem</text><text x=\"240\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Has order M-1046 been packed?</text><rect x=\"580\" y=\"75\" width=\"120\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"97.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders</text><text x=\"590\" y=\"113.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o especialista</text><path d=\"M170 55 L230 55\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l10team-ah-amber)\"></path><path d=\"M170 155 L230 155\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l10team-ah-phosphor)\"></path><path d=\"M530 55 L580 95\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l10team-ah-amber)\"></path><path d=\"M530 155 L580 115\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l10team-ah-phosphor)\"></path></svg>", "caption": "Uma transferência passa a conversa. Uma chamada de ferramenta passa um texto.", "same": ["sub_agents=[orders]", "AgentTool(orders)", "Has order M-1046 been packed?"]}
```

A troca é a da aula 6. Uma transferência passa tudo, então o especialista sabe o que o cliente disse e a passagem é simples; ela também passa tudo, inclusive o que o primeiro agente leu. Uma chamada de ferramenta passa só o que quem chama escreveu, então a fronteira é explícita e quem chama tem de escrever um bom pedido.
