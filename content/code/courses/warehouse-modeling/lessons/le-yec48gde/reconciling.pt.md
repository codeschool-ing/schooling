---
title: Conciliando os números
version: 1
---

Conciliar dois números significa explicar a diferença entre eles com exatidão, ao centavo, em vez de declarar um
deles errado. Financeiro e vendas diferem naquilo que o financeiro inclui e vendas não, e o frete é o primeiro
suspeito:

```sql
-- Where do finance and sales part company? Shipping is the obvious suspect.
SET TimeZone = 'America/Sao_Paulo';
SELECT sum(shipping_cents) AS shipping,
       count(*) FILTER (WHERE paid_at IS NULL) AS orders_never_paid_online,
       count(*) FILTER (WHERE paid_at IS NULL AND status = 'completed') AS of_which_in_a_shop
FROM read_csv('extract/orders.csv')
WHERE CAST(ordered_at AS DATE) BETWEEN '2025-12-01' AND '2025-12-31'
  AND status <> 'cancelled';
```

```
ana@lab:~/wh$ duckdb wh.duckdb < reconcile.sql
┌──────────┬──────────────────────────┬────────────────────┐
│ shipping │ orders_never_paid_online │ of_which_in_a_shop │
│  int128  │          int64           │       int64        │
├──────────┼──────────────────────────┼────────────────────┤
│ 17924700 │                    23405 │              23405 │
└──────────┴──────────────────────────┴────────────────────┘
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT 773739182 - 755814482 AS finance_minus_sales"
┌─────────────────────┐
│ finance_minus_sales │
│        int32        │
├─────────────────────┤
│            17924700 │
└─────────────────────┘
```

**O frete explica a diferença inteira.** O dezembro do financeiro é o dezembro de vendas mais 17.924.700 centavos de
frete, e mais nada: os dois marts concordam sobre cada pedido e cada livro, e discordam só sobre se frete é receita.
Isso é uma decisão de negócio, e tem dono: o financeiro, provavelmente, ou quem assina as contas.

O número do marketing está mais longe por dois motivos. A data dele é a do pagamento, então um pedido feito em 30 de
novembro e pago em 1º de dezembro conta em dezembro. E **23.405 pedidos de dezembro não têm data de pagamento
nenhuma**: todos eles estão `completed`, o status de uma venda no caixa de uma loja, onde o dinheiro é recebido
enquanto o livro troca de mãos e nenhuma hora de pagamento separada é registrada. O mart do marketing foi construído a
partir dos hábitos do site e deixa de fora, em silêncio, todas as lojas. Isso não é uma definição; é um defeito, e
ninguém o tinha visto, porque ninguém nunca tinha posto os três números lado a lado.

A lição que Kimball tirou de reuniões assim é que as dimensões não são a única coisa que precisa ser compartilhada.
**As medidas também precisam ser conformadas**: uma definição para cada, escrita, com um nome próprio. "Receita" é
uma palavra que três times usam para três coisas. **Vendas líquidas** e **recebimentos** são duas medidas com duas
definições, e as duas podem morar num warehouse sem reunião. O dicionário de campos da lição 12 é onde essas
definições ficam guardadas.
