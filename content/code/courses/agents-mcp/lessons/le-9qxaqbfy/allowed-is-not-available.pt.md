---
title: Permitido não é o mesmo que disponível
version: 1
---

Três opções decidem o que uma chamada de ferramenta pode fazer, e os nomes são parecidos o bastante para confundir:

| opção | o que ela decide |
|---|---|
| `tools` | quais das ferramentas embutidas do Claude Code **existem** na sessão (seção 04) |
| `allowed_tools` | quais chamadas rodam **sem perguntar a ninguém** |
| `disallowed_tools` | quais ferramentas são removidas e recusadas, diga o resto o que disser |

O `cs_refund.py` oferece as três ferramentas da loja e permite só o `get_order`. Toda configuração abaixo deixa o `refund` disponível e não permitido, então alguém tem de decidir cada chamada de reembolso. Quem decide é o **modo de permissão**.

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
      "note": "**A mesma base em todo modo**: nenhuma ferramenta embutida, nenhum arquivo de configuração, e só o `get_order` permitido."
    },
    {
      "code": "        o.permission_mode = \"dontAsk\"\n    if how in (\"ask\", \"hooked\"):\n",
      "note": "**Recusar tudo o que não é permitido**, sem perguntar."
    },
    {
      "code": "        o.permission_mode = \"default\"\n        o.can_use_tool = ask_a_person\n    if how == \"hooked\":\n        o.hooks = {\"PreToolUse\": [HookMatcher(matcher=\"mcp__shop__.*\", hooks=[audit_and_limit])]}",
      "note": "**Perguntar**: com `can_use_tool` definido, a pergunta vai para essa função (seção 07)."
    }
  ]
}
```

Primeiro sem `permission_mode` nenhum:

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

A recusa nomeia o modo: **auto**. Esta versão do CLI, sem modo dado, manda um classificador julgar cada chamada, e o segundo comando mostra o que isso significou no fio. Além dos dois pedidos do agente houve **mais onze**, cada um com um prompt de sistema começando por *"You are a security monitor for autonomous AI coding agents."* O primeiro foi para um modelo chamado `claude-sonnet-5`, que o labllm não tem (`404`); os outros dez foram para o `scripted-1`, que não tinha regra para eles, então nenhum veredito voltou, e depois de uns oito segundos tentando (9.723 ms para a execução, contra menos de dois nas outras) o CLI recusou a chamada.

A recusa foi segura. O que o padrão fez no caminho é a lição. Cada pedido ao classificador levava a mensagem do cliente e os argumentos do reembolso, então **a conversa foi mandada a um modelo que o código nunca nomeou**, onze vezes, por uma chamada de ferramenta. Com um fornecedor real esses pedidos são cobrados e registrados como qualquer outro. Um modo que decide o que sai do processo não é coisa para herdar; defina-o.

Com `dontAsk`:

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

Recusada na hora, e o modelo foi avisado. Leia a mensagem que o CLI escreveu para o modelo, impressa inteira pelo segundo comando: ela diz ao modelo que ele *pode* chegar ao mesmo objetivo "using other tools that might naturally be used", desde que não o faça "in malicious ways". **Essa é uma frase pedindo ao modelo que use o próprio julgamento**, e julgamento não é fronteira. Na execução padrão da seção 04 este agente tinha `Bash` e `Write`, e o `data/shop.db` é um arquivo que o processo da ana consegue escrever. Com `tools=[]` não há outra ferramenta para buscar, e a recusa se sustenta pelo que a sessão contém, não pelo que o modelo decide.
