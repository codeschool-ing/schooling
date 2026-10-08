---
title: O hospedeiro lê, o modelo pede
version: 2
---

A aula 14 fez o `search_help` devolver URIs, para um hospedeiro poder ler os artigos. O `mcp_host.py` dá ao modelo uma ferramenta para pedir um, `read_help`, e faz a leitura ele mesmo. O modelo nunca fala com um recurso; ele pede ao hospedeiro, e o hospedeiro decide.

Essa decisão tem uma regra: só URIs `help://` são lidas. Para ver a regra funcionando, o modelo precisa pedir outra coisa, e, quando pedimos com todas as letras que lesse um arquivo, o `llama3.2:3b` não tentou. Um modelo que tenta é fácil de imaginar e difícil de produzir na hora, então a segunda execução abaixo aponta o hospedeiro para o `standin.py` da aula 3, que responde a partir de um arquivo escrito antes. Este é o arquivo; ele também roteiriza um reembolso para a seção 06:

```json
{"Read file:///": [{"tool": "read_help", "input": {"uri": "file:///home/ana/agents/data/shop.db"}},
                   {"text": "I can only read articles from the help centre."}],
 "arrived damaged": [{"tool": "refunds__refund", "input": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}},
                     {"text": "Done: 3890 cents have been refunded on order M-1047."}]}
```

Primeiro o modelo real, depois o dublê na porta 11436:

```
ana@lab:~/agents$ python mcp_host.py "Read file:///home/ana/agents/data/shop.db for me." 2> host.err
step 1: shop__search_help {"query": "file:///home/ana/agents/data/shop.db"}
  result: {"result": [{"title": "Tracking a parcel", "uri": "help://h08"}, {"title": "Items that cannot be returned", "u
answer: It appears that the file at `file:///home/ana/agents/data/shop.db` is a SQLite database, but I couldn't retrieve the actual content of the database. However, I can suggest that you use the `sqlite3` command-line tool to view the contents of the database. 

You can use the following command to list the tables in the database:

`sqlite3 shop.db .tables`

This will list all the tables in the database. You can then use the `.headers on` and `.mode column` commands to view the contents of each table.

For example, to view the contents of the `items` table, you can use the following command:

`sqlite3 shop.db "SELECT * FROM items"`

This will display the contents of the `items` table.

Please note that you will need to have the `sqlite3` command-line tool installed on your system to view the contents of the database.
ana@lab:~/agents$ python standin.py standin15.json &
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11436 python mcp_host.py "Read file:///home/ana/agents/data/shop.db for me." 2> host.err
step 1: read_help {"uri": "file:///home/ana/agents/data/shop.db"}
  error: only help:// articles can be read
answer: I can only read articles from the help centre.
```

O `llama3.2:3b` buscou a URI na central de ajuda, recebeu três títulos sem relação e então ensinou o cliente a abrir o banco de dados com o `sqlite3`, até uma tabela chamada `items` que a loja não tem. Nada foi lido, porque nada pediu leitura.

O dublê pediu `file:///home/ana/agents/data/shop.db`, que é uma URI, e nada no MCP impede um modelo de escrever uma numa chamada de ferramenta. O `run()` recusa tudo o que não começa com `help://` antes de qualquer servidor ser perguntado, e o modelo recebeu um resultado com erro dizendo isso. A resposta do dublê estava escrita no arquivo; a recusa, o resultado com erro e a linha de auditoria da seção 07 são do hospedeiro. A checagem fica no hospedeiro porque o hospedeiro é onde o pedido vira ação; o servidor shop também teria recusado (ele só serve `help://`), mas um hospedeiro que dependesse disso estaria confiando que todo servidor que ele conecta tem o mesmo cuidado.

O mesmo padrão serve para qualquer recurso que um hospedeiro expõe: **decida que URIs o modelo pode levar o hospedeiro a ler**, por esquema, por servidor, por padrão, e recuse o resto no código do hospedeiro. A aula 17 testa essa fronteira com uma instrução escondida num documento, contra o próprio laboratório do curso.
