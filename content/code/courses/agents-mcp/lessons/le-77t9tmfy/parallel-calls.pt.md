---
title: Duas chamadas numa resposta
version: 1
---

Um modelo pode pedir várias ferramentas numa resposta quando as chamadas não dependem umas das outras. Perguntado sobre dois pedidos, não há motivo para consultar o primeiro, esperar e depois consultar o segundo. **O curso roteirizou o substituto para pedir os dois de uma vez**, como fazem os modelos atuais:

```
ana@lab:~/agents$ python agent.py "What is the status of my orders M-1043 and M-1048?"
[1] get_order({"order_id": "M-1043"}) -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "s
[1] get_order({"order_id": "M-1048"}) -> {"id": "M-1048", "customer_id": "c-102", "placed_on": "2026-09-30", "s
[2] answer: M-1043 has shipped (tracking BR5512340003). M-1048 was cancelled, so nothing from it will arrive.
```

As duas chamadas levam o número de passo `[1]`: uma resposta, dois blocos `tool_use`, dois resultados mandados de volta juntos numa mensagem. A execução levou dois pedidos em vez de três. Com a regra de tempo do laboratório isso economiza o tempo de um pedido; com ferramentas que levam segundos cada, como buscar uma página ou um banco lento, rodá-las ao mesmo tempo no hospedeiro economiza também o tempo da mais lenta. O `agent.py` as roda uma depois da outra, o que é correto e simples; a aula 18 mede o que a concorrência compra.

## Toda chamada recebe o seu resultado

A API exige que todo `tool_use` de uma resposta seja respondido por um `tool_result` com o seu id na mensagem imediatamente seguinte. O `--drop-one` manda de volta só o primeiro resultado, o bug de um hospedeiro que para de processar os blocos de uma resposta depois do primeiro, ou que, quando uma ferramenta levanta erro, pula o resto:

```
ana@lab:~/agents$ python agent.py "What is the status of my orders M-1043 and M-1048?" --drop-one 2>&1 | tail -n 1
anthropic.BadRequestError: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'messages.2: tool_use ids were found without tool_result blocks immediately after: toolu_lab_0012_2'}, 'request_id': 'req_lab_0013'}
```

O labllm recusa a conversa como a API da Anthropic recusa: `messages.2` (a terceira mensagem, contando do zero) tem uma chamada cujo id nunca recebeu resultado. **A correção é nunca descartar uma chamada em silêncio.** Se uma ferramenta não pode rodar, mande um resultado mesmo assim, marcado como erro, dizendo por quê (*"não executada: a chamada anterior falhou"*). O modelo então sabe o que aconteceu com cada pedido que fez.

## Quando não rodar chamadas juntas

Leituras independentes podem rodar juntas sem risco. Chamadas que dependem umas das outras, ou que escrevem, não deveriam, mesmo que um modelo as peça numa resposta. Um reembolso e a consulta que o justifica vêm nessa ordem, e dois reembolsos do mesmo pedido numa resposta são mais provavelmente um erro que um plano. Um hospedeiro pode rodar leituras ao mesmo tempo e escritas uma de cada vez, ou recusar uma resposta que peça mais de uma escrita.
