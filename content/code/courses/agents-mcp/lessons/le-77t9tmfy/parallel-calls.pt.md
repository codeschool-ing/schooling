---
title: Duas chamadas numa resposta
version: 2
---

Um modelo pode pedir várias ferramentas numa resposta quando as chamadas não dependem umas das outras. Perguntado sobre dois pedidos, não há motivo para consultar o primeiro, esperar e depois consultar o segundo, e o `llama3.2:3b` não fez isso:

```
ana@lab:~/agents$ python agent.py "What is the status of my orders M-1043 and M-1048?"
[1] get_order({"order_id": "M-1043"}) -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "s
[1] get_order({"order_id": "M-1048"}) -> {"id": "M-1048", "customer_id": "c-102", "placed_on": "2026-09-30", "s
[2] answer: The current status of your orders are as follows:

- Order M-1043: Shipped on 2026-09-28. The book details are as follows:
  - Book ID: b13
  - Quantity: 1
  - Price in cents: 2490
  - Total price in cents: 2490
  - Book ID: b14
  - Quantity: 1
  - Price in cents: 2590
  - Total price in cents: 2590
  - Book ID: b26
  - Quantity: 1
  - Price in cents: 5990
  - Total price in cents: 5990
  - Total price for order M-1043: 11070 cents

- Order M-1048: Cancelled on 2026-09-30. There is no tracking information available.
```

As duas chamadas levam o número de passo `[1]`: uma resposta, dois blocos `tool_use`, dois resultados mandados de volta juntos numa mensagem. A execução levou dois pedidos em vez de três. Com ferramentas que levam segundos cada, como buscar uma página ou um banco lento, rodá-las ao mesmo tempo no hospedeiro economiza também o tempo da mais lenta. O `agent.py` as roda uma depois da outra, o que é correto e simples; a aula 18 mede o que a concorrência compra. (A resposta depois recita cada linha do M-1043 em centavos, o que ninguém pediu: a observação as trazia, e a seção 07 da aula 3 é sobre o que deixar de fora de uma.)

## Toda chamada recebe o seu resultado

A API da Anthropic exige que todo `tool_use` de uma resposta seja respondido por um `tool_result` com o seu id na mensagem imediatamente seguinte, e recusa o pedido com um `400` que nomeia a chamada quando falta um. O `--drop-one` manda de volta só o primeiro resultado, o bug de um hospedeiro que para de processar os blocos de uma resposta depois do primeiro, ou que, quando uma ferramenta levanta erro, pula o resto. Um modelo que pede duas coisas de uma vez em toda execução deixa o bug fácil de ver, então esta parte usa o dublê, com duas chamadas escritas numa resposta. Salve-o como `~/agents/parallel.json`:

```json
{"M-1043 and M-1048": [
  [{"tool": "get_order", "input": {"order_id": "M-1043"}},
   {"tool": "get_order", "input": {"order_id": "M-1048"}}],
  {"text": "M-1043 has shipped (tracking BR5512340003). M-1048 was cancelled, so nothing from it will arrive."}
 ]
}
```

```
ana@lab:~/agents$ python standin.py parallel.json &
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11436 python agent.py "What is the status of my orders M-1043 and M-1048?"
[1] get_order({"order_id": "M-1043"}) -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "s
[1] get_order({"order_id": "M-1048"}) -> {"id": "M-1048", "customer_id": "c-102", "placed_on": "2026-09-30", "s
[2] answer: M-1043 has shipped (tracking BR5512340003). M-1048 was cancelled, so nothing from it will arrive.
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11436 python agent.py "What is the status of my orders M-1043 and M-1048?" --drop-one
[1] get_order({"order_id": "M-1043"}) -> {"id": "M-1043", "customer_id": "c-102", "placed_on": "2026-09-28", "s
[1] get_order({"order_id": "M-1048"}) -> {"id": "M-1048", "customer_id": "c-102", "placed_on": "2026-09-30", "s
[2] answer: M-1043 has shipped (tracking BR5512340003). M-1048 was cancelled, so nothing from it will arrive.
```

As duas execuções imprimem o mesmo, e esse é o problema. Na segunda, o hospedeiro rodou as duas consultas, mandou de volta só o resultado do M-1043, e a resposta ainda informa o status do M-1048. **Nada a recusou.** Nem o Ollama nem o dublê conferem a regra que a API da Anthropic impõe; a resposta do dublê foi escrita de antemão, e um modelo real no mesmo lugar tem duas escolhas, ambas ruins: dizer que não encontra o M-1048, ou adivinhar. Essa recusa vale a pena, e um hospedeiro que fala com um modelo que não a impõe precisa impô-la ele mesmo. **Nunca descarte uma chamada em silêncio.** Se uma ferramenta não pode rodar, mande um resultado mesmo assim, marcado como erro, dizendo por quê (*"não executada: a chamada anterior falhou"*). O modelo então sabe o que aconteceu com cada pedido que fez.

## Quando não rodar chamadas juntas

Leituras independentes podem rodar juntas sem risco. Chamadas que dependem umas das outras, ou que escrevem, não deveriam, mesmo que um modelo as peça numa resposta. Um reembolso e a consulta que o justifica vêm nessa ordem, e dois reembolsos do mesmo pedido numa resposta são mais provavelmente um erro que um plano. Um hospedeiro pode rodar leituras ao mesmo tempo e escritas uma de cada vez, ou recusar uma resposta que peça mais de uma escrita.
