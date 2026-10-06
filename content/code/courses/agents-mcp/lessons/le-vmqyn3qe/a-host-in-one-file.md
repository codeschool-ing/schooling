---
title: A host in one file
version: 1
---

A library's MCP support makes the host's decisions for you, and lesson 12 showed three libraries making them three ways. `mcp_host.py` makes them itself, in code: lesson 7's loop, now with MCP servers instead of local functions, and the `mcp` SDK's `Client` for each connection. It talks to the model through the Anthropic Messages API, which labllm answers.

```schooling-example
{
  "language": "python",
  "file": "mcp_host.py",
  "parts": [
    {
      "code": "\"\"\"A host: one model, two MCP servers, and every decision about them written down.\"\"\"\nimport asyncio\nimport json\nimport sys\nfrom contextlib import AsyncExitStack\n\nimport anthropic\nfrom mcp import Client, StdioServerParameters\nfrom mcp.types import ElicitResult\n\nSYSTEM = \"You are the support agent of the MCP client lesson. Use the tools; never guess.\"\nMAX_STEPS = 6\n"
    },
    {
      "code": "ENV = {\"PATH\": \"/opt/agents/bin:/usr/bin:/bin\", \"HOME\": \"/home/ana\",   # all a server process inherits:\n       \"MINILM_DIR\": \"/opt/agents/share/all-MiniLM-L6-v2\"}             # search_help's embedding model\n",
      "note": "**What a server process inherits, as a list.** Nothing from ana's shell reaches a server unless it is named here. Section 04."
    },
    {
      "code": "SERVERS = {\n    \"shop\": {\"args\": [\"marginalia_mcp.py\"], \"trust_hints\": True},    # ours: its readOnlyHint is believed\n    \"refunds\": {\"args\": [\"refund_mcp.py\"], \"trust_hints\": False},    # every call needs a person\n}\nmodel = anthropic.Anthropic()\n\n\ndef ask(question):\n    print(f\"  ? {question} [y/n] \", end=\"\", flush=True)\n    answer = sys.stdin.readline().strip()\n    print(answer)\n    return answer == \"y\"\n\n\n",
      "note": "**Two servers and how much each is trusted.** `shop` is lesson 14's server, ours, so its `readOnlyHint` is believed; `refunds` is lesson 13's, and every one of its calls needs a person."
    },
    {
      "code": "async def server_asks(context, params):\n    \"\"\"A server's elicitation, mid-call (lesson 13's multi round-trip request), put to the person.\"\"\"\n    return ElicitResult(action=\"accept\", content={\"approve\": ask(f\"the server asks: {params.message}\")})\n\n\n",
      "note": "**The server's own question**, lesson 13's multi round-trip request, put to the person. Section 06."
    },
    {
      "code": "def audit(**entry):\n    with open(\"host-audit.jsonl\", \"a\") as f:\n        f.write(json.dumps(entry) + \"\\n\")\n\n\nasync def main(task):\n    async with AsyncExitStack() as stack:\n        clients, tools, needs_person = {}, [], {}\n        for name, conf in SERVERS.items():\n",
      "note": "**One line per call**, written by the host. Section 07."
    },
    {
      "code": "            params = StdioServerParameters(command=\"python\", args=conf[\"args\"], env=ENV)\n            clients[name] = await stack.enter_async_context(Client(params, elicitation_callback=server_asks))\n            for t in (await clients[name].list_tools()).tools:\n",
      "note": "**One client per server**, each started with `ENV` and nothing else."
    },
    {
      "code": "                full = f\"{name}__{t.name}\"                       # the server's name keeps two get_orders apart\n                read_only = bool(t.annotations and t.annotations.read_only_hint)\n",
      "note": "**The server's name goes into every tool's name**, so lesson 12's two `get_order` tools could not collide here."
    },
    {
      "code": "                needs_person[full] = not (read_only and conf[\"trust_hints\"])\n",
      "note": "**Decided once, at start**: a person is asked unless the tool says it is read-only and its server is one whose word the host takes."
    },
    {
      "code": "                tools.append({\"name\": full, \"description\": f\"(server {name}) {t.description}\",\n                              \"input_schema\": t.input_schema})\n",
      "note": "**The model is told which server each tool came from**, in the description."
    },
    {
      "code": "        tools.append({\"name\": \"read_help\", \"description\": \"Read one help centre article by its help:// URI.\",\n                      \"input_schema\": {\"type\": \"object\", \"properties\": {\"uri\": {\"type\": \"string\"}},\n                                       \"required\": [\"uri\"]}})\n\n        messages = [{\"role\": \"user\", \"content\": task}]\n",
      "note": "**A tool the host provides itself**, to read help articles. Section 05."
    },
    {
      "code": "        for step in range(1, MAX_STEPS + 1):\n            reply = model.messages.create(model=\"scripted-1\", max_tokens=1024, system=SYSTEM,\n                                          tools=tools, messages=messages)\n            messages.append({\"role\": \"assistant\", \"content\": reply.content})\n            calls = [b for b in reply.content if b.type == \"tool_use\"]\n            if not calls:\n                print(\"answer:\", reply.content[0].text)\n                return\n            results = []\n            for call in calls:\n                print(f\"step {step}: {call.name} {json.dumps(call.input)}\")\n                text, failed = await run(call, clients, needs_person)\n                print(f\"  {'error' if failed else 'result'}: {text[:110]}\".replace(\"\\n\", \" \"))\n                results.append({\"type\": \"tool_result\", \"tool_use_id\": call.id, \"content\": text, \"is_error\": failed})\n            messages.append({\"role\": \"user\", \"content\": results})\n        print(f\"stopped: {MAX_STEPS} steps without an answer\")\n\n\n",
      "note": "**Lesson 7's loop**, with a step limit."
    },
    {
      "code": "async def run(call, clients, needs_person):\n    \"\"\"Every tool call passes here: the host's rules, then the server, then the audit line.\"\"\"\n    if call.name == \"read_help\":                                 # the host reads a resource, not the model\n        allowed = call.input[\"uri\"].startswith(\"help://\")\n        audit(server=\"shop\", resource=call.input[\"uri\"], approved=allowed)\n        if not allowed:\n            return \"only help:// articles can be read\", True\n        result = await clients[\"shop\"].read_resource(call.input[\"uri\"])\n        return result.contents[0].text, False\n    server, _, tool = call.name.partition(\"__\")\n    approved = not needs_person[call.name] or ask(f\"run {call.name} {json.dumps(call.input)}?\")\n    if not approved:\n        audit(server=server, tool=tool, arguments=call.input, approved=False)\n        return \"Not approved by staff; nothing was done.\", True\n    result = await clients[server].call_tool(tool, call.input)\n    audit(server=server, tool=tool, arguments=call.input, approved=True, is_error=result.is_error)\n",
      "note": "**Every call passes through here**: the host's rules, then the server, then the audit."
    },
    {
      "code": "    if result.structured_content is not None:\n        return json.dumps(result.structured_content), result.is_error\n    return result.content[0].text, result.is_error\n\n\nasyncio.run(main(sys.argv[1]))",
      "note": "**Structured results go to the model as JSON**; text results as text; `isError` as `is_error`."
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The path of one tool call through mcp_host.py. A read_help call is checked by the host: only help:// URIs are read, through the shop server. Any other call is looked up in needs_person: if the tool is not read-only on a trusted server, a person is asked first. Then the server runs it, and may ask its own question mid-call. Every call ends in a line in host-audit.jsonl, refused or not.\"><defs><marker id=\"l15run-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15run-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l15run-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tool call</text><text x=\"30\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">from the model</text><rect x=\"190\" y=\"20\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">read_help</text><text x=\"200\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">help:// only</text><rect x=\"190\" y=\"160\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">needs_person</text><text x=\"200\" y=\"193.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ask a person?</text><rect x=\"410\" y=\"160\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the server</text><text x=\"420\" y=\"193.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">may ask too</text><rect x=\"580\" y=\"90\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">host-audit</text><text x=\"590\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">every call</text><path d=\"M150 105 L190 45\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l15run-ah-amber)\"></path><path d=\"M150 125 L190 185\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l15run-ah-amber)\"></path><path d=\"M370 185 L410 185\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l15run-ah-phosphor)\"></path><path d=\"M370 45 L580 105\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l15run-ah-wire)\"></path><path d=\"M550 185 L580 125\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l15run-ah-wire)\"></path></svg>", "caption": "Every rule is the host's, except the question the server asks itself."}
```
