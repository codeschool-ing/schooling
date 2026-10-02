---
title: The loop in code
version: 1
---

The host is short. It connects to the shop's MCP server (lesson 7 section 06), turns the tools the
server lists into the tool definitions the model's API expects, and runs the loop with a limit on the
number of steps. Every decision the model makes in this lesson was written by the course, as rules in
`scripted-1`; the host, the server and every tool result are real.

```schooling-example
{
  "language": "python",
  "file": "agent.py",
  "parts": [
    {
      "code": "\"\"\"A host: it starts the shop's MCP server, offers its tools to the model, and runs the loop.\"\"\"\nimport asyncio\nimport json\nimport sys\n\nimport anthropic\nfrom mcp import Client, StdioServerParameters\n\n"
    },
    {
      "code": "MAX_STEPS = 5\nmodel = anthropic.Anthropic()\n\n\n",
      "note": "**The guards are constants in the host**, where the model cannot change them."
    },
    {
      "code": "def approve(name, args):\n    answer = input(f\"allow {name}({json.dumps(args)})? [y/N] \")\n    print(answer)\n    return answer.strip().lower() == \"y\"\n\n\n",
      "note": "**A person approves a call that changes something**, seeing the exact arguments."
    },
    {
      "code": "async def run(question):\n    async with Client(StdioServerParameters(command=\"python\", args=[\"mcp_shop.py\"])) as shop:\n        listed = (await shop.list_tools()).tools\n        tools = [{\"name\": t.name, \"description\": t.description, \"input_schema\": t.input_schema} for t in listed]\n        read_only = {t.name for t in listed if t.annotations and t.annotations.read_only_hint}\n        messages = [{\"role\": \"user\", \"content\": question}]\n        seen = set()\n",
      "note": "**The server's tools become the model's tools.** Their names, descriptions and schemas come from `tools/list`, and the host remembers which ones say they only read."
    },
    {
      "code": "        for step in range(1, MAX_STEPS + 1):\n            r = model.messages.create(model=\"scripted-1\", max_tokens=500, tools=tools, messages=messages)\n            messages.append({\"role\": \"assistant\", \"content\": [b.model_dump(exclude_none=True) for b in r.content]})\n            for b in r.content:\n                if b.type == \"text\":\n                    print(f\"[{step}] model:  {b.text}\")\n            if r.stop_reason != \"tool_use\":\n                return\n",
      "note": "**One step is one request**: the model sees everything so far and either answers or asks for tools. No `tool_use` means it answered, and the loop ends."
    },
    {
      "code": "            results = []\n            for b in r.content:\n                if b.type != \"tool_use\":\n                    continue\n                print(f\"[{step}] call:   {b.name}({json.dumps(b.input)})\")\n                call = (b.name, json.dumps(b.input, sort_keys=True))\n                if call in seen:\n                    print(f\"[{step}] host:   the same call twice in one task; stopping\")\n                    return\n                seen.add(call)\n                if b.name not in read_only and not approve(b.name, b.input):\n                    text, error = \"refused by the operator\", True\n                else:\n                    result = await shop.call_tool(b.name, b.input)\n                    text, error = result.content[0].text, result.is_error\n                print(f\"[{step}] result: {' '.join(text.split())[:72]}\")\n                results.append({\"type\": \"tool_result\", \"tool_use_id\": b.id, \"content\": text, \"is_error\": error})\n            messages.append({\"role\": \"user\", \"content\": results})\n",
      "note": "**Each call goes through the guards**: refused if repeated, held for approval if it changes something, otherwise made through MCP. The result, error or not, goes back to the model."
    },
    {
      "code": "        print(f\"host: stopped after {MAX_STEPS} steps without an answer\")\n\n\n",
      "note": "**Running out of steps is reported**, not hidden behind a made-up answer."
    },
    {
      "code": "asyncio.run(run(sys.argv[1]))"
    }
  ]
}
```

## A question that needs two tools

```
ana@dev:~/shop$ python agent.py "Can the customer of order 1042 still return it?"
[1] model:  I will look up the order first.
[1] call:   get_order({"order_id": "1042"})
[1] result: { "status": "delivered", "delivered_on": "2026-09-28", "lines": [ { "sku
[2] call:   read_handbook({"name": "returns"})
[2] result: # Returns and refunds A customer may return any item within 30 days of d
[3] model:  Yes. Order 1042 was delivered on 28 September 2026, and the handbook allows a return within 30 days of delivery, so the customer has until 28 October 2026. The two mugs must be unused and in their original packaging.
```

Three steps. **Step 1**: the model announces a plan and asks for the order. **Step 2**: with the
delivery date in the conversation, it asks for the returns page. **Step 3**: with both, it answers,
and `stop_reason` is no longer `tool_use`, so the loop ends.

Read the answer against the tool results. The delivery date, 28 September, came from `get_order`;
the 30 days came from `read_handbook`; the conclusion, 28 October, is arithmetic on the two. **Every
fact in the answer has a tool result behind it**, which is what makes an agent's answer checkable in
the same way lesson 6 section 08 checked citations.

## What the code does that the model cannot

- **It stops.** `MAX_STEPS` is a hard limit, enforced by a `for` loop rather than requested in a
  prompt.
- **It refuses repeats.** The same call twice in one task is almost always a loop the model will not
  leave on its own; lesson 7 section 09 shows one.
- **It asks before acting.** A tool not marked read-only is not called until a person says yes;
  lesson 7 section 08 shows both answers.
- **It reports errors as results.** A tool that fails returns `is_error` to the model, which can try
  something else, instead of crashing the host.
