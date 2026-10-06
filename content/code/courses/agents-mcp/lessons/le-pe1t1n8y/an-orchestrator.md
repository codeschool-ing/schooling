---
title: An orchestrator and two specialists
version: 1
---

`multi.py` builds all three designs this lesson compares from one function, `loop`, which is lesson 4's agent loop made reusable: a name, a system prompt, a set of tools and a conversation. **The agents' decisions and words were written by the course** as rules for the stand-in; the delegation, the separate loops, the tools and their results are real.

```schooling-example
{
  "language": "python",
  "file": "multi.py",
  "parts": [
    {
      "code": "\"\"\"Several agents: an orchestrator that delegates to specialists, a triage agent that hands over, or one agent alone.\"\"\"\nimport json\nimport sys\n\nimport anthropic\n\nimport shop\nfrom tools import TOOLS as SHOP_TOOLS, run_tool\n\nclient = anthropic.Anthropic()\nBY_NAME = {t[\"name\"]: t for t in SHOP_TOOLS}\n"
    },
    {
      "code": "SEARCH_HELP = {\"name\": \"search_help\", \"description\": \"Search Marginalia's help centre and return the three closest articles.\",\n               \"input_schema\": {\"type\": \"object\", \"additionalProperties\": False, \"required\": [\"query\"],\n                                \"properties\": {\"query\": {\"type\": \"string\"}}}}\nQUESTION = {\"type\": \"object\", \"additionalProperties\": False, \"required\": [\"question\"],\n            \"properties\": {\"question\": {\"type\": \"string\"}}}\n",
      "note": "**A tool definition** for the help-centre search, which lesson 4's `tools.py` does not carry."
    },
    {
      "code": "EVIDENCE = \"--evidence\" in sys.argv\n\n\ndef shop_tool(name, args):\n    if name == \"search_help\":\n        return json.dumps([{\"title\": a[\"title\"], \"body\": a[\"body\"]} for a in shop.search_help(args[\"query\"])]), False\n    return run_tool(name, args)\n\n\n",
      "note": "**A switch for section 08.**"
    },
    {
      "code": "def loop(name, system, tools, messages, run, depth=0):\n    \"\"\"One agent: its own system prompt, its own tools, its own conversation. Returns (answer, evidence).\"\"\"\n    pad, evidence = \"    \" * depth, []\n    for step in range(1, 6):\n        reply = client.messages.create(model=\"scripted-1\", max_tokens=1024, system=system,\n                                       tools=tools, messages=messages)\n        messages.append({\"role\": \"assistant\", \"content\": reply.content})\n        calls = [b for b in reply.content if b.type == \"tool_use\"]\n        if not calls:\n            answer = \" \".join(b.text for b in reply.content if b.type == \"text\")\n            print(f\"{pad}{name}: {answer}\")\n            return answer, evidence\n        results = []\n        for b in calls:\n            print(f\"{pad}{name} -> {b.name}({json.dumps(b.input)})\")\n            text, is_error = run(b.name, b.input, depth)\n",
      "note": "**One agent.** Its own system prompt, its own tools, its own `messages`. The `depth` only indents the printout, so you can see who is talking."
    },
    {
      "code": "            evidence.append(f\"{b.name} {json.dumps(b.input)} -> {text[:110]}\")\n            results.append({\"type\": \"tool_result\", \"tool_use_id\": b.id, \"content\": text, \"is_error\": is_error})\n        messages.append({\"role\": \"user\", \"content\": results})\n    return f\"{name} stopped after 5 steps\", evidence\n\n\n",
      "note": "**Every call and the start of its result is kept**, whether or not anyone asks for it."
    },
    {
      "code": "SPECIALISTS = {\n    \"orders\": (\"You are Marginalia's orders specialist. Answer the question about orders with your tools, \"\n               \"in two sentences at most.\", [BY_NAME[\"get_order\"], SEARCH_HELP]),\n    \"catalogue\": (\"You are Marginalia's catalogue specialist. Answer the question about books with your tools, \"\n                  \"in two sentences at most.\", [BY_NAME[\"find_books\"]]),\n}\n\n\n",
      "note": "**Two specialists, each with only its tools.** Orders gets `get_order` and the help centre; catalogue gets `find_books` and nothing else."
    },
    {
      "code": "def ask(specialist, question, depth):\n    \"\"\"A specialist used as a tool: it gets the question only, and its answer is the tool's result.\"\"\"\n    system, tools = SPECIALISTS[specialist]\n    answer, evidence = loop(specialist, system, tools, [{\"role\": \"user\", \"content\": question}],\n                            lambda n, a, d: shop_tool(n, a), depth + 1)\n    if EVIDENCE:\n        answer += \"\\nEvidence:\\n\" + \"\\n\".join(evidence)\n    return answer, False\n\n\n",
      "note": "**A specialist used as a tool.** It starts a fresh conversation with the question alone, and its answer becomes the tool's result."
    },
    {
      "code": "def orchestrate(task):\n    tools = [{\"name\": \"ask_orders\", \"description\": \"Ask the orders specialist one question about orders.\",\n              \"input_schema\": QUESTION},\n             {\"name\": \"ask_catalogue\", \"description\": \"Ask the catalogue specialist one question about books.\",\n              \"input_schema\": QUESTION}]\n    system = (\"You are Marginalia's support orchestrator. Delegate: ask_orders for anything about an order, \"\n              \"ask_catalogue for books. Then answer the customer.\")\n    loop(\"orchestrator\", system, tools, [{\"role\": \"user\", \"content\": task}],\n         lambda n, a, d: ask(n.removeprefix(\"ask_\"), a[\"question\"], d))\n\n\n",
      "note": "**The orchestrator's tools are the specialists**: `ask_orders` and `ask_catalogue`, each taking one question."
    },
    {
      "code": "def triage(task):\n    \"\"\"Handoff: the triage agent transfers control, and the specialist answers the customer itself.\"\"\"\n    messages = [{\"role\": \"user\", \"content\": task}]\n    tools = [{\"name\": f\"transfer_to_{s}\", \"description\": f\"Hand this conversation to the {s} specialist.\",\n              \"input_schema\": {\"type\": \"object\", \"properties\": {}}} for s in SPECIALISTS]\n    reply = client.messages.create(model=\"scripted-1\", max_tokens=200, tools=tools, messages=messages,\n                                   system=\"You are Marginalia's triage agent. Transfer the conversation to the right specialist.\")\n    call = next(b for b in reply.content if b.type == \"tool_use\")\n    target = call.name.removeprefix(\"transfer_to_\")\n    print(f\"triage hands the conversation to {target}\")\n    system, specialist_tools = SPECIALISTS[target]\n    loop(target, system, specialist_tools, [{\"role\": \"user\", \"content\": task}], lambda n, a, d: shop_tool(n, a))\n\n\n",
      "note": "**Handoff**: one request to decide, then the specialist's loop runs on the customer's message and answers it."
    },
    {
      "code": "def alone(task):\n    tools = [BY_NAME[\"get_order\"], SEARCH_HELP, BY_NAME[\"find_books\"]]\n    loop(\"agent\", \"You are Marginalia's support agent, working alone. Use the tools, then answer.\", tools,\n         [{\"role\": \"user\", \"content\": task}], lambda n, a, d: shop_tool(n, a))\n\n\nif __name__ == \"__main__\":\n    mode = \"--handoff\" in sys.argv and triage or \"--single\" in sys.argv and alone or orchestrate\n    mode(sys.argv[1])",
      "note": "**The baseline**: one agent with all three tools."
    }
  ]
}
```

