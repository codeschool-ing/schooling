---
title: Workflows, where a step needs no model
version: 2
---

Lesson 5 separated agents, which decide their own steps, from workflows, whose steps are fixed in code. The ADK has had workflow agents for the second kind, `SequentialAgent`, `ParallelAgent` and `LoopAgent`, which run sub-agents one after another, all at once or in a loop, in an order fixed in code. In this version the first of them announces its own replacement:

```
ana@lab:~/agents$ python -c 'from google.adk.agents import SequentialAgent; SequentialAgent(name="pipeline", sub_agents=[])'
<string>:1: DeprecationWarning: SequentialAgent is deprecated in favor of Workflow and will be removed in a future version. Workflow cannot yet be used as an LlmAgent sub-agent.
```

The replacement is `Workflow`, a graph of nodes joined by edges, and a node can be an agent **or a plain function**. `adk_pipeline.py` uses one of each:

```schooling-example
{
  "language": "python",
  "file": "adk_pipeline.py",
  "parts": [
    {
      "code": "\"\"\"A fixed two-step workflow: plain code finds the facts, then an agent writes the reply from them.\"\"\"\nimport asyncio\nimport json\nimport re\n\nfrom google.adk.agents import Agent\nfrom google.adk.models.lite_llm import LiteLlm\nfrom google.adk.runners import InMemoryRunner\nfrom google.adk.workflow import START, Workflow\nfrom google.genai.types import Content, Part\n\nimport shop\nfrom adk_show import show\n\nMODEL = LiteLlm(model=\"ollama_chat/llama3.2:3b\")\n\n\n"
    },
    {
      "code": "def find_facts(node_input: str) -> str:\n    \"\"\"No model: the order id is a pattern, and the facts are a lookup.\"\"\"\n",
      "note": "**A node that is a function.** It receives the previous node's output, here the customer's message."
    },
    {
      "code": "    order = shop.get_order(re.search(r\"M-[0-9]{4}\", node_input).group(0))\n    return json.dumps({k: order[k] for k in (\"id\", \"status\", \"delivered_on\")})\n\n\n",
      "note": "**No model**: the order id is a pattern and the facts are a lookup, so code does it, every time the same way."
    },
    {
      "code": "writer = Agent(name=\"writer\", model=MODEL,\n               instruction=\"You write the customer's reply in the Google ADK lesson, from the facts you are given.\")\n",
      "note": "**A node that is an agent**, which writes the reply."
    },
    {
      "code": "pipeline = Workflow(name=\"pipeline\", edges=[(START, find_facts, writer)])",
      "note": "**The graph**: from the start to the function, from the function to the agent."
    },
    {
      "code": "\n\n\nasync def main():\n    runner = InMemoryRunner(agent=pipeline, app_name=\"marginalia\")\n    session = await runner.session_service.create_session(app_name=\"marginalia\", user_id=\"bia\")\n    async for event in runner.run_async(user_id=\"bia\", session_id=session.id,\n                                        new_message=Content(role=\"user\", parts=[Part(text=\"When was M-1042 delivered?\")])):\n        show(event)\n\n\nasyncio.run(main())"
    }
  ]
}
```

```
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ python adk_pipeline.py 2> /dev/null
pipeline output  {"id": "M-1042", "status": "delivered", "delivered_on": "2026-09-24"}
writer   text    Here's a possible customer reply in a Google ADK lesson format:

"Hi, just wanted to confirm that my order (M-1042) was delivered on 2026-09-24 as you stated. Can I get an update on the status of my order now? Thanks!"
ana@lab:~/agents$ python -c 'import json; [print(m["role"] + ":", json.dumps(m.get("content"), ensure_ascii=False)[:200]) for l in open("requests.jsonl") for m in json.loads(l)["request"].get("messages", [])]'
system: "You write the customer's reply in the Google ADK lesson, from the facts you are given."
user: "{\"id\": \"M-1042\", \"status\": \"delivered\", \"delivered_on\": \"2026-09-24\"}"
```

The function's output appears as an event of the workflow, and the writer wrote from it, though not what was meant: it wrote the customer's side, thanking the shop for a delivery. The second command prints everything the model received in the only request of the run: **one user message, the facts as JSON**. Not the customer's question, and not any instruction to look anything up. Finding an order needed no model, so no model was asked, and the model that wrote the reply could only use the facts it was given, which is lesson 5's argument for putting the fixed steps in code. That also cuts both ways: if the reply needed the customer's own words, the function would have had to pass them on, because each node receives only what the previous one produced. Here it needed even less than that: one line saying who the reply is for, which the writer's instruction left out and nothing else could supply.
