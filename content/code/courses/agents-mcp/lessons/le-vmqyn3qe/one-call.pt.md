---
title: Uma chamada
version: 2
---

O hospedeiro iniciou os dois servidores, listou as ferramentas deles e perguntou ao modelo, o `llama3.2:3b`, através do gravador da aula 1:

```
ana@lab:~/agents$ python recorder.py &
ana@lab:~/agents$ export ANTHROPIC_BASE_URL=http://127.0.0.1:11435
ana@lab:~/agents$ python mcp_host.py "Where is my order M-1043?" 2> host.err
step 1: shop__get_order {"order_id": "M-1043"}
  result: {"id": "M-1043", "status": "shipped", "placed_on": "2026-09-28", "delivered_on": null, "tracking": "BR55123400
answer: Your order M-1043 has been shipped. The tracking number is BR5512340003. You can track the status of your order by visiting the tracking link or entering the tracking number on the shipping carrier's website.
```

O modelo chamou `shop__get_order` e respondeu a partir do resultado. Ninguém foi perguntado: o `get_order` é só leitura e o `shop` é um servidor em cujas dicas o hospedeiro acredita. O que chegou ao modelo foi o resultado estruturado da aula 14, em JSON, sem o `customer_id`.

O que o modelo recebeu como oferta, lido do log do gravador:

```
ana@lab:~/agents$ python -c 'import json; [print(t["name"].ljust(20), t["description"][:70]) for t in json.loads(open("requests.jsonl").readline())["request"]["tools"]]'
shop__get_order      (server shop) Look up one Marginalia order: status, dates, tracking, l
shop__search_help    (server shop) Search Marginalia's help centre by meaning. Returns titl
refunds__refund      (server refunds) Refund part or all of an order, in cents, after a mem
read_help            Read one help centre article by its help:// URI.
```

Quatro ferramentas. Três vieram dos servidores, cada uma renomeada como `servidor__ferramenta` e descrita como vinda do seu servidor, e uma, `read_help`, é do próprio hospedeiro. O renome é a lição da aula 12 posta em prática: quando dois servidores oferecem o mesmo nome, este hospedeiro oferece dois nomes diferentes, e o modelo consegue ver que servidor está escolhendo. Um hospedeiro que acrescenta servidores que os usuários instalam não deve fazer menos.
