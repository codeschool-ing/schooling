---
title: Allowed is not the same as available
version: 1
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
      "code": "    o = ClaudeAgentOptions(model=\"scripted-1\", system_prompt=SYSTEM, mcp_servers={\"shop\": shop_server},\n                           tools=[], setting_sources=[], allowed_tools=[\"mcp__shop__get_order\"])\n    if how == \"dont-ask\":\n",
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
ana@lab:~/agents$ python cs_refund.py default "One copy of M-1047 arrived damaged; please refund it."
system     init tools=3
assistant  tool_use mcp__shop__refund {'order_id': 'M-1047', 'cents': 3890, 'reason': 'one copy arrived damaged'}
system     informational
system     permission_denied
user       tool_result (error) Auto mode could not evaluate this action and is blocking it for safety — run with --debug 
assistant  I could not issue this refund myself; a colleague will review order M-1047 and reply to you by email.
result     success turns=2 9723 ms cost_usd=0.0048 session=23322038
ana@lab:~/agents$ python -c 'import json; [print(r["status"], r["request"]["model"], r["request"]["system"][1]["text"].splitlines()[0]) for r in map(json.loads, open("/var/log/labllm/requests.jsonl"))]' | sort | uniq -c
      2 200 scripted-1 You are a Claude agent, built on Anthropic's Claude Agent SDK.
     10 200 scripted-1 You are a security monitor for autonomous AI coding agents.
      1 404 claude-sonnet-5 You are a security monitor for autonomous AI coding agents.
```

The refusal names the mode: **auto**. This CLI version, given no mode, has each call judged by a classifier, and the second command shows what that meant on the wire. Besides the agent's two requests there were **eleven more**, each with a system prompt beginning *"You are a security monitor for autonomous AI coding agents."* The first went to a model called `claude-sonnet-5`, which labllm does not have (`404`); the other ten went to `scripted-1`, which had no rule for them, so no verdict came back, and after about eight seconds of trying (9,723 ms for the run, against under two for the others) the CLI refused the call.

The refusal was safe. What the default did on the way is the lesson. Each classifier request carried the customer's message and the refund's arguments, so **the conversation was sent to a model the code never named**, eleven times, for one tool call. With a real provider those requests are billed and logged like any other. A mode that decides what leaves the process is not something to inherit; set it.

With `dontAsk`:

```
ana@lab:~/agents$ python cs_refund.py dont-ask "One copy of M-1047 arrived damaged; please refund it."
system     init tools=3
assistant  tool_use mcp__shop__refund {'order_id': 'M-1047', 'cents': 3890, 'reason': 'one copy arrived damaged'}
system     permission_denied
user       tool_result (error) Permission to use mcp__shop__refund has been denied because Claude Code is running in don'
assistant  I could not issue this refund myself; a colleague will review order M-1047 and reply to you by email.
result     success turns=2 1755 ms cost_usd=0.0050 session=25efd6c3
ana@lab:~/agents$ python -c 'import json; [print(b["content"]) for r in map(json.loads, open("/var/log/labllm/requests.jsonl")) for m in r["request"]["messages"] if isinstance(m["content"], list) for b in m["content"] if b.get("type") == "tool_result"]' | head -1
Permission to use mcp__shop__refund has been denied because Claude Code is running in don't ask mode. IMPORTANT: You *may* attempt to accomplish this action using other tools that might naturally be used to accomplish this goal, e.g. using head instead of cat. But you *should not* attempt to work around this denial in malicious ways, e.g. do not use your ability to run tests to execute non-test actions. You should only try to work around this restriction in reasonable ways that do not attempt to bypass the intent behind this denial. If you believe this capability is essential to complete the user's request, STOP and explain to the user what you were trying to do and why you need this permission. Let the user decide how to proceed.
```

Refused at once, and the model was told so. Read the message the CLI wrote for the model, printed in full by the second command: it tells the model it *may* reach the same goal "using other tools that might naturally be used", as long as it does not do so "in malicious ways". **That is a sentence asking the model to use its judgement**, and judgement is not a boundary. In section 04's default run this agent had `Bash` and `Write`, and `data/shop.db` is a file ana's process can write. With `tools=[]` there is no other tool to reach for, and the refusal holds because of what the session contains, not because of what the model decides.
