---
title: Conciliar: três totais que precisam concordar
version: 1
---

Uma transformação pode estar certa em cada arquivo e errada no total, e o jeito mais barato de
descobrir é somar alguma coisa de dois jeitos que não compartilham código. **A receita da Ponto
Final pode ser calculada de três jeitos**, a partir de três tabelas diferentes:

- o mart, depois do staging, dos joins e do agrupamento;
- as linhas, como quantidade vezes preço unitário, direto do `raw`;
- os pagamentos, o dinheiro que a loja de fato recebeu, direto do `raw`.

```
ana@vm:~/etl$ psql -d wh -c "SELECT (SELECT sum(revenue_cents) FROM marts.daily_sales) AS mart, (SELECT sum(l.quantity * l.unit_price_cents) FROM raw.order_lines l JOIN raw.orders o USING (order_id) WHERE o.status = 'completed') AS lines, (SELECT sum(p.amount_cents) FROM raw.payments p JOIN raw.orders o USING (order_id) WHERE o.status = 'completed') AS payments"
   mart    |   lines   | payments  
-----------+-----------+-----------
 212162290 | 212162290 | 212162290
(1 row)
```

Três números, até o centavo: R$ 2.121.622,90 em cada um. O mart não perdeu nada nos joins nem contou
nada duas vezes, as linhas somam o que foi cobrado, e cada pedido concluído foi pago por inteiro. Se o
primeiro número fosse maior que o terceiro, o mart teria feito fan-out. Se o segundo diferisse do
terceiro, os próprios dados da loja discordariam entre si — um caixa que cobrou algo diferente da soma
das suas linhas — e essa seria uma pergunta para a loja, não para o pipeline.

## Para que serve uma conciliação

**Ela não é um teste de um arquivo em particular. É um teste da transformação inteira contra um fato
que a transformação não produziu.** É isso que a faz valer mais que conferir cada passo: um bug em
qualquer lugar entre o `raw` e os `marts` aparece no único número do fim.

Três hábitos a tornam rotina:

- **escolha totais que importam para alguém** — receita, livros vendidos, pedidos — para que uma
  diferença vire uma conversa e não uma curiosidade;
- **concilie com a origem também, não só com a camada crua**, de vez em quando, porque a camada crua
  também pode estar errada, como mostrou o pedido perdido da lição 4;
- **rode sempre**, depois de cada montagem. A lição 16 a torna parte do pipeline, para que uma
  diferença pare a carga em vez de ser achada por quem lê o relatório.
