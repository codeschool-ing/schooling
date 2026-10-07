---
title: Colunas derivadas
version: 1
---

Uma **variável derivada** é uma coluna calculada a partir de outras: a hora de um pedido a partir
do seu horário, o número de itens a partir dos itens do pedido, a idade de um cliente a partir do
ano de nascimento. Nenhuma delas acrescenta informação que não estava lá. O que elas acrescentam é
uma pergunta que agora cabe numa linha: as cestas de sábado são maiores, empresas pedem mais
itens, quando o aplicativo fica movimentado.

O primeiro passo é um ponto de partida com que todos concordam. A aula 9 tomou três decisões sobre
os totais dos pedidos, e elas são aplicadas uma vez, num arquivo só, para que nenhuma coluna
seguinte seja construída sobre um valor que uma aula anterior já corrigiu:

```schooling-example
{
  "language": "python",
  "file": "ready.py",
  "parts": [
    {
      "code": "from orders import orders  # lesson 9: totals as numbers, each customer's name from the CRM\nfrom typos import wrong\nfrom when import orders as timed\n\n",
      "note": "Os pedidos da aula 9 e os seus sete totais digitados errado, e os horários em São Paulo da aula 7."
    },
    {
      "code": "fix = orders[\"order_id\"].isin(wrong[\"order_id\"])\norders.loc[fix, \"total\"] = orders.loc[fix, \"order_id\"].map(wrong.set_index(\"order_id\")[\"expected\"])\n",
      "note": "**Os sete totais digitados errado** trocados pelo que os próprios itens somam."
    },
    {
      "code": "orders[\"total\"] = orders[\"total\"].clip(lower=0)  # lesson 9: a coupon above the basket is charged 0\n",
      "note": "**Um total negativo vira 0**: o cupom era maior que a cesta."
    },
    {
      "code": "orders[\"placed\"] = orders[\"order_id\"].map(timed.set_index(\"order_id\")[\"placed\"])\n",
      "note": "O horário de cada pedido em São Paulo, juntado pela chave."
    }
  ]
}
```

Depois, as colunas derivadas, uma linha cada:

```schooling-example
{
  "language": "python",
  "file": "derive.py",
  "parts": [
    {
      "code": "from lines import lines\nfrom ready import orders\n\n",
      "note": "Os itens e os pedidos como o `ready.py` os deixou."
    },
    {
      "code": "CORPORATE = \"Ltda|Escritório|Clínica|Colégio|Agência|Studio\"  # lesson 9's December buyers\n\n",
      "note": "O padrão que a aula 9 usou para reconhecer nome de empresa."
    },
    {
      "code": "orders[\"hour\"] = orders[\"placed\"].dt.hour\norders[\"weekday\"] = orders[\"placed\"].dt.day_name()\n",
      "note": "**Hora e dia da semana**, a partir do horário limpo."
    },
    {
      "code": "orders[\"items\"] = orders[\"order_id\"].map(lines.groupby(\"order_id\").size())\n",
      "note": "**Itens por pedido**, contados nos itens e mapeados pela chave."
    },
    {
      "code": "orders[\"corporate\"] = orders[\"name\"].str.contains(CORPORATE, na=False)\n",
      "note": "**Uma marca, não uma exclusão**: verdadeira nos dezesseis pedidos corporativos."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from derive import orders; print(orders[['order_id', 'placed', 'hour', 'weekday', 'items', 'total', 'corporate']].head(4).to_string(index=False))"
order_id              placed  hour   weekday  items  total  corporate
  100001 2025-01-01 07:00:30     7 Wednesday      1  66.60      False
  100002 2025-01-01 08:07:08     8 Wednesday      2  46.70      False
  100003 2025-01-01 08:24:01     8 Wednesday      4 108.30      False
  100004 2025-01-01 09:53:12     9 Wednesday      2 132.75      False
ana@lab:~/clean$ python -c "from derive import orders; print(orders['items'].isna().sum(), orders['corporate'].sum()); print(orders.groupby('weekday')['total'].agg(['size', 'median']).round(2).to_string())"
0 16
           size  median
weekday                
Friday     5400   58.15
Monday     3836   56.88
Saturday   5093   57.85
Sunday     2599   55.25
Thursday   3816   58.58
Tuesday    3857   58.45
Wednesday  3925   57.45
```

Todo pedido tem pelo menos um item, então `items` não tem vazios; essa verificação vale a sua
linha, porque um pedido sem itens seria um problema de junção da aula 11 aparecendo aqui como
zero. Dezesseis pedidos estão marcados como corporativos, os compradores de dezembro que a aula 9
achou. **Eles são marcados, não removidos**: uma coluna diz o que são, e cada análise decide se os
inclui.

A tabela dos dias da semana mostra para que serve uma coluna derivada. Sextas e sábados trazem mais
pedidos, domingos menos, e a mediana da cesta quase não se mexe ao longo da semana, entre R$ 55,25 e
R$ 58,58. É uma descoberta sobre volume, não sobre tamanho de cesta, e bastou uma coluna derivada
para vê-la.

Três hábitos mantêm as colunas derivadas honestas:

- **Derive da coluna limpa, nunca da bruta.** `placed` é o horário em São Paulo da aula 7;
  derivar a hora do `ordered_at` bruto deixaria todo pedido do site três horas fora.
- **Dê à coluna o nome do que ela guarda**, com a unidade quando houver: `items`, não `n`;
  `days_since`, não `recency`.
- **Escreva a fórmula em código, uma vez.** Uma coluna derivada calculada à mão numa célula de
  planilha é um valor que ninguém consegue recalcular quando os dados mudam.
