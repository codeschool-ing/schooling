---
title: The loop in code
version: 2
---

The host is short. It connects to the shop's MCP server (lesson 7 section 06), turns the tools the
server lists into the tool definitions the model's API expects, and runs the loop with a limit on the
number of steps. Every decision in this lesson, which tool to call and what to answer, is
`llama3.2:3b`'s.

```schooling-example
{
  "language": "python",
  "file": "agent.py",
  "parts": [
    {
      "code": "\"\"\"A host: it starts the shop's MCP server, offers its tools to the model, and runs the loop.\"\"\"\nimport asyncio\nimport json\nimport sys\nfrom datetime import date\n\nimport anthropic\nfrom mcp import Client, StdioServerParameters\n\n"
    },
    {
      "code": "MAX_STEPS = 5\nRULES = (f\"Today is {date.today():%d %B %Y}. Answer questions about the shop with its tools. \"\n         \"Every fact in your answer must come from a tool result; if the tools cannot give \"\n         \"the answer, say that you could not find it.\")\nREMIND = \"Call another tool if you need one; otherwise answer.\"\nmodel = anthropic.Anthropic()\nsent = []  # input tokens of each request, reused prefix included (lesson 2 section 07)\n\n\n",
      "note": "**The guards are constants in the host**, where the model cannot change them. Two more things the host can add, each only when asked: `--rules` puts `RULES` in a system prompt, today's date, which no tool gives, and the rule that every fact needs a tool result behind it; `--remind` puts `REMIND` after every batch of results. Lesson 7 section 09 runs both."
    },
    {
      "code": "def approve(name, args):\n    try:\n        answer = input(f\"allow {name}({json.dumps(args)})? [y/N] \")\n    except EOFError:  # nobody at the keyboard is a no\n        answer = \"\"\n    print(answer)\n    return answer.strip().lower() == \"y\"\n\n\n",
      "note": "**A person approves a call that changes something**, seeing the exact arguments. Nobody at the keyboard counts as a no."
    },
    {
      "code": "async def run(question, rules, remind):\n    async with Client(StdioServerParameters(command=\"python\", args=[\"mcp_shop.py\"])) as shop:\n        listed = (await shop.list_tools()).tools\n        tools = [{\"name\": t.name, \"description\": t.description, \"input_schema\": t.input_schema} for t in listed]\n        read_only = {t.name for t in listed if t.annotations and t.annotations.read_only_hint}\n        messages = [{\"role\": \"user\", \"content\": question}]\n        extra = {\"system\": RULES} if rules else {}\n        seen = set()\n",
      "note": "**The server's tools become the model's tools.** Their names, descriptions and schemas come from `tools/list`, and the host remembers which ones say they only read."
    },
    {
      "code": "        for step in range(1, MAX_STEPS + 1):\n            r = model.messages.create(model=\"llama3.2:3b\", max_tokens=500, tools=tools, messages=messages,\n                                      extra_body={\"temperature\": 0}, **extra)\n            sent.append(r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0))\n            messages.append({\"role\": \"assistant\", \"content\": [b.model_dump(exclude_none=True) for b in r.content]})\n            for b in r.content:\n                if b.type == \"text\":\n                    print(f\"[{step}] model:  {b.text}\")\n            if r.stop_reason != \"tool_use\":\n                return\n",
      "note": "**One step is one request**: the model sees everything so far and either answers or asks for tools. No `tool_use` means it answered, and the loop ends. Temperature 0, as in lesson 6, so a rerun mostly takes the same path, and every request's input tokens are kept for the last line."
    },
    {
      "code": "            results = []\n            for b in r.content:\n                if b.type != \"tool_use\":\n                    continue\n                print(f\"[{step}] call:   {b.name}({json.dumps(b.input)})\")\n                call = (b.name, json.dumps(b.input, sort_keys=True))\n                if call in seen:\n                    print(f\"[{step}] host:   the same call twice in one task; stopping\")\n                    return\n                seen.add(call)\n                if b.name not in read_only and not approve(b.name, b.input):\n                    text, error = \"refused by the operator\", True\n                else:\n                    result = await shop.call_tool(b.name, b.input)\n                    text, error = result.content[0].text, result.is_error\n                print(f\"[{step}] result: {' '.join(text.split())[:72]}\")\n                results.append({\"type\": \"tool_result\", \"tool_use_id\": b.id, \"content\": text, \"is_error\": error})\n            if remind:\n                results.append({\"type\": \"text\", \"text\": REMIND})\n            messages.append({\"role\": \"user\", \"content\": results})\n",
      "note": "**Each call goes through the guards**: refused if repeated, held for approval if it changes something, otherwise made through MCP. The result, error or not, goes back to the model as a `tool_result`, all of a step's results in one message."
    },
    {
      "code": "        print(f\"host: stopped after {MAX_STEPS} steps without an answer\")\n\n\n",
      "note": "**Running out of steps is reported**, not hidden behind a made-up answer."
    },
    {
      "code": "question = [a for a in sys.argv[1:] if not a.startswith(\"--\")][0]\nasyncio.run(run(question, \"--rules\" in sys.argv, \"--remind\" in sys.argv))\nprint(f\"host: {len(sent)} requests, {sum(sent)} input tokens: {sent}\")\n",
      "note": "**What the task cost**, in requests and input tokens, printed however it ended."
    }
  ]
}
```

