---
title: O telefone sem fio
version: 1
---

O cliente pergunta se os dois pedidos, M-1043 e M-1048, estão a caminho. O orquestrador pergunta ao especialista de pedidos; o especialista consulta os dois. **O curso roteirizou o especialista para resumir sem cuidado**, como um modelo real às vezes comprime dois resultados numa frase tranquilizadora, para mostrar o que acontece em seguida. Tudo o que o hospedeiro faz é real.

```
ana@lab:~/agents$ python multi.py "Are both of my orders, M-1043 and M-1048, on their way?"
orchestrator -> ask_orders({"question": "Are orders M-1043 and M-1048 on their way?"})
    orders -> get_order({"order_id": "M-1043"})
    orders -> get_order({"order_id": "M-1048"})
    orders: Both orders are in the system and I found no problems with either.
orchestrator: Yes, both of your orders are on their way.
```

O especialista leu `shipped` no M-1043 e `cancelled` no M-1048, e respondeu *"Both orders are in the system and I found no problems with either."* ("Os dois pedidos estão no sistema e não achei problema em nenhum."). Cada palavra disso se defende: os dois pedidos existem, e um cancelamento não é um defeito. O orquestrador, que só viu essa frase, respondeu à pergunta que recebeu: sim, os dois estão a caminho. **Cada agente se comportou de forma razoável, e o cliente ouviu algo falso**, e vai esperar uma encomenda que nunca vem.

Esse é o telefone sem fio: a informação se degrada a cada reconto, e numa cadeia de agentes ninguém depois consegue perceber. O orquestrador não tinha como saber que "nenhum problema" escondia um cancelamento, porque a única coisa que atravessou a fronteira foi o reconto.

## Anexar a evidência

A correção não é um prompt mais bem escrito pedindo cuidado ao especialista. É mandar os fatos pela fronteira junto com o resumo. Com `--evidence`, a `ask()` acrescenta à resposta do especialista toda chamada que ele fez e o começo de cada resultado, e quem faz isso é o hospedeiro, então o especialista não tem como deixar nada de fora:

```
ana@lab:~/agents$ python multi.py "Are both of my orders, M-1043 and M-1048, on their way?" --evidence
orchestrator -> ask_orders({"question": "Are orders M-1043 and M-1048 on their way?"})
    orders -> get_order({"order_id": "M-1043"})
    orders -> get_order({"order_id": "M-1048"})
    orders: Both orders are in the system and I found no problems with either.
orchestrator: Only one of them. M-1043 has shipped (tracking BR5512340003), but M-1048 was cancelled, so nothing from it is on its way.
ana@lab:~/agents$ grep -h l06-tel-orch-2 /var/log/labllm/requests.jsonl | tail -n 1 | python -c 'import json, sys; r = json.loads(sys.stdin.read()); print(r["request"]["messages"][-1]["content"][0]["content"])'
Both orders are in the system and I found no problems with either.
Evidence:
get_order {"order_id": "M-1043"} -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "shipped", "delivered_on": null,
get_order {"order_id": "M-1048"} -> {"id": "M-1048", "customer_id": "c-102", "placed_on": "2026-09-30", "status": "cancelled", "delivered_on": nul
```

O último comando imprime exatamente o que o orquestrador recebeu como resultado da ferramenta. A frase descuidada continua lá, palavra por palavra, e embaixo dela estão os dois resultados que ela deveria resumir, com `"status": "cancelled"` bem à vista. O orquestrador, roteirizado para ler a evidência quando ela está presente, respondeu certo: só um pedido está a caminho.

**O especialista não melhorou; a fronteira melhorou.** Evidência custa tokens, duas linhas de resultados aqui, e deveria ser aparada para os campos que importam (o conselho da aula 3 sobre observações vale de novo). O que ela compra é que o agente que escreve a resposta final trabalha a partir dos fatos, e não da impressão de outro modelo sobre eles, e que quem ler o rastro depois vê tanto o resumo quanto o que ele resumiu.
