---
title: Coortes que ainda não terminaram
version: 1
---

**Uma coorte só pode ser observada pelo tempo que ela existe.** A coorte de janeiro de 2024 tem dois
anos de dado; a de junho de 2025 tem seis meses; a de dezembro de 2025 tem um. É por isso que o mapa
de calor de duas seções atrás é um triângulo: as células abaixo da diagonal ainda não aconteceram. Os
estatísticos chamam isso de **censura à direita**, porque o que falta está à direita, no futuro.

A censura causa dois tipos de erro.

## O mês ainda em andamento

A célula mais nova de cada coorte muitas vezes é um mês que não terminou. Isto roda a mesma conta do
mês 1 duas vezes, uma com os pedidos conhecidos em 15 de dezembro de 2025 e outra no fim do mês:

```schooling-example
{"language": "python", "file": "censor.py", "parts": [{"code": "import pandas as pd\n\ncustomers = pd.read_csv(\"customers.csv\", parse_dates=[\"signup\"])\norders = pd.read_csv(\"orders.csv\", parse_dates=[\"date\"])\norders = orders.merge(customers[[\"customer\", \"signup\"]], on=\"customer\")\norders[\"cohort\"] = orders[\"signup\"].dt.to_period(\"M\")\nsize = customers.groupby(customers[\"signup\"].dt.to_period(\"M\")).size()"}, {"code": "def month_one(data):\n    later = data[data[\"date\"].dt.to_period(\"M\") == data[\"cohort\"] + 1]\n    return (later.groupby(\"cohort\")[\"customer\"].nunique() / size * 100).round(1)", "note": "Retenção no mês 1 por coorte: a fração que pediu no mês de calendário seguinte ao cadastro."}, {"code": "final = month_one(orders)\nmid_december = month_one(orders[orders[\"date\"] <= \"2025-12-15\"])\ntable = pd.DataFrame({\"run on 15 Dec\": mid_december, \"run on 31 Dec\": final})\nprint(table.loc[\"2025-08\":\"2025-11\"].rename_axis(\"cohort\").to_string())", "note": "A mesma conta rodada com os pedidos conhecidos em 15 de dezembro e em 31 de dezembro."}], "output": "         run on 15 Dec  run on 31 Dec\ncohort                               \n2025-08           91.0           91.0\n2025-09           92.5           92.5\n2025-10           87.8           87.8\n2025-11           81.0           92.0"}
```

Em 15 de dezembro, **a retenção no mês 1 da coorte de novembro aparece como 81,0 por cento**, um
desabamento em relação às coortes anteriores. No fim do mês ela aparece como 92,0. Nada aconteceu com
os clientes de novembro: metade do mês 1 deles ainda não tinha acontecido. É o dado incompleto da aula
6 de novo, agora dentro de uma tabela de coortes, e a solução é a mesma: **deixe de fora células cujo
período não terminou**, ou pinte-as de cinza e diga por quê.

## Tirar a média de colunas de comprimentos diferentes

O segundo erro é a média. "Retenção média no mês 6" em todas as coortes só pode usar as coortes com
pelo menos seis meses, então descreve só as mais antigas. Uma "curva média de retenção" montada tirando
a média de cada coluna usa um conjunto diferente de coortes em cada coluna: o mês 1 tira a média das
dezoito coortes do mapa de calor, o mês 12 só das doze de 2024, e se as coortes mais novas se
comportam diferente, a curva dobra onde o conjunto de coortes muda e não onde o comportamento muda.

As práticas seguras:

- **compare coortes nas idades a que todas chegaram**, e diga quais são;
- **ao tirar a média de uma curva, use as mesmas coortes em toda coluna**, aceitando uma curva mais
  curta;
- **pondere pelo tamanho da coorte** quando os tamanhos diferem muito, ou uma coorte pequena mexe na
  média tanto quanto uma grande.
