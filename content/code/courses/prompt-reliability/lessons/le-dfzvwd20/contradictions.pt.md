---
title: Duas instruções que discordam
version: 2
---

Duas linhas do `v2-long.txt` falam do tamanho do resumo. Foram escritas para reclamações
diferentes e as duas parecem razoáveis:

```
ana@lab:~/triage$ grep -n -e brief -e detail prompts/v2-long.txt
4:Keep the summary brief so the team can scan the queue quickly.
16:The team reads the summary instead of the message, so describe the problem in full detail.
```

A linha 4 quer um resumo que a equipe consiga percorrer rápido. A linha 16, acrescentada depois
por alguém cuja reclamação era que o resumo deixava coisas de fora, quer o problema em todos os
detalhes. **Ninguém consegue obedecer às duas, então o modelo escolhe, e você não tem voz nisso.**

Aqui estão duas mensagens com o prompt curto, que pede uma frase, e com o longo:

```
ana@lab:~/triage$ grep t17 cases/dev.jsonl
{"id": "t17", "message": "My order was dispatched ten days ago and still hasn't arrived. I need it for a birthday on Saturday.", "expect": {"category": "delivery", "urgency": "high"}}
ana@lab:~/triage$ pl show runs/v2.jsonl t17
│ {"category": "delivery", "urgency": "high", "summary": "Order has not arrived ten days after dispatch and is needed for a birthday on Saturday"}
stop: stop, tokens in 114, out 35, 3.6 s
ana@lab:~/triage$ pl show runs/long.jsonl t17
│ {"category": "delivery", "urgency": "high", "summary": "Order has not arrived 10 days after dispatch and is needed for a birthday on Saturday"}
stop: stop, tokens in 211, out 36, 4.2 s
ana@lab:~/triage$ pl show runs/v2.jsonl t23
│ {"category": "returns", "urgency": "high", "summary": "Customer is reporting a damaged parcel with ruined books and wants to initiate a return process."}
stop: stop, tokens in 106, out 36, 4.0 s
ana@lab:~/triage$ pl show runs/long.jsonl t23
│ {"category": "returns", "urgency": "high", "summary": "Received damaged parcel with water-soaked books"}
stop: stop, tokens in 203, out 27, 3.2 s
```

O `t17` voltou quase palavra por palavra igual com os dois prompts. O `t23` voltou **mais curto**
com o prompt que pede todos os detalhes: o prompt curto escreveu *"Customer is reporting a damaged
parcel with ruined books and wants to initiate a return process"*, o longo *"Received damaged
parcel with water-soaked books"*. Nessa mensagem a linha 4 venceu. Nas quarenta, a resposta média
cresceu de 30,6 tokens para 33,6, então em algumas outras a linha 16 venceu.

**É isso que uma contradição compra: regra nenhuma.** Qual de duas instruções em conflito um modelo
segue depende do modelo, da redação, de onde cada uma está e da mensagem à frente dele, e pode mudar
quando o modelo for atualizado. Você não consegue ler a resposta no prompt, e também não consegue
lê-la numa resposta só: o `t23` sozinho diz que a brevidade venceu, a média diz que o detalhe venceu.

## O que custa

O desacordo é decidido de novo em toda chamada, pelo que o modelo calhar de pesar mais naquela
mensagem, e você paga de dois jeitos. A saída a mais é pequena aqui, três tokens por resposta,
porque as mensagens do conjunto de teste são curtas e todos os detalhes acrescentam no máximo uma
oração; uma caixa de entrada com parágrafos aumentaria a diferença. O custo maior é que **o tamanho
de um resumo deixou de ser uma coisa que você decidiu**, então nada adiante pode contar com ele.

Os guias que a Anthropic e a OpenAI publicam sobre escrever prompts abrem com o mesmo conselho:
seja claro e direto sobre o que você quer. Um prompt que pede duas coisas incompatíveis é o jeito
mais simples de não ser claro, e a correção não é uma terceira linha dizendo qual vence. **Cada
instrução sozinha dá uma resposta que você escolheu; as duas juntas dão uma que o modelo
escolheu.** Decida, e apague a outra.
