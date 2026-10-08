---
title: Um hospedeiro num arquivo
version: 2
---

O suporte a MCP de uma biblioteca toma as decisões do hospedeiro por você, e a aula 12 mostrou três bibliotecas tomando-as de três jeitos. O `mcp_host.py` as toma ele mesmo, em código: o laço da aula 7, agora com servidores MCP no lugar de funções locais, e o `Client` do SDK `mcp` para cada conexão. Ele fala com o modelo pela API de Messages da Anthropic, que o Ollama responde.

```schooling-example
{
  "language": "python",
  "file": "mcp_host.py",
  "parts": [
    {
      "code": "\"\"\"A host: one model, two MCP servers, and every decision about them written down.\"\"\"\nimport asyncio\nimport json\nimport sys\nfrom contextlib import AsyncExitStack\n\nimport anthropic\nfrom mcp import Client, StdioServerParameters\nfrom mcp.types import ElicitResult\n\nSYSTEM = \"You are the support agent of the MCP client lesson. Use the tools; never guess.\"\nMAX_STEPS = 6\n"
    },
    {
      "code": "ENV = {\"PATH\": \"/home/ana/agents/.venv/bin:/usr/bin:/bin\", \"HOME\": \"/home/ana\"}   # all a server process inherits\n",
      "note": "**O que um processo de servidor herda, como lista.** Nada do shell da ana chega a um servidor se não estiver nomeado aqui. Seção 04."
    },
    {
      "code": "SERVERS = {\n    \"shop\": {\"args\": [\"marginalia_mcp.py\"], \"trust_hints\": True},    # ours: its readOnlyHint is believed\n    \"refunds\": {\"args\": [\"refund_mcp.py\"], \"trust_hints\": False},    # every call needs a person\n}\nmodel = anthropic.Anthropic()\n\n\ndef ask(question):\n    print(f\"  ? {question} [y/n] \", end=\"\", flush=True)\n    answer = sys.stdin.readline().strip()\n    print(answer)\n    return answer == \"y\"\n\n\n",
      "note": "**Dois servidores e quanto se confia em cada um.** O `shop` é o servidor da aula 14, nosso, então o `readOnlyHint` dele é acreditado; o `refunds` é o da aula 13, e toda chamada dele precisa de uma pessoa."
    },
    {
      "code": "async def server_asks(context, params):\n    \"\"\"A server's elicitation, mid-call (lesson 13's multi round-trip request), put to the person.\"\"\"\n    return ElicitResult(action=\"accept\", content={\"approve\": ask(f\"the server asks: {params.message}\")})\n\n\n",
      "note": "**A pergunta do próprio servidor**, o pedido de várias idas e voltas da aula 13, feita à pessoa. Seção 06."
    },
    {
      "code": "def audit(**entry):\n    with open(\"host-audit.jsonl\", \"a\") as f:\n        f.write(json.dumps(entry) + \"\\n\")\n\n\nasync def main(task):\n    async with AsyncExitStack() as stack:\n        clients, tools, needs_person = {}, [], {}\n        for name, conf in SERVERS.items():\n",
      "note": "**Uma linha por chamada**, escrita pelo hospedeiro. Seção 07."
    },
    {
      "code": "            params = StdioServerParameters(command=\"python\", args=conf[\"args\"], env=ENV)\n            clients[name] = await stack.enter_async_context(Client(params, elicitation_callback=server_asks))\n            for t in (await clients[name].list_tools()).tools:\n",
      "note": "**Um cliente por servidor**, cada um iniciado com o `ENV` e mais nada."
    },
    {
      "code": "                full = f\"{name}__{t.name}\"                       # the server's name keeps two get_orders apart\n                read_only = bool(t.annotations and t.annotations.read_only_hint)\n",
      "note": "**O nome do servidor entra no nome de toda ferramenta**, então as duas ferramentas `get_order` da aula 12 não colidiriam aqui."
    },
    {
      "code": "                needs_person[full] = not (read_only and conf[\"trust_hints\"])\n",
      "note": "**Decidido uma vez, no início**: uma pessoa é perguntada a menos que a ferramenta diga que é só leitura e o servidor dela seja um em cuja palavra o hospedeiro confia."
    },
    {
      "code": "                tools.append({\"name\": full, \"description\": f\"(server {name}) {t.description}\",\n                              \"input_schema\": t.input_schema})\n",
      "note": "**O modelo fica sabendo de que servidor veio cada ferramenta**, na descrição."
    },
    {
      "code": "        tools.append({\"name\": \"read_help\", \"description\": \"Read one help centre article by its help:// URI.\",\n                      \"input_schema\": {\"type\": \"object\", \"properties\": {\"uri\": {\"type\": \"string\"}},\n                                       \"required\": [\"uri\"]}})\n\n        messages = [{\"role\": \"user\", \"content\": task}]\n",
      "note": "**Uma ferramenta que o próprio hospedeiro oferece**, para ler artigos de ajuda. Seção 05."
    },
    {
      "code": "        for step in range(1, MAX_STEPS + 1):\n            reply = model.messages.create(model=\"llama3.2:3b\", max_tokens=1024, system=SYSTEM,\n                                          tools=tools, messages=messages)\n            messages.append({\"role\": \"assistant\", \"content\": reply.content})\n            calls = [b for b in reply.content if b.type == \"tool_use\"]\n            if not calls:\n                print(\"answer:\", reply.content[0].text)\n                return\n            results = []\n            for call in calls:\n                print(f\"step {step}: {call.name} {json.dumps(call.input)}\")\n                text, failed = await run(call, clients, needs_person)\n                print(f\"  {'error' if failed else 'result'}: {text[:110]}\".replace(\"\\n\", \" \"))\n                results.append({\"type\": \"tool_result\", \"tool_use_id\": call.id, \"content\": text, \"is_error\": failed})\n            messages.append({\"role\": \"user\", \"content\": results})\n        print(f\"stopped: {MAX_STEPS} steps without an answer\")\n\n\n",
      "note": "**O laço da aula 7**, com limite de passos."
    },
    {
      "code": "async def run(call, clients, needs_person):\n    \"\"\"Every tool call passes here: the host's rules, then the server, then the audit line.\"\"\"\n    if call.name == \"read_help\":                                 # the host reads a resource, not the model\n        allowed = call.input[\"uri\"].startswith(\"help://\")\n        audit(server=\"shop\", resource=call.input[\"uri\"], approved=allowed)\n        if not allowed:\n            return \"only help:// articles can be read\", True\n        result = await clients[\"shop\"].read_resource(call.input[\"uri\"])\n        return result.contents[0].text, False\n    server, _, tool = call.name.partition(\"__\")\n    approved = not needs_person[call.name] or ask(f\"run {call.name} {json.dumps(call.input)}?\")\n    if not approved:\n        audit(server=server, tool=tool, arguments=call.input, approved=False)\n        return \"Not approved by staff; nothing was done.\", True\n    result = await clients[server].call_tool(tool, call.input)\n    audit(server=server, tool=tool, arguments=call.input, approved=True, is_error=result.is_error)\n",
      "note": "**Toda chamada passa por aqui**: as regras do hospedeiro, depois o servidor, depois a auditoria."
    },
    {
      "code": "    if result.structured_content is not None:\n        return json.dumps(result.structured_content), result.is_error\n    return result.content[0].text, result.is_error\n\n\nasyncio.run(main(sys.argv[1]))",
      "note": "**Resultados estruturados vão ao modelo como JSON**; resultados em texto, como texto; `isError` como `is_error`."
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O caminho de uma chamada de ferramenta pelo mcp_host.py. Uma chamada read_help é conferida pelo hospedeiro: só URIs help:// são lidas, pelo servidor shop. Qualquer outra chamada é procurada em needs_person: se a ferramenta não é só leitura num servidor confiável, uma pessoa é perguntada antes. Depois o servidor a roda, e pode fazer a própria pergunta no meio da chamada. Toda chamada termina numa linha no host-audit.jsonl, recusada ou não.\"><defs><marker id=\"l15run-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15run-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l15run-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">chamada</text><text x=\"30\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do modelo</text><rect x=\"190\" y=\"20\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">read_help</text><text x=\"200\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só help://</text><rect x=\"190\" y=\"160\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">needs_person</text><text x=\"200\" y=\"193.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">perguntar a alguém?</text><rect x=\"410\" y=\"160\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o servidor</text><text x=\"420\" y=\"193.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pode perguntar também</text><rect x=\"580\" y=\"90\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">host-audit</text><text x=\"590\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">toda chamada</text><path d=\"M150 105 L190 45\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l15run-ah-amber)\"></path><path d=\"M150 125 L190 185\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l15run-ah-amber)\"></path><path d=\"M370 185 L410 185\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l15run-ah-phosphor)\"></path><path d=\"M370 45 L580 105\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l15run-ah-wire)\"></path><path d=\"M550 185 L580 125\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l15run-ah-wire)\"></path></svg>", "caption": "Toda regra é do hospedeiro, menos a pergunta que o próprio servidor faz."}
```
