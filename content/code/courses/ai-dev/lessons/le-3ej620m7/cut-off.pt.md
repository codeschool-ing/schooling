---
title: Quando a resposta é cortada
version: 1
---

Uma resposta termina por um entre poucos motivos, e a resposta diz qual em **`stop_reason`**. Os
dois que você encontra em toda aplicação são `end_turn`, quando o modelo decidiu que tinha
terminado, e `max_tokens`, quando não tinha e acabou o espaço que a requisição deu. **Uma resposta
que parou em `max_tokens` está inacabada**, e o bug mais comum em código em volta de um modelo é
tratá-la como se não estivesse.

## A mesma pergunta com espaço de menos

O `lab/cutoff.py` pede ao `scripted-1` que explique a regra de frete da loja e imprime por que ele
parou. A explicação é texto escrito pelo curso; o corte é do labllm, feito exatamente no número de
tokens que a requisição permitiu:

```python
import sys

import anthropic

client = anthropic.Anthropic()
r = client.messages.create(model="scripted-1", max_tokens=int(sys.argv[1]),
                           messages=[{"role": "user", "content": "Explain the shop's shipping rule."}])
print(f"stop_reason={r.stop_reason} output_tokens={r.usage.output_tokens}")
print(r.content[0].text)
if r.stop_reason == "max_tokens":
    print("!! the reply was cut off; do not use it as if it were complete")
```

```
ana@dev:~/shop$ python lab/cutoff.py 40
stop_reason=max_tokens output_tokens=40
The cart charges a flat 15.00 for shipping, and nothing at all once the order reaches 200.00. The threshold is checked after the discount, not before it: a cart of
!! the reply was cut off; do not use it as if it were complete
ana@dev:~/shop$ python lab/cutoff.py 300
stop_reason=end_turn output_tokens=147
The cart charges a flat 15.00 for shipping, and nothing at all once the order reaches 200.00. The threshold is checked after the discount, not before it: a cart of 210.00 with a 10% coupon comes to 189.00 and pays shipping again. Every amount is held in integer cents, so 15.00 is the constant SHIPPING = 1500 and 200.00 is FREE_SHIPPING_FROM = 20000, both in shop/cart.py. The rule lives in Cart.shipping(), which Cart.total() calls after subtracting the discount. If you change the threshold, test_free_shipping_from_200 in tests/test_cart.py is the test that should change with it.
```

Quarenta tokens terminam no meio de uma frase: *a cart of*. Aqui o corte é óbvio porque uma pessoa
consegue ler. Ele deixa de ser óbvio quando a resposta é para um programa. **JSON cortado em
`max_tokens` não é JSON**, uma lista cortada é uma lista mais curta que parece completa, e código
cortado ainda pode ser código válido sem o último ramo. Só o `stop_reason` separa uma coisa da
outra.

## O que fazer com o `max_tokens`

Decida por ponto de chamada, e escreva a decisão:

- **Dê espaço à resposta.** O `max_tokens` é um teto, não uma meta: você paga pelos tokens que o
  modelo escreve, não pelo espaço que permitiu. Um teto um pouco acima da maior resposta esperada
  não custa nada a mais nas respostas mais curtas.
- **Trate `max_tokens` como erro onde a completude importa.** Uma resposta estruturada (aula 8) que
  parou ali é uma chamada que falhou: tente de novo com mais espaço ou informe a falha, nunca a
  interprete.
- **Continue, quando o texto é prosa.** Mande a resposta parcial de volta como começo do turno do
  assistente e peça o resto. Funciona porque o modelo continua a partir de qualquer texto que
  receba, que a aula 1 seção 06 fez ser a definição de um modelo.

## Parando de propósito

O `stop_sequences` termina a resposta antes, numa sequência que você escolhe, e informa isso:

```
ana@dev:~/shop$ python -c 'import anthropic; r = anthropic.Anthropic().messages.create(model="tiny-1", max_tokens=60, stop_sequences=["\n\n"], messages=[{"role": "user", "content": "Return the"}]); print(r.stop_reason, repr(r.stop_sequence)); print(repr(r.content[0].text))'
stop_sequence '\n\n'
' number of data.\nmode                Mode (most common values of data.\nstdev               Sample standard deviation.'
```

O `stop_reason` é `stop_sequence`, o `stop_sequence` diz qual casou, e a própria sequência não está
no texto. Uma sequência de parada é útil quando a saída tem um marcador natural de fim, como uma tag
de fechamento que você pediu, e sai mais barato que deixar o modelo escrever além dela e cortar o
resto.

Os outros valores de `stop_reason` pertencem a aulas seguintes: `tool_use`, quando o modelo parou
para pedir uma ferramenta (aula 8), e `refusal`, que alguns provedores usam quando um sistema de
segurança encerrou a resposta. **Trate cada valor que você conhece e falhe alto em qualquer um que
não conhece**, porque a lista cresce a cada versão nova da API.