## A question that needs two tools

Whether a customer can still return order 1042 takes two facts: when the order was delivered, which
`get_order` knows, and how long the return window is, which the returns page says.

```
ana@dev:~/shop$ python agent.py "Can the customer of order 1042 still return it?"
[1] call:   get_order({"order_id": "1042"})
[1] result: { "status": "delivered", "delivered_on": "2026-09-28", "lines": [ { "sku
[2] model:  Unfortunately, the customer of order 1042 is no longer able to return the order. According to the order status, the order was delivered on September 28, 2026, which means that the return window has expired. If you have any further questions or concerns, please let me know.
host: 2 requests, 455 input tokens: [289, 166]
```

Two steps. **Step 1**: the model asks for the order. **Step 2**: with the delivery date in the
conversation, it answers, and `stop_reason` is no longer `tool_use`, so the loop ends.

Read the answer against the tool results. The delivery date, 28 September, came from `get_order`.
That the window "has expired" came from nowhere: the model never read the returns page, so it does
not know the window is 30 days, and nothing told it what day it is today, so it could not have
counted to 30 anyway. The recording was made on 7 October, nine days after delivery; the answer is
wrong. **Every fact in an agent's answer should have a tool result behind it**, which is what makes
the answer checkable in the same way lesson 6 section 08 checked citations, and this one has one of
three.

There is a reason it did not go on to the returns page, and it is not in the model. Look at the
last line: the second request carried 166 input tokens, fewer than the first, although it holds
everything the first did plus the order. Something left. Ollama turns the conversation into one
long prompt with a **template** that belongs to the model, and `llama3.2:3b`'s puts the tool
definitions in one place only:

```
ana@dev:~/shop$ ollama show llama3.2:3b --template | sed -n 13,25p
{{- if eq .Role "user" }}<|start_header_id|>user<|end_header_id|>
{{- if and $.Tools $last }}

Given the following functions, please respond with a JSON for a function call with its proper arguments that best answers the given prompt.

Respond in the format {"name": function name, "parameters": dictionary of argument name and its value}. Do not use variables.

{{ range $.Tools }}
{{- . }}
{{ end }}
{{ .Content }}<|eot_id|>
{{- else }}
```

`if and $.Tools $last`: **the tools are listed only inside the last message, and only when that
message is the user's.** After a tool result the last message is the result, so on step 2 the model
was not shown any tool at all. It could only answer. Every request this host makes has the same
shape, so with this model on this server an agent gets one round of tools, and whatever it asks for
in that round is all it will ever have. Lesson 7 section 09 shows what happens when the host puts
the tools back in front of it.

So ana names both steps in the question, and the model asks for everything at once:

```
ana@dev:~/shop$ python agent.py "Look up order 1042 and the returns page of the handbook, then tell me whether the customer can still return it."
[1] call:   get_order({"order_id": "1042"})
[1] result: { "status": "delivered", "delivered_on": "2026-09-28", "lines": [ { "sku
[1] call:   read_handbook({"name": "returns"})
[1] result: # Returns and refunds A customer may return any item within 30 days of d
[1] call:   issue_refund({"order_id": "1042", "cents": "0"})
allow issue_refund({"order_id": "1042", "cents": "0"})? [y/N] 
[1] result: refused by the operator
[2] model:  It seems like the tool call was refused by the operator. The output indicates that the customer is no longer eligible for a return, as it has been 30 days since delivery. However, if the item is faulty, it may still be covered by the warranty.
host: 2 requests, 696 input tokens: [302, 394]
```

**Three calls in one step**, which the API allows and the loop handles: every `tool_use` block in the
reply is run, and all the results go back together. It is also the only way this model can use two
tools, given its one round. Two are the ones she asked for. The third is
`issue_refund`, for an amount of `"0"`, which nobody asked for. It is not read-only, so the host held
it for approval; nobody was at the keyboard, and the host read that as a no. The answer that follows
is wrong again, for the reason the first one was: it now has the 30 days and still has no today, and
says that 30 days have passed.

Two lessons from two runs. **The host is what stood between a question and a refund**, which is the
subject of lesson 7 section 08. And a fact the model needs and no tool gives, like the date, has to
come from the host; lesson 7 section 09 adds it.

## What the code does that the model cannot

- **It stops.** `MAX_STEPS` is a hard limit, enforced by a `for` loop rather than requested in a
  prompt.
- **It refuses repeats.** The same call twice in one task is almost always a loop the model will not
  leave on its own; lesson 7 section 09 says why it stays in even though this model never looped.
- **It asks before acting.** A tool not marked read-only is not called until a person says yes, and
  above it was not called; lesson 7 section 08 shows both answers.
- **It reports errors as results.** A tool that fails returns `is_error` to the model, which can try
  something else, instead of crashing the host.
