---
title: Allowed is not the same as available
version: 2
---

Three options decide what a tool call may do, and their names are close enough to confuse:

| option | what it decides |
|---|---|
| `tools` | which of Claude Code's built-in tools **exist** in the session (section 04) |
| `allowed_tools` | which tool calls run **without asking anybody** |
| `disallowed_tools` | which tools are removed and refused, whatever else says |

`cs_refund.py` offers the shop's three tools and allows only `get_order`. Every configuration below leaves `refund` available and not allowed, so somebody has to decide each refund call. Who decides is the **permission mode**.

```schooling-example
{
  "language": "python",
  "file": "cs_refund.py",
  "parts": [
    {
      "code": "async def main(how, task):\n"
    },
    {
      "code": "    o = ClaudeAgentOptions(model=\"qwen2.5:3b\", system_prompt=SYSTEM, mcp_servers={\"shop\": shop_server},\n                           tools=[], setting_sources=[], allowed_tools=[\"mcp__shop__get_order\"])\n    if how == \"dont-ask\":\n",
      "note": "**The same base in every mode**: no built-in tools, no settings files, and only `get_order` allowed."
    },
    {
      "code": "        o.permission_mode = \"dontAsk\"\n    if how in (\"ask\", \"hooked\"):\n",
      "note": "**Refuse anything that is not allowed**, without asking."
    },
    {
      "code": "        o.permission_mode = \"default\"\n        o.can_use_tool = ask_a_person\n    if how == \"hooked\":\n        o.hooks = {\"PreToolUse\": [HookMatcher(matcher=\"mcp__shop__.*\", hooks=[audit_and_limit])]}",
      "note": "**Ask**: with `can_use_tool` set, the question goes to that function (section 07)."
    }
  ]
}
```

First with no `permission_mode` at all:

```
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ python cs_refund.py default "Please refund the whole order M-1047."
system     init tools=3
assistant  tool_use mcp__shop__refund {'cents': 1000000, 'order_id': 'M-1047', 'reason': 'Customer requested refund for whole order.'}
system     informational
system     permission_denied
user       tool_result (error) qwen2.5:3b is temporarily unavailable (timed out), so auto mode cannot determine the safet
assistant  It seems that the service is currently unavailable. I will wait for a moment and then try to process the refund request again. If the issue persists, I will proceed with other tasks that do not require this action. Please be informed that read-only operations such as reading files and searching code do not require the service and can still be performed.
result     success turns=2 188320 ms cost_usd=0.0061 session=c2660697
ana@lab:~/agents$ python -c 'import json; [print(r["status"], r["request"]["model"], r["request"]["system"][1]["text"].splitlines()[0]) for r in map(json.loads, open("requests.jsonl"))]' | sort | uniq -c
      2 200 qwen2.5:3b You are a Claude agent, built on Anthropic's Claude Agent SDK.
      1 404 claude-sonnet-5 You are a security monitor for autonomous AI coding agents.
```

The model asked to refund 1,000,000 cents on an order of 7,780, and the call was refused, by a mode nobody chose: this CLI version, given no mode, runs in **auto**, where a classifier judges each call that is not allowed. The second command shows what that meant on the wire. Besides the agent's two requests there was one more, with a system prompt beginning *"You are a security monitor for autonomous AI coding agents."*, sent to a model called `claude-sonnet-5`, which Ollama does not have (`404`). The refusal the model read says what came next: the CLI asked `qwen2.5:3b` for the verdict instead, and gave up waiting. That request is not in the recorder's log, because the CLI had stopped waiting before Ollama answered, but Ollama's own log has it: 30,421 tokens, cut to 4,098 like section 04's. The run took 188 seconds.

The refusal was safe, and for the wrong reason: nothing judged the refund, the judge was unavailable. What the default did on the way is the lesson. The classifier's request carried the customer's message and the refund's arguments, so **the conversation was sent to a model the code never named**, and against a provider that has `claude-sonnet-5` it would have been answered, billed and logged like any other request. A mode that decides what leaves the process is not something to inherit; set it.

With `dontAsk`:

```
ana@lab:~/agents$ rm -f requests.jsonl
ana@lab:~/agents$ python cs_refund.py dont-ask "Please refund the whole order M-1047."
system     init tools=3
assistant  tool_use mcp__shop__refund {'order_id': 'M-1047', 'reason': 'Full refund for order M-1047', 'cents': 1000000}
system     permission_denied
user       tool_result (error) Permission to use mcp__shop__refund has been denied because Claude Code is running in don'
assistant  I'm sorry, but according to the current settings, I don't have the permission to fully refund the order M-1047. To proceed, I would need to use another tool or approach that aligns with the permissions granted.

However, if you believe that it's essential to attempt this refund using different tools, I can help guide you on how to do so. Please let me know how you'd like to proceed.

Otherwise, I will need to look into other ways to assist you with this request, such as looking for articles in Marginalia's help center that might offer guidance on handling this situation.
Would you like to start by searching for help articles?
result     success turns=2 59345 ms cost_usd=0.0073 session=03a5bd02
ana@lab:~/agents$ python -c 'import json; [print(b["content"]) for r in map(json.loads, open("requests.jsonl")) for m in r["request"]["messages"] if isinstance(m["content"], list) for b in m["content"] if b.get("type") == "tool_result"]' | head -1
Permission to use mcp__shop__refund has been denied because Claude Code is running in don't ask mode. IMPORTANT: You *may* attempt to accomplish this action using other tools that might naturally be used to accomplish this goal, e.g. using head instead of cat. But you *should not* attempt to work around this denial in malicious ways, e.g. do not use your ability to run tests to execute non-test actions. You should only try to work around this restriction in reasonable ways that do not attempt to bypass the intent behind this denial. If you believe this capability is essential to complete the user's request, STOP and explain to the user what you were trying to do and why you need this permission. Let the user decide how to proceed.
```

Refused at once, and the model was told so. Read the message the CLI wrote for the model, printed in full by the second command: it tells the model it *may* reach the same goal "using other tools that might naturally be used", as long as it does not do so "in malicious ways". **That is a sentence asking the model to use its judgement**, and judgement is not a boundary. This model read it as an opening: it offered to guide the customer through attempting the refund "using different tools". In section 04's default run this agent had `Bash` and `Write`, and `data/shop.db` is a file ana's process can write. With `tools=[]` there is no other tool to reach for, and the refusal holds because of what the session contains, not because of what the model decides.
