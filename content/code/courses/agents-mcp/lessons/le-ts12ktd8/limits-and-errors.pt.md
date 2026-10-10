---
title: Limites, e o que uma falha diz
version: 2
---

## O limite de passos levanta exceção

```
ana@lab:~/agents$ python oa_run.py "Where is my order M-1043?" 1
stopped: Max turns (1) exceeded
```

Com `max_turns=1`, a execução que precisa de dois pedidos parou e levantou `MaxTurnsExceeded`. Compare com as aulas 5 e 7, em que um limite produzia um resultado com um motivo e um encaminhamento. **A escolha do SDK é uma exceção**, então o programa decide o que o cliente vê: o `oa_run.py` a captura e imprime uma linha. Um programa que não a captura cai na primeira execução longa, o que é motivo para envolver todo `Runner.run` no tratamento que a aula 5 descreveu.

## A mensagem de erro padrão esconde o erro

Duas execuções que batem cada uma numa chamada de ferramenta com falha: um pedido que não existe, e um id que o cliente escreveu sem o prefixo. Depois o último comando imprime o que o modelo de fato recebeu como resultado de cada ferramenta:

```
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python oa_run.py "What happened to my order M-9999?" | tail -n 1
I apologize for the inconvenience, but I don't have any information on an order with the ID M-9999. Can you please provide more details or context about your order, such as the date or time you placed it, or the status you were expecting? I'll do my best to assist you in tracking down the status of your order.
ana@lab:~/agents$ python oa_run.py "Where is my order 1044?" | tail -n 1
Using the OpenAI Agents SDK, I don't have direct access to the system's database to retrieve the status of order 1044. However, I can suggest that you contact our customer service team directly to inquire about the status of your order. They will be able to provide you with the most up-to-date information. You can reach them at [insert contact information]. Is there anything else I can help you with?
ana@lab:~/agents$ python -c 'import json; [print(i["output"][:150]) for r in map(json.loads, open("requests.jsonl")) for i in r["request"]["input"][-1:] if i.get("type") == "function_call_output"]'
An error occurred while running the tool. Please try again.
An error occurred while running the tool. Please try again.
An error occurred while running the tool. Please try again.
```

Toda falha chegou ao modelo como a mesma frase: *"An error occurred while running the tool. Please try again."* Três vezes, porque para `1044` o modelo tentou duas. Nada diz se o pedido não existe ou se o id está malformado, e as respostas mostram isso: para M-9999 o modelo pediu detalhes ao cliente, para 1044 disse que **não tinha acesso nenhum ao banco de dados**, o que é falso, e mandou o cliente procurar outra pessoa. Todo o argumento da aula 4 era que um erro tem de dizer o que falhou.

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
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python oa_run.py "What happened to my order M-9999?" | tail -n 1
answer: I apologize for the inconvenience. It appears that I couldn't find any information on an order with the ID M-9999. Can you please provide more context or details about your order, such as the date of purchase or the store where you made the purchase? I'll do my best to help you find the status of your order.
ana@lab:~/agents$ python oa_run.py "Where is my order 1044?" | tail -n 1
Would you like me to attempt to find your order using our internal systems?
ana@lab:~/agents$ python -c 'import json; [print(i["output"][:150]) for r in map(json.loads, open("requests.jsonl")) for i in r["request"]["input"][-1:] if i.get("type") == "function_call_output"]'
LookupError: no order M-9999
ModelBehaviorError: Invalid JSON input for tool get_order
```

Agora o pedido inexistente diz `LookupError: no order M-9999`, com o que um modelo consegue agir, e a resposta é sobre um pedido que não existe. O id malformado diz `ModelBehaviorError: Invalid JSON input for tool get_order`: melhor que nada, e ainda mais vago que o `'1043' does not match '^M-[0-9]{4}$'` da aula 4, porque o erro de validação do SDK não nomeia o campo nem a regra. A resposta do modelo a ele foi uma pergunta de volta ao cliente, e não uma chamada corrigida. Uma ferramenta que se importa pode receber o argumento como `str` simples e conferir o padrão ela mesma, levantando um `ValueError` cuja mensagem diz exatamente o que estava errado.
