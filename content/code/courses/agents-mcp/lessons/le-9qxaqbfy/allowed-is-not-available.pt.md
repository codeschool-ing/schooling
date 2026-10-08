---
title: Permitido não é o mesmo que disponível
version: 2
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
      "code": "    o = ClaudeAgentOptions(model=\"qwen2.5:3b\", system_prompt=SYSTEM, mcp_servers={\"shop\": shop_server},\n                           tools=[], setting_sources=[], allowed_tools=[\"mcp__shop__get_order\"])\n    if how == \"dont-ask\":\n",
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

O modelo pediu para reembolsar 1.000.000 de centavos num pedido de 7.780, e a chamada foi recusada, por um modo que ninguém escolheu: esta versão do CLI, sem modo dado, roda em **auto**, em que um classificador julga cada chamada não permitida. O segundo comando mostra o que isso significou no fio. Além dos dois pedidos do agente houve mais um, com um prompt de sistema começando por *"You are a security monitor for autonomous AI coding agents."*, mandado a um modelo chamado `claude-sonnet-5`, que o Ollama não tem (`404`). A recusa que o modelo leu diz o que veio depois: o CLI pediu o veredito ao `qwen2.5:3b` e desistiu de esperar. Esse pedido não está no log do gravador, porque o CLI já tinha parado de esperar antes de o Ollama responder, mas o log do próprio Ollama o tem: 30.421 tokens, cortados para 4.098 como os da seção 04. A execução levou 188 segundos.

A recusa foi segura, e pelo motivo errado: nada julgou o reembolso, o juiz estava indisponível. O que o padrão fez no caminho é a lição. O pedido ao classificador levava a mensagem do cliente e os argumentos do reembolso, então **a conversa foi mandada a um modelo que o código nunca nomeou**, e diante de um fornecedor que tem o `claude-sonnet-5` ela teria sido respondida, cobrada e registrada como qualquer outro pedido. Um modo que decide o que sai do processo não é coisa para herdar; defina-o.

Com `dontAsk`:

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

Recusada na hora, e o modelo foi avisado. Leia a mensagem que o CLI escreveu para o modelo, impressa inteira pelo segundo comando: ela diz ao modelo que ele *pode* chegar ao mesmo objetivo "using other tools that might naturally be used", desde que não o faça "in malicious ways". **Essa é uma frase pedindo ao modelo que use o próprio julgamento**, e julgamento não é fronteira. Este modelo a leu como uma brecha: ofereceu guiar o cliente para tentar o reembolso "usando ferramentas diferentes". Na execução padrão da seção 04 este agente tinha `Bash` e `Write`, e o `data/shop.db` é um arquivo que o processo da ana consegue escrever. Com `tools=[]` não há outra ferramenta para buscar, e a recusa se sustenta pelo que a sessão contém, não pelo que o modelo decide.
