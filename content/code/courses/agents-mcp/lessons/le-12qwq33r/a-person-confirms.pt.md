---
title: Uma pessoa confirma o reembolso
version: 2
---

A versão do ADK para a aprovação da aula 8 é uma flag na ferramenta, `require_confirmation=True`. O agente de reembolsos a tem, e um `before_tool_callback` na frente de toda ferramenta:

```python
"""A refund that needs a person's confirmation, and a callback that refuses large ones first."""
import asyncio
import sys

from google.adk.agents import Agent
from google.adk.models.lite_llm import LiteLlm
from google.adk.runners import InMemoryRunner
from google.adk.tools import FunctionTool
from google.genai.types import Content, FunctionResponse, Part

from adk_show import show
from adk_tools import get_order, refund

MODEL = LiteLlm(model="ollama_chat/llama3.2:3b")
LIMIT = 5000  # cents; above this a refund is refused in code and no person is asked


def limit_refunds(tool, args, tool_context):
    if tool.name != "refund":
        return None                                                      # None: carry on
    try:
        cents = int(args["cents"])   # the model's arguments arrive unchecked: "7780", or not a number at all
    except (KeyError, ValueError):
        return {"error": "cents must be a whole number of cents"}        # returned instead of running the tool
    if cents > LIMIT:
        return {"error": f"Refunds above {LIMIT} cents need a manager."}
    return None


agent = Agent(name="refunds", model=MODEL,
              instruction="You handle refunds in the Google ADK lesson.",
              tools=[get_order, FunctionTool(refund, require_confirmation=True)],
              before_tool_callback=limit_refunds)


async def run(runner, session, message):
    """One run of the agent; returns the confirmation it stopped to wait for, if any."""
    waiting = None
    async for event in runner.run_async(user_id="bia", session_id=session.id, new_message=message):
        show(event)
        for part in event.content.parts if event.content else []:
            if part.function_call and part.function_call.name == "adk_request_confirmation":
                waiting = part.function_call
    return waiting


async def main(task):
    runner = InMemoryRunner(agent=agent, app_name="marginalia")
    session = await runner.session_service.create_session(app_name="marginalia", user_id="bia")
    waiting = await run(runner, session, Content(role="user", parts=[Part(text=task)]))
    while waiting:
        call = waiting.args["originalFunctionCall"]
        print(f"approve? {call['name']} {call['args']} [y/n] ", end="", flush=True)
        answer = sys.stdin.readline().strip()
        print(answer)
        reply = FunctionResponse(id=waiting.id, name="adk_request_confirmation", response={"confirmed": answer == "y"})
        waiting = await run(runner, session, Content(role="user", parts=[Part(function_response=reply)]))


asyncio.run(main(sys.argv[1]))
```

O `limit_refunds` é chamado antes de qualquer ferramenta rodar. Devolver `None` deixa a chamada seguir; devolver um dicionário **substitui o resultado da ferramenta**, e a ferramenta não roda. O `run()` informa a confirmação que o agente está esperando, se houver, e o `main()` pergunta a uma pessoa e manda a resposta de volta como a próxima mensagem.

A primeira execução de reembolso, com os avisos que esta aula silencia em todo o resto:

```
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ echo n | python adk_refund.py "One copy of M-1047 arrived damaged; please refund it."
/home/ana/agents/.venv/lib/python3.12/site-packages/google/adk/models/llm_request.py:306: UserWarning: [EXPERIMENTAL] feature FeatureName.JSON_SCHEMA_FOR_FUNC_DECL is enabled.
  declaration = tool._get_declaration()
/home/ana/agents/.venv/lib/python3.12/site-packages/google/adk/features/_feature_decorator.py:71: UserWarning: [EXPERIMENTAL] feature FeatureName.TOOL_CONFIRMATION is enabled.
  check_feature_enabled()
refunds  call    refund {"order_id": "M-1047", "cents": 0, "reason": "damaged"}
refunds  call    adk_request_confirmation {"originalFunctionCall": {"id": "call_o6jnay1q", "args": {"order_id": "M-1047", 
refunds  result  refund {"error": "This tool call requires confirmation, please approve or reject."}
approve? refund {'order_id': 'M-1047', 'cents': 0, 'reason': 'damaged'} [y/n] n
refunds  result  refund {"error": "This tool call is rejected."}
refunds  text    Refunds: Sorry, but the Google ADK tool does not have the ability to process refunds for damaged or defective items. If you would like to request a refund, please contact the seller or manufacturer directly.
ana@lab:~/agents$ wc -l < requests.jsonl
8
```

Os dois avisos dizem que o ADK marca **os dois recursos que esta execução usou como experimentais**: a forma JSON Schema das declarações de função e a própria confirmação de ferramenta. Um recurso experimental pode mudar de forma entre versões, o que é mais um motivo para este laboratório fixar as versões.

