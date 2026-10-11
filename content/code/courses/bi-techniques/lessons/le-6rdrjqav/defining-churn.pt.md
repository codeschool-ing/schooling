---
title: Definir churn
version: 1
---

**Um cliente deu churn quando não vai voltar.** Ninguém consegue observar isso: um cliente que não
pede há um mês pode estar de férias, pode pedir semana que vem, ou pode ter ido de vez. Uma assinatura
cancelada dá um evento claro; a maioria dos negócios, a Panela incluída para clientes que simplesmente
param de pedir, precisa definir churn a partir do silêncio.

```schooling-example
{"language": "python", "file": "churn.py", "parts": [{"code": "import pandas as pd\n\ncustomers = pd.read_csv(\"customers.csv\", parse_dates=[\"signup\"])\norders = pd.read_csv(\"orders.csv\", parse_dates=[\"date\"])\ncohort = customers[customers[\"signup\"].dt.to_period(\"M\") == \"2024-01\"]\nmine = orders[orders[\"customer\"].isin(cohort[\"customer\"])].merge(cohort, on=\"customer\")\nmine[\"month\"] = (mine[\"date\"].dt.to_period(\"M\") - mine[\"signup\"].dt.to_period(\"M\")).apply(lambda d: d.n)", "note": "A coorte de janeiro de 2024 e os pedidos dela."}, {"code": "last = mine.groupby(\"customer\")[\"month\"].max()\nprint(\"January 2024 cohort,\", len(cohort), \"customers\")\nprint(f\"{'month':>5} {'ordered that month':>19} {'still to order again':>21}\")\nfor m in (1, 3, 6, 12):\n    active = mine[mine[\"month\"] == m][\"customer\"].nunique() / len(cohort)\n    alive = (last >= m).sum() / len(cohort)\n    print(f\"{m:>5} {active:>19.0%} {alive:>21.0%}\")", "note": "Dois jeitos de contar um cliente numa idade: pediu naquele mês, ou ainda tinha um pedido por vir naquela idade ou depois."}, {"code": "gaps = orders.sort_values(\"date\").groupby(\"customer\")[\"date\"].diff().dt.days.dropna()\nprint(f\"\\ngaps between one order and the next, {len(gaps):,} of them\")\nfor q in (0.5, 0.9, 0.95, 0.99):\n    print(f\"  {q:.0%} of gaps are at most {gaps.quantile(q):.0f} days\")", "note": "Todo intervalo entre um pedido de um cliente e o seguinte, em dias, e quão longos são os mais longos."}], "output": "January 2024 cohort, 272 customers\nmonth  ordered that month  still to order again\n    1                 88%                   91%\n    3                 70%                   73%\n    6                 49%                   49%\n   12                 25%                   26%\n\ngaps between one order and the next, 97,772 of them\n  50% of gaps are at most 7 days\n  90% of gaps are at most 21 days\n  95% of gaps are at most 28 days\n  99% of gaps are at most 42 days"}
```

A primeira tabela compara duas contagens para a coorte de janeiro de 2024. **"Pediu naquele mês"** é
a retenção de atividade da aula 12. **"Ainda vai pedir de novo"** conta um cliente como vivo numa
idade se ele faz algum pedido naquela idade ou depois. Na Panela as duas ficam a poucos pontos, 88%
contra 91% no mês 1, porque clientes que param raramente voltam. Num negócio em que as pessoas pulam
meses, uma academia ou um serviço de streaming, as duas podem ficar bem longe, e a primeira subestima
quantos clientes ainda são clientes.

## Escolher o silêncio que conta

A segunda tabela é a base de uma definição defensável. Metade dos intervalos entre pedidos da Panela
são de uma semana, o tempo entre caixas semanais; **95 por cento são de no máximo 28 dias, e 99 por
cento de no máximo 42.** Um cliente em silêncio há mais tempo que quase todo intervalo que terminou em
outro pedido muito provavelmente foi embora.

Então uma definição como **"churn: nenhum pedido por 42 dias"** vem do dado e não de um número
redondo, e a escolha do percentil é uma troca:

- **um silêncio curto demais**, 14 dias, conta como churn muitos clientes que só estavam entre uma
  caixa e outra, e uma campanha de retenção gasta descontos com gente que ia voltar de qualquer jeito;
- **um silêncio longo demais**, 120 dias, percebe o churn meses depois de ele acontecer, tarde demais
  para fazer qualquer coisa.

Dois cuidados. **O limiar muda entre grupos cujo ritmo de pedido muda**: clientes quinzenais têm
intervalos normais mais longos que os semanais, e a aula 18 mostra o Norte da Panela recebendo as
caixas uma semana depois de todo mundo, então um limiar único trata o Norte como mais "perdido" do que
está. E **o churn só pode ser julgado onde o silêncio teve tempo de acontecer**: um cliente cujo último
pedido foi dez dias antes do fim do dado está indefinido, não ativo.
