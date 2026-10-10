---
title: Hooks run before every call
version: 2
---

A **hook** is a function the CLI calls at a fixed point of the loop: before a tool runs, after it, when a session starts, when the agent stops, and at others. A `PreToolUse` hook sees every tool call, including the allowed ones, and can deny it before any permission rule is consulted.

```schooling-example
{
  "language": "python",
  "file": "cs_refund.py",
  "parts": [
    {
      "code": "\"\"\"A refund under four permission arrangements.\"\"\"\nimport json\nimport sys\n\nimport anyio\nfrom claude_agent_sdk import ClaudeAgentOptions, HookMatcher, PermissionResultAllow, PermissionResultDeny, query\n\nfrom cs_show import show\nfrom cs_tools import shop_server\n\nSYSTEM = \"You handle refunds for Marginalia's customers in the Claude Agent SDK lesson.\"\n",
      "note": "**The whole of `cs_refund.py`**: the shop's tools from `cs_tools.py`, the printer from `cs_show.py`, and the system prompt."
    },
    {
      "code": "LIMIT = 5000  # cents; above this a refund is refused in code and no person is asked\n\n\nasync def ask_a_person(tool_name, tool_input, context):\n    print(f\"approve?   {tool_name} {tool_input} [y/n] \", end=\"\", flush=True)\n    answer = sys.stdin.readline().strip()\n    print(answer)\n    if answer == \"y\":\n        return PermissionResultAllow()\n    return PermissionResultDeny(message=\"Not approved by staff. A colleague will review this refund.\")\n\n\n",
      "note": "**A rule with a right answer**, kept in code: a refund above 50.00 is never this agent's decision."
    },
    {
      "code": "async def audit_and_limit(hook_input, tool_use_id, context):\n",
      "note": "**The hook receives the call**: tool name and arguments."
    },
    {
      "code": "    with open(\"audit.jsonl\", \"a\") as f:\n        f.write(json.dumps({\"tool\": hook_input[\"tool_name\"], \"input\": hook_input[\"tool_input\"]}) + \"\\n\")\n",
      "note": "**Every call is written down first**, allowed or not, before anything decides."
    },
    {
      "code": "    if hook_input[\"tool_name\"] == \"mcp__shop__refund\" and hook_input[\"tool_input\"][\"cents\"] > LIMIT:\n        return {\"hookSpecificOutput\": {\"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\",\n                                       \"permissionDecisionReason\": f\"Refunds above {LIMIT} cents need a manager.\"}}\n",
      "note": "**Over the limit, the call is denied here**, with a reason the model reads."
    },
    {
      "code": "    return {}\n\n\n",
      "note": "**An empty answer means no opinion**: the call continues to the permission rules."
    },
    {
      "code": "async def main(how, task):\n    o = ClaudeAgentOptions(model=\"qwen2.5:3b\", system_prompt=SYSTEM, mcp_servers={\"shop\": shop_server},\n                           tools=[], setting_sources=[], allowed_tools=[\"mcp__shop__get_order\"])\n    if how == \"dont-ask\":\n        o.permission_mode = \"dontAsk\"\n    if how in (\"ask\", \"hooked\"):\n        o.permission_mode = \"default\"\n        o.can_use_tool = ask_a_person\n    if how == \"hooked\":\n        o.hooks = {\"PreToolUse\": [HookMatcher(matcher=\"mcp__shop__.*\", hooks=[audit_and_limit])]}\n    async for message in query(prompt=task, options=o):\n        show(message)\n\n\nanyio.run(main, sys.argv[1], sys.argv[2])",
      "note": "**The four arrangements**, chosen by the first argument; section 06 read them."
    }
  ]
}
```

The hook is attached with a matcher, a pattern over tool names, so it runs for every tool of the shop server: `HookMatcher(matcher="mcp__shop__.*", hooks=[audit_and_limit])`. The model asked to refund the whole order:

```
ana@lab:~/agents$ echo n | python cs_refund.py hooked "Please refund the whole order M-1047."
/home/ana/agents/.venv/lib/python3.12/site-packages/claude_agent_sdk/types.py:1948: CanUseToolShadowedWarning: can_use_tool will not be invoked for: mcp__shop__get_order. An allowed_tools entry that allows a whole tool auto-approves it before the callback is consulted. To gate every tool call, use a PreToolUse hook; or narrow the entry so calls fall through to can_use_tool. Allow rules from settings files can also shadow the callback but are not visible here.
  _warn_if_can_use_tool_shadowed(options)
system     init tools=3
assistant  tool_use mcp__shop__refund {'cents': 10000000, 'order_id': 'M-1047', 'reason': 'Full refund for M-1047 order'}
user       tool_result (error) PreToolUse:mcp__shop__refund hook error: Refunds above 5000 cents need a manager.
assistant  The refund process for the order M-1047 has been flagged to a manager due to the amount being above 5000 cents, which is a threshold that requires managerial review. I will now look into the issue and get back to you once a decision has been made.
result     success turns=2 15185 ms cost_usd=0.0041 session=247d37c6
ana@lab:~/agents$ python cs_refund.py hooked "Where is my order M-1043?" | tail -1
/home/ana/agents/.venv/lib/python3.12/site-packages/claude_agent_sdk/types.py:1948: CanUseToolShadowedWarning: can_use_tool will not be invoked for: mcp__shop__get_order. An allowed_tools entry that allows a whole tool auto-approves it before the callback is consulted. To gate every tool call, use a PreToolUse hook; or narrow the entry so calls fall through to can_use_tool. Allow rules from settings files can also shadow the callback but are not visible here.
  _warn_if_can_use_tool_shadowed(options)
result     success turns=2 25957 ms cost_usd=0.0075 session=1ae8d95c
ana@lab:~/agents$ cat audit.jsonl
{"tool": "mcp__shop__refund", "input": {"cents": 10000000, "order_id": "M-1047", "reason": "Full refund for M-1047 order"}}
{"tool": "mcp__shop__get_order", "input": {"order_id": "M-1043"}}
```

The model asked for 10,000,000 cents, more than a thousand times the order's 7780, and the hook denied it. The second command asked about an order, a call `allowed_tools` approves without asking anybody, and the hook saw that one too: `audit.jsonl` has both lines. **No person was asked**: the `n` on standard input was never read, because the call never reached `can_use_tool`. The model read *"PreToolUse:mcp__shop__refund hook error: Refunds above 5000 cents need a manager."* and passed the case on. The audit line was written before the decision, so the refused call is on record with its arguments.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The path a tool call took in this lesson&#x27;s runs, left to right. First the PreToolUse hook runs and may deny the call. Then, if the tool is in allowed_tools, it runs with no further question. Otherwise the permission mode decides: dontAsk denies, auto asks a classifier, and default calls can_use_tool, where a person answers. Every denial reaches the model as an error tool result.\"><defs><marker id=\"l9gate-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l9gate-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PreToolUse</text><text x=\"30\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hook: may deny</text><rect x=\"190\" y=\"90\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">allowed_tools</text><text x=\"200\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">listed: runs</text><rect x=\"360\" y=\"20\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"370\" y=\"35.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dontAsk</text><text x=\"370\" y=\"51.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">denied</text><rect x=\"360\" y=\"92\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"370\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">auto</text><text x=\"370\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a classifier decides</text><rect x=\"360\" y=\"164\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"370\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">default</text><text x=\"370\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">asks can_use_tool</text><rect x=\"560\" y=\"164\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a person</text><text x=\"570\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">y or n</text><path d=\"M150 115 L190 115\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l9gate-ah-amber)\"></path><path d=\"M320 106 L360 43\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l9gate-ah-wire)\"></path><path d=\"M320 115 L360 115\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l9gate-ah-wire)\"></path><path d=\"M320 124 L360 187\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l9gate-ah-amber)\"></path><path d=\"M510 187 L560 187\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l9gate-ah-amber)\"></path></svg>", "caption": "Each layer can say no. Only allowed_tools says yes without asking."}
```

That ordering is what makes hooks the right place for two kinds of rule. **Rules with a right answer**, such as a limit, belong where no model and no tired person can be talked out of them. **Records** belong at the first point every call passes, so that the log has the calls that were refused as well as the ones that ran. This repository applies the same idea to its own staff: every administrative write records the actor (`internal/audit`), and lesson 17 uses it as the worked example.
