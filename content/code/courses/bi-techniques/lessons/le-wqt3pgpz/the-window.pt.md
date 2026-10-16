---
title: A janela de observação
version: 1
---

A tabela da seção anterior contou a idade em **meses de calendário**: um pedido feito em fevereiro por
um cliente que entrou em janeiro é mês 1, tenha ele entrado em 1º de janeiro ou em 31 de janeiro. É o
jeito mais simples de montar a tabela, e ele dá em silêncio quantidades diferentes de tempo a
clientes diferentes.

```schooling-example
{"language": "python", "file": "windows.py", "parts": [{"code": "import pandas as pd\n\ncustomers = pd.read_csv(\"customers.csv\", parse_dates=[\"signup\"])\norders = pd.read_csv(\"orders.csv\", parse_dates=[\"date\"])\norders = orders.merge(customers[[\"customer\", \"signup\"]], on=\"customer\")\njoined = customers[customers[\"signup\"] < \"2025-06-01\"].copy()\njoined[\"part\"] = pd.cut(joined[\"signup\"].dt.day, [0, 10, 20, 31],\n                        labels=[\"days 1-10\", \"days 11-20\", \"days 21-31\"])", "note": "Clientes que se cadastraram antes de junho de 2025, para todo mundo ter tido pelo menos trinta dias, agrupados pela parte do mês em que entraram."}, {"code": "calendar = orders[(orders[\"date\"].dt.to_period(\"M\") - orders[\"signup\"].dt.to_period(\"M\"))\n                  .apply(lambda d: d.n) == 0]\ndays = orders[(orders[\"date\"] - orders[\"signup\"]).dt.days < 30]", "note": "Dois jeitos de dizer \"o primeiro mês\": o resto do mês de calendário em que entraram, e os trinta dias a partir da data de cadastro."}, {"code": "joined[\"orders, rest of signup month\"] = joined[\"customer\"].map(calendar.groupby(\"customer\").size())\njoined[\"orders, first 30 days\"] = joined[\"customer\"].map(days.groupby(\"customer\").size())\nprint(joined.groupby(\"part\", observed=True)[[\"orders, rest of signup month\",\n                                             \"orders, first 30 days\"]].mean().round(2).to_string())", "note": "O número médio de pedidos em cada versão do primeiro mês."}], "output": "            orders, rest of signup month  orders, first 30 days\npart                                                           \ndays 1-10                           2.69                   3.24\ndays 11-20                          1.87                   3.22\ndays 21-31                          1.14                   3.21"}
```

**Clientes que entraram nos dez primeiros dias fizeram 2,69 pedidos no resto do mês de cadastro;
clientes que entraram nos dez últimos fizeram 1,14.** Eles não estão menos animados. Tinham menos mês
pela frente. Contados em trinta dias a partir do cadastro de cada um, os três grupos ficam quase
idênticos: 3,24, 3,22 e 3,21.

A mesma distorção passa pela tabela inteira. O mês 0 é um mês cheio para alguns clientes e um dia para
outros, e o mês 1 começa um dia depois do cadastro para alguns e trinta dias depois para outros. Numa
coorte de algumas centenas, as datas de entrada se espalham pelo mês e os erros quase se anulam, e é
por isso que meses de calendário ainda são comuns. Eles param de se anular no momento em que o
espalhamento é desigual: uma coorte dominada por uma campanha no dia 28, ou um mês com um feriado numa
ponta.

## Escolher a janela

| janela | como a idade é contada | bom para | cuidado com |
|---|---|---|---|
| **meses de calendário** | mês do evento menos mês do início | relatórios alinhados ao calendário | exposição desigual dentro do mês 0 e do mês 1 |
| **dias desde o início**, em blocos de 30 ou 7 | dias entre o evento e o início | comparar comportamento com justiça | um "mês" que não é mais um mês de calendário |

**Qualquer que seja a usada, ela é escrita ao lado da tabela.** Um número de retenção sem a sua janela
não pode ser comparado com outro, e dois times citando "retenção no mês 1" pelas duas definições podem
diferir em vários pontos estando os dois certos.
