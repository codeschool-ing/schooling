---
title: A person confirms the refund
version: 2
---

The ADK's version of lesson 8's approval is a flag on the tool, `require_confirmation=True`. The refund agent has it, and a `before_tool_callback` in front of every tool:

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

`limit_refunds` is called before any tool runs. Returning `None` lets the call continue; returning a dictionary **replaces the tool's result**, and the tool does not run. `run()` reports the confirmation the agent is waiting for, if any, and `main()` asks a person and sends the answer back as the next message.

The first refund run, with the warnings this lesson silences everywhere else:

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

The two warnings say that ADK marks **both features this run used as experimental**: the JSON Schema form of function declarations and tool confirmation itself. An experimental feature can change shape between versions, which is one more reason this lab pins its versions.

The events show how the pause works. When the model asked for `refund`, the ADK did not run it. It emitted a call of its own, `adk_request_confirmation`, carrying the original call and its arguments, recorded `{"error": "This tool call requires confirmation, please approve or reject."}` against the refund, and **the run ended**. The person's `n` went back as a function response in a new run, and the refund was rejected. The recorder logged 8 requests in all, most of them LiteLLM's `/api/show`, and none while the script waited for the answer: **the run had already ended**, so the model was not asked anything while the person decided. Look at what the person was asked to decide, too: a refund of 0 cents, for a damaged copy worth 3890.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A refund that needs confirmation, as two runs. In the first run the model asks for refund; ADK answers with a request for confirmation and the run ends. A person answers, and the answer is sent as the message of a second run, in which the refund runs or is rejected and the model writes the reply. No request reached the model while the person was deciding.\"><defs><marker id=\"l10conf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10conf-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">run 1</text><rect x=\"20\" y=\"40\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">request 1</text><text x=\"30\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">model asks for refund</text><rect x=\"200\" y=\"40\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">adk_request_confirmation</text><text x=\"210\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the run ends here</text><rect x=\"430\" y=\"40\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a person</text><text x=\"440\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">y or n</text><text x=\"200\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">run 2</text><rect x=\"200\" y=\"130\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the refund runs, or not</text><text x=\"210\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its result</text><rect x=\"430\" y=\"130\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">request 2</text><text x=\"440\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the model replies</text><path d=\"M170 65 L200 65\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l10conf-ah-amber)\"></path><path d=\"M400 65 L430 65\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l10conf-ah-phosphor)\"></path><path d=\"M490 90 L490 110 L300 110 L300 130\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l10conf-ah-phosphor)\"></path><path d=\"M400 155 L430 155\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l10conf-ah-amber)\"></path></svg>", "caption": "The wait is between two runs, so nothing is held open while a person decides."}
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

Approved, the refund did not run either. The person said yes to 0 cents, `refund` refused the amount (`cannot refund 0 cents on M-1047: 7780 left to refund`), and the refunds table stayed empty. A confirmation puts the arguments in front of a person; it does not make them right.

Because the pause is between two runs, and the confirmation is an event in the session, a person could answer from a different process later, as with lesson 8's `to_state()`, as long as the session is kept somewhere both processes can reach. `InMemoryRunner` keeps it in memory, so here it could not. The ADK's database session service is the other option, and in this lab it is not installed: it needs the library's `db` extra.

## A rule before the question

```
ana@lab:~/agents$ echo y | python adk_refund.py "Please refund the whole order M-1047."
refunds  call    refund {"cents": 0, "order_id": "M-1047", "reason": "Refunding whole order"}
refunds  call    adk_request_confirmation {"originalFunctionCall": {"id": "call_7gbqgyoi", "args": {"cents": 0, "order_id"
refunds  result  refund {"error": "This tool call requires confirmation, please approve or reject."}
approve? refund {'cents': 0, 'order_id': 'M-1047', 'reason': 'Refunding whole order'} [y/n] y
refunds  result  refund {"error": "cannot refund 0 cents on M-1047: 7780 left to refund"}
refunds  text    The request to refund the whole order M-1047 was not successful. The order still has a remaining balance of $7780.00.
```

Asked to refund the whole order, the model asked for 0 cents again. `limit_refunds` let the call through, since 0 is under the limit, the person was asked and said yes, and `refund` refused it. The callback is still the place for a rule with a right answer: it runs before the question, on every call, with nobody to persuade. In a run made while writing this lesson it met the model's strangest argument, `"get_order"` as the number of cents, and crashed on it; it now refuses anything that is not a whole number before anybody is asked. A rule with a right answer goes in code, before the people, which is lesson 9's hook in another library.
