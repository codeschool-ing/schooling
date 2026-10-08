---
title: Um modelo menor
version: 2
---

A aula 1 baixou um segundo modelo, o `llama3.2:1b`: a mesma família com um terço dos parâmetros, 1,3 GB em disco em vez de 2,0. A mesma execução, sem mais nenhuma mudança:

```
ana@lab:~/agents$ python cost_run.py llama3.2:1b
step   input  c.write  c.read  output     ms  stop
   1     994        0      15      34   5588  tool_use
       tool get_order {"function": "get_order", "parameters": {"properties": {"order_id": "M-1043"}, "required": ["order_id"], "type": "object"}, "type": "function"}Traceback (most recent call last):
  File "/home/ana/agents/cost_run.py", line 57, in <module>
    out = json.dumps(RUN[call.name](call.input))
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/agents/cost_run.py", line 29, in <lambda>
    RUN = {"get_order": lambda a: shop.get_order(a["order_id"]),
                                                 ~^^^^^^^^^^^^
KeyError: 'order_id'
```

O primeiro pedido **levou 5.588 ms em vez de 10.447**, para os mesmos 994 tokens lidos: um modelo menor lê e escreve mais rápido. E aí o programa quebrou. O modelo pediu o `get_order` e, como argumentos, devolveu a própria descrição da ferramenta, `{"function": "get_order", "parameters": {...}}`, com o id do pedido enterrado um nível abaixo de onde o `order_id` deveria estar. O `cost_run.py` confiou nos argumentos, coisa contra a qual a aula 4 alertou, e `a["order_id"]` levantou `KeyError`.

É isso que um modelo menor troca. Ele é mais rápido e, num fornecedor, mais barato por token, e é menos capaz de fazer o que o maior fez neste mesmo pedido. **Quais tarefas ele aguenta é uma pergunta a responder testando**, não supondo, e o teste são execuções como esta, muitas delas, lidas pela chamada e não só pelo tempo. O padrão de roteamento da aula 2 é onde a resposta rende: mande as perguntas fáceis para o modelo pequeno e as difíceis para o grande, decida qual é qual com algo barato, e confira as chamadas de ferramenta do modelo pequeno antes de executá-las, porque uma checagem de schema teria transformado essa quebra num resultado de erro que o laço saberia tratar.

O que um modelo menor não muda é a forma da conta. Ele ainda lê o prompt inteiro a cada pedido. Essa parte é o assunto da próxima seção.
