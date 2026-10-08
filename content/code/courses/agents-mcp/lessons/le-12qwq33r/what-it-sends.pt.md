---
title: O que o ADK põe no fio
version: 1
---

O `wire.py` imprime cada pedido do log do labllm nos termos da própria API do Gemini: a instrução de sistema, o esquema de parâmetros de cada ferramenta, e o conteúdo.

```python
"""What each request in the recorder's log carried, in the format of Ollama's own API."""
import json

for n, line in enumerate(open("requests.jsonl"), 1):
    r = json.loads(line)
    q = r["request"]
    print(f"request {n}: {r['path']}")
    for tool in q.get("tools", []):
        f = tool["function"]
        print(f"  tool {f['name']}:", json.dumps(f["parameters"]))
    for m in q["messages"]:
        print(f"  {m['role']}:", json.dumps(m.get("content") or m.get("tool_calls"), ensure_ascii=False)[:150])
```

```
ana@lab:~/agents$ python wire.py
request 1:
  systemInstruction: "You answer Marginalia's customers in the Google ADK lesson. Use the tools; never guess.\n\nYou are an agent. Your internal name is \"support\"."
  tool get_order: {"properties": {"order_id": {"title": "Order Id", "type": "string"}}, "required": ["order_id"], "title": "get_orderParams", "type": "object"}
  tool search_help: {"properties": {"query": {"title": "Query", "type": "string"}}, "required": ["query"], "title": "search_helpParams", "type": "object"}
  user: {"text": "Where is my order M-1043?"}
request 2:
  systemInstruction: "You answer Marginalia's customers in the Google ADK lesson. Use the tools; never guess.\n\nYou are an agent. Your internal name is \"support\"."
  tool get_order: {"properties": {"order_id": {"title": "Order Id", "type": "string"}}, "required": ["order_id"], "title": "get_orderParams", "type": "object"}
  tool search_help: {"properties": {"query": {"title": "Query", "type": "string"}}, "required": ["query"], "title": "search_helpParams", "type": "object"}
  user: {"text": "Where is my order M-1043?"}
  model: {"functionCall": {"id": "fc_lab_0002_1", "args": {"order_id": "M-1043"}, "name": "get_order"}}
  user: {"functionResponse": {"id": "fc_lab_0002_1", "name": "get_order", "response": {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "sta
```

Três coisas são escolhas da biblioteca.

**A instrução ganha uma frase.** A `instruction` do agente vem seguida de *"You are an agent. Your internal name is \"support\"."* O ADK a acrescenta a todo agente, e a seção 06 mostra que ele acrescenta bem mais quando um agente tem outros para quem transferir. O que o modelo lê é o seu texto mais o da biblioteca, e o único jeito de ver tudo é olhar o pedido.

**O esquema é gerado.** `get_order(order_id: str)` virou um esquema de objeto com uma propriedade string obrigatória, e os títulos do Pydantic vieram junto (`"Order Id"`, `"get_orderParams"`), como na aula 8. A docstring virou a descrição. Um padrão para `M-` e quatro dígitos não está lá, porque nada na anotação de tipo o dizia; a regra da aula 4, de que o esquema deve levar o que o código confere, vale aqui também.

**O resultado é um objeto, não texto.** A última linha é um `functionResponse` cujo `response` é o próprio pedido, em JSON. A API do Gemini recebe o resultado de uma função como valor estruturado, e o ADK passa o dicionário adiante. O SDK da aula 8 transformou o mesmo dicionário no `str()` do Python; a ferramenta da aula 9 escreveu o próprio texto. Uma função que devolve algo que não é dicionário é embrulhada num, sob a chave `result`: a seção 06 mostra isso, como `{"result": null}` e `{"result": "Order M-1046 still says..."}`.
