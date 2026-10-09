---
title: A linha de auditoria
version: 2
---

Toda chamada que chegou ao `run()` escreveu uma linha no `host-audit.jsonl`, acontecesse o que acontecesse com ela:

```
ana@lab:~/agents$ cat host-audit.jsonl
{"server": "shop", "tool": "get_order", "arguments": {"order_id": "M-1043"}, "approved": true, "is_error": false}
{"server": "shop", "tool": "search_help", "arguments": {"query": "send book back"}, "approved": true, "is_error": false}
{"server": "shop", "tool": "search_help", "arguments": {"query": "file:///home/ana/agents/data/shop.db"}, "approved": true, "is_error": false}
{"server": "shop", "resource": "file:///home/ana/agents/data/shop.db", "approved": false}
{"server": "refunds", "tool": "refund", "arguments": {"reason": "damaged", "order_id": "M-1047", "cents": "0"}, "approved": false}
{"server": "refunds", "tool": "refund", "arguments": {"cents": 0, "order_id": "M-1047", "reason": "damaged"}, "approved": true, "is_error": true}
{"server": "refunds", "tool": "refund", "arguments": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}, "approved": true, "is_error": false}
```

Sete linhas para as execuções desta aula: a consulta, as duas buscas, a leitura recusada de uma URI `file://`, o reembolso recusado, o reembolso aprovado de 0 centavos que o servidor rejeitou e o aprovado de 3890. Cada uma diz qual servidor, qual ferramenta ou recurso, os argumentos, se foi aprovada e se o resultado foi um erro. As execuções do dublê estão lá ao lado das do modelo real, porque o hospedeiro escreve uma linha para toda chamada, seja quem for que pediu.

Três propriedades fazem valer a pena tê-la. **Ela é escrita pelo hospedeiro**, o único componente que vê toda chamada, de todo servidor. **Ela registra recusas**, o que um log escrito pelos servidores não conseguiria: o reembolso recusado nunca chegou ao `refunds`, e a URI `file://` nunca chegou a ninguém. E **ela registra argumentos**, porque "um reembolso foi aprovado" serve menos que "0 centavos no M-1047, aprovado, e rejeitado pelo servidor", que é a linha que mostra que uma pessoa disse sim sem ler.

Ela também é dado pessoal, como a aula 8 disse dos rastros: os argumentos incluem ids de pedido, e poderiam incluir qualquer coisa que um cliente digitou. Guarde-a onde fica o resto desses dados, e apague-a no mesmo prazo. A regra deste repositório para as próprias escritas administrativas, de que toda uma registra quem a fez (`internal/audit`), é o modelo sobre o qual a aula 17 constrói.
