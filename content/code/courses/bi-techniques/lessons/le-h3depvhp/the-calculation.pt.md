---
title: A conta, à mão e pela biblioteca
version: 1
---

A aritmética é curta o bastante para ser escrita, e escrevê-la é o melhor jeito de ver qual entrada
faz o quê.

```schooling-example
{"language": "python", "file": "samplesize.py", "parts": [{"code": "from math import ceil, sqrt\n\nfrom scipy.stats import norm\nfrom statsmodels.stats.power import NormalIndPower\nfrom statsmodels.stats.proportion import proportion_effectsize\n\nbaseline, mde = 0.042, 0.006\nalpha, power = 0.05, 0.80\np1, p2 = baseline, baseline + mde", "note": "As quatro entradas. O `p1` é a taxa do controle e o `p2` a do tratamento se o efeito for exatamente o MDE."}, {"code": "z_alpha = norm.ppf(1 - alpha / 2)\nz_power = norm.ppf(power)\npooled = (p1 + p2) / 2\nn = (z_alpha * sqrt(2 * pooled * (1 - pooled))\n     + z_power * sqrt(p1 * (1 - p1) + p2 * (1 - p2))) ** 2 / mde ** 2\nprint(f\"z for alpha {z_alpha:.3f}, z for power {z_power:.3f}\")\nprint(f\"by hand:     {ceil(n):,} visitors in each group\")", "note": "A fórmula padrão para comparar duas proporções. O `norm.ppf` transforma uma probabilidade numa distância na curva normal: 1,96 para 5 por cento bilateral, 0,84 para 80 por cento de poder. O quadrado do MDE no denominador é a linha a lembrar."}, {"code": "effect = proportion_effectsize(p2, p1)\nn_sm = NormalIndPower().solve_power(effect_size=effect, alpha=alpha, power=power)\nprint(f\"statsmodels: {ceil(n_sm):,} visitors in each group (effect size h = {effect:.4f})\")", "note": "O statsmodels faz isso pelo h de Cohen, um tamanho de efeito que reescala as duas proporções para a variância ficar igual em todo lugar. Uma aproximação um pouco diferente, então um número um pouco diferente."}], "output": "z for alpha 1.960, z for power 0.842\nby hand:     18,739 visitors in each group\nstatsmodels: 18,719 visitors in each group (effect size h = 0.0290)"}
```

**Cerca de dezenove mil visitantes em cada grupo**, 18.739 pela fórmula de livro e 18.719 pela
aproximação do statsmodels. A diferença de 20 visitantes não importa: um tamanho de amostra é um
número de planejamento, e a convenção é ficar com o maior e arredondar para cima.

Leia a fórmula mais uma vez pela forma. O numerador é o ruído: dois valores z para os dois riscos,
vezes a dispersão de uma proporção perto de 4 por cento. O denominador é o sinal, o MDE, **ao
quadrado**. Com todo o resto igual, a amostra cresce com o quadrado do quão pequeno é o efeito que
você quer ver.

## De onde vem a fórmula

A aula 12 de `statistics` deu o erro padrão de uma proporção, `sqrt(p(1 − p)/n)`. O teste da aula 10
vai comparar a diferença de duas taxas com o erro padrão dela; o tamanho de amostra é o `n` em que uma
diferença verdadeira de exatamente o MDE fica longe o bastante de zero para, 80 por cento das vezes,
cair além do limiar de 5 por cento. Os dois valores z são essas duas distâncias, somadas.
