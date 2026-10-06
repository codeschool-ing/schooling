---
title: The model behind one method
version: 1
---

The loop needs four things from a model call: the text, the tool calls, why it stopped and how many tokens it took. Everything else about the provider (the SDK, the request format, the response classes) is a detail the loop should not know. `minagent` puts it all behind one method.

```schooling-example
{
  "language": "python",
  "file": "minagent.py",
  "parts": [
    {
      "code": "# ---------------------------------------------------------------- the model, behind one method\n\n@dataclass\n"
    },
    {
      "code": "class Call:\n    id: str\n    name: str\n    args: dict\n\n\n@dataclass\n",
      "note": "**A tool call, provider-neutral**: an id, a name, the arguments."
    },
    {
      "code": "class Reply:\n    text: str\n    calls: list\n    stop: str\n    tokens_in: int\n    tokens_out: int\n",
      "note": "**Everything the loop reads from a reply.** Five fields, plus the reply in the form it goes back into the conversation."
    },
    {
      "code": "    content: list  # the reply as it goes back into the conversation\n\n\n",
      "note": "**The one piece of the wire that leaks through.** The conversation is kept in Anthropic's shape, so the adapter hands back the blocks to append as they are."
    },
    {
      "code": "class AnthropicModel:\n    \"\"\"The one place that knows a provider's wire. Anything with complete() can stand in for it.\"\"\"\n\n",
      "note": "**The only class that imports a provider's SDK.** An OpenAI or Gemini adapter would be another class with the same method."
    },
    {
      "code": "    def __init__(self, model=\"scripted-1\", max_tokens=1024, max_retries=2):\n        import anthropic\n        self.client = anthropic.Anthropic(max_retries=max_retries)\n        self.model, self.max_tokens = model, max_tokens\n\n",
      "note": "**`max_retries` is passed straight to the SDK**; section 07 is about what that means."
    },
    {
      "code": "    def complete(self, system, messages, tools):\n        r = self.client.messages.create(model=self.model, max_tokens=self.max_tokens, system=system,\n                                        tools=tools, messages=messages)\n        return Reply(text=\"\".join(b.text for b in r.content if b.type == \"text\"),\n                     calls=[Call(b.id, b.name, b.input) for b in r.content if b.type == \"tool_use\"],\n                     stop=r.stop_reason, tokens_in=r.usage.input_tokens, tokens_out=r.usage.output_tokens,\n                     content=[b.model_dump(exclude_none=True) for b in r.content])\n\n",
      "note": "**One request, translated into a `Reply`.** Text blocks are joined, `tool_use` blocks become `Call`s."
    }
  ]
}
```

## Why the seam is worth a class

**Tests.** Anything with a `complete` method that returns a `Reply` can stand in for the model. `test_minagent.py`'s `FakeModel` is eight lines that replay replies the test wrote, and the loop cannot tell the difference. Section 09 runs seven tests with it in a twentieth of a second.

**Providers.** Moving to another provider means writing another adapter: build that provider's request from `system`, `messages` and `tools`, and fill a `Reply` from its response. Lesson 4 section 07 listed what differs between the three wires: the shape of a tool definition, the arguments arriving as an object or as a string, the stop reason that does or does not say a tool was called. All of that lives in the adapter and nowhere else.

**Cost and routing.** A second adapter on a cheaper model, chosen per task, is how lesson 18 cuts cost without touching the loop.

The seam is not perfectly clean: the conversation format inside `Agent.run` is Anthropic's (`tool_use` and `tool_result` blocks), so an OpenAI adapter would translate the conversation on the way in as well as the reply on the way out. labllm does exactly that translation for its three wires, and it is about forty lines; a production adapter would keep its own neutral message type instead. `minagent` keeps Anthropic's to stay short, and says so here.
