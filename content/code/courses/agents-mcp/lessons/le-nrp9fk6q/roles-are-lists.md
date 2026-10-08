---
title: A role is a list of tools
version: 2
---

`role_host.py` is lesson 15's host with one change of shape: the agent has a **role**, and the role is written down as the servers and tools it may use.

```schooling-example
{
  "language": "python",
  "file": "role_host.py",
  "parts": [
    {
      "code": "\"\"\"A host whose agent's role decides which servers start, which tools exist, and what a reply may contain.\"\"\"\nimport asyncio\nimport json\nimport sys\nimport uuid\nfrom contextlib import AsyncExitStack\n\nimport anthropic\nfrom mcp import Client, StdioServerParameters\nfrom mcp.types import ElicitResult\n\nSYSTEM = \"You are the support agent of the permissions lesson. Use the tools; never guess.\"\nHERE = \"/home/ana/agents\"\nENV = {\"PATH\": \"/home/ana/agents/.venv/bin:/usr/bin:/bin\", \"HOME\": \"/home/ana\"}\nSERVERS = {\"shop\": \"marginalia_mcp.py\", \"refunds\": \"refund_mcp.py\"}\n"
    },
    {
      "code": "ROLES = {                                            # least privilege, written down: a role is a list of tools\n    \"support\": {\"shop\": [\"get_order\", \"search_help\"]},\n    \"refunds\": {\"shop\": [\"get_order\"], \"refunds\": [\"refund\"]},\n}\n",
      "note": "**Least privilege, as data.** The support agent reads orders and the help centre; the refunds agent reads orders and refunds. Nothing else exists for either."
    },
    {
      "code": "CONFIRM = {\"refunds__refund\"}                        # tools a person approves, call by call\n",
      "note": "**Calls a person approves**, one by one."
    },
    {
      "code": "CANARY = \"PINEAPPLE\"                                 # the test article's marker; it must never reach a customer\nRUN = uuid.uuid4().hex[:8]\nmodel = anthropic.Anthropic()\n\n\ndef ask(question):\n    print(f\"  ? {question} [y/n] \", end=\"\", flush=True)\n    answer = sys.stdin.readline().strip()\n    print(answer)\n    return answer == \"y\"\n\n\nasync def server_asks(context, params):\n    return ElicitResult(action=\"accept\", content={\"approve\": ask(f\"the server asks: {params.message}\")})\n\n\n",
      "note": "**A marker that must never reach a customer.** Section 06."
    },
    {
      "code": "def audit(role, **entry):\n    with open(\"role-audit.jsonl\", \"a\") as f:\n        f.write(json.dumps({\"run\": RUN, \"actor\": f\"agent:{role}\", **entry}) + \"\\n\")\n\n\nasync def main(role, task):\n    allowed = ROLES[role]\n    async with AsyncExitStack() as stack:\n        clients, tools = {}, []\n",
      "note": "**Every line names the actor**, `agent:support` or `agent:refunds`, and the run it belongs to."
    },
    {
      "code": "        for server, names in allowed.items():           # a server the role does not use is never started\n            params = StdioServerParameters(command=\"python\", args=[f\"{HERE}/{SERVERS[server]}\"], env=ENV)\n            clients[server] = await stack.enter_async_context(Client(params, elicitation_callback=server_asks))\n            for t in (await clients[server].list_tools()).tools:\n",
      "note": "**A server the role does not use is never started.** The support agent's host never launches the refunds server."
    },
    {
      "code": "                if t.name in names:                       # a tool the role does not list is never offered\n                    tools.append({\"name\": f\"{server}__{t.name}\", \"description\": t.description,\n                                  \"input_schema\": t.input_schema})\n        if \"shop\" in allowed:\n            tools.append({\"name\": \"read_help\", \"description\": \"Read one help centre article by its help:// URI.\",\n                          \"input_schema\": {\"type\": \"object\", \"properties\": {\"uri\": {\"type\": \"string\"}},\n                                           \"required\": [\"uri\"]}})\n        print(f\"role {role}: offered {', '.join(t['name'] for t in tools)}\")\n        offered = {t[\"name\"] for t in tools}\n        messages = [{\"role\": \"user\", \"content\": task}]\n        for step in range(1, 7):\n            reply = model.messages.create(model=\"llama3.2:3b\", max_tokens=1024, system=SYSTEM,\n                                          tools=tools, messages=messages)\n            messages.append({\"role\": \"assistant\", \"content\": reply.content})\n            calls = [b for b in reply.content if b.type == \"tool_use\"]\n            if not calls:\n                answer = reply.content[0].text\n",
      "note": "**A tool the role does not list is never offered** to the model."
    },
    {
      "code": "                if CANARY in answer:                      # an output check with a right answer: it is code\n                    audit(role, held=answer)\n                    print(\"held for review: the reply repeats the test canary\")\n                else:\n                    print(\"answer:\", answer)\n                return\n            results = []\n            for call in calls:\n                print(f\"step {step}: {call.name} {json.dumps(call.input)}\")\n                text, failed = await run(role, call, offered, clients)\n                print(f\"  {'refused' if failed else 'result'}: {text[:100]}\".replace(\"\\n\", \" \"))\n                results.append({\"type\": \"tool_result\", \"tool_use_id\": call.id, \"content\": text, \"is_error\": failed})\n            messages.append({\"role\": \"user\", \"content\": results})\n\n\nasync def run(role, call, offered, clients):\n",
      "note": "**An output check with a right answer**, so it is code."
    },
    {
      "code": "    if call.name not in offered:                          # the model asked for a tool this agent does not have\n        audit(role, tool=call.name, arguments=call.input, approved=False, reason=\"not offered\")\n        return f\"{call.name} is not available to the {role} agent\", True\n    if call.name == \"read_help\":\n        result = await clients[\"shop\"].read_resource(call.input[\"uri\"])\n        audit(role, resource=call.input[\"uri\"], approved=True)\n        return result.contents[0].text, False\n    if call.name in CONFIRM and not ask(f\"run {call.name} {json.dumps(call.input)}?\"):\n        audit(role, tool=call.name, arguments=call.input, approved=False, reason=\"declined by staff\")\n        return \"Not approved by staff; nothing was done.\", True\n    server, _, tool = call.name.partition(\"__\")\n    result = await clients[server].call_tool(tool, call.input)\n    audit(role, tool=call.name, arguments=call.input, approved=True, is_error=result.is_error)\n    if result.structured_content is not None:\n        return json.dumps(result.structured_content), result.is_error\n    return result.content[0].text, result.is_error\n\n\nasyncio.run(main(sys.argv[1], sys.argv[2]))",
      "note": "**A call to a tool this agent was not given is refused**, and the refusal is audited."
    }
  ]
}
```

