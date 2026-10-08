---
title: Limites de turnos, e sessões em disco
version: 1
---

## O limite de turnos

```
ana@lab:~/agents$ python cs_run.py one-turn "Where is my order M-1043?"
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1043'}
system     informational
user       tool_result {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "shipped", "
result     error_max_turns turns=2 378 ms cost_usd=0.0018 session=eecf2e5e
raised     ResultError: Claude Code returned an error result: Reached maximum number of turns (1) (exit code: 1)
```

Com `max_turns=1` a execução parou depois do primeiro resultado de ferramenta. O fluxo ainda terminou com um `result`, de subtipo `error_max_turns`, então um programa que lê o fluxo sabe o que aconteceu; e depois o `query()` **levantou `ResultError`** também, que o `cs_run.py` captura. O SDK da aula 8 levantava exceção; este informa e depois levanta, e um programa tem de tratar a exceção de qualquer jeito. Repare em `turns=2` numa execução limitada a um: o que o CLI conta como turno e o que a opção limita não são a mesma contagem. Teste um limite contra o que a execução fez, não contra o número que você pôs.

## Sessões

Toda execução escreve a conversa num arquivo, e cada `result` traz o id da sessão. O `cs_session.py` manda duas mensagens da Bia, primeiro como duas execuções separadas, depois com a segunda retomando a primeira:

```python
"""Two messages from one customer: separate runs, then the second resuming the first."""
import sys

import anyio
from claude_agent_sdk import ClaudeAgentOptions, ResultMessage, query

from cs_show import show
from cs_tools import shop_server

SYSTEM = "You answer Marginalia's customers in the Claude Agent SDK lesson."


async def turn(text, resume=None):
    o = ClaudeAgentOptions(model="qwen2.5:3b", system_prompt=SYSTEM, mcp_servers={"shop": shop_server},
                           tools=[], setting_sources=[], resume=resume,
                           allowed_tools=["mcp__shop__get_order", "mcp__shop__search_help"])
    session = None
    async for message in query(prompt=text, options=o):
        show(message)
        if isinstance(message, ResultMessage):
            session = message.session_id
    return session


async def main(how):
    first = await turn("Hello, this is Bia. When was my order M-1042 delivered?")
    print("---")
    await turn("Can I still return it?", resume=first if how == "resume" else None)


anyio.run(main, sys.argv[1])
```

```
ana@lab:~/agents$ python cs_session.py separate
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1042'}
system     informational
user       tool_result {"id": "M-1042", "customer_id": "c-101", "placed_on": "2026-09-20", "status": "delivered",
assistant  Order M-1042 was delivered on 24 September 2026.
result     success turns=2 1207 ms cost_usd=0.0043 session=61027713
---
system     init tools=3
assistant  Which order do you mean? Please send me its number, such as M-1042.
system     informational
result     success turns=1 1050 ms cost_usd=0.0019 session=9428d322
ana@lab:~/agents$ python cs_session.py resume
system     init tools=3
assistant  tool_use mcp__shop__get_order {'order_id': 'M-1042'}
system     informational
user       tool_result {"id": "M-1042", "customer_id": "c-101", "placed_on": "2026-09-20", "status": "delivered",
assistant  Order M-1042 was delivered on 24 September 2026.
result     success turns=2 1224 ms cost_usd=0.0043 session=09b2f915
---
system     init tools=3
assistant  tool_use mcp__shop__search_help {'query': 'return a book'}
system     informational
user       tool_result [{"title": "How to return a book", "body": "You have 30 days from delivery to return a pri
assistant  Yes. M-1042 was delivered on 24 September, and books can be returned within 30 days of delivery, so until 24 October.
result     success turns=2 2208 ms cost_usd=0.0106 session=09b2f915
ana@lab:~/agents$ ls ~/.claude/projects/-home-ana-agents/ | wc -l; grep -l "this is Bia" ~/.claude/projects/-home-ana-agents/*.jsonl | wc -l
3
2
```

Separada, a segunda execução perguntou qual pedido. Retomada com `resume=first`, ela levou o primeiro turno, usou-o, e ficou **na mesma sessão**, `09b2f915` nos dois resultados. **As palavras do modelo foram escritas pelo curso**; o histórico que fez a diferença foi do SDK, e estava no pedido, como a aula 1 disse que tem de estar. A estimativa do turno retomado, 0.0106, é mais que o dobro dos 0.0043 do primeiro turno, porque levou o primeiro turno além de um resultado de busca.

O último comando é a parte para lembrar. O CLI guardou **três arquivos de sessão**, um por sessão, em `~/.claude/projects/` sob um diretório com o nome do diretório de trabalho, e dois deles têm a mensagem da Bia. Ninguém passou um caminho; eles estão ali porque o Claude Code guarda toda sessão para poder retomá-la. Para um agente que atende clientes, isso é um depósito de dados pessoais que o programa nunca menciona, o que a aula 8 disse do `sessions.db` e que vale aqui com menos aviso. Decida onde esses arquivos ficam, por quanto tempo e como são apagados quando um cliente pede; as opções de armazenamento de sessão do SDK existem exatamente para isso.
