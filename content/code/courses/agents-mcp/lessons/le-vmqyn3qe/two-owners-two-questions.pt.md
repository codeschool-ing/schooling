---
title: Dois donos, duas perguntas
version: 1
---

Um reembolso vai para o servidor `refunds`, cujas ferramentas o hospedeiro nunca roda sem uma pessoa. Recusado:

```
ana@lab:~/agents$ echo n | python mcp_host.py "One copy of M-1047 arrived damaged; please refund it." 2> host.err
step 1: refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}
  ? run refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}? [y/n] n
  error: Not approved by staff; nothing was done.
answer: I could not issue this refund myself; a colleague will review order M-1047 and reply to you by email.
```

O hospedeiro perguntou, a pessoa disse `n`, e a chamada nunca chegou ao servidor. O modelo leu *"Not approved by staff; nothing was done."* como resultado com erro. Aprovado:

```
ana@lab:~/agents$ printf "y\ny\n" | python mcp_host.py "One copy of M-1047 arrived damaged; please refund it." 2> host.err
step 1: refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}
  ? run refunds__refund {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}? [y/n] y
  ? the server asks: Refund 3890 cents on M-1047? [y/n] y
  result: {"result": "{\"order_id\": \"M-1047\", \"refunded\": 3890, \"left\": 3890}"}
answer: Done: 38.90 has been refunded to your original payment for the damaged copy in order M-1047.
```

A pessoa foi perguntada **duas vezes**. Primeiro pelo hospedeiro, porque a política dele diz que toda chamada ao `refunds` precisa de uma pessoa. Depois pelo servidor, durante a chamada: o `refund_mcp.py` devolve o `input_required` da aula 13 com a própria pergunta, e o `Client` a entregou ao `server_asks`, que a fez à pessoa. Só depois de dois sins o reembolso rodou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Duas perguntas sobre um reembolso, de dois donos. O hospedeiro perguntou primeiro, porque a política dele diz que as ferramentas do servidor refunds sempre precisam de uma pessoa. O servidor perguntou durante a chamada, porque o próprio código dele não reembolsa sem aprovação. Um não em qualquer uma das duas para o reembolso.\"><defs><marker id=\"l15two-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15two-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o modelo</text><text x=\"30\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">refunds__refund</text><rect x=\"200\" y=\"20\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"37.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1. o hospedeiro pergunta</text><text x=\"210\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">política: reembolso precisa de uma pessoa</text><rect x=\"200\" y=\"120\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"137.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">2. o servidor pergunta</text><text x=\"210\" y=\"153.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">código: sem aprovação, sem reembolso</text><rect x=\"490\" y=\"70\" width=\"210\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">reembolsado: 3890</text><text x=\"500\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só depois de dois sins</text><path d=\"M150 95 L200 45\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l15two-ah-amber)\"></path><path d=\"M315 70 L315 120\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l15two-ah-amber)\"></path><path d=\"M430 145 L490 95\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l15two-ah-phosphor)\"></path></svg>", "caption": "Duas regras, dois donos. Nenhum precisa confiar que o outro perguntou.", "same": ["refunds__refund"]}
```

Perguntar duas vezes não é um desenho para copiar em toda ferramenta; para a maioria, uma pergunta no lugar certo basta. Ele mostra algo que vale saber: **a regra do hospedeiro e a regra do servidor pertencem a donos diferentes**. O dono do hospedeiro decide que chamadas os usuários dele precisam confirmar; o dono do servidor decide o que o sistema dele não faz sem aprovação, seja qual for o hospedeiro que chama. Nenhum vê o código do outro, e nenhum deve contar com o outro ter perguntado. Quando os dois existem, uma pessoa pode ser perguntada duas vezes, e um hospedeiro torna isso suportável mostrando quem está perguntando, como o `ask()` faz.