A customer asks two unrelated things at once:

```
ana@lab:~/agents$ python multi.py "Did my order M-1043 ship yet? Also, can you suggest a science fiction book you have in stock?"
orchestrator -> ask_orders({"question": "Has order M-1043 shipped?"})
    orders -> get_order({"order_id": "M-1043"})
    orders: Yes, M-1043 has shipped and is not delivered yet. Its tracking code is BR5512340003.
orchestrator -> ask_catalogue({"question": "Which science fiction books are in stock?"})
    catalogue -> find_books({"genre": "science fiction"})
    catalogue: In stock: The Time Machine by H. G. Wells at 24.90 and The War of the Worlds by H. G. Wells at 25.90.
orchestrator: Yes, order M-1043 has shipped; its tracking code is BR5512340003. For science fiction, we have The Time Machine (24.90) and The War of the Worlds (25.90), both by H. G. Wells, in stock.
```

The indentation is the delegation. The orchestrator asked both specialists in one reply, the way lesson 4's agent asked for two orders at once. Each specialist ran its own loop: one tool call, one answer. The orchestrator read both answers as tool results and wrote the reply.

Look at what each specialist was asked: *"Has order M-1043 shipped?"* and *"Which science fiction books are in stock?"* Neither saw the customer's message. **The orchestrator rewrote the task into two questions**, and each specialist's whole knowledge of the conversation is that one sentence. Section 07 is about that boundary.
