---
title: Conferir a divisão antes de ler o resultado
version: 1
---

Antes de alguém olhar a conversão, duas conferências dizem se a aleatorização funcionou. Levam um
minuto e pegam as falhas que tornam sem sentido todo número posterior.

```schooling-example
{"language": "python", "file": "srm.py", "parts": [{"code": "import pandas as pd\nfrom scipy.stats import chisquare\n\nvisits = pd.read_csv(\"experiment.csv\")\ncounts = visits[\"group\"].value_counts()\nprint(counts.to_string())\nresult = chisquare(counts.values)\nprint(f\"chi-square {result.statistic:.2f}, p = {result.pvalue:.3f}\")", "note": "O teste de desequilíbrio da amostra: um teste qui-quadrado comparando os tamanhos observados dos grupos com uma divisão igual, o teste da aula 16 de `statistics`."}, {"code": "print(\"\\nshare on mobile, by group\")\nprint(visits.groupby(\"group\")[\"device\"].apply(lambda d: (d == \"mobile\").mean()).round(4).to_string())", "note": "Uma conferência de equilíbrio: algo que o tratamento não consegue mudar deveria ser igual nos dois grupos."}, {"code": "broken = chisquare([50412, 48950])\nprint(f\"\\nanother test, 50,412 against 48,950: chi-square {broken.statistic:.2f}, p = {broken.pvalue:.1e}\")", "note": "A mesma conferência nas contagens de um teste cuja divisão quebrou."}], "output": "group\nnew    25392\nold    25008\nchi-square 2.93, p = 0.087\n\nshare on mobile, by group\ngroup\nnew    0.6802\nold    0.6806\n\nanother test, 50,412 against 48,950: chi-square 21.51, p = 3.5e-06"}
```

## Desequilíbrio da amostra

O teste da Panela planejou uma divisão igual e teve **25.392 visitantes no grupo novo e 25.008 no
antigo**. O teste qui-quadrado pergunta quão surpreendente é uma diferença desse tamanho se a divisão
fosse de fato justa: p = 0,087. Uma moeda honesta produz uma diferença assim mais de uma vez em doze,
então não há evidência de problema.

O segundo teste é outra história: p = 3,5 × 10⁻⁶, uma diferença que uma divisão justa produziria
algumas vezes em um milhão. Isso é um **desequilíbrio da amostra**, em inglês *sample ratio mismatch*
(SRM), e quando acontece **o resultado do teste não é interpretado, diga o que disser**. Uma divisão
quebrada quase sempre quer dizer que alguns visitantes se perderam de um grupo e não do outro, e os
perdidos raramente são uma amostra aleatória: uma página de tratamento que quebra em celulares velhos
perde exatamente os visitantes menos propensos a comprar, e o tratamento parece melhor por isso.

Causas comuns que vale conhecer, porque o conserto está no encanamento e não na estatística:

- a página do tratamento carrega mais devagar e alguns visitantes saem antes de ser contados;
- um robô ou rastreador é filtrado num grupo e não no outro;
- o sorteio acontece depois de um redirecionamento que os navegadores de um grupo não seguem;
- o teste foi ligado para um grupo algumas horas antes do outro.

Como a conferência é tão barata, **usa-se um limiar rígido**, muitas vezes p abaixo de 0,001: um SRM
real produz p-valores minúsculos, e a conferência não deveria dar alarme falso teste após teste.

## Equilíbrio

A segunda conferência compara algo que o tratamento não consegue afetar. A fração de visitantes no
celular foi 0,6802 no grupo novo e 0,6806 no antigo, a quatro décimos de milésimo um do outro. Uma
diferença aqui, numa característica fixada antes de o visitante ver qualquer coisa, quereria dizer
que os grupos foram montados de jeitos diferentes. Conferir uma ou duas características assim é um
seguro barato; conferir vinte e relatar a que diferiu é o problema da aula 11 em outra forma.
