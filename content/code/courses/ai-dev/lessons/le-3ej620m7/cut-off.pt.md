---
title: Quando a resposta é cortada
version: 2
---

Uma resposta termina por um entre poucos motivos, e a resposta diz qual em **`stop_reason`**. Os
dois que você encontra em toda aplicação são `end_turn`, quando o modelo decidiu que tinha
terminado, e `max_tokens`, quando não tinha e acabou o espaço que a requisição deu. **Uma resposta
que parou em `max_tokens` está inacabada**, e o bug mais comum em código em volta de um modelo é
tratá-la como se não estivesse.

## A mesma pergunta com espaço de menos

O `~/shop/scratch/cutoff.py` manda o código do carrinho como prompt de sistema, pede ao modelo que
explique a regra de frete, e imprime por que ele parou:

```python
import sys

import anthropic

client = anthropic.Anthropic()
r = client.messages.create(model="llama3.2:3b", max_tokens=int(sys.argv[1]),
                           system=open("shop/cart.py").read(),
                           messages=[{"role": "user", "content": "Explain the shop's shipping rule."}])
print(f"stop_reason={r.stop_reason} output_tokens={r.usage.output_tokens}")
print(r.content[0].text)
if r.stop_reason == "max_tokens":
    print("!! the reply was cut off; do not use it as if it were complete")
```

```
ana@dev:~/shop$ python scratch/cutoff.py 40
ana@dev:~/shop$ python scratch/cutoff.py 400
```

Quarenta tokens terminam no meio de uma frase: *If the order's subtotal*. Aqui o corte é óbvio
porque uma pessoa consegue ler. Ele deixa de ser óbvio quando a resposta é para um programa. **JSON
cortado no `max_tokens` não é JSON**, uma lista cortada é uma lista mais curta que parece completa,
e código cortado ainda pode ser código válido a que falta o último ramo. Só o `stop_reason` separa
os casos.

**E leia a resposta completa antes de confiar nela.** Ela terminou sozinha, `end_turn`, e está
errada duas vezes: 20.000 centavos são 200,00 e não "$20", e o frete é de 15,00 fixos, não "$1.50
por unidade". O `cart.py` inteiro estava na requisição. Uma resposta completa não é uma resposta
certa, e a aula 4 é sobre conferir.

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

O `stop_sequences` encerra a resposta mais cedo, numa string que você escolhe. Aqui o modelo recebe
o pedido de uma lista de cinco e parou no número do terceiro item:

```
ana@dev:~/shop$ python -c 'import anthropic; r = anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=80, stop_sequences=["3."], messages=[{"role": "user", "content": "Write a numbered list of five fruits."}]); print(r.stop_reason, repr(r.stop_sequence)); print(repr(r.content[0].text))'
```

O texto parou onde devia, e a própria sequência não está nele. **Mas o `stop_reason` diz
`end_turn` e o `stop_sequence` é `None`.** A API da Anthropic informaria `stop_sequence` e daria o
nome da string que casou; a cópia do formato no Ollama para na string e informa a parada como se o
modelo tivesse terminado sozinho. Uma API compatível é compatível até um detalhe como este, e é por
isso que um código que se ramifica pelo `stop_reason` merece um teste contra o provedor em que vai
rodar de verdade. Uma sequência de parada é útil quando a saída tem um marcador natural de fim,
como uma tag de fechamento que você pediu, e sai mais barata que deixar o modelo escrever além dela
e cortar o resto.

Os outros valores de `stop_reason` pertencem a aulas seguintes: `tool_use`, quando o modelo parou
para pedir uma ferramenta (aula 8), e `refusal`, que alguns provedores usam quando um sistema de
segurança encerrou a resposta. **Trate cada valor que você conhece e falhe alto em qualquer um que
não conhece**, porque a lista cresce a cada versão nova da API.
