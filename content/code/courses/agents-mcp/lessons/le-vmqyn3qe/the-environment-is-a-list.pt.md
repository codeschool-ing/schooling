---
title: O ambiente é uma lista
version: 1
---

A aula 12 descobriu que um hospedeiro entregava aos servidores o ambiente inteiro, chaves de API incluídas. O `mcp_host.py` entrega a cada servidor exatamente o que o `ENV` nomeia. A primeira versão dessa lista tinha só `PATH` e `HOME`. Rodando de novo com aquela lista, que é o que o `host_minimal.py` é:

```
ana@lab:~/agents$ grep -v MINILM_DIR mcp_host.py | sed 's/"HOME": "\/home\/ana",   # all/"HOME": "\/home\/ana"}   # all/' > host_minimal.py; python host_minimal.py 'How do I send a book back?' 2> host.err; tail -1 host.err
step 1: shop__search_help {"query": "send a book back"}
  error: Error executing tool search_help
step 2: read_help {"uri": "help://h14"}
  result: # How to return a book  You have 30 days from delivery to return a printed book in the condition you received 
answer: You have 30 days from delivery to return a printed book. Start the return from the order in your account, print the prepaid label and drop the parcel at any post office; returns are free.
mcp.server.mcpserver.exceptions.UnexpectedToolError: Error executing tool search_help
```

O `search_help` falhou com *"Error executing tool search_help"*. O `host.err` é para onde foi a saída de erro dos servidores, e a última linha dele mostra que o servidor registrou uma queda, com o traceback acima. O motivo não estava na mensagem que o modelo recebeu: o `search_help` faz o embedding da consulta com o modelo MiniLM de `embeddings-vectors`, e o módulo que o carrega acha o diretório do modelo pelo `MINILM_DIR`. Sem a variável, ele procurou num diretório padrão que não existe neste laboratório. O modelo seguiu e leu o `help://h14` mesmo assim, porque as regras do curso roteirizaram esse próximo passo; um modelo real talvez não seguisse.

Com o `MINILM_DIR` na lista:

```
ana@lab:~/agents$ python mcp_host.py "How do I send a book back?" 2> host.err
step 1: shop__search_help {"query": "send a book back"}
  result: {"result": [{"title": "How to return a book", "uri": "help://h14"}, {"title": "Damaged books on arrival", "uri
step 2: read_help {"uri": "help://h14"}
  result: # How to return a book  You have 30 days from delivery to return a printed book in the condition you received 
answer: You have 30 days from delivery to return a printed book. Start the return from the order in your account, print the prepaid label and drop the parcel at any post office; returns are free.
```

Duas lições de uma falha. **Um ambiente mínimo tem de ser completo**: liste o que cada servidor precisa, e teste as ferramentas que precisam disso. E **a queda de um servidor é contada ao log dele, não ao cliente**, como a aula 14 explicou; um hospedeiro que joga fora a saída de erro dos servidores (as aulas 11 e 12 jogaram, com `2> /dev/null`) jogou fora o único lugar onde estava o motivo.
