---
title: Um padrão, não um valor
version: 1
---

**Algumas anomalias se escondem à vista porque nenhum valor isolado é incomum.** Um pedido de R$ 200
com status `refunded` é comum; reembolsos acontecem quando uma cesta chega danificada. Vinte e três
deles de uma conta em três dias não são. O teste para esse tipo não é uma distância numa coluna, mas
um resumo por entidade — aqui, por cliente:

```schooling-example
{
  "language": "python",
  "file": "refunds.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom orders import orders\n\n"
    },
    {
      "code": "orders[\"placed\"] = pd.to_datetime(orders[\"ordered_at\"].str[:19].str.replace(\"T\", \" \"))\n",
      "note": "Um horário para medir intervalos. O UTC do site e a hora local do aplicativo diferem em três horas, o que não importa para intervalos de dias."
    },
    {
      "code": "per = orders.groupby(\"customer_id\").agg(\n    orders=(\"order_id\", \"count\"),\n    refunded=(\"status\", lambda s: (s == \"refunded\").sum()),\n    first=(\"placed\", \"min\"),\n    last=(\"placed\", \"max\"),\n)\n",
      "note": "**Uma linha por cliente**: pedidos, reembolsos, primeiro e último pedido."
    },
    {
      "code": "per[\"refund_rate\"] = (per[\"refunded\"] / per[\"orders\"]).round(2)\n",
      "note": "A fração dos pedidos de um cliente que foi reembolsada."
    },
    {
      "code": "print(f\"customers: {len(per)}, median refund rate: {per['refund_rate'].median():.2f}\")\nprint(per.sort_values(\"refunded\", ascending=False).head(4).to_string())\n",
      "note": "O cliente típico, e os quatro com mais reembolsos."
    }
  ]
}
```

```
ana@lab:~/clean$ python refunds.py
customers: 2273, median refund rate: 0.00
             orders  refunded               first                last  refund_rate
customer_id                                                                       
C01857           23        23 2025-08-12 10:33:15 2025-08-14 21:21:11         1.00
C01009           42         6 2025-01-05 21:06:05 2025-12-29 23:59:09         0.14
C00249           45         4 2025-01-04 18:19:53 2025-12-23 14:30:34         0.09
C00784           46         4 2025-02-03 19:03:14 2025-12-30 12:46:44         0.09
```

O cliente mediano tem taxa de reembolso zero. Os três clientes seguintes com mais reembolsos têm um
punhado ao longo de um ano de compras comuns. **O cliente C01857 fez 23 pedidos em menos de três dias,
e todos foram reembolsados.** A conta:

```
ana@lab:~/clean$ psql -c "SELECT DISTINCT customer_id, signed_up, signup_channel, normalize(city, NFC) AS city FROM raw.customers WHERE customer_id = (SELECT customer_id FROM raw.orders WHERE status = 'refunded' GROUP BY 1 ORDER BY count(*) DESC LIMIT 1)"
 customer_id | signed_up  | signup_channel |   city    
-------------+------------+----------------+-----------
 C01857      | 08/11/2025 | app            | São Paulo
(1 row)
```

Cadastrada pelo aplicativo em 11 de agosto, na véspera do primeiro pedido. Uma conta nova, uma rajada
intensa, um reembolso em tudo, e depois silêncio: essa é a forma do abuso de reembolso, em que alguém
alega que as entregas falharam ou chegaram estragadas para ficar com a comida e receber o dinheiro de
volta.

**Isso é um achado para quem cuida de fraude, não um valor a limpar.** O trabalho da analista é
detectar e informar, com a evidência que torna tudo conferível — a conta, as datas, as contagens, a
comparação com todos os outros clientes — e mantê-lo fora das análises que ele distorceria, como uma
taxa de reembolso por cidade. Decidir se é fraude não cabe à analista: pode haver uma explicação que o
dado não mostra, como uma rota de entrega que falhou todo dia naquela semana.

O que torna o padrão visível é escolher a unidade certa. **Por pedido, nada se destaca; por cliente,
uma conta fica sozinha.** O mesmo movimento acha outros padrões de abuso — muitas contas dividindo um
endereço de entrega, cupons usados em muitas contas novas num único dia — e a análise exploratória da
aula 15 é onde o hábito de resumir por entidade vira rotina.
