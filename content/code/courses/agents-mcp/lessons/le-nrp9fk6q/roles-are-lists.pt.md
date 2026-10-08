---
title: Um papel é uma lista de ferramentas
version: 1
---

O `role_host.py` é o hospedeiro da aula 15 com uma mudança de forma: o agente tem um **papel**, e o papel é escrito como os servidores e ferramentas que ele pode usar.

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
      "note": "**Privilégio mínimo, como dado.** O agente de suporte lê pedidos e a central de ajuda; o agente de reembolsos lê pedidos e reembolsa. Nada mais existe para nenhum dos dois."
    },
    {
      "code": "CONFIRM = {\"refunds__refund\"}                        # tools a person approves, call by call\n",
      "note": "**Chamadas que uma pessoa aprova**, uma a uma."
    },
    {
      "code": "CANARY = \"PINEAPPLE\"                                 # the test article's marker; it must never reach a customer\nRUN = uuid.uuid4().hex[:8]\nmodel = anthropic.Anthropic()\n\n\ndef ask(question):\n    print(f\"  ? {question} [y/n] \", end=\"\", flush=True)\n    answer = sys.stdin.readline().strip()\n    print(answer)\n    return answer == \"y\"\n\n\nasync def server_asks(context, params):\n    return ElicitResult(action=\"accept\", content={\"approve\": ask(f\"the server asks: {params.message}\")})\n\n\n",
      "note": "**Um marcador que nunca pode chegar a um cliente.** Seção 06."
    },
    {
      "code": "def audit(role, **entry):\n    with open(\"role-audit.jsonl\", \"a\") as f:\n        f.write(json.dumps({\"run\": RUN, \"actor\": f\"agent:{role}\", **entry}) + \"\\n\")\n\n\nasync def main(role, task):\n    allowed = ROLES[role]\n    async with AsyncExitStack() as stack:\n        clients, tools = {}, []\n",
      "note": "**Toda linha nomeia o ator**, `agent:support` ou `agent:refunds`, e a execução a que pertence."
    },
    {
      "code": "        for server, names in allowed.items():           # a server the role does not use is never started\n            params = StdioServerParameters(command=\"python\", args=[f\"{HERE}/{SERVERS[server]}\"], env=ENV)\n            clients[server] = await stack.enter_async_context(Client(params, elicitation_callback=server_asks))\n            for t in (await clients[server].list_tools()).tools:\n",
      "note": "**Um servidor que o papel não usa nunca é iniciado.** O hospedeiro do agente de suporte nunca lança o servidor de reembolsos."
    },
    {
      "code": "                if t.name in names:                       # a tool the role does not list is never offered\n                    tools.append({\"name\": f\"{server}__{t.name}\", \"description\": t.description,\n                                  \"input_schema\": t.input_schema})\n        if \"shop\" in allowed:\n            tools.append({\"name\": \"read_help\", \"description\": \"Read one help centre article by its help:// URI.\",\n                          \"input_schema\": {\"type\": \"object\", \"properties\": {\"uri\": {\"type\": \"string\"}},\n                                           \"required\": [\"uri\"]}})\n        print(f\"role {role}: offered {', '.join(t['name'] for t in tools)}\")\n        offered = {t[\"name\"] for t in tools}\n        messages = [{\"role\": \"user\", \"content\": task}]\n        for step in range(1, 7):\n            reply = model.messages.create(model=\"llama3.2:3b\", max_tokens=1024, system=SYSTEM,\n                                          tools=tools, messages=messages)\n            messages.append({\"role\": \"assistant\", \"content\": reply.content})\n            calls = [b for b in reply.content if b.type == \"tool_use\"]\n            if not calls:\n                answer = reply.content[0].text\n",
      "note": "**Uma ferramenta que o papel não lista nunca é oferecida** ao modelo."
    },
    {
      "code": "                if CANARY in answer:                      # an output check with a right answer: it is code\n                    audit(role, held=answer)\n                    print(\"held for review: the reply repeats the test canary\")\n                else:\n                    print(\"answer:\", answer)\n                return\n            results = []\n            for call in calls:\n                print(f\"step {step}: {call.name} {json.dumps(call.input)}\")\n                text, failed = await run(role, call, offered, clients)\n                print(f\"  {'refused' if failed else 'result'}: {text[:100]}\".replace(\"\\n\", \" \"))\n                results.append({\"type\": \"tool_result\", \"tool_use_id\": call.id, \"content\": text, \"is_error\": failed})\n            messages.append({\"role\": \"user\", \"content\": results})\n\n\nasync def run(role, call, offered, clients):\n",
      "note": "**Uma checagem de saída com resposta certa**, então é código."
    },
    {
      "code": "    if call.name not in offered:                          # the model asked for a tool this agent does not have\n        audit(role, tool=call.name, arguments=call.input, approved=False, reason=\"not offered\")\n        return f\"{call.name} is not available to the {role} agent\", True\n    if call.name == \"read_help\":\n        result = await clients[\"shop\"].read_resource(call.input[\"uri\"])\n        audit(role, resource=call.input[\"uri\"], approved=True)\n        return result.contents[0].text, False\n    if call.name in CONFIRM and not ask(f\"run {call.name} {json.dumps(call.input)}?\"):\n        audit(role, tool=call.name, arguments=call.input, approved=False, reason=\"declined by staff\")\n        return \"Not approved by staff; nothing was done.\", True\n    server, _, tool = call.name.partition(\"__\")\n    result = await clients[server].call_tool(tool, call.input)\n    audit(role, tool=call.name, arguments=call.input, approved=True, is_error=result.is_error)\n    if result.structured_content is not None:\n        return json.dumps(result.structured_content), result.is_error\n    return result.content[0].text, result.is_error\n\n\nasyncio.run(main(sys.argv[1], sys.argv[2]))",
      "note": "**Uma chamada a uma ferramenta que este agente não recebeu é recusada**, e a recusa é auditada."
    }
  ]
}
```

O agente de suporte recebeu um pedido de reembolso. A regra do curso fez o modelo pedir `refunds__refund` mesmo assim, do jeito que um modelo poderia pedir depois de ler uma mensagem convincente:

```
ana@lab:~/agents$ python role_host.py support "One copy of M-1047 arrived damaged; please refund it." 2> host.err
role support: offered shop__get_order, shop__search_help, read_help
step 1: refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}
  refused: refunds__refund is not available to the support agent
answer: I cannot issue refunds myself; a colleague will review order M-1047 and reply to you by email.
```

A ferramenta não existia para este agente. O hospedeiro recusou a chamada antes de qualquer servidor participar (o servidor de reembolsos nem estava rodando), e o modelo disse ao cliente que um colega ia olhar. **Ninguém precisou perceber a tempo**: a fronteira se sustentou pelo que o agente recebeu, não por algo que o modelo decidiu.

O agente de reembolsos, com o mesmo pedido:

```
ana@lab:~/agents$ printf "y\ny\n" | python role_host.py refunds "One copy of M-1047 arrived damaged; please refund it." 2> host.err
role refunds: offered shop__get_order, refunds__refund, read_help
step 1: refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}
  ? run refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}? [y/n] y
  ? the server asks: Refund 3890 cents on M-1047? [y/n] y
  result: {"result": "{\"order_id\": \"M-1047\", \"refunded\": 3890, \"left\": 3890}"}
answer: Done: 38.90 has been refunded to your original payment for the damaged copy in order M-1047.
```

O reembolso rodou, depois de duas aprovações (seção 05). Dois agentes, duas listas, e a diferença entre eles são três linhas de dados que podem ser revisadas como qualquer outra mudança.
