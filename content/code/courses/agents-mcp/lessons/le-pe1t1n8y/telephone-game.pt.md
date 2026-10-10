---
title: O telefone sem fio
version: 2
---

A informação se degrada a cada reconto, e numa cadeia de agentes ninguém depois consegue perceber: o agente que escreve a resposta final só sabe o que chegou até ele atravessando uma fronteira. A seção 04 já mostrou uma forma disso, um orquestrador que largou metade do que os especialistas acharam. Eis outra pergunta, se os dois pedidos, M-1043 e M-1048, estão a caminho:

```
ana@lab:~/agents$ python multi.py "Are both of my orders, M-1043 and M-1048, on their way?"
orchestrator -> ask_orders({"question": "Are both of my orders, M-1043 and M-1048, on their way?"})
    orders -> get_order({"order_id": "M-1043"})
    orders -> get_order({"order_id": "M-1048"})
    orders: Order M-1043 is on its way and has a tracking number BR5512340003. Order M-1048 was cancelled, so it is not on its way.
orchestrator: To answer the user's question about their orders, I will use the output from the tool call to format the response.

"Hello, I'm happy to help you with your orders. Order M-1043 is currently on its way and you can track its progress with the tracking number BR5512340003. Unfortunately, Order M-1048 was cancelled, so it will not be arriving. If you have any further questions or concerns, please don't hesitate to ask. Is there anything else I can assist you with today?"
```

O especialista se saiu bem: consultou os dois pedidos e disse, corretamente, que um está a caminho e o outro foi cancelado. O orquestrador então começou a resposta com *"To answer the user's question about their orders, I will use the output from the tool call to format the response"*, que é a linha de instrução do próprio template de conversa do `llama3.2:3b` (a seção 07 da aula 1 a imprimiu), repetida como se fizesse parte da resposta, e pôs a resposta de verdade entre aspas depois dela. Os fatos sobreviveram desta vez e a forma não; um cliente leria as anotações do modelo para si mesmo.

Um modelo comprime, larga e reformula a cada salto, e um resumo descuidado é o caso para o qual desenhar: dois resultados espremidos numa frase tranquilizadora, *"I found no problems with either"*, quando um deles é um cancelamento. Um orquestrador que só vê essa frase não tem como saber o que ela esconde.

## Anexar a evidência

A correção não é um prompt mais bem escrito pedindo cuidado ao especialista. É mandar os fatos pela fronteira junto com o resumo. Com `--evidence`, a `ask()` acrescenta à resposta do especialista toda chamada que ele fez e o começo de cada resultado, e quem faz isso é o hospedeiro, então o especialista não tem como deixar nada de fora:

```
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python multi.py "Are both of my orders, M-1043 and M-1048, on their way?" --evidence
orchestrator -> ask_orders({"question": "Are both of my orders, M-1043 and M-1048, on their way?"})
    orders -> get_order({"order_id": "M-1043"})
    orders -> get_order({"order_id": "M-1048"})
    orders: M-1043 is on its way, but M-1048 was cancelled.
orchestrator: I apologize for the inconvenience, but your order M-1048 has been cancelled. On the other hand, your order M-1043 is currently on its way and should be delivered soon. I'll make sure to keep you updated on the status of your orders. Is there anything else I can assist you with?
ana@lab:~/agents$ python -c 'import json; r = [json.loads(l)["request"] for l in open("requests.jsonl")]; o = [x for x in r if "orchestrator" in x["system"]][-1]; [print(b["content"]) for b in o["messages"][-1]["content"]]'
M-1043 is on its way, but M-1048 was cancelled.
Evidence:
get_order {"order_id": "M-1043"} -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "status": "shipped", "delivered_on": null,
get_order {"order_id": "M-1048"} -> {"id": "M-1048", "customer_id": "c-102", "placed_on": "2026-09-30", "status": "cancelled", "delivered_on": nul
```

O último comando lê o arquivo do gravador e imprime exatamente o que o orquestrador recebeu como resultado da ferramenta: a frase do especialista e, embaixo dela, os dois resultados que ela deveria resumir, com `"status": "cancelled"` bem à vista. Quem os anexou foi o hospedeiro, não o especialista, então eles chegam diga o que disser a frase acima deles. A frase deste especialista estava correta; uma descuidada teria sido conferida contra as linhas abaixo dela.

**O especialista não melhorou; a fronteira melhorou.** Evidência custa tokens, duas linhas de resultados aqui, e deveria ser aparada para os campos que importam (o conselho da aula 3 sobre observações vale de novo). O que ela compra é que o agente que escreve a resposta final trabalha a partir dos fatos, e não da impressão de outro modelo sobre eles, e que quem ler o rastro depois vê tanto o resumo quanto o que ele resumiu.
