---
title: Um limiar por grupo
version: 1
---

A correção mais rápida que um analista consegue fazer sem retreinar nada é **mover o limiar do grupo
sobre o qual o modelo erra**. Se os clientes fiéis do Norte recebem riscos altos demais, exija um risco
maior antes de marcar alguém no Norte. O programa testa isso nas notas da aula 17.

```schooling-example
{"language": "python", "file": "north_threshold.py", "parts": [{"code": "import pandas as pd\n\nscored = pd.read_csv(\"scored.csv\", index_col=\"customer\")\nnorth = scored[scored[\"region\"] == \"North\"]\nstayed, churned = north[north[\"churned\"] == 0], north[north[\"churned\"] == 1]", "note": "As notas da aula 17 de novo, só do Norte."}, {"code": "print(\"threshold for the North   false alarms among stayers   recall\")\nfor threshold in (0.2, 0.3, 0.4, 0.5):\n    fa = (stayed[\"risk\"] >= threshold).mean()\n    rec = (churned[\"risk\"] >= threshold).mean()\n    print(f\"{threshold:24.2f}   {fa:26.1%}   {rec:6.1%}\")", "note": "Sobe o limiar do Norte passo a passo e observa as duas taxas de erro dele."}], "output": "threshold for the North   false alarms among stayers   recall\n                    0.20                        22.0%    58.8%\n                    0.30                        15.0%    58.8%\n                    0.40                        11.0%    52.9%\n                    0.50                         6.0%    52.9%"}
```

Para trazer os alarmes falsos do Norte até os das outras regiões, de 6,2% a 9,2%, o limiar precisa
subir até cerca de 0,5. No caminho, a revocação do Norte cai de 58,8% para 52,9%, um cliente de 17, o
que de novo é pouco demais para ler.

Funciona no número. Mesmo assim é a correção mais fraca, por três motivos.

- **Trata o sintoma.** O modelo continua lendo um ritmo lento como esfriamento. Reuse-o em outra
  decisão e o problema volta, sem nada no modelo para avisar alguém.
- **Usa o grupo explicitamente.** Dois clientes com o mesmo risco são tratados diferente por causa de
  onde moram. Dá para defender isso, como correção de uma falha conhecida, mas tem de ser defendido,
  por escrito, e em alguns tipos de decisão e alguns países não é permitido.
- **Precisa que o grupo seja conhecido e grande o bastante para afinar.** Um limiar ajustado em 100
  clientes fiéis é ele próprio um número ruidoso, e para um grupo que ninguém pensou em checar não há
  limiar nenhum.

Um limiar por grupo é um remendo razoável quando a causa não se alcança a tempo, aplicado às claras
enquanto a correção de verdade é construída. Como resposta permanente, esconde uma falha que o próximo
uso do modelo vai achar de novo.
