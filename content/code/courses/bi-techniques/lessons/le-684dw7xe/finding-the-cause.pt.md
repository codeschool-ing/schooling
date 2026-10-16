---
title: Encontrando a causa
version: 1
---

Uma auditoria diz que um grupo é tratado diferente. Não diz por quê, e **o porquê decide a correção**.
Uma diferença que vem de os clientes do Norte de fato se comportarem diferente pediria uma resposta;
uma diferença que vem de o modelo lê-los errado pede outra. O lugar de começar são as entradas do
modelo, e como cada uma fica para o grupo.

```schooling-example
{"language": "python", "file": "rhythm.py", "parts": [{"code": "import pandas as pd\n\ncustomers = pd.read_csv(\"customers.csv\").set_index(\"customer\")\norders = pd.read_csv(\"orders.csv\", parse_dates=[\"date\"]).sort_values(\"date\")\norders[\"gap\"] = orders.groupby(\"customer\")[\"date\"].diff().dt.days\norders = orders.join(customers, on=\"customer\")\nprint(\"median days between a customer's orders\")\nprint(orders.pivot_table(index=\"region\", columns=\"plan\", values=\"gap\", aggfunc=\"median\"))", "note": "Os dias entre cada pedido e o pedido anterior do mesmo cliente, depois a mediana por região e plano: o ritmo em que cada tipo de cliente pede."}, {"code": "scored = pd.read_csv(\"scored.csv\", index_col=\"customer\")\nstayed = scored[scored[\"churned\"] == 0]\nprint(\"\\ncustomers who stayed, on 30 Jun 2025\")\nprint(stayed.groupby(\"region\")[[\"recency\", \"orders_90\", \"risk\"]].mean().round(2))", "note": "Só os clientes que ficaram: o que o modelo viu deles, e o risco que lhes deu."}], "output": "median days between a customer's orders\nplan       fortnightly  weekly\nregion                        \nNorth             21.0    14.0\nNortheast         14.0     7.0\nSouth             14.0     7.0\nSoutheast         14.0     7.0\n\ncustomers who stayed, on 30 Jun 2025\n           recency  orders_90  risk\nregion                             \nNorth        11.84       3.80  0.14\nNortheast     7.67       6.96  0.09\nSouth         7.10       6.75  0.09\nSoutheast     7.35       6.68  0.09"}
```

A primeira tabela é a causa. **Um cliente no Norte pede a cada 14 dias no plano semanal e a cada 21
no quinzenal**, uma semana mais devagar que o mesmo plano em qualquer outro lugar, porque as entregas
chegam ao Norte uma semana depois. A segunda tabela é como o modelo vê isso: os clientes fiéis do Norte
têm recência de 11,84 dias contra 7,10 a 7,67 nas outras regiões, e 3,80 pedidos em 90 dias contra
6,68 a 6,96. As duas entradas dizem "esfriando", e o modelo, que aprendeu com uma população 74% do
Sudeste, as lê como elas se leem no Sudeste. **O risco médio que ele dá a um cliente fiel do Norte é
0,14, contra 0,09 em todo o resto.**

Isto é **viés de medição**. Recência e contagem de pedidos foram escolhidas como medidas de
engajamento, e para a maioria dos clientes elas são. Para um cliente cuja caixa chega uma semana
atrasada, elas medem geografia. Nada está errado no dado: toda data nele está correta. O que está
errado é supor que onze dias de silêncio querem dizer a mesma coisa para todo mundo.

É também um caso de **viés de agregação**, já que um modelo só foi ajustado às quatro regiões. E é
viés de representação, já que o Norte é uma fatia pequena demais do dado de treino para o modelo
aprender o ritmo dele sozinho.

## Uma causa é uma afirmação

Que as entregas levam uma semana a mais é algo que o time de logística da Panela pode confirmar ou
negar, e um analista deveria perguntar a eles antes de construir uma correção em cima disso. O dado
mostra um ritmo mais lento; o motivo do ritmo vem de fora do dado. Uma correção para a causa errada
pode deixar a disparidade no lugar e acrescentar uma história que faz todo mundo parar de olhar.
