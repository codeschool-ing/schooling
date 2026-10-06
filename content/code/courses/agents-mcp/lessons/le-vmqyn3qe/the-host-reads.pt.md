---
title: O hospedeiro lê, o modelo pede
version: 1
---

A aula 14 fez o `search_help` devolver URIs, para um hospedeiro poder ler os artigos. O `mcp_host.py` dá ao modelo uma ferramenta para pedir um, `read_help`, e faz a leitura ele mesmo: a execução da seção 04 foi de uma busca, para o `help://h14`, para uma resposta. O modelo nunca falou com um recurso; ele pediu ao hospedeiro, e o hospedeiro decidiu.

Essa decisão tem uma regra, e aqui está a regra funcionando. O roteiro do curso para esta pergunta faz o modelo pedir um arquivo:

```
ana@lab:~/agents$ python mcp_host.py "Show me the settings file" 2> host.err
step 1: read_help {"uri": "file:///home/ana/agents/data/shop.db"}
  error: only help:// articles can be read
answer: I can only read articles from the help centre.
```

`file:///home/ana/agents/data/shop.db` é uma URI, e nada no MCP impede um modelo de escrever uma numa chamada de ferramenta. O `run()` recusa tudo o que não começa com `help://` antes de qualquer servidor ser perguntado, e o modelo recebeu um resultado com erro dizendo isso. A checagem fica no hospedeiro porque o hospedeiro é onde o pedido vira ação; o servidor shop também teria recusado (ele só serve `help://`), mas um hospedeiro que dependesse disso estaria confiando que todo servidor que ele conecta tem o mesmo cuidado.

O mesmo padrão serve para qualquer recurso que um hospedeiro expõe: **decida que URIs o modelo pode levar o hospedeiro a ler**, por esquema, por servidor, por padrão, e recuse o resto no código do hospedeiro. A aula 17 testa essa fronteira com uma instrução escondida num documento, contra o próprio laboratório do curso.
