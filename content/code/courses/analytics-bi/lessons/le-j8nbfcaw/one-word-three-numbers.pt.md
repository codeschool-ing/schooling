---
title: A receita, do jeito que três times a calculam
version: 1
---

A imagem mais comum de uma métrica é que ela é um número: a receita foi tanto no trimestre
passado, e quem calcular corretamente chega à mesma resposta. **Uma métrica não é um número. É
uma definição, e o número é o que a definição produz num dado dia.** Duas pessoas que concordam
na palavra e discordam na definição vão calcular as duas corretamente e chegar a números
diferentes, e cada uma vai achar que a outra errou.

Aqui está o primeiro trimestre de 2026 da Lantern, do jeito que três times calculariam "receita"
a partir da mesma tabela, cada um com um motivo:

```
lantern=# SELECT round(sum(gross_cents) / 100.0, 2) AS marketing,
lantern-#        round(sum(gross_cents - gross_cents * discount_pct / 100) / 100.0, 2) AS ecommerce,
lantern-#        round(sum(gross_cents - gross_cents * discount_pct / 100)
lantern(#          FILTER (WHERE status = 'paid' AND customer_id <> 1) / 100.0, 2) AS finance
lantern-# FROM order_totals
lantern-# WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01';
 marketing | ecommerce |  finance  
-----------+-----------+-----------
 329036.20 | 305267.62 | 294209.60
(1 row)
```

O **marketing** reporta R$ 329.036,20: o valor de todo pedido feito, porque o que ele quer saber é
quanta demanda as campanhas produziram, e um pedido estornado foi demanda. O **gerente de
e-commerce** reporta R$ 305.267,62: o que foi cobrado dos clientes depois dos cupons, porque é o
que o checkout recebeu. O **financeiro** reporta R$ 294.209,60: só os pedidos que continuaram
pagos, sem a conta de teste da loja, porque esse é o dinheiro que entrou e ficou.

Nenhum dos três está errado. Cada um responde a uma pergunta diferente, e a distância entre o
primeiro e o último é de R$ 34.826,60, mais de um décimo do valor do trimestre. O defeito não está
em consulta nenhuma. **Está em a mesma palavra nomear as três**, de modo que um slide que diz
"receita: R$ 329 mil" e um relatório para o conselho que diz "receita: R$ 294 mil" parecem uma
contradição, e uma reunião é gasta para descobrir que não são.

Esta aula é sobre eliminar essa reunião: nomear do que uma métrica é feita, escrever a definição
onde toda ferramenta e toda pessoa leem a mesma frase, e conciliar dois números quando eles
discordam.