The support agent was asked for a refund, with `llama3.2:3b` behind it:

```
ana@lab:~/agents$ python role_host.py support "One copy of M-1047 arrived damaged; please refund it." 2> host.err
role support: offered shop__get_order, shop__search_help, read_help
step 1: shop__get_order {"order_id": "M-1047"}
  result: {"id": "M-1047", "status": "delivered", "placed_on": "2026-09-15", "delivered_on": "2026-09-18", "tr
answer: Unfortunately, I'm a permissions lesson support agent and do not have the capability to process refunds. I can direct you to the relevant customer service department for assistance with your refund request. Would you like me to provide you with their contact information?
```

The model looked the order up and then told the customer it could not process refunds, which is true, and offered to pass them to customer service. It never asked for `refunds__refund`, so this run says nothing about the boundary: a model that does not try a door does not test the lock. A model that does try, after reading a convincing message, is what the test needs, and lesson 3's `standin.py` plays one, replying from this file:

```json
{"arrived damaged": [{"tool": "refunds__refund", "input": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}},
                     {"text": "I cannot issue refunds myself; a colleague will review order M-1047."}]}
```

```
ana@lab:~/agents$ python standin.py standin17.json &
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11436 python role_host.py support "One copy of M-1047 arrived damaged; please refund it." 2> host.err
role support: offered shop__get_order, shop__search_help, read_help
step 1: refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}
  refused: refunds__refund is not available to the support agent
answer: I cannot issue refunds myself; a colleague will review order M-1047.
```

The tool did not exist for this agent. The host refused the call before any server was involved (the refunds server was not even running), and the stand-in's written reply told the customer a colleague would look. **Nobody had to notice in time**: the boundary held because of what the agent was given, not because of anything the model decided, and that is why it holds the same for a real model that does try.

The refunds agent, asked the same thing by the real model:

```
ana@lab:~/agents$ printf "y\ny\n" | python role_host.py refunds "One copy of M-1047 arrived damaged; please refund it." 2> host.err
role refunds: offered shop__get_order, refunds__refund, read_help
step 1: refunds__refund {"order_id": "M-1047", "cents": "0", "reason": "damaged item arrived"}
  ? run refunds__refund {"order_id": "M-1047", "cents": "0", "reason": "damaged item arrived"}? [y/n] y
  ? the server asks: Refund 0 cents on M-1047? [y/n] y
  refused: Error executing tool refund
answer: Sorry to hear that you received a damaged copy of M-1047. Unfortunately, I don't have the exact information about your order, including the order number, to process a refund. Could you please provide me with the order number or any other relevant details so I can assist you further?
```

The model asked for `"0"` cents, as a string. The person approved it twice, once for the host and once for the server, and only the server's own rule stopped it: `shop.refund` will not refund 0 cents, so the call failed, and the model then asked the customer for the order number it had just used. Two agents, two lists, and the difference between them is three lines of data that can be reviewed like any other change. What the refunds agent did with its list is the next section's subject.
