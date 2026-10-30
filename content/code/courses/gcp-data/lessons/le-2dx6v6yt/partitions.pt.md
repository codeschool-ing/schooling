---
title: Particionamento, e os três jeitos de cortar uma tabela
version: 1
---

**Uma tabela particionada é uma tabela guardada em muitos pedaços, cortada pelo valor de uma coluna, e
uma consulta que cita essa coluna no filtro lê só os pedaços de que precisa.** A aula 14 mostrou que
sob demanda cobra os bytes das colunas que uma consulta lê. O particionamento decide quais linhas
dessas colunas ela tem de ler. Juntos, eles são a conta: uma consulta que cita duas colunas de uma
tabela cortada por dia, e pergunta sobre um dia, paga duas colunas de um dia. A mesma consulta numa
tabela sem partição paga duas colunas de todos os dias que a tabela guarda.

**Uma partição não é um índice, e a diferença importa para a conta.** Um índice ajuda um banco a achar
linhas mais rápido e não muda nada no que é cobrado. Uma partição muda o que o BigQuery lê antes de a
consulta começar, e por isso muda os bytes cobrados, e o dry run da aula 16 consegue imprimir a
diferença antes de qualquer coisa rodar. Tudo nesta seção vem da documentação do Google, "Introduction
to partitioned tables" e "Query partitioned tables", e da página de preços. A próxima seção pratica a
mesma ideia no DuckDB.

## Três jeitos de cortar

**Por uma coluna de data ou hora**, que é o que a Quitanda quer. A tabela cita uma coluna do tipo
`DATE`, `TIMESTAMP` ou `DATETIME`, e uma granularidade: `DAY`, `HOUR`, `MONTH` ou `YEAR`. Cada
linha vai para a partição do seu valor, e uma linha cujo valor é `NULL` vai para uma partição própria
chamada `__NULL__`. Os pedidos da Quitanda, particionados por `dt` e por dia, seriam uma partição por
dia, exatamente as sessenta pastas da aula 13.

**Por horário de ingestão**, para dado que não tem coluna de data em que se possa confiar. O BigQuery
põe cada linha na partição do momento em que ela chegou, e a expõe como duas pseudocolunas,
`_PARTITIONTIME` e `_PARTITIONDATE`, que uma consulta filtra como qualquer outra coluna. Serve para uma
tabela bruta de chegada, em que o momento da chegada é a única data certa; é errado para pedidos,
porque um pedido atrasado cai na partição do dia em que foi carregado e não na do dia em que foi feito.

**Por faixa de inteiros**, para uma coluna de número inteiro. A tabela cita a coluna, um início, um fim
e um intervalo, e cada intervalo é uma partição: `store_id` de 0 a 100 de dez em dez daria dez. Valores
fora da faixa vão para uma partição chamada `__UNPARTITIONED__`. Serve para uma tabela consultada por
uma chave numérica de faixa conhecida, como um número de cliente cortado em blocos, e é a mais rara das
três.

## A tabela, escrita

O DDL dos pedidos da Quitanda, em GoogleSQL, particionado por dia e clusterizado por loja. Ele aparece
como seria rodado e não foi rodado; a linha do clustering é explicada duas seções adiante:

```sql
CREATE TABLE quitanda.orders (
  order_id    STRING NOT NULL,
  customer_id STRING,
  store_id    INT64,
  district    STRING,
  items       INT64,
  total_cents INT64,
  payment     STRING,
  created_at  TIMESTAMP,
  dt          DATE
)
PARTITION BY dt
CLUSTER BY store_id
OPTIONS (require_partition_filter = TRUE, partition_expiration_days = 1095);
```

**`PARTITION BY dt` é a decisão**, e os outros dois tipos seriam escritos
`PARTITION BY _PARTITIONDATE` e `PARTITION BY RANGE_BUCKET(store_id, GENERATE_ARRAY(0, 100, 10))`.
As duas opções são as proteções que a próxima seção explica: uma recusa uma consulta que não filtra por
`dt`, e a outra apaga cada partição três anos depois da data dela.

## O que uma partição também compra

**Uma partição é uma unidade de armazenamento além de leitura.** A aula 13 precificou a consequência:
cada partição vai para longo prazo sozinha depois de 90 dias sem escrita, então uma tabela que recebe
um dia novo toda noite e nunca mexe nos antigos fica quase toda em longo prazo. **Apagar uma partição é
gratuito**: a página de preços põe apagar "individual table partitions" entre as operações gratuitas,
e `partition_expiration_days` faz isso numa agenda, sem consulta e sem conta. E um job noturno que
substitui os dados de um dia pode sobrescrever só essa partição e deixar os outros dias, e os relógios
de 90 dias deles, em paz.

**A coluna escolhida tem de ser a coluna pela qual as perguntas filtram.** Particionar por
`created_at` enquanto todo relatório filtra por `dt` leria todas as partições, porque o filtro não cita
a coluna de particionamento. Na Quitanda as duas guardam o mesmo dia, e os relatórios dizem `dt`, então
é `dt`. Uma tabela só pode ser particionada por uma coluna, e é por isso que o segundo filtro mais
comum vai para o clustering.
