---
title: Workflows, where a step needs no model
version: 1
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
    }
  ]
}
```

```
ana@lab:~/agents$ python adk_pipeline.py 2> /dev/null
pipeline output  {"id": "M-1042", "status": "delivered", "delivered_on": "2026-09-24"}
writer   text    Your order M-1042 was delivered on 24 September 2026. If anything is wrong with it, reply to this email and we will help.
ana@lab:~/agents$ python -c 'import json; [print(json.dumps(c, ensure_ascii=False)) for l in open("/var/log/labllm/requests.jsonl") for c in json.loads(l)["request"]["contents"]]'
{"parts": [{"text": "{\"id\": \"M-1042\", \"status\": \"delivered\", \"delivered_on\": \"2026-09-24\"}"}], "role": "user"}
```

The function's output appears as an event of the workflow, and the writer answered from it. The second command prints everything the model received in the only request of the run: **one user message, the facts as JSON**. Not the customer's question, and not any instruction to look anything up. Finding an order needed no model, so no model was asked, and the model that wrote the reply could only use the facts it was given, which is lesson 5's argument for putting the fixed steps in code. That also cuts both ways: if the reply needed the customer's own words, the function would have had to pass them on, because each node receives only what the previous one produced.
