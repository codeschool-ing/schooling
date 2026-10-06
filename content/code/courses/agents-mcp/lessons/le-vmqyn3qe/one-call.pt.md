---
title: Uma chamada
version: 1
---

O hospedeiro iniciou os dois servidores, listou as ferramentas deles e perguntou ao modelo. A regra do curso fez o modelo chamar `shop__get_order`:

```
ana@lab:~/agents$ python mcp_host.py "Where is my order M-1043?" 2> host.err
step 1: shop__get_order {"order_id": "M-1043"}
  result: {"id": "M-1043", "status": "shipped", "placed_on": "2026-09-28", "delivered_on": null, "tracking": "BR55123400
answer: Order M-1043 has shipped; its tracking code is BR5512340003, and the link in your shipping email follows it.
```

**A chamada e a resposta do modelo foram escritas pelo curso**; o hospedeiro, os dois clientes e o servidor são reais. Ninguém foi perguntado: o `get_order` é só leitura e o `shop` é um servidor em cujas dicas o hospedeiro acredita. O que chegou ao modelo foi o resultado estruturado da aula 14, em JSON, sem o `customer_id`.

O que o modelo recebeu como oferta, lido do log do labllm:

```
ana@lab:~/agents$ python -c 'import json; [print(t["name"].ljust(20), t["description"][:70]) for t in json.loads(open("/var/log/labllm/requests.jsonl").readline())["request"]["tools"]]'
shop__get_order      (server shop) Look up one Marginalia order: status, dates, tracking, l
shop__search_help    (server shop) Search Marginalia's help centre by meaning. Returns titl
refunds__refund      (server refunds) Refund part or all of an order, in cents, after a mem
read_help            Read one help centre article by its help:// URI.
```

Quatro ferramentas. Três vieram dos servidores, cada uma renomeada como `servidor__ferramenta` e descrita como vinda do seu servidor, e uma, `read_help`, é do próprio hospedeiro. O renome é a lição da aula 12 posta em prática: quando dois servidores oferecem o mesmo nome, este hospedeiro oferece dois nomes diferentes, e o modelo consegue ver que servidor está escolhendo. Um hospedeiro que acrescenta servidores que os usuários instalam não deve fazer menos.
