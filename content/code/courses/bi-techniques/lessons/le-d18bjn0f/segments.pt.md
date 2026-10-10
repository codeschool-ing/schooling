---
title: O segmento que venceu
version: 1
---

A forma mais comum do problema é a quebra por segmento. Um teste que venceu no geral é fatiado por
aparelho, dia da semana ou região para ver "onde funcionou", e alguma fatia sempre se destaca.

```schooling-example
{"language": "python", "file": "segments.py", "parts": [{"code": "import pandas as pd\nfrom statsmodels.stats.multitest import multipletests\nfrom statsmodels.stats.proportion import proportions_ztest\n\nvisits = pd.read_csv(\"experiment.csv\", parse_dates=[\"day\"])\nvisits[\"weekday\"] = visits[\"day\"].dt.day_name().str[:3]", "note": "Acrescenta o dia da semana, um jeito natural de fatiar um teste."}, {"code": "rows = []\nfor column in (\"device\", \"weekday\"):\n    for value, part in visits.groupby(column):\n        g = part.groupby(\"group\")[\"converted\"].agg([\"sum\", \"count\"])\n        _, p = proportions_ztest(g[\"sum\"].values, g[\"count\"].values)\n        lift = (g.loc[\"new\", \"sum\"] / g.loc[\"new\", \"count\"] - g.loc[\"old\", \"sum\"] / g.loc[\"old\", \"count\"])\n        rows.append((f\"{column}={value}\", round(100 * lift, 2), p))", "note": "O mesmo teste z da aula 10, rodado separadamente em cada um de nove segmentos: dois aparelhos e sete dias da semana."}, {"code": "table = pd.DataFrame(rows, columns=[\"segment\", \"lift, points\", \"p\"])\ntable[\"Holm\"] = multipletests(table[\"p\"], method=\"holm\")[1]\nprint(table.round(3).to_string(index=False))\nprint(f\"\\nsignificant at 5%: {(table['p'] < 0.05).sum()} of {len(table)} segments; \"\n      f\"after Holm: {(table['Holm'] < 0.05).sum()}\")", "note": "O `multipletests` ajusta os nove p-valores por terem sido feitas nove comparações. O método de Holm é explicado na próxima seção."}], "output": "       segment  lift, points     p  Holm\ndevice=desktop         -0.07 0.825 1.000\n device=mobile          0.62 0.006 0.056\n   weekday=Fri          0.14 0.771 1.000\n   weekday=Mon          0.31 0.531 1.000\n   weekday=Sat          0.08 0.879 1.000\n   weekday=Sun          0.07 0.884 1.000\n   weekday=Thu          0.51 0.313 1.000\n   weekday=Tue          0.70 0.136 0.954\n   weekday=Wed          0.96 0.046 0.364\n\nsignificant at 5%: 2 of 9 segments; after Holm: 0"}
```

Dois dos nove segmentos são significativos sozinhos. Um deles é o tipo de resultado que acaba num
slide: **no celular, o checkout novo subiu a conversão em 0,62 ponto, p = 0,006**, enquanto no
computador não fez nada. Ele bate com a hipótese da aula 7, de que o formulário antigo perdia gente
no celular, quase bem demais.

**É ruído.** O `panela.py` dá à página nova exatamente o mesmo efeito em todo aparelho; ele nem olha o
aparelho ao decidir quem converte. Uma distância desse tamanho no celular apareceu por acaso entre
nove fatias, e o resultado de quarta-feira, 0,96 ponto com p = 0,046, é a mesma coisa num dia da
semana sobre o qual ninguém tinha teoria. Depois da correção da última coluna, **nenhum dos dois é
significativo**: o p ajustado do segmento de celular é 0,056.

O achado do celular é perigoso justamente por caber numa história. Um segmento que confirma o que o
time já acreditava é conferido menos que um que surpreende, e tem exatamente a mesma chance de ser
acaso. O uso honesto dele é uma hipótese nova, "o checkout de um passo ajuda mais no celular",
testada num experimento novo desenhado para essa pergunta.
