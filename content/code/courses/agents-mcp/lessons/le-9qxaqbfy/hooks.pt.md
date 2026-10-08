---
title: Hooks rodam antes de toda chamada
version: 2
---

Um **hook** é uma função que o CLI chama num ponto fixo do laço: antes de uma ferramenta rodar, depois, quando uma sessão começa, quando o agente para, e em outros. Um hook `PreToolUse` vê toda chamada de ferramenta, inclusive as permitidas, e pode negá-la antes de qualquer regra de permissão ser consultada.

```schooling-example
{
  "language": "python",
  "file": "cs_refund.py",
  "parts": [
    {
      "code": "\"\"\"A refund under four permission arrangements.\"\"\"\nimport json\nimport sys\n\nimport anyio\nfrom claude_agent_sdk import ClaudeAgentOptions, HookMatcher, PermissionResultAllow, PermissionResultDeny, query\n\nfrom cs_show import show\nfrom cs_tools import shop_server\n\nSYSTEM = \"You handle refunds for Marginalia's customers in the Claude Agent SDK lesson.\"\n",
      "note": "**O `cs_refund.py` inteiro**: as ferramentas da loja vindas do `cs_tools.py`, a impressão do `cs_show.py` e o prompt de sistema."
    },
    {
      "code": "LIMIT = 5000  # cents; above this a refund is refused in code and no person is asked\n\n\nasync def ask_a_person(tool_name, tool_input, context):\n    print(f\"approve?   {tool_name} {tool_input} [y/n] \", end=\"\", flush=True)\n    answer = sys.stdin.readline().strip()\n    print(answer)\n    if answer == \"y\":\n        return PermissionResultAllow()\n    return PermissionResultDeny(message=\"Not approved by staff. A colleague will review this refund.\")\n\n\n",
      "note": "**Uma regra com resposta certa**, guardada no código: um reembolso acima de 50,00 nunca é decisão deste agente."
    },
    {
      "code": "async def audit_and_limit(hook_input, tool_use_id, context):\n",
      "note": "**O hook recebe a chamada**: nome da ferramenta e argumentos."
    },
    {
      "code": "    with open(\"audit.jsonl\", \"a\") as f:\n        f.write(json.dumps({\"tool\": hook_input[\"tool_name\"], \"input\": hook_input[\"tool_input\"]}) + \"\\n\")\n",
      "note": "**Toda chamada é anotada primeiro**, permitida ou não, antes de qualquer decisão."
    },
    {
      "code": "    if hook_input[\"tool_name\"] == \"mcp__shop__refund\" and hook_input[\"tool_input\"][\"cents\"] > LIMIT:\n        return {\"hookSpecificOutput\": {\"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\",\n                                       \"permissionDecisionReason\": f\"Refunds above {LIMIT} cents need a manager.\"}}\n",
      "note": "**Acima do limite, a chamada é negada aqui**, com um motivo que o modelo lê."
    },
    {
      "code": "    return {}\n\n\n",
      "note": "**Uma resposta vazia quer dizer sem opinião**: a chamada segue para as regras de permissão."
    },
    {
      "code": "async def main(how, task):\n    o = ClaudeAgentOptions(model=\"qwen2.5:3b\", system_prompt=SYSTEM, mcp_servers={\"shop\": shop_server},\n                           tools=[], setting_sources=[], allowed_tools=[\"mcp__shop__get_order\"])\n    if how == \"dont-ask\":\n        o.permission_mode = \"dontAsk\"\n    if how in (\"ask\", \"hooked\"):\n        o.permission_mode = \"default\"\n        o.can_use_tool = ask_a_person\n    if how == \"hooked\":\n        o.hooks = {\"PreToolUse\": [HookMatcher(matcher=\"mcp__shop__.*\", hooks=[audit_and_limit])]}\n    async for message in query(prompt=task, options=o):\n        show(message)\n\n\nanyio.run(main, sys.argv[1], sys.argv[2])",
      "note": "**Os quatro arranjos**, escolhidos pelo primeiro argumento; a seção 06 os leu."
    }
  ]
}
```

O hook é preso com um matcher, um padrão sobre nomes de ferramenta, então ele roda para toda ferramenta do servidor da loja: `HookMatcher(matcher="mcp__shop__.*", hooks=[audit_and_limit])`. O modelo pediu para reembolsar o pedido inteiro:

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

O modelo pediu 10.000.000 de centavos, mais de mil vezes os 7780 do pedido, e o hook negou. O segundo comando perguntou por um pedido, uma chamada que o `allowed_tools` aprova sem perguntar a ninguém, e o hook viu essa também: o `audit.jsonl` tem as duas linhas. **Ninguém foi perguntado**: o `n` na entrada padrão nunca foi lido, porque a chamada nunca chegou ao `can_use_tool`. O modelo leu *"PreToolUse:mcp__shop__refund hook error: Refunds above 5000 cents need a manager."* e encaminhou o caso. A linha de auditoria foi escrita antes da decisão, então a chamada recusada está registrada com os argumentos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O caminho que uma chamada de ferramenta fez nas execuções desta aula, da esquerda para a direita. Primeiro roda o hook PreToolUse, que pode negar a chamada. Depois, se a ferramenta está em allowed_tools, ela roda sem mais perguntas. Se não, o modo de permissão decide: dontAsk nega, auto pergunta a um classificador, e default chama can_use_tool, onde uma pessoa responde. Toda negação chega ao modelo como resultado de ferramenta com erro.\"><defs><marker id=\"l9gate-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l9gate-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PreToolUse</text><text x=\"30\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hook: pode negar</text><rect x=\"190\" y=\"90\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">allowed_tools</text><text x=\"200\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">listado: roda</text><rect x=\"360\" y=\"20\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"370\" y=\"35.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dontAsk</text><text x=\"370\" y=\"51.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">negada</text><rect x=\"360\" y=\"92\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"370\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">auto</text><text x=\"370\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um classificador decide</text><rect x=\"360\" y=\"164\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"370\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">default</text><text x=\"370\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pergunta ao can_use_tool</text><rect x=\"560\" y=\"164\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma pessoa</text><text x=\"570\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">y ou n</text><path d=\"M150 115 L190 115\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l9gate-ah-amber)\"></path><path d=\"M320 106 L360 43\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l9gate-ah-wire)\"></path><path d=\"M320 115 L360 115\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l9gate-ah-wire)\"></path><path d=\"M320 124 L360 187\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l9gate-ah-amber)\"></path><path d=\"M510 187 L560 187\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l9gate-ah-amber)\"></path></svg>", "caption": "Cada camada pode dizer não. Só o allowed_tools diz sim sem perguntar."}
```

Essa ordem é o que torna os hooks o lugar certo para dois tipos de regra. **Regras com resposta certa**, como um limite, ficam onde nenhum modelo e nenhuma pessoa cansada podem ser convencidos a desistir delas. **Registros** ficam no primeiro ponto por onde toda chamada passa, para que o log tenha as chamadas recusadas além das que rodaram. Este repositório aplica a mesma ideia à própria equipe: toda escrita administrativa registra quem a fez (`internal/audit`), e a aula 17 a usa como exemplo resolvido.
