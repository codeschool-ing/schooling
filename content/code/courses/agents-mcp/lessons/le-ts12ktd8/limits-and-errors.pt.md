---
title: Limites, e o que uma falha diz
version: 1
---

## O limite de passos levanta exceção

```
ana@lab:~/agents$ python oa_run.py "Where is my order M-1043?" 2
stopped: Max turns (2) exceeded
```

Com `max_turns=2`, a execução que precisa de três pedidos parou e levantou `MaxTurnsExceeded`. Compare com as aulas 5 e 7, em que um limite produzia um resultado com um motivo e um encaminhamento. **A escolha do SDK é uma exceção**, então o programa decide o que o cliente vê: o `oa_run.py` a captura e imprime uma linha. Um programa que não a captura cai na primeira execução longa, o que é motivo para envolver todo `Runner.run` no tratamento que a aula 5 descreveu.

## A mensagem de erro padrão esconde o erro

Duas execuções que batem cada uma numa chamada de ferramenta com falha: um pedido que não existe, e um id que o substituto do curso manda sem o prefixo. Depois a última linha imprime o que o modelo de fato recebeu como resultado de cada ferramenta:

```
ana@lab:~/agents$ python oa_run.py "What happened to my order M-9999?" | tail -n 1
answer: I cannot find an order M-9999. Could you check the number in your confirmation email?
ana@lab:~/agents$ python oa_run.py "Where is my order 1044?" | tail -n 1
answer: Order M-1044 was delivered on 14 August 2026.
ana@lab:~/agents$ python -c 'import json; [print(m["content"][:150]) for r in map(json.loads, open("/var/log/labllm/requests.jsonl")) for m in r["request"]["messages"][-1:] if m["role"] == "tool"]'
An error occurred while running the tool. Please try again.
An error occurred while running the tool. Please try again.
{'id': 'M-1044', 'customer_id': 'c-103', 'placed_on': '2026-08-11', 'status': 'delivered', 'delivered_on': '2026-08-14', 'shipping': 0, 'tracking': 'B
```

As duas falhas chegaram ao modelo como a mesma frase: *"An error occurred while running the tool. Please try again."* Nada diz se o pedido não existe ou se o id está malformado. O modelo roteirizado respondeu com bom senso porque o curso o escreveu assim; **um modelo real a quem se diz "tente de novo" muito provavelmente tentaria a mesma chamada de novo**, e todo o argumento da aula 4 era que um erro tem de dizer o que falhou.

A correção é um argumento. O `failure_error_function` decide o que o modelo lê quando uma ferramenta levanta erro:

```schooling-example
{
  "language": "python",
  "file": "oa_tools.py",
  "parts": [
    {
      "code": "\"\"\"Marginalia's tools for the OpenAI Agents SDK: shop.py's functions, decorated.\"\"\"\nfrom typing import Annotated, Literal\n\nfrom agents import function_tool\nfrom pydantic import Field\n\nimport shop\n\n\n"
    },
    {
      "code": "def say_what_failed(ctx, error):\n    \"\"\"What the model reads when a tool fails: the error itself, not a generic apology.\"\"\"\n    return f\"{type(error).__name__}: {error}\"\n\n\n",
      "note": "**O tipo e a mensagem do erro, como o modelo vai lê-los.** É a regra do `run_tool` da aula 4 em duas linhas."
    },
    {
      "code": "@function_tool(failure_error_function=say_what_failed)\ndef get_order(order_id: Annotated[str, Field(pattern=\"^M-[0-9]{4}$\")]) -> dict:\n    \"\"\"Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents.\"\"\"\n    return shop.get_order(order_id)\n\n\n@function_tool\ndef search_help(query: str) -> list[dict]:\n    \"\"\"Search Marginalia's help centre by meaning and return the three closest articles.\"\"\"\n    return [{\"title\": a[\"title\"], \"body\": a[\"body\"]} for a in shop.search_help(query)]\n\n\n@function_tool(needs_approval=True)\ndef refund(order_id: Annotated[str, Field(pattern=\"^M-[0-9]{4}$\")], cents: int, reason: str) -> dict:\n    \"\"\"Refund part or all of an order to the customer's original payment, in cents.\"\"\"\n    return shop.refund(order_id, cents, reason, approved_by=\"ana\")",
      "note": "**Aplicado ao `get_order`.** As outras ferramentas ficam com o padrão, para mostrar a diferença."
    }
  ]
}
```

```
ana@lab:~/agents$ python oa_run.py "What happened to my order M-9999?" | tail -n 1
answer: I cannot find an order M-9999. Could you check the number in your confirmation email?
ana@lab:~/agents$ python oa_run.py "Where is my order 1044?" | tail -n 1
answer: Order M-1044 was delivered on 14 August 2026.
ana@lab:~/agents$ python -c 'import json; [print(m["content"][:150]) for r in map(json.loads, open("/var/log/labllm/requests.jsonl")) for m in r["request"]["messages"][-1:] if m["role"] == "tool"]'
LookupError: no order M-9999
ModelBehaviorError: Invalid JSON input for tool get_order
{'id': 'M-1044', 'customer_id': 'c-103', 'placed_on': '2026-08-11', 'status': 'delivered', 'delivered_on': '2026-08-14', 'shipping': 0, 'tracking': 'B
```

Agora o pedido inexistente diz `LookupError: no order M-9999`, com o que um modelo consegue agir. O id malformado diz `ModelBehaviorError: Invalid JSON input for tool get_order`: melhor que nada, e ainda mais vago que o `'1043' does not match '^M-[0-9]{4}$'` da aula 4, porque o erro de validação do SDK não nomeia o campo nem a regra. Uma ferramenta que se importa pode receber o argumento como `str` simples e conferir o padrão ela mesma, levantando um `ValueError` cuja mensagem diz exatamente o que estava errado.
