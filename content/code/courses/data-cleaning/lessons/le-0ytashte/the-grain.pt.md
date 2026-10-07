---
title: O grão de uma tabela
version: 1
---

O **grão** de uma tabela é o que uma linha representa. Em `order_items` uma linha é um item de um
pedido; em `orders`, um pedido; no CRM, um cliente. Toda coluna derivada pertence a um grão, e a
maior parte dos erros com colunas derivadas é uma coluna calculada num grão e usada em outro.

Colunas no nível do cliente são feitas agrupando os pedidos, para que cada cliente vire uma linha:

```schooling-example
{
  "language": "python",
  "file": "per_customer.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "from derive import orders\nfrom years import customers\n\n",
      "note": "Os pedidos derivados, e os clientes com os anos de nascimento da aula 10."
    },
    {
      "code": "per = orders.groupby(\"customer_id\").agg(orders=(\"order_id\", \"size\"), revenue=(\"total\", \"sum\"),\n                                         first=(\"placed\", \"min\"), last=(\"placed\", \"max\"))\n",
      "note": "**Uma linha por cliente**: quantos pedidos, quanto, primeiro e último."
    },
    {
      "code": "per[\"days_since\"] = (pd.Timestamp(\"2026-01-01\") - per[\"last\"]).dt.days\n",
      "note": "Dias inteiros do último pedido até 1º de janeiro de 2026."
    },
    {
      "code": "per = per.join(customers.set_index(\"customer_id\")[\"birth\"])\n",
      "note": "O ano de nascimento, juntado pelo código do cliente."
    },
    {
      "code": "per[\"age\"] = 2025 - per[\"birth\"]  # the age reached during 2025\n",
      "note": "**A idade completada em 2025**: o ano de nascimento é tudo o que o CRM sabe."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from per_customer import per; print(len(per)); print(per.head(3).to_string())"
2273
             orders  revenue               first                last  days_since  birth   age
customer_id                                                                                  
C00001           10   840.05 2025-01-23 19:50:14 2025-12-28 16:29:57           3   1986    39
C00002           23  1639.30 2025-01-16 11:47:40 2025-12-22 17:33:44           9   1982    43
C00003           12  1046.75 2025-01-24 15:20:48 2025-12-18 20:53:31          13   <NA>  <NA>
```

2.273 linhas, uma por código de cliente que fez pedido em 2025: 2.241 dos 2.376 clientes do CRM,
e os 32 órfãos da aula 11, que têm pedidos e não têm linha no CRM. `C00003` é um dos órfãos, então
o `birth` e o `age` dele ficam vazios, como os de qualquer pessoa cujo ano de nascimento era um
marcador. `days_since` conta a partir de
1º de janeiro de 2026, o dia seguinte ao fim dos dados, então um cliente cujo último pedido foi
em 28 de dezembro está a 3 dias.

Agora, o erro. Suponha que um relatório precise de cada pedido ao lado da receita anual do seu
cliente, o que é razoável, e que alguém some essa coluna:

```
ana@lab:~/clean$ python -c "from derive import orders; from per_customer import per; wrong = orders.merge(per[['revenue']], left_on='customer_id', right_index=True); print(round(orders['total'].sum(), 2), round(wrong['revenue'].sum(), 2))"
2677679.5 52515704.25
```

A receita real é R$ 2.677.679,50. A soma sobre a coluna juntada é R$ 52.515.704,25, quase vinte
vezes mais, porque **um número do nível do cliente foi copiado para cada pedido desse cliente** e
depois somado uma vez por cópia. Um cliente com 23 pedidos entra com a sua receita 23 vezes.

É o leque da aula 11 com outra roupa, e a defesa é a mesma ideia: **saber o grão de cada tabela e
de cada coluna**. Uma coluna do nível do cliente numa tabela de pedidos pode ser mostrada,
comparada ou usada como filtro, mas nunca somada. Quando uma coluna precisa viver num grão mais
grosso, dê a ela um nome que diga isso, como `customer_revenue`, para que a próxima pessoa que for
usar `sum()` pare e leia antes.