Os eventos mostram como a pausa funciona. Quando o modelo pediu `refund`, o ADK não o rodou. Ele emitiu uma chamada própria, `adk_request_confirmation`, levando a chamada original e os argumentos, registrou `{"error": "This tool call requires confirmation, please approve or reject."}` para o reembolso, e **a execução terminou**. O `n` da pessoa voltou como resposta de função numa execução nova, e o reembolso foi rejeitado. O gravador registrou 8 pedidos ao todo, quase todos o `/api/show` do LiteLLM, e nenhum enquanto o script esperava a resposta: **a execução já tinha terminado**, então nada foi perguntado ao modelo enquanto a pessoa decidia. Repare também no que a pessoa teve de decidir: um reembolso de 0 centavos, por um exemplar danificado que vale 3890.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Um reembolso que precisa de confirmação, como duas execuções. Na primeira, o modelo pede refund; o ADK responde com um pedido de confirmação e a execução termina. Uma pessoa responde, e a resposta é mandada como a mensagem de uma segunda execução, na qual o reembolso roda ou é rejeitado e o modelo escreve a resposta. Nenhum pedido chegou ao modelo enquanto a pessoa decidia.\"><defs><marker id=\"l10conf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10conf-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">execução 1</text><rect x=\"20\" y=\"40\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pedido 1</text><text x=\"30\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o modelo pede refund</text><rect x=\"200\" y=\"40\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">adk_request_confirmation</text><text x=\"210\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a execução termina aqui</text><rect x=\"430\" y=\"40\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma pessoa</text><text x=\"440\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">y ou n</text><text x=\"200\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">execução 2</text><rect x=\"200\" y=\"130\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o reembolso roda, ou não</text><text x=\"210\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o resultado</text><rect x=\"430\" y=\"130\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pedido 2</text><text x=\"440\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o modelo responde</text><path d=\"M170 65 L200 65\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l10conf-ah-amber)\"></path><path d=\"M400 65 L430 65\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l10conf-ah-phosphor)\"></path><path d=\"M490 90 L490 110 L300 110 L300 130\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l10conf-ah-phosphor)\"></path><path d=\"M400 155 L430 155\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l10conf-ah-amber)\"></path></svg>", "caption": "A espera fica entre duas execuções, então nada fica aberto enquanto uma pessoa decide."}
```

```
ana@lab:~/agents$ echo y | python adk_refund.py "One copy of M-1047 arrived damaged; please refund it."
refunds  call    refund {"cents": 0, "reason": "damaged", "order_id": "M-1047"}
refunds  call    adk_request_confirmation {"originalFunctionCall": {"id": "call_lf78qut8", "args": {"cents": 0, "reason": 
refunds  result  refund {"error": "This tool call requires confirmation, please approve or reject."}
approve? refund {'cents': 0, 'reason': 'damaged', 'order_id': 'M-1047'} [y/n] y
refunds  result  refund {"error": "cannot refund 0 cents on M-1047: 7780 left to refund"}
refunds  text    I'm sorry, but I am unable to refund M-1047. The tool call response indicates that there is still an outstanding refund amount of $7780. I recommend reaching out to the Google Support team or the relevant department to discuss possible alternatives for resolving the issue.
ana@lab:~/agents$ python -c 'import sqlite3; print(sqlite3.connect("data/shop.db").execute("SELECT order_id, cents, approved_by FROM refunds").fetchall())'
[]
```

Aprovado, o reembolso também não rodou. A pessoa disse sim a 0 centavos, o `refund` recusou o valor (`cannot refund 0 cents on M-1047: 7780 left to refund`), e a tabela de reembolsos ficou vazia. Uma confirmação põe os argumentos diante de uma pessoa; ela não os torna certos.

Como a pausa fica entre duas execuções, e a confirmação é um evento na sessão, uma pessoa poderia responder de outro processo mais tarde, como com o `to_state()` da aula 8, desde que a sessão fique guardada num lugar que os dois processos alcancem. O `InMemoryRunner` a guarda na memória, então aqui não daria. O serviço de sessões em banco de dados do ADK é a outra opção, e neste laboratório ele não está instalado: precisa do extra `db` da biblioteca.

## Uma regra antes da pergunta

```
ana@lab:~/agents$ echo y | python adk_refund.py "Please refund the whole order M-1047."
refunds  call    refund {"cents": 0, "order_id": "M-1047", "reason": "Refunding whole order"}
refunds  call    adk_request_confirmation {"originalFunctionCall": {"id": "call_7gbqgyoi", "args": {"cents": 0, "order_id"
refunds  result  refund {"error": "This tool call requires confirmation, please approve or reject."}
approve? refund {'cents': 0, 'order_id': 'M-1047', 'reason': 'Refunding whole order'} [y/n] y
refunds  result  refund {"error": "cannot refund 0 cents on M-1047: 7780 left to refund"}
refunds  text    The request to refund the whole order M-1047 was not successful. The order still has a remaining balance of $7780.00.
```

Pedido para reembolsar o pedido inteiro, o modelo pediu 0 centavos de novo. O `limit_refunds` deixou a chamada passar, já que 0 está abaixo do limite, a pessoa foi perguntada e disse sim, e o `refund` a recusou. O callback continua sendo o lugar de uma regra com resposta certa: ele roda antes da pergunta, em toda chamada, sem ninguém a convencer. Numa execução feita enquanto esta aula era escrita, ele encontrou o argumento mais estranho do modelo, `"get_order"` como número de centavos, e caiu com isso; agora ele recusa tudo o que não é um número inteiro antes de alguém ser perguntado. Uma regra com resposta certa vai no código, antes das pessoas, que é o hook da aula 9 em outra biblioteca.
