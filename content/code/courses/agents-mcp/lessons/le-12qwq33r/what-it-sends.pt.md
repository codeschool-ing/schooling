---
title: O que o ADK põe no fio
version: 2
---

O `wire.py` imprime cada pedido do log do gravador nos termos da própria API do Ollama: o caminho, o esquema de parâmetros de cada ferramenta e as mensagens.

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
    for m in q.get("messages", []):   # LiteLLM's first request, /api/show, asks about the model and carries none
        print(f"  {m['role']}:", json.dumps(m.get("content") or m.get("tool_calls"), ensure_ascii=False)[:150])
```

```
ana@lab:~/agents$ python wire.py
request 1: /api/show
request 2: /api/show
request 3: /api/chat
  tool get_order: {"properties": {"order_id": {"title": "Order Id", "type": "string"}}, "required": ["order_id"], "title": "get_orderParams", "type": "object"}
  tool search_help: {"properties": {"query": {"title": "Query", "type": "string"}}, "required": ["query"], "title": "search_helpParams", "type": "object"}
  system: "You answer Marginalia's customers in the Google ADK lesson. Use the tools; never guess.\n\nYou are an agent. Your internal name is \"support\"."
  user: "Where is my order M-1043?"
request 4: /api/show
request 5: /api/chat/api/show
request 6: /api/show
request 7: /api/show
request 8: /api/chat
  tool get_order: {"properties": {"order_id": {"title": "Order Id", "type": "string"}}, "required": ["order_id"], "title": "get_orderParams", "type": "object"}
  tool search_help: {"properties": {"query": {"title": "Query", "type": "string"}}, "required": ["query"], "title": "search_helpParams", "type": "object"}
  system: "You answer Marginalia's customers in the Google ADK lesson. Use the tools; never guess.\n\nYou are an agent. Your internal name is \"support\"."
  user: "Where is my order M-1043?"
  assistant: null
  tool: "{\"id\": \"M-1043\", \"customer_id\": \"c-102\", \"placed_on\": \"2026-09-28\", \"status\": \"shipped\", \"delivered_on\": null, \"shipping\": 0, \"t
```

**Oito pedidos para uma resposta, e dois deles eram a conversa.** Os outros seis são o LiteLLM perguntando ao Ollama sobre o modelo, `/api/show`, antes e entre as duas conversas, e um deles foi para `/api/chat/api/show`, um caminho que o Ollama não tem: o LiteLLM montou esse endereço sozinho, e o Ollama respondeu com um `404`. Nada disso está no `adk_run.py`. É o que uma biblioteca a um passo do seu código faz por você, e o gravador é o único motivo de isso estar visível.

Mais três coisas são escolhas da biblioteca.

**A instrução ganha uma frase.** A `instruction` do agente vem seguida de *"You are an agent. Your internal name is \"support\"."* O ADK a acrescenta a todo agente, e a seção 06 mostra que ele acrescenta bem mais quando um agente tem outros para quem transferir. O que o modelo lê é o seu texto mais o da biblioteca, e o único jeito de ver tudo é olhar o pedido.

**O esquema é gerado.** `get_order(order_id: str)` virou um esquema de objeto com uma propriedade string obrigatória, e os títulos do Pydantic vieram junto (`"Order Id"`, `"get_orderParams"`), como na aula 8. A docstring virou a descrição. Um padrão para `M-` e quatro dígitos não está lá, porque nada na anotação de tipo o dizia; a regra da aula 4, de que o esquema deve levar o que o código confere, vale aqui também.

**A chamada não chegou ao modelo; o resultado dela chegou.** No segundo pedido o resultado da ferramenta está lá, o pedido como JSON numa mensagem `tool`. A chamada que o produziu não está: a vez do assistente chega com o conteúdo vazio e sem `tool_calls`, que o `wire.py` imprime como `null`. Os eventos do ADK guardam a chamada, e em algum ponto entre eles e o Ollama ela se perdeu, então o modelo leu um resultado sem a pergunta antes dele. Respondeu certo mesmo assim. **O que o modelo leu não é a conversa que o ADK guarda**, e nada na saída do ADK diz isso; o pedido diz. Uma função que devolve algo que não é um dicionário é embrulhada num, sob a chave `result`: a seção 06 mostra isso, como `{"result": null}` e `{"result": "The order M-1046 has been packed..."}`.
