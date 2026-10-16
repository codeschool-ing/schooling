---
title: Perguntas no Metabase, e o join de que ninguém o avisou
version: 1
---

A aula 3 fez ao Metabase a primeira pergunta. Uma **pergunta** é a unidade de trabalho do Metabase:
uma consulta mais o jeito de desenhá-la. Há dois jeitos de escrever uma, e o menu **New** oferece os
dois:

- **Question** abre o editor da aula 3 — dados, filtros, resumos, agrupamentos, escolhidos em listas.
  É o que faz do Metabase uma ferramenta de autoatendimento: alguém que nunca escreveu SQL consegue
  perguntar "receita líquida por mês, de pedidos pagos, no Sul".
- **SQL query** abre um editor de SQL sobre o mesmo banco. É o que um analista usa quando o editor não
  consegue expressar a pergunta, e o resultado pode ser desenhado e salvo como qualquer outro.

Uma pergunta montada no editor pode virar SQL a qualquer momento (o **View SQL** da aula 3), mas não o
contrário: uma pergunta em SQL é opaca para o Metabase, que não consegue oferecer as colunas dela como
filtros a outras pessoas, do jeito que faz com uma pergunta do editor. **Prefira o editor onde ele
basta**, por esse motivo.

## Um join de que o Metabase não foi avisado

Peça a receita líquida por segmento e o editor parece se recusar: `Orders` não tem `segment`, e a lista
**by** não oferece as colunas do cliente. A camada da Lantern é feita de views, e views não carregam
chaves estrangeiras, então o Metabase não tem como saber que `orders.customer_id` aponta para
`customers`.

Avise-o, uma vez, nas configurações de admin: **Table Metadata**, depois o banco Lantern, a tabela
`Orders` e o campo `Customer ID`. Ponha o tipo semântico dele em **Foreign Key** e o destino em
`Customers → Customer ID`. Daí em diante a lista **by** em `Orders` oferece a região e o segmento do
cliente, e o Metabase escreve o join sozinho. Pedida a soma da receita líquida pelo segmento do
cliente, ele escreveu isto:

```
SELECT
  "customers__via__customer_id"."segment" AS "customers__via__customer_id__segment",
  SUM("semantic"."orders"."net_revenue") AS "sum"
FROM
  "semantic"."orders"
  LEFT JOIN (
    SELECT
      "semantic"."customers"."customer_id" AS "customer_id",
      "semantic"."customers"."signed_up" AS "signed_up",
      "semantic"."customers"."state" AS "state",
      "semantic"."customers"."region" AS "region",
      "semantic"."customers"."segment" AS "segment",
      "semantic"."customers"."acquisition_channel" AS "acquisition_channel"
    FROM
      "semantic"."customers"
  ) AS "customers__via__customer_id" ON "semantic"."orders"."customer_id" = "customers__via__customer_id"."customer_id"
GROUP BY
  "customers__via__customer_id"."segment"
ORDER BY
  "customers__via__customer_id"."segment" ASC
```

Salva como `segment.sql` e rodada com o papel que o Metabase usa:

```
ana@vm:~$ PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -f segment.sql
 customers__via__customer_id__segment |    sum    
--------------------------------------+-----------
 home                                 | 690935.35
 office                               | 355821.05
(2 rows)
```

Duas observações sobre o SQL. O join é um `LEFT JOIN` do fato para uma dimensão — a direção segura da
aula 3, uma linha por pedido mantida. E os números batem com a camada: R$ 690.935,35 para home e R$
355.821,05 para office, que somam os R$ 1.046.756,40 que a camada inteira guarda.

**O Table Metadata também é parte da camada semântica.** Uma chave estrangeira definida ali, uma coluna
escondida ali, uma descrição escrita ali: cada uma é uma definição que agora mora no Metabase, e não no
banco, e a pergunta da aula 3 vale — a próxima ferramenta que chegar a encontraria?
