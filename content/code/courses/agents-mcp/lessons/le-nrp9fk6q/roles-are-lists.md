---
title: A role is a list of tools
version: 1
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

The support agent was asked for a refund. The course's rule had the model ask for `refunds__refund` anyway, the way a model might after reading a convincing message:

```
ana@lab:~/agents$ python role_host.py support "One copy of M-1047 arrived damaged; please refund it." 2> host.err
role support: offered shop__get_order, shop__search_help, read_help
step 1: refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}
  refused: refunds__refund is not available to the support agent
answer: I cannot issue refunds myself; a colleague will review order M-1047 and reply to you by email.
```

The tool did not exist for this agent. The host refused the call before any server was involved (the refunds server was not even running), and the model told the customer a colleague would look. **Nobody had to notice in time**: the boundary held because of what the agent was given, not because of anything the model decided.

The refunds agent, asked the same thing:

```
ana@lab:~/agents$ printf "y\ny\n" | python role_host.py refunds "One copy of M-1047 arrived damaged; please refund it." 2> host.err
role refunds: offered shop__get_order, refunds__refund, read_help
step 1: refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}
  ? run refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}? [y/n] y
  ? the server asks: Refund 3890 cents on M-1047? [y/n] y
  result: {"result": "{\"order_id\": \"M-1047\", \"refunded\": 3890, \"left\": 3890}"}
answer: Done: 38.90 has been refunded to your original payment for the damaged copy in order M-1047.
```

The refund ran, after two approvals (section 05). Two agents, two lists, and the difference between them is three lines of data that can be reviewed like any other change.
