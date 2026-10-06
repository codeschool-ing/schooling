---
title: Perguntando a uma pessoa
version: 1
---

No modo `default`, uma chamada que não é permitida vai para o `can_use_tool`, uma função que você fornece. O SDK passa o nome da ferramenta e os argumentos exatos que o modelo escolheu; a função devolve permitir ou negar, e uma negação leva uma mensagem para o modelo.

```schooling-example
{
  "language": "python",
  "file": "cs_refund.py",
  "parts": [
    {
      "code": "async def ask_a_person(tool_name, tool_input, context):\n",
      "note": "**O callback**: nome da ferramenta, argumentos e um objeto de contexto."
    },
    {
      "code": "    print(f\"approve?   {tool_name} {tool_input} [y/n] \", end=\"\", flush=True)\n    answer = sys.stdin.readline().strip()\n    print(answer)\n    if answer == \"y\":\n",
      "note": "**A pessoa vê exatamente o que rodaria**, argumentos incluídos."
    },
    {
      "code": "        return PermissionResultAllow()\n",
      "note": "**Permitir**: a chamada roda como o modelo pediu."
    },
    {
      "code": "    return PermissionResultDeny(message=\"Not approved by staff. A colleague will review this refund.\")",
      "note": "**Negar, com uma mensagem** que vira o resultado da ferramenta."
    }
  ]
}
```

As respostas `n` e depois `y` foram digitadas por uma pessoa e entregues pela entrada padrão:

```
ana@lab:~/agents$ echo n | python cs_refund.py ask "One copy of M-1047 arrived damaged; please refund it."
/opt/agents/lib/python3.11/site-packages/claude_agent_sdk/types.py:1948: CanUseToolShadowedWarning: can_use_tool will not be invoked for: mcp__shop__get_order. An allowed_tools entry that allows a whole tool auto-approves it before the callback is consulted. To gate every tool call, use a PreToolUse hook; or narrow the entry so calls fall through to can_use_tool. Allow rules from settings files can also shadow the callback but are not visible here.
  _warn_if_can_use_tool_shadowed(options)
system     init tools=3
assistant  tool_use mcp__shop__refund {'order_id': 'M-1047', 'cents': 3890, 'reason': 'one copy arrived damaged'}
approve?   mcp__shop__refund {'order_id': 'M-1047', 'cents': 3890, 'reason': 'one copy arrived damaged'} [y/n] n
user       tool_result (error) Not approved by staff. A colleague will review this refund.
assistant  I could not issue this refund myself; a colleague will review order M-1047 and reply to you by email.
result     success turns=2 1776 ms cost_usd=0.0045 session=04b52ee3
ana@lab:~/agents$ echo y | python cs_refund.py ask "One copy of M-1047 arrived damaged; please refund it."
/opt/agents/lib/python3.11/site-packages/claude_agent_sdk/types.py:1948: CanUseToolShadowedWarning: can_use_tool will not be invoked for: mcp__shop__get_order. An allowed_tools entry that allows a whole tool auto-approves it before the callback is consulted. To gate every tool call, use a PreToolUse hook; or narrow the entry so calls fall through to can_use_tool. Allow rules from settings files can also shadow the callback but are not visible here.
  _warn_if_can_use_tool_shadowed(options)
system     init tools=3
assistant  tool_use mcp__shop__refund {'order_id': 'M-1047', 'cents': 3890, 'reason': 'one copy arrived damaged'}
approve?   mcp__shop__refund {'order_id': 'M-1047', 'cents': 3890, 'reason': 'one copy arrived damaged'} [y/n] y
user       tool_result {"order_id": "M-1047", "refunded": 3890, "left": 3890}
assistant  Done: 38.90 has been refunded to your original payment for the damaged copy in order M-1047.
result     success turns=2 1782 ms cost_usd=0.0045 session=aabdccdd
ana@lab:~/agents$ python -c 'import sqlite3; print(sqlite3.connect("data/shop.db").execute("SELECT order_id, cents, approved_by FROM refunds").fetchall())'
[('M-1047', 3890, 'ana')]
```

Recusado, o reembolso não rodou e o modelo leu *"Not approved by staff. A colleague will review this refund."* como resultado com erro. Aprovado, ele rodou: o segundo comando lê a tabela de reembolsos, e há uma linha, 3890 centavos no M-1047, aprovada por ana. **As respostas ao cliente foram escritas pelo curso.**

O aviso acima de cada execução é do SDK, e vale a leitura: o `can_use_tool` não vai ser chamado para o `get_order`, porque uma entrada em `allowed_tools` aprova a ferramenta inteira antes de o callback ser consultado. É isso que este programa quer (consultar um pedido não precisa da aprovação de ninguém), e é também a forma de um erro real: permita uma ferramenta "por enquanto" e a pessoa que devia ver cada chamada nunca vê nenhuma. A aprovação da aula 8 estava presa à ferramenta; aqui ela é a ausência da ferramenta numa lista, e uma lista é fácil de aumentar.

Uma diferença em relação à aula 8 importa em produção. O `can_use_tool` é chamado enquanto a execução espera, dentro do mesmo processo, como era o `confirm` da aula 7. Não há estado para salvar e retomar depois; uma pessoa que responde amanhã precisa de outro desenho, como uma ferramenta de reembolso que só registra um pedido.
