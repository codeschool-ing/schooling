---
title: Os números, todos eles
version: 1
---

As conferências da aula 9 passaram: a divisão foi justa e os grupos equilibrados. Só agora se olha
a conversão. **Um resultado é relatado como contagens, taxas, a diferença com o seu intervalo, e o
teste**, nunca só como p-valor e nunca só como alta relativa.

```schooling-example
{"language": "python", "file": "result.py", "parts": [{"code": "import pandas as pd\nfrom statsmodels.stats.proportion import confint_proportions_2indep, proportions_ztest\n\nvisits = pd.read_csv(\"experiment.csv\", parse_dates=[\"day\"])"}, {"code": "def compare(data, label):\n    groups = data.groupby(\"group\")[\"converted\"].agg([\"sum\", \"count\"])\n    new, old = groups.loc[\"new\"], groups.loc[\"old\"]\n    rate_new, rate_old = new[\"sum\"] / new[\"count\"], old[\"sum\"] / old[\"count\"]", "note": "Para cada grupo, os visitantes que converteram e o total de visitantes."}, {"code": "    z, p = proportions_ztest([new[\"sum\"], old[\"sum\"]], [new[\"count\"], old[\"count\"]])\n    low, high = confint_proportions_2indep(new[\"sum\"], new[\"count\"], old[\"sum\"], old[\"count\"])", "note": "O teste z de duas proporções da aula 16 de `statistics`, bilateral por padrão, e um intervalo de confiança de 95% para a diferença entre as duas taxas."}, {"code": "    print(label)\n    print(f\"  old {old['sum']:,} of {old['count']:,} = {rate_old:.2%}\")\n    print(f\"  new {new['sum']:,} of {new['count']:,} = {rate_new:.2%}\")\n    print(f\"  difference {100 * (rate_new - rate_old):+.2f} points, \"\n          f\"95% interval {100 * low:+.2f} to {100 * high:+.2f}\")\n    print(f\"  relative lift {rate_new / rate_old - 1:+.1%}, z = {z:.2f}, p = {p:.3f}\")", "note": "Tudo de que um leitor precisa: contagens, taxas, a diferença em pontos com o intervalo, a alta relativa, e o teste."}, {"code": "compare(visits, \"all three weeks\")\ncompare(visits[visits[\"day\"] >= \"2025-03-17\"], \"weeks 2 and 3 only\")", "note": "O teste inteiro, como planejado, e as duas semanas depois da novidade da aula 9."}], "output": "all three weeks\n  old 1,070 of 25,008 = 4.28%\n  new 1,187 of 25,392 = 4.67%\n  difference +0.40 points, 95% interval +0.03 to +0.76\n  relative lift +9.3%, z = 2.15, p = 0.032\nweeks 2 and 3 only\n  old 711 of 16,688 = 4.26%\n  new 733 of 16,912 = 4.33%\n  difference +0.07 points, 95% interval -0.36 to +0.51\n  relative lift +1.7%, z = 0.33, p = 0.739"}
```

Nas três semanas, como planejado, **o checkout novo converteu 4,67% dos visitantes e o antigo
4,28%**: uma diferença de +0,40 ponto, ou +9,3% em termos relativos. O teste dá z = 2,15 e
p = 0,032.

Nas duas últimas semanas, depois que a novidade se apagou, a diferença é de +0,07 ponto, com um
intervalo de −0,36 a +0,51, e p = 0,739.

O controle converteu 4,28%, perto dos 4,2 por cento que o plano supôs na aula 8, então o teste teve
mais ou menos o poder para o qual foi desenhado. Vale fazer essa conferência sempre: uma base longe
da do plano quer dizer que o teste foi, na prática, dimensionado para outro efeito.

As três próximas seções leem essas linhas uma a uma.
