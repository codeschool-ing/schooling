---
title: A linha de auditoria
version: 1
---

Toda chamada que chegou ao `run()` escreveu uma linha no `host-audit.jsonl`, acontecesse o que acontecesse com ela:

```
ana@lab:~/agents$ cat host-audit.jsonl
{"server": "shop", "tool": "get_order", "arguments": {"order_id": "M-1043"}, "approved": true, "is_error": false}
{"server": "shop", "tool": "search_help", "arguments": {"query": "send a book back"}, "approved": true, "is_error": true}
{"server": "shop", "resource": "help://h14", "approved": true}
{"server": "shop", "tool": "search_help", "arguments": {"query": "send a book back"}, "approved": true, "is_error": false}
{"server": "shop", "resource": "help://h14", "approved": true}
{"server": "shop", "resource": "file:///home/ana/agents/data/shop.db", "approved": false}
{"server": "refunds", "tool": "refund", "arguments": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}, "approved": false}
{"server": "refunds", "tool": "refund", "arguments": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}, "approved": true, "is_error": false}
```

Oito linhas para as execuções desta aula: a consulta, a busca que falhou e a boa, três leituras de recursos (uma recusada), o reembolso recusado e o aprovado. Cada uma diz que servidor, que ferramenta ou recurso, os argumentos, se foi aprovada e se o resultado foi um erro.

Três propriedades fazem valer a pena tê-la. **Ela é escrita pelo hospedeiro**, o único componente que vê toda chamada, de todo servidor. **Ela registra recusas**, o que um log escrito pelos servidores não conseguiria: o reembolso recusado nunca chegou ao `refunds`, e a URI `file://` nunca chegou a ninguém. E **ela registra argumentos**, porque "um reembolso foi aprovado" serve menos que "3890 centavos no M-1047, aprovado".

Ela também é dado pessoal, como a aula 8 disse dos rastros: os argumentos incluem ids de pedido, e poderiam incluir qualquer coisa que um cliente digitou. Guarde-a onde fica o resto desses dados, e apague-a no mesmo prazo. A regra deste repositório para as próprias escritas administrativas, de que toda uma registra quem a fez (`internal/audit`), é o modelo sobre o qual a aula 17 constrói.
