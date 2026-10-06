---
title: BigQuery
version: 1
---

O **BigQuery** é o warehouse do Google Cloud, e o que mais esconde as máquinas. Não há cluster para criar:
você cria um **dataset**, que é um contêiner de tabelas, carrega dados e roda consultas. O Google decide
quantas máquinas uma consulta recebe.

As peças dele, no vocabulário das lições anteriores:

- O **armazenamento** é colunar, no formato próprio do Google, guardado no sistema de arquivos distribuído
  dele e cobrado por gigabyte ao mês.
- O **processamento** é medido em **slots**: um slot é uma unidade de capacidade de processamento, mais ou
  menos uma fatia do processador e da memória de uma máquina. Uma consulta recebe quantos slots conseguir
  usar, até o que o projeto permite.
- O **particionamento** é declarado por tabela, por uma coluna de data ou timestamp, pelo horário de
  ingestão, ou por uma faixa de inteiros. Uma consulta que filtra pela coluna de partição lê só as partições
  correspondentes, exatamente como as pastas Parquet fizeram na lição 7.
- O **clustering** é declarado em até quatro colunas, e ordena os dados dentro de cada partição por elas,
  para que blocos possam ser pulados pelas estatísticas, os zone maps da lição 8.

O DDL da tabela fato da Ana, no dialeto do BigQuery (**não executado**: não há BigQuery neste laboratório):

```sql
CREATE TABLE ponto_final.fact_sales (
  sale_date      DATE,
  shop_key       INT64,
  book_key       INT64,
  customer_key   INT64,
  promotion_key  INT64,
  order_id       INT64,
  line_no        INT64,
  quantity       INT64,
  gross_cents    INT64,
  discount_cents INT64,
  net_cents      INT64
)
PARTITION BY sale_date
CLUSTER BY shop_key, book_key;
```

Uma mudança em relação ao laboratório é deliberada: a data é uma coluna `DATE` e não uma chave inteira, porque
o BigQuery particiona por uma coluna de data. A dimensão `dim_date` continua, ligada pela própria data. As
colunas de clustering são as que as consultas filtram depois da data, que é o conselho da lição 8 sobre a
ordem, escrito como declaração.

O BigQuery oferece dois jeitos de pagar pelo processamento: **sob demanda**, pelos bytes que cada consulta lê,
e por **capacidade**, pelos slots reservados por hora. O primeiro é o que muda o projeto de um modelo, e é a
próxima seção.
