---
title: Quando uma medida engana
version: 1
---

Cada uma das três medidas tem um jeito de dizer algo falso, e cada falha tem um formato
reconhecível.

## O MAPE pune mais o mesmo erro quando o real é baixo

```schooling-example
{"language": "python", "file": "mape_trap.py", "parts": [{"code": "import numpy as np\n\nprint(\"the same miss of 50 orders, against two actual values\")\nfor actual, forecast in [(150, 100), (50, 100)]:\n    print(f\"  actual {actual:3}, forecast {forecast}: error {abs(forecast - actual)}, \"\n          f\"{abs(forecast - actual) / actual:.0%} of the actual\")", "note": "Uma previsão de 100, errando por 50 em cada direção."}, {"code": "actual = np.array([3, 1, 0, 2])\nforecast = np.array([2, 2, 2, 2])\nwith np.errstate(divide=\"ignore\"):\n    print(\"\\nsmall counts:\", np.abs(forecast - actual) / actual)", "note": "Quatro dias de um produto que vende um punhado por dia, um deles nenhum. O `errstate` silencia o aviso do numpy sobre divisão por zero, para que o resultado em si seja o que aparece."}], "output": "the same miss of 50 orders, against two actual values\n  actual 150, forecast 100: error 50, 33% of the actual\n  actual  50, forecast 100: error 50, 100% of the actual\n\nsmall counts: [0.33333333 1.                inf 0.        ]"}
```

**O mesmo erro de 50 pedidos conta como 33 por cento quando a semana veio movimentada e 100 por
cento quando veio calma.** Então um modelo que prevê baixo é penalizado menos, em média, que um que
prevê alto pelo mesmo tanto, e escolher modelos pelo MAPE favorece em silêncio os que preveem baixo.
Se prever baixo quer dizer faltar ingrediente, esse é o lado errado para pender.

## O MAPE quebra com números pequenos

A segunda metade da saída mostra o outro problema. Um dia com uma venda errado por um é um erro de
100 por cento; um dia com nenhuma não pode ser dividido, e o numpy devolve `inf`, infinito, o que
torna a média infinita. **O MAPE é inutilizável em séries com zeros ou contagens muito pequenas**: um
produto numa região pequena, as horas da madrugada, uma loja nova. Use o MAE ali, ou divida o erro
absoluto total pelo total real, uma medida muitas vezes chamada de **WAPE**, erro percentual absoluto
ponderado, que só falha se tudo for zero.

## RMSE e MAE ficam na unidade da própria série

Um RMSE de 460 pedidos é bom para uma série de dez mil por semana e péssimo para uma de quinhentos.
**Nenhum dos dois pode ser comparado entre séries de tamanhos diferentes**, e é por isso que o MAPE,
com todos os defeitos, sobrevive: é o único dos três que um gerente consegue comparar entre as
regiões da Panela. Quando as regiões são grandes o bastante para não ter zeros, esse é um uso
legítimo.

## Toda medida pode ser manipulada pela escolha do teste

Um modelo medido nas semanas em que foi ajustado parece melhor do que é. Um modelo medido num trecho
calmo parece melhor que um medido no Natal. **Fixe o período de teste antes de olhar os resultados**,
use semanas que os modelos nunca viram, e meça todo candidato nas mesmas semanas. A próxima seção
leva isso um passo adiante.
